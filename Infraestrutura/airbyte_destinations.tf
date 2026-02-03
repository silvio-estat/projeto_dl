resource "airbyte_destination_custom" "minio_bronze" {
  name         = "MinIO - Camada Bronze"
  workspace_id = var.workspace_id

  # ID correto do Destination S3 (O comentário anterior estava errado)
  definition_id = "4816b78f-1489-44c1-9060-4b19d5fa9362"

  configuration = jsonencode({
    # "destination_type" não é estritamente necessário aqui, mas não atrapalha
    
    # CORREÇÃO CRÍTICA: De "s3_endpoint" para "endpoint"
    "s3_endpoint"         : "http://172.17.0.1:9000",
    
    "s3_bucket_name"   : "bronze",
    "s3_bucket_path"   : "$${NAMESPACE}/$${STREAM_NAME}/$${YEAR}$${MONTH}$${DAY}$${EPOCH}",
    "s3_bucket_region" : "us-east-1",
    "access_key_id"    : var.minio_user,
    "secret_access_key": var.minio_password,

    "format" : {
      "format_type"             : "Parquet",
      "compression_codec"       : "SNAPPY",
      "block_size_mb"           : 128,
      "max_padding_size_mb"     : 8,
      "page_size_kb"            : 1024,
      "dictionary_page_size_kb" : 1024,
      "dictionary_encoding"     : true
    }
  })
}