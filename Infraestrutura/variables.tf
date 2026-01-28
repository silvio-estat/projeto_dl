
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

variable "client_id" {
  description = "Usuário do Airbyte (Client ID)"
  type        = string
  default     = "b52fd097-0d16-4902-ba5f-f46828366b48"
}

variable "client_secret" {
  description = "Senha do Airbyte (Client Secret)"
  type        = string
  sensitive   = true
  default     = "VKSqDR1bi6BWQuNkAO3OCWdO4QTqnZx7"
}

variable "workspace_id" {
  description = "ID do Workspace do Airbyte (pegue na URL)"
  type        = string
  default     = "e852573b-b429-4217-819d-2915f52c83e1"
}