
provider "google" {
  project     = "nshawca"
  region      = "europe-west1"
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
      image = data.google_container_registry_image.nshawca_latest.image_url
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
    address = "gcr.io"
    username = "oauth2accesstoken"
    password = data.google_client_config.default.access_token
  }
}

data "docker_registry_image" "nshawca_image" {
  name = "gcr.io/nshawca/nshawca-webserver:latest"
}

data "google_container_registry_image" "nshawca_latest" {
  name = "nshawca-webserver"
  project = "nshawca"
  digest = data.docker_registry_image.nshawca_image.sha256_digest
}