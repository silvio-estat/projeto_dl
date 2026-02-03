import os
import tempfile
from datetime import datetime, timedelta
from airflow.sdk import dag, task
from airflow.providers.amazon.aws.hooks.s3 import S3Hook

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
    dag_id="pdf_para_markdown_docling_ocr", # Atualizei o ID para refletir a mudança
    start_date=datetime(2025, 1, 1),
    schedule="@hourly",
    catchup=False,
    default_args=default_args,
    tags=["etl", "docling", "minio", "ocr"],
)
def pipeline_pdf_md():

    @task
    def listar_arquivos_pendentes():
        """
        Lista todos os PDFs no Bronze e verifica se já existem no Prata.
        """
        hook = S3Hook(aws_conn_id=CONN_ID)
        arquivos_bronze = hook.list_keys(bucket_name=BUCKET_ORIGEM) or []
        
        pdfs = [f for f in arquivos_bronze if f.lower().endswith('.pdf')]
        
        pendentes = []
        for pdf in pdfs:
            nome_md = pdf.rsplit('.', 1)[0] + ".md"
            existe = hook.check_for_key(key=nome_md, bucket_name=BUCKET_DESTINO)
            
            if not existe:
                pendentes.append(pdf)
                print(f"Novo arquivo encontrado: {pdf}")
            else:
                print(f"Arquivo já processado: {pdf}")
                
        return pendentes

    @task
    def converter_e_salvar(arquivo_pdf):
        """
        Baixa, converte (COM OCR EM PORTUGUÊS) e sobe o MD.
        """
        # Importações necessárias para a configuração avançada
        from docling.document_converter import DocumentConverter, PdfFormatOption
        from docling.datamodel.pipeline_options import PdfPipelineOptions, TesseractOcrOptions
        from docling.datamodel.base_models import InputFormat
        
        hook = S3Hook(aws_conn_id=CONN_ID)
        
        # --- CONFIGURAÇÃO AVANÇADA DO DOCLING (INJETADA AQUI) ---
        print(f"⚙️ Configurando Pipeline de OCR (Português) para {arquivo_pdf}...")

        # 1. Opções do pipeline: Ativar OCR e Tabelas
        pipeline_options = PdfPipelineOptions(
            do_ocr=True,
            do_table_structure=True,
            generate_picture_images=True
        )

        # 2. Configurar Tesseract para Português
        # IMPORTANTE: O container/servidor onde o Airflow roda precisa ter 
        # o pacote 'tesseract-ocr-por' instalado.
        pipeline_options.ocr_options = TesseractOcrOptions(lang=['por'])

        # 3. Instanciar o converter com as opções customizadas
        converter = DocumentConverter(
            format_options={
                InputFormat.PDF: PdfFormatOption(pipeline_options=pipeline_options)
            }
        )
        # ---------------------------------------------------------

        with tempfile.TemporaryDirectory() as tmp_dir:
            local_pdf = os.path.join(tmp_dir, os.path.basename(arquivo_pdf))
            local_md = os.path.splitext(local_pdf)[0] + ".md"
            
            # 1. Baixar do MinIO
            print(f"Baixando {arquivo_pdf}...")
            obj = hook.get_key(key=arquivo_pdf, bucket_name=BUCKET_ORIGEM)
            obj.download_file(local_pdf)
            
            # 2. Converter usando a instância configurada do Docling
            print("Iniciando conversão com OCR e estrutura de tabelas...")
            result = converter.convert(local_pdf)
            
            texto_md = result.document.export_to_markdown()
            
            # Salvar localmente
            with open(local_md, "w") as f:
                f.write(texto_md)
            
            # 3. Subir para o MinIO
            nome_destino_md = os.path.splitext(arquivo_pdf)[0] + ".md"
            print(f"Enviando {nome_destino_md} para {BUCKET_DESTINO}...")
            
            hook.load_file(
                filename=local_md,
                key=nome_destino_md,
                bucket_name=BUCKET_DESTINO,
                replace=True
            )

    # --- ORQUESTRAÇÃO ---
    lista_de_pdfs = listar_arquivos_pendentes()
    converter_e_salvar.expand(arquivo_pdf=lista_de_pdfs)

pipeline = pipeline_pdf_md()