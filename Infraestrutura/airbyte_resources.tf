# --- FONTE (SOURCE): POSTGRESQL ---

resource "airbyte_source_postgres" "postgres_source" {
  configuration = {
    # No Linux/Docker, para acessar o host de dentro do container,
    # muitas vezes usamos o IP da interface docker0 (geralmente 172.17.0.1)
    # ou tentamos host.docker.internal se o abctl configurou.
    host     = "172.17.0.1" 
    port     = 5432
    database = "app_db"
    username = var.postgres_user
    password = var.postgres_password
    
    # Configurações de replicação (CDC ou Standard)
    replication_method = {
      standard = {}
    }
    ssl_mode = {
      disable = {}
    }
  }
  name         = "Postgres - Produção"
  workspace_id = var.airbyte_workspace_id
}