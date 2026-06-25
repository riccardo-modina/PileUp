variable "neon_api_key" {
  type        = string
  description = "Neon API Key"
  sensitive   = true
}

variable "django_secret_key" {
  type        = string
  description = "Django Secret Key"
  sensitive   = true
}

variable "database_url" {
  type        = string
  description = "PostgreSQL Database URL"
  sensitive   = true
}

variable "neon_db_id" {
  type        = string
  description = "Neon database ID"
}
