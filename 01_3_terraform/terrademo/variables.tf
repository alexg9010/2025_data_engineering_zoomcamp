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

variable "bq_dataset_name" {
  description = "BigQuery dataset name"
  default     = "demo_dataset"
}

variable "gcs_storage_class" {
  description = "Storage class for GCS bucket"
  default     = "STANDARD"
}

variable "gcs_bucket_name" {
  description = "GCS bucket name"
  default     = "terraform-demo-449214-terra-bucket"

} 