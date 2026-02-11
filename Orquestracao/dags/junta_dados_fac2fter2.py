#import os
import re # Importar aqui fora é melhor se usado em tasks padrão, mas dentro da task funciona também
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
    dag_id="transforma_dados_fac2fter2",
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
        # Ajuste: prefix deve ser explicitamente nomeado para clareza
        arquivos_bronze = hook.list_keys(bucket_name=BUCKET_ORIGEM, prefix="dados_relacionais/FAC2FTER/") or []
        
        # Filtro simples para garantir que a string não é vazia e é parquet
        arquivos = [f for f in arquivos_bronze if f and f.lower().endswith('.parquet')]

        print(f"Arquivos encontrados no bucket {BUCKET_ORIGEM}: {len(arquivos)}")
        return arquivos


    @task
    def renomar_e_mover_arquivos(lista_arquivos: list):
        if not lista_arquivos:
            print("Nenhum arquivo para processar.")
            return []

        hook = S3Hook(aws_conn_id=CONN_ID)
        # Ajuste: Se o bucket destino é "prata", não precisamos repetir "prata/" no prefixo, 
        # a menos que você queira uma pasta chamada prata dentro do bucket prata.
        # Vou assumir que você quer manter a estrutura de pastas original.
        PREFIX_DESTINO = "dados_relacionais/FAC2FTER/" 
        
        movimentacoes = []

        for path_completo in lista_arquivos:
            try:
                # Ex: dados_relacionais/FAC2FTER/areas_de_interesse/2026...parquet
                parts = path_completo.split('/')
                # Cuidado: se a estrutura mudar, parts[-2] pode quebrar. 
                # Idealmente valida-se o tamanho de parts.
                if len(parts) < 2:
                    print(f"Estrutura de pasta inesperada: {path_completo}")
                    continue
                    
                tabela = parts[-2]  # areas_de_interesse
                nome_arquivo = parts[-1]

                # Extração do Epoch
                match = re.search(r'(\d{13})', nome_arquivo)
                if match:
                    epoch_ms = int(match.group(1))
                    dt_obj = datetime.fromtimestamp(epoch_ms / 1000.0)
                    timestamp_str = dt_obj.strftime('%Y%m%d_%H%M%S')
                else:
                    timestamp_str = datetime.now().strftime('%Y%m%d_manual')

                # Definição do novo nome
                novo_nome = f"{tabela}_{timestamp_str}.parquet"
                # Caminho destino: dados_relacionais/FAC2FTER/novo_nome.parquet
                novo_path = f"{PREFIX_DESTINO}{novo_nome}"

                print(f"Movendo: {path_completo} -> s3://{BUCKET_DESTINO}/{novo_path}")

                # Copia para o bucket PRATA (Corrigido)
                hook.copy_object(
                    source_bucket_key=path_completo,
                    dest_bucket_key=novo_path,
                    source_bucket_name=BUCKET_ORIGEM,
                    dest_bucket_name=BUCKET_DESTINO 
                )
                
                # Deleta do bucket ORIGEM
                #hook.delete_objects(bucket=BUCKET_ORIGEM, keys=path_completo)
                
                movimentacoes.append(f"{path_completo} -> {novo_path}")
                
            except Exception as e:
                print(f"Erro ao processar arquivo {path_completo}: {str(e)}")
                # Não damos raise aqui para não parar o loop dos outros arquivos,
                # mas em produção talvez você queira falhar a task.

        return movimentacoes

    # --- ORQUESTRAÇÃO ---
    arquivos = listar_arquivos_disponiveis()
    renomar_e_mover_arquivos(arquivos)

pipeline = pipeline_fac2fter()