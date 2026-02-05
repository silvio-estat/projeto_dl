
###############################
## CREDENCIAIS minio
###############################


variable "minio_user" {
  description = "Usuário raiz do MinIO"
  type        = string
  #sensitive   = true
}

variable "minio_password" {
  description = "Senha raiz do MinIO"
  type        = string
  #sensitive   = true
}

variable "minio_url" {
  description = "Endereco do MinIO"
  type        = string
  #sensitive   = true
}


###############################
## CREDENCIAIS Postgres
###############################

variable "postgres_user" {
  description = "Usuário do Postgres"
  type        = string
  sensitive   = true
}

variable "postgres_password" {
  description = "Senha do Postgres"
  type        = string
  sensitive   = true
}

###############################
## CREDENCIAIS Airbyte
###############################

variable "client_id" {
  description = "Usuário do Airbyte (Client ID)"
  type        = string
  sensitive   = true
}

variable "client_secret" {
  description = "Senha do Airbyte (Client Secret)"
  type        = string
  sensitive   = true
}

variable "workspace_id" {
  description = "ID do Workspace do Airbyte (pegue na URL)"
  type        = string
  sensitive   = true
}

###############################
## CREDENCIAIS Source Airbyte
###############################


variable "fac2fter_host" {
  description = "Endereço IP ou Hostname do Banco Postgres"
  type        = string
}

variable "fac2fter_db" {
  description = "Nome do banco de dados (Database Name)"
  type        = string
}

variable "fac2fter_porta" {
  description = "Porta do banco de dados"
  type        = number
}