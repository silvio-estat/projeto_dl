output "network_name" {
  description = "Nome da rede Docker compartilhada"
  value       = docker_network.data_network.name
}

output "minio_container_name" {
  description = "Nome do container do MinIO para DNS interno"
  value       = docker_container.minio.name
}

output "minio_endpoint" {
  description = "Endpoint interno para outros containers"
  value       = "http://${docker_container.minio.name}:9000"
}

