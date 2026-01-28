import os
import tempfile
from datetime import datetime, timedelta
from airflow.sdk import dag, task
from airflow.providers.amazon.aws.hooks.s3 import S3Hook

# --- CONFIGURAÇÕES ---
# Nome da conexão que criaremos na UI do Airflow (Passo final)
CONN_ID = "minio_local"
BUCKET_ORIGEM = "bronze"
BUCKET_DESTINO = "prata"

default_args = {
    "owner": "Silvio",
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}

@dag(
    dag_id="pdf_para_markdown_docling",
    start_date=datetime(2025, 1, 1),
    schedule="@hourly", # Roda a cada hora (pode mudar para @daily ou None)
    catchup=False,
    default_args=default_args,
    tags=["etl", "docling", "minio"],
)
def pipeline_pdf_md():

    @task
    def listar_arquivos_pendentes():
        """
        Lista todos os PDFs no Bronze e verifica se já existem no Prata.
        Retorna apenas os que precisam ser processados.
        """
        # Hook é a ferramenta do Airflow para conectar no S3/MinIO
        hook = S3Hook(aws_conn_id=CONN_ID)
        
        # 1. Listar arquivos no bucket Bronze
        # (O MinIO usa a mesma estrutura do S3, então o S3Hook funciona perfeitamente)
        arquivos_bronze = hook.list_keys(bucket_name=BUCKET_ORIGEM) or []
        
        # Filtra apenas PDFs
        pdfs = [f for f in arquivos_bronze if f.lower().endswith('.pdf')]
        
        pendentes = []
        for pdf in pdfs:
            # Define qual seria o nome do arquivo convertido
            nome_md = pdf.rsplit('.', 1)[0] + ".md"
            
            # Verifica se esse MD já existe no destino
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
        Recebe o nome de um arquivo PDF, baixa, converte e sobe o MD.
        """
        from docling.document_converter import DocumentConverter
        from docling.datamodel.base_models import InputFormat
        
        hook = S3Hook(aws_conn_id=CONN_ID)
        
        # Cria uma pasta temporária que se autodestrói no fim da task
        with tempfile.TemporaryDirectory() as tmp_dir:
            local_pdf = os.path.join(tmp_dir, os.path.basename(arquivo_pdf))
            local_md = os.path.splitext(local_pdf)[0] + ".md"
            
            # 1. Baixar do MinIO
            print(f"Baixando {arquivo_pdf}...")
            obj = hook.get_key(key=arquivo_pdf, bucket_name=BUCKET_ORIGEM)
            obj.download_file(local_pdf)
            
            # 2. Converter usando Docling
            print("Iniciando conversão com Docling...")
            converter = DocumentConverter()
            result = converter.convert(local_pdf)
            
            # Exportar para Markdown
            texto_md = result.document.export_to_markdown()
            
            # Salvar o MD localmente
            with open(local_md, "w") as f:
                f.write(texto_md)
            
            # 3. Subir para o MinIO (Bucket Prata)
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
    
    # "Dynamic Task Mapping": Cria uma task separada para CADA PDF encontrado.
    # Se achar 10 PDFs, cria 10 tasks de conversão em paralelo.
    converter_e_salvar.expand(arquivo_pdf=lista_de_pdfs)

pipeline = pipeline_pdf_md()