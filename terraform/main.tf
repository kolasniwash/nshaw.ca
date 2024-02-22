terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.17.0"
    }
  }
}

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
      image = "gcr.io/nshawca/nshawca-webserver:latest"
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
