terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.0"
    }
    minio = {
      source  = "aminueza/minio"
      version = ">= 1.0.0"
    }
    # --- NOVO BLOCO AQUI ---
    time = {
      source  = "hashicorp/time"
      version = "0.9.1"
    }
    airbyte = {
      source  = "airbytehq/airbyte"
      version = "0.13.0" # Versão estável recente
    }
  }
}
