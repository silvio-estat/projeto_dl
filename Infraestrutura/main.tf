# 1. A Rede "Ilha"
resource "docker_network" "data_network" {
  name   = "datalake_network"
  driver = "bridge"
}

# 2. Imagem do MinIO
resource "docker_image" "minio" {
  name         = "minio/minio:latest"
  keep_locally = true
}

# 3. O Volume Gerenciado (A "Caixa Preta" segura do Docker)
resource "docker_volume" "minio_storage" {
  name = "minio_data_vol"
}

# 4. O Container MinIO
resource "docker_container" "minio" {
  name    = "minio_server"
  image   = docker_image.minio.image_id
  restart = "unless-stopped"

  networks_advanced {
    name = docker_network.data_network.name
  }

  ports {
    internal = 9000
    external = 9000
  }
  ports {
    internal = 9001
    external = 9001
  }

  env = [
    "MINIO_ROOT_USER=${var.minio_user}",
    "MINIO_ROOT_PASSWORD=${var.minio_password}"
  ]

  command = ["server", "/data", "--console-address", ":9001"]

  # --- A MUDANÇA ESTÁ AQUI ---
  # Agora apontamos para o volume gerenciado, não mais para seu PC.
  volumes {
    volume_name    = docker_volume.minio_storage.name
    container_path = "/data"
  }
}

# 5. O Timer de Espera (Mantivemos para segurança)
resource "time_sleep" "wait_for_minio" {
  depends_on      = [docker_container.minio]
  create_duration = "10s"
}

# 6. Criação dos Buckets
resource "minio_s3_bucket" "bronze" {
  bucket     = "bronze"
  acl        = "private"
  depends_on = [time_sleep.wait_for_minio]
}

resource "minio_s3_bucket" "prata" {
  bucket     = "prata"
  acl        = "private"
  depends_on = [time_sleep.wait_for_minio]
}

resource "minio_s3_bucket" "ouro" {
  bucket     = "ouro"
  acl        = "private"
  depends_on = [time_sleep.wait_for_minio]
}

##############################################
# --- POSTGRESQL (Origem de Dados e Metadados) ---
##############################################

# 1. Imagem do Postgres (Versão 13 é robusta e compatível com tudo)
resource "docker_image" "postgres" {
  name         = "postgres:13"
  keep_locally = true
}

# 2. Volume para os dados do banco não sumirem
resource "docker_volume" "pg_data" {
  name = "postgres_data_vol"
}

# 3. O Container do Postgres
resource "docker_container" "postgres" {
  name    = "postgres_db"
  image   = docker_image.postgres.image_id
  restart = "unless-stopped"

  # Conecta na mesma rede do MinIO (fundamental para o Airbyte ver os dois)
  networks_advanced {
    name = docker_network.data_network.name
  }

  # Porta: Interna 5432 (padrão), Externa 5432 (para você acessar do DBeaver/Notebook)
  ports {
    internal = 5432
    external = 5432
  }

  # Credenciais (Puxando das variáveis que vamos criar)
  env = [
    "POSTGRES_USER=${var.postgres_user}",
    "POSTGRES_PASSWORD=${var.postgres_password}",
    "POSTGRES_DB=app_db" # Banco de dados inicial
  ]

  # Persistência
  volumes {
    volume_name    = docker_volume.pg_data.name
    container_path = "/var/lib/postgresql/data"
  }
}

# --- CONFIGURAÇÃO DO AIRBYTE ---

provider "airbyte" {
  # URL base da API
  server_url = "http://localhost:8000/api/public/v1"

  # Autenticação Moderna (Client Credentials)
  # Pegamos estes valores do seu comando 'abctl local credentials'
  client_id     = var.client_id
  client_secret = var.client_secret
}