
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
  default = "89456f3d-bc7e-4e6d-bc73-c61d25a9531c"
}

variable "client_secret" {
  description = "Senha do Airbyte (Client Secret)"
  type        = string
  sensitive   = true
  default = "61qmHCZO1zmu5O1ucWHKuUUN1h11AbPs"
}

variable "workspace_id" {
  description = "ID do Workspace do Airbyte (pegue na URL)"
  type        = string
  default = "e852573b-b429-4217-819d-2915f52c83e1"
}