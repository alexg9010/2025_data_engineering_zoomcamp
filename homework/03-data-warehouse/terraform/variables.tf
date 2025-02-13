variable "project" {
  description = "GCP project ID"
  default     = "terraform-demo-449214"
}

variable "region" {
  description = "GCP region"
  default     = "europe-west10"

}

variable "location" {
  description = "GCP region"
  default     = "EU"
}

variable "gcs_storage_class" {
  description = "Storage class for GCS bucket"
  default     = "STANDARD"
}

variable "gcs_bucket_name" {
  description = "GCS bucket name"
  default     = "dezoomcamp_hw3_2025-123456"
}

variable "bq_dataset_name" {
  description = "BigQuery dataset name"
  default     = "homework_dataset"
}
