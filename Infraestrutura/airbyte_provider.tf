
provider "airbyte" {
  # URL base da API
  server_url = "http://localhost:8000/api/public/v1"

  # Autenticação Moderna (Client Credentials)
  # Pegamos estes valores do seu comando 'abctl local credentials'
  client_id     = var.client_id
  client_secret = var.client_secret

}