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
  region      = "us-west1"
}


resource "random_id" "bucket_prefix" {
  byte_length = 8
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