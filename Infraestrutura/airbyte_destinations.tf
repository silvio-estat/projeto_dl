resource "airbyte_destination_custom" "minio_bronze" {
  name         = "MinIO - Camada Bronze"
  workspace_id = var.workspace_id

  # Certifique-se de usar o ID que você pegou na URL no passo anterior
  definition_id = "4816b78f-1489-44c1-9060-4b19d5fa9362"

  configuration = jsonencode({
    "destination_type" : "S3",
    "s3_endpoint" : "http://minio_server:9000",
    "s3_bucket_name" : "bronze",

    # CORREÇÃO 1: Nome do campo atualizado de 's3_path_format' para 's3_bucket_path'
    "s3_bucket_path" : "$${NAMESPACE}/$${STREAM_NAME}/$${YEAR}_$${MONTH}_$${DAY}_$${EPOCH}_",

    "s3_bucket_region" : "us-east-1",
    "access_key_id" : var.minio_user,
    "secret_access_key" : var.minio_password,

    # CORREÇÃO 2: Estrutura do formato simplificada (Flat) com 'format_type'
    "format" : {
      "format_type" : "JSONL",
      "compression_codec" : "GZIP",
      "flattening" : "Root level flattening"
    }
  })
}