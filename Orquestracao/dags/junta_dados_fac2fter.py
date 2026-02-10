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
    dag_id="transforma_dados_fac2fter", # Atualizei o ID para refletir a mudança
    start_date=datetime(2025, 1, 1),
    schedule="@hourly",
    catchup=False,
    default_args=default_args,
    tags=["etl", "transform", "minio", "fac2fter"],
)

def pipeline_fac2fter():

    @task
    def listar_arquivos_disponiveis():
        """
        Lista todas as tabelas disponiveis da FAC2FTER no MINIO.
        """
        hook = S3Hook(aws_conn_id=CONN_ID)
        arquivos_bronze = hook.list_keys(bucket_name=BUCKET_ORIGEM,prefix="dados_relacionais/FAC2FTER/") or []
        
        #arquivos = [f for f in arquivos_bronze if f.lower().endswith('.parquet')]
        
        arquivos = [f for f in arquivos_bronze if f.lower()]

         # ESTA LINHA IMPRIME NO LOG
        print(f"Arquivos encontrados no bucket {BUCKET_ORIGEM}: {arquivos}")
        
        # Opcional: imprimir um por um para facilitar a leitura no log
        for arq in arquivos:
            print(f"-> Arquivo detectado: {arq}")

        return arquivos

    listar_arquivos_disponiveis()
    

pipeline = pipeline_fac2fter()