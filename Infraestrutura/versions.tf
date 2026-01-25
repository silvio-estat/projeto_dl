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
      source = "hashicorp/time"
      version = "0.9.1"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

provider "minio" {
  minio_server   = "localhost:9000"
  minio_user     = var.minio_user
  minio_password = var.minio_password
  minio_ssl      = false
}