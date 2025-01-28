terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.18.0"
    }
  }
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs
provider "google" {
  project = var.project
  region  = var.region
}

resource "google_storage_bucket" "demo-bucket" {
  ## bucket name has to be unique across all google cloud storage
  ## usually bucket name is in the format of <project_id>-<bucket_name>
  name = var.gcs_bucket_name
  ## adjust if you want to use a different location
  location      = var.location
  force_destroy = true

  ## delete bucket after 3 days
  lifecycle_rule {
    condition {
      ## Minimum age of an object in days
      age = 3
    }
    action {
      type = "Delete"
    }
  }

  ## automatically abort multipart uploads that are incomplete after x days
  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }
}


resource "google_bigquery_dataset" "demo_dataset" {
  dataset_id = var.bq_dataset_name
  location   = var.location
}