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