# --- DUCKDB BI SERVER (Isolado para Terceiros) ---

# 1. Usaremos uma imagem Python leve para rodar o servidor proxy
resource "docker_image" "python_bi" {
  name         = "python:3.10-slim"
  keep_locally = true
}

# 2. Script do Servidor (Python)
# Este script cria um servidor "Fake Postgres" que roda queries no DuckDB
resource "local_file" "bi_server_script" {
  filename = "${path.module}/bi_server.py"
  content  = <<-EOT
    import os
    import duckdb
    from buenavista.postgres import BuenaVistaServer
    from buenavista.adapter import duckdb_adapter

    # 1. Configurações de Ambiente
    MINIO_ENDPOINT = os.getenv("MINIO_ENDPOINT", "minio_server:9000")
    MINIO_KEY = os.getenv("MINIO_ACCESS_KEY", "minioadmin")
    MINIO_SECRET = os.getenv("MINIO_SECRET_KEY", "minioadmin")

    print("--- INICIANDO SERVIDOR DUCKDB PARA BI ---")
    
    # 2. Inicia o DuckDB em memória (Processamento Efêmero)
    # Ele vai ler os dados do MinIO sob demanda.
    con = duckdb.connect()

    # 3. Configura acesso ao S3/MinIO
    print("Configurando extensão httpfs...")
    con.execute("INSTALL httpfs; LOAD httpfs;")
    con.execute(f"SET s3_region='us-east-1';")
    con.execute(f"SET s3_endpoint='{MINIO_ENDPOINT}';")
    con.execute(f"SET s3_access_key_id='{MINIO_KEY}';")
    con.execute(f"SET s3_secret_access_key='{MINIO_SECRET}';")
    con.execute("SET s3_use_ssl=false;")
    con.execute("SET s3_url_style='path';")

    # 4. (Opcional) Criar VIEWS para facilitar a vida do usuário de BI
    # Aqui você pode mapear os buckets para tabelas virtuais
    # Exemplo: O usuário verá uma tabela chamada 'vendas_bronze'
    # con.execute("CREATE VIEW vendas_bronze AS SELECT * FROM read_parquet('s3://bronze/*.parquet')")

    print("Servidor pronto! Aceitando conexões na porta 5432...")

    # 5. Inicia o Servidor Proxy (Finge ser Postgres na porta interna 5432)
    # O usuário conecta com qualquer login/senha, pois é local/dev
    server = BuenaVistaServer(
        ("0.0.0.0", 5432), 
        duckdb_adapter.DuckDBAdapter(con)
    )
    server.serve_forever()
  EOT
}

# 3. O Container Isolado
resource "docker_container" "duckdb_bi" {
  name    = "duckdb_bi_server"
  image   = docker_image.python_bi.image_id
  restart = "unless-stopped"

  networks_advanced {
    name = docker_network.data_network.name
  }

  # Porta Externa EXCLUSIVA para o BI (Usei 5434 para não conflitar)
  ports {
    internal = 5432
    external = 5434
  }

  env = [
    "MINIO_ENDPOINT=minio_server:9000",
    "MINIO_ACCESS_KEY=${var.minio_user}",
    "MINIO_SECRET_KEY=${var.minio_password}"
  ]

  # Instala as dependências e roda o script ao iniciar
  # (Em produção, você criaria um Dockerfile para isso ficar mais rápido)
  entrypoint = [
    "sh", "-c",
    "pip install duckdb buenavista psycopg2-binary && python /app/bi_server.py"
  ]

  # Monta o script Python dentro do container
  volumes {
    host_path      = abspath(local_file.bi_server_script.filename)
    container_path = "/app/bi_server.py"
  }
}