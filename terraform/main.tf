
provider "google" {
  project = var.project
  region  = "europe-west1"
}

resource "google_storage_bucket" "default" {
  name          = "nshawca-tfstate"
  force_destroy = false
  location      = "us-west1"
  storage_class = "STANDARD"
  versioning {
    enabled = true
  }
}

resource "google_cloud_run_v2_service" "default" {
  name     = "blog"
  location = "europe-west1"
  client   = "terraform"

  template {
    containers {
      image = data.google_container_registry_image.webserver_latest.image_url
      ports {
        container_port = 80
      }
    }
  }
}

resource "google_cloud_run_v2_service_iam_member" "noauth" {
  location = google_cloud_run_v2_service.default.location
  name     = google_cloud_run_v2_service.default.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}


data "google_client_config" "default" {}

provider "docker" {
  registry_auth {
    address  = "gcr.io"
    username = "oauth2accesstoken"
    password = data.google_client_config.default.access_token
  }
}

data "docker_registry_image" "webserver_image" {
  name = "gcr.io/${var.project}/${var.image_name}:latest"
}

data "google_container_registry_image" "webserver_latest" {
  name    = var.image_name
  project = var.project
  digest  = data.docker_registry_image.webserver_image.sha256_digest
}

variable "project" {
  type        = string
  description = "GCP Project ID"
  sensitive   = true
}

variable "image_name" {
  type        = string
  description = "Name of the image to deploy"
  sensitive   = true
}