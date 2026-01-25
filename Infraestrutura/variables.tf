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