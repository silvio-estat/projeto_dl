
#############################################
###### CONFIGURANDO O PROVIDER DO DOCKER
############################################

provider "docker" {
  host = "unix:///var/run/docker.sock"

}

# 1. A Rede "Ilha"
resource "docker_network" "data_network" {
  name   = "datalake_network"
  driver = "bridge"
}

#############################################
###### CONFIGURANDO O PROVIDER DO MINIO
############################################

provider "minio" {
  minio_server   = "localhost:9000"
  minio_user     = var.minio_user
  minio_password = var.minio_password
  minio_ssl      = false
}


# 2. Imagem do MinIO
resource "docker_image" "minio" {
  name         = "minio/minio:latest"
  keep_locally = true
}

# 3. O Volume Gerenciado (A "Caixa Preta" segura do Docker)
resource "docker_volume" "minio_storage" {
  name = "minio_data_vol"
      # --- TRAVA DE SEGURANÇA ---
  lifecycle {
    prevent_destroy = true
  }
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
  create_duration = "30s" # 30s costuma ser suficiente

  # O segredo é este bloco triggers:
  triggers = {
    # Se o ID do container mudar, este recurso será destruído e recriado,
    # forçando a espera de 30s novamente.
    minio_container_id = docker_container.minio.id
  }

  depends_on = [docker_container.minio]
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

#############################################
###### CONFIGURANDO O PROVIDER DO QDRANT
############################################

# 1. Imagem do Qdrant
resource "docker_image" "qdrant" {
  name         = "qdrant/qdrant:latest"
  keep_locally = true
}


# 2. Volume Gerenciado para o Qdrant (Persistência dos vetores)
resource "docker_volume" "qdrant_storage" {
  name = "qdrant_data_vol"
  lifecycle {
    prevent_destroy = true
  }
}

# 3. O Container Qdrant
resource "docker_container" "qdrant" {
  name    = "qdrant_server"
  image   = docker_image.qdrant.image_id
  restart = "unless-stopped"

  # Conectando à mesma rede do Data Lake ("Ilha") definida anteriormente
  networks_advanced {
    name = docker_network.data_network.name
  }

  # Porta da API HTTP (usada para interagir via REST ou Client Python)
  ports {
    internal = 6333
    external = 6333
  }

  # Porta GRPC (usada para alta performance, opcional mas recomendada)
  ports {
    internal = 6334
    external = 6334
  }

  # Montando o volume para persistir os dados em /qdrant/storage
  volumes {
    volume_name    = docker_volume.qdrant_storage.name
    container_path = "/qdrant/storage"
  }

  # Variáveis de ambiente opcionais (ex: habilitar logs de debug se necessário)
  env = [
    "QDRANT__LOG_LEVEL=INFO"
  ]
}