terraform {
  required_providers { docker = { source = "kreuzwerker/docker", version = "~> 3.0" } }
}
provider "docker" {}
variable "postgres_password" {
  description = "PostgreSQL password; set with TF_VAR_postgres_password"
  type        = string
  sensitive   = true
}
resource "docker_network" "task_manager" { name = "task-manager-network" }
resource "docker_volume" "postgres_data" { name = "task-manager-postgres-data" }
resource "docker_image" "postgres" { name = "postgres:16-alpine" }
resource "docker_container" "postgres" {
  name  = "task-manager-postgres"
  image = docker_image.postgres.image_id
  networks_advanced { name = docker_network.task_manager.name }
  volumes {
    volume_name    = docker_volume.postgres_data.name
    container_path = "/var/lib/postgresql/data"
  }
  env = ["POSTGRES_DB=taskmanager", "POSTGRES_USER=taskuser", "POSTGRES_PASSWORD=${var.postgres_password}"]
}
