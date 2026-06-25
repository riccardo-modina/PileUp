terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    # needed for some firebase functions
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
    neon = {
      source  = "kislerdm/neon"
      version = ">= 0.13.0"
    }
  }
}

provider "google" {
  project = "financeappbackend"
  region  = "europe-west1"
}

provider "google-beta" {
  project = "financeappbackend"
  region  = "europe-west1"
}

provider "neon" {
  api_key = var.neon_api_key
}
