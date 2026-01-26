resource "airbyte_connection" "postgres_to_minio_bronze" {
  name = "Sync: Postgres -> MinIO (Bronze)"

  # 1. Referência à Origem (que criamos no airbyte_resources.tf)
  source_id = airbyte_source_postgres.postgres_source.source_id

  # 2. Referência ao Destino (que criamos na etapa anterior)
  destination_id = airbyte_destination_custom.minio_bronze.destination_id

  # 3. Frequência de Atualização (Schedule)
  # Aqui deixei como "manual" para você testar clicando, 
  # mas você pode mudar para "cron" se quiser automático.
  schedule = {
    schedule_type = "manual" 
    # Exemplo para rodar a cada 24h:
    # schedule_type = "cron"
    # cron_expression = "0 0 12 * * ?" 
  }

  # 4. Configurações de Prefixo (Opcional)
  # Isso define se as tabelas no destino terão algum prefixo no nome
  prefix = ""

  # 5. Status inicial
  status = "active"
  
  # 6. Modo de Sincronização Padrão (Opcional, mas bom especificar)
  # O Airbyte tentará aplicar "Full Refresh | Overwrite" ou "Incremental | Append"
  # dependendo do que o banco suportar.
  namespace_definition = "source"
}