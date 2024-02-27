terraform {
  backend "gcs" {
    bucket = "nshawca-tfstate"
    prefix = "terraform/state"
  }
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.13.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.17.0"
    }
  }
}