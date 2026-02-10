resource "airbyte_connection" "postgres_to_minio_bronze" {
  name           = "Sync: Postgres -> MinIO (Bronze)"
  source_id      = airbyte_source_postgres.postgres_source.source_id
  destination_id = airbyte_destination_custom.minio_bronze.destination_id
  
  schedule = {
    schedule_type = "manual"
  }

  # Configuração Específica por Tabela
  configurations = {
    streams = [

      # Tabela 1: Operacoes
      {
        name = "operacoes"
        #sync_mode = "incremental_append"       # Lê apenas o que mudou (CDC) - só vai dar certo depois que as tabelas estiverem preparadas para tal
        sync_mode = "full_refresh_overwrite" 
        cursor_field = [] 
        primary_key  = [["id"]] 
      },

      # Tabela 2: Posicao das forcas amigas
      {
        name = "posicoes_de_forcas_amigas"
        #sync_mode = "incremental_append"      
        sync_mode = "full_refresh_overwrite"  
        cursor_field = [] 
        primary_key  = [["key"]] 
      },
      
      # Tabela 3: pontos de interesse
      {
        name = "pontos_de_interesse"
        #sync_mode = "incremental_append"
        sync_mode = "full_refresh_overwrite" 
        cursor_field = []
        primary_key  = [["key"]]
      },

      # Tabela 4: Atribuicoes de usuarios
      {
        name = "atribuicoes_de_usuarios"
        #sync_mode = "incremental_append" 
        sync_mode = "full_refresh_overwrite"       
        cursor_field = [] 
        primary_key  = [["key"]]
      },

      # Tabela :5 Matriz de sincronizacao
      {
        name = "matriz_sincronizacao"
        #sync_mode = "incremental_append"   
        sync_mode = "full_refresh_overwrite"     
        cursor_field = [] 
        primary_key  = [["id"]]
      },

      # Tabela 6: Chats
      {
        name = "chats"
        #sync_mode = "incremental_append" 
        sync_mode = "full_refresh_overwrite"       
        cursor_field = [] 
        primary_key  = [["id"]]
      },

      # Tabela 7: messages
      {
        name = "messages"
        #sync_mode = "incremental_append"  
        sync_mode = "full_refresh_overwrite"      
        cursor_field = [] 
        primary_key  = [["messageID"]]
      },

      # Tabela 8: comentarios
      {
        name = "comentarios"
        #sync_mode = "incremental_append"  
        sync_mode = "full_refresh_overwrite"      
        cursor_field = [] 
        primary_key  = [["messageID"]]
      }
    ]
  }
}