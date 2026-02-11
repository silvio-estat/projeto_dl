import os
import tempfile
from datetime import datetime, timedelta
from airflow.sdk import dag, task
from airflow.providers.amazon.aws.hooks.s3 import S3Hook
import gc 
from airflow.exceptions import AirflowTaskTimeout

# --- CONFIGURAÇÕES ---
CONN_ID = "minio_conn"
BUCKET_ORIGEM = "bronze"
BUCKET_DESTINO = "prata"

default_args = {
    "owner": "Silvio",
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}

@dag(
    dag_id="pdf_para_markdown_docling_ocr3", # Atualizei o ID para refletir a mudança
    start_date=datetime(2025, 1, 1),
    schedule="@hourly",
    catchup=False,
    default_args=default_args,
    tags=["etl", "docling", "minio", "ocr"],
)
def pipeline_pdf_md():

    @task
    def listar_arquivos_pendentes():
        print("🔍 Listando arquivos no MinIO (Modo Caminho Completo)...")
        hook = S3Hook(aws_conn_id=CONN_ID)
        
        # 1. Listar chaves brutas
        arquivos_bronze = hook.list_keys(bucket_name=BUCKET_ORIGEM) or []
        arquivos_prata = hook.list_keys(bucket_name=BUCKET_DESTINO) or []
        
        print(f"Total de objetos no Bronze: {len(arquivos_bronze)}")
        print(f"Total de objetos no Prata: {len(arquivos_prata)}")

        # 2. Normalizar Bronze (Mantendo o caminho, removendo apenas a extensão)
        # Ex: 'Manuais/COTER/doc1.pdf' vira 'manuais/coter/doc1'
        set_bronze_paths = set()
        mapa_original = {} # Para recuperar o nome com letras maiúsculas/minúsculas originais

        for f in arquivos_bronze:
            if f.lower().endswith('.pdf'):
                # Removemos a extensão (.pdf) e forçamos minúsculo, mas MANTEMOS AS PASTAS
                path_sem_ext = os.path.splitext(f)[0].lower()
                set_bronze_paths.add(path_sem_ext)
                mapa_original[path_sem_ext] = f
            
        # 3. Normalizar Prata
        set_prata_paths = set()
        for f in arquivos_prata:
            if f.lower().endswith('.md'):
                # Removemos a extensão (.md) e forçamos minúsculo
                path_sem_ext = os.path.splitext(f)[0].lower()
                
                # Opcional: Checagem de tamanho > 0
                try:
                    # Otimização: Se tiver muitos arquivos, comente o head_object para ganhar tempo
                    # obj = hook.head_object(key=f, bucket_name=BUCKET_DESTINO)
                    # if obj.get('ContentLength', 0) > 0:
                    set_prata_paths.add(path_sem_ext)
                except:
                    pass

        # 4. Diferença de Conjuntos
        # O que tem no Bronze (como path) que não tem no Prata (como path)
        paths_pendentes = set_bronze_paths - set_prata_paths
        
        # 5. Reconstrói a lista final usando o nome original do PDF
        lista_final = [mapa_original[p] for p in paths_pendentes]
        
        print(f"📉 Análise Final:")
        print(f"   PDFs Válidos no Bronze: {len(set_bronze_paths)}")
        print(f"   MDs Válidos no Prata: {len(set_prata_paths)}")
        print(f"   Diferença (Pendentes): {len(lista_final)}")
        
        if len(lista_final) == 0:
            print("✅ Tudo sincronizado. Se faltam arquivos, verifique se são .parquet ou se não são PDFs.")
            
        return lista_final

    @task(
    pool="pool_docling_serial", 
    # DEFESA 1: Se travar por 20 min, mata e tenta de novo (OOM muitas vezes trava o processo)
    execution_timeout=timedelta(minutes=20), 
    retries=3, # Tenta 3 vezes antes de desistir do arquivo
    retry_delay=timedelta(minutes=2), # Espera o sistema "esfriar/liberar RAM"
    )
    def converter_e_salvar(arquivo_pdf):
        """
        Baixa, converte (COM OCR EM PORTUGUÊS) e sobe o MD com gestão de memória.
        """
        # Importações dentro da task para evitar overhead no Parse da DAG
        from docling.document_converter import DocumentConverter, PdfFormatOption
        from docling.datamodel.pipeline_options import PdfPipelineOptions, TesseractOcrOptions
        from docling.datamodel.base_models import InputFormat
        
        print(f"🚀 Iniciando processamento blindado para: {arquivo_pdf}")
        
        hook = S3Hook(aws_conn_id=CONN_ID)
        
        try:
            # --- CONFIGURAÇÃO DOCLING ---
            pipeline_options = PdfPipelineOptions(
                do_ocr=True,
                do_table_structure=True,
                generate_picture_images=True
            )
            pipeline_options.ocr_options = TesseractOcrOptions(lang=['por'])

            # Instancia o conversor
            converter = DocumentConverter(
                format_options={
                    InputFormat.PDF: PdfFormatOption(pipeline_options=pipeline_options)
                }
            )

            with tempfile.TemporaryDirectory() as tmp_dir:
                local_pdf = os.path.join(tmp_dir, os.path.basename(arquivo_pdf))
                local_md = os.path.splitext(local_pdf)[0] + ".md"
                
                # Baixar
                obj = hook.get_key(key=arquivo_pdf, bucket_name=BUCKET_ORIGEM)
                obj.download_file(local_pdf)
                
                # Converter
                print("⏳ Aplicando OCR (isso consome muita RAM)...")
                result = converter.convert(local_pdf) # Ponto crítico de falha
                texto_md = result.document.export_to_markdown()
                
                # Salvar Local
                with open(local_md, "w") as f:
                    f.write(texto_md)
                
                # Upload
                nome_destino_md = os.path.splitext(arquivo_pdf)[0] + ".md"
                hook.load_file(
                    filename=local_md,
                    key=nome_destino_md,
                    bucket_name=BUCKET_DESTINO,
                    replace=True
                )
                print(f"✅ Sucesso: {arquivo_pdf}")

        except AirflowTaskTimeout:
            print(f"⏰ Timeout! O arquivo {arquivo_pdf} demorou demais ou travou.")
            raise # Garante que o Airflow saiba que falhou para acionar o retry

        except Exception as e:
            print(f"❌ Erro no arquivo {arquivo_pdf}: {str(e)}")
            raise # Relança a exceção para contar como falha e acionar retry

        finally:
            # DEFESA 2: Limpeza explícita de memória
            # Isso é crucial quando rodamos OCR pesado em loop ou workers limitados
            print("🧹 Executando Garbage Collection...")
            if 'converter' in locals(): del converter
            if 'result' in locals(): del result
            if 'texto_md' in locals(): del texto_md
            gc.collect() # Chama o lixeiro do Python imediatamente

    # --- ORQUESTRAÇÃO ---
    lista_de_pdfs = listar_arquivos_pendentes()
    converter_e_salvar.expand(arquivo_pdf=lista_de_pdfs)

pipeline = pipeline_pdf_md()