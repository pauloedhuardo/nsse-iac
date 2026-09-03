resource "aws_secretsmanager_secret" "documentdb" {
  name                    = "nsse-documentdb-secret"
  recovery_window_in_days = 0
  tags                    = var.tags
}

data "aws_secretsmanager_random_password" "documentdb" {
  password_length    = 30
  exclude_numbers    = true
  exclude_characters = "/@\""
  include_space      = false
}

resource "aws_secretsmanager_secret_version" "fisrt" {
  secret_id = aws_secretsmanager_secret.documentdb.id
  secret_string = jsonencode({
    username = "nsse",
    password = data.aws_secretsmanager_random_password.documentdb.random_password
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}