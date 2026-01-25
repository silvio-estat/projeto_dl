
###############################
## CREDENCIAIS minio
###############################


variable "minio_user" {
  description = "Usuário raiz do MinIO"
  type        = string
  default     = "minioadmin" # Altere ou passe via -var
}

variable "minio_password" {
  description = "Senha raiz do MinIO"
  type        = string
  default     = "minioadmin" # Altere ou passe via -var
  sensitive   = true
}


###############################
## CREDENCIAIS Postgres
###############################

variable "postgres_user" {
  description = "Usuário do Postgres"
  type        = string
  default     = "postgres"
}

variable "postgres_password" {
  description = "Senha do Postgres"
  type        = string
  default     = "postgres" # Senha de dev
  sensitive   = true
}

###############################
## CREDENCIAIS Airbyte
###############################

variable "airbyte_username" {
  description = "Usuário do Airbyte (Client ID)"
  type        = string
}

variable "airbyte_password" {
  description = "Senha do Airbyte (Client Secret)"
  type        = string
  sensitive   = true
}

variable "airbyte_workspace_id" {
  description = "ID do Workspace do Airbyte (pegue na URL)"
  type        = string
}