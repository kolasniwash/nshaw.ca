terraform {
  backend "gcs" {
    bucket  = "nshawca-tfstate"
    prefix  = "terraform/state"
  }
}