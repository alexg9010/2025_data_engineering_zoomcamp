variable "project" {
  description = "GCP project ID"
  default     = "dbt-demo-451819"
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
  default     = "dezoomcamp-dbt--451819-bucket"
}

variable "bq_dataset_name" {
  description = "BigQuery dataset name"
  default     = "trips_data_all"
}
