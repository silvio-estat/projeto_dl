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

    @task
    def renomar_arquivos(lista_arquivos: list):

        import re
        hook = S3Hook(aws_conn_id=CONN_ID)
        PREFIX_PRATA = "prata/dados_relacionais/FAC2FTER/"
        movimentacoes = []

        for path_completo in lista_arquivos:
        # Garante que estamos lidando apenas com arquivos .parquet
            if not path_completo.lower().endswith('.parquet'):
                continue

            try:
                # 1. Extração de metadados
                # Ex: dados_relacionais/FAC2FTER/areas_de_interesse/2026_02_10_1770729523441_0.parquet
                parts = path_completo.split('/')
                tabela = parts[-2]  # areas_de_interesse
                nome_arquivo = parts[-1]

                # 2. Extração e conversão do Epoch (Airbyte usa milissegundos)
                # Buscamos o padrão numérico de 13 dígitos antes do .parquet
                match = re.search(r'(\d{13})', nome_arquivo)
                if match:
                    epoch_ms = int(match.group(1))
                    dt_obj = datetime.fromtimestamp(epoch_ms / 1000.0)
                    timestamp_str = dt_obj.strftime('%Y%m%d_%H%M%S')
                else:
                    # Fallback caso o padrão de epoch mude
                    timestamp_str = datetime.now().strftime('%Y%m%d_manual')

                # 3. Definição do novo nome
                novo_nome = f"{tabela}_{timestamp_str}.parquet"
                novo_path = f"{PREFIX_PRATA}{novo_nome}"

                # 4. Operação de movimentação no MinIO
                # O S3Hook simplifica o Copy + Delete
                hook.copy_object(
                    source_bucket_key=path_completo,
                    dest_bucket_key=novo_path,
                    source_bucket_name=BUCKET_ORIGEM,
                    dest_bucket_name=BUCKET_ORIGEM # Ou BUCKET_DESTINO se for diferente
                )
                hook.delete_objects(bucket=BUCKET_ORIGEM, keys=path_completo)
                
                movimentacoes.append(f"{path_completo} -> {novo_path}")
                
            except Exception as e:
                print(f"Erro ao processar arquivo {path_completo}: {str(e)}")

        return movimentacoes

    arquivos = listar_arquivos_disponiveis()
    renomar_arquivos(arquivos)


pipeline = pipeline_fac2fter()