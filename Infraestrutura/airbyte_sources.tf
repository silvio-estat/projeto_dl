# --- FONTE (SOURCE): 


#POSTGRESQL --- SOMENTE PARA TESTES LOCAIS ---

# resource "airbyte_source_postgres" "postgres_source" {
#   configuration = {
#     # No Linux/Docker, para acessar o host de dentro do container,
#     # muitas vezes usamos o IP da interface docker0 (geralmente 172.17.0.1)
#     # ou tentamos host.docker.internal se o abctl configurou.
#     host     = var.fac2fter_host
#     port     = var.fac2fter_porta
#     database = var.fac2fter_db
#     username = var.postgres_user
#     password = var.postgres_password

#     # Configurações de replicação (CDC ou Standard)
#     replication_method = {
#       standard = {}
#     }
#     ssl_mode = {
#       disable = {}
#     }
#   }
#   name         = "Postgres - Produção"
#   workspace_id = var.workspace_id
# }

resource "airbyte_source_postgres" "postgres_source" {
  configuration = {
    host     = var.fac2fter_host
    port     = var.fac2fter_porta
    database = var.fac2fter_db
    username = var.postgres_user
    password = var.postgres_password

    # --- HABILITANDO O CDC ---
    replication_method = {
      cdc = {
        replication_slot = "airbyte_slot"
        publication      = "airbyte_publication"
        initial_waiting_seconds = 5
      }
    }
    
    ssl_mode = {
      disable = {}
    }
  }
  name         = "Postgres - Produção"
  workspace_id = var.workspace_id
}