# Project Configuration
variable "project_id" {
  description = "The Google Cloud project ID"
  type        = string
}

variable "region" {
  description = "The Google Cloud region"
  type        = string
  default     = "us-central1"
}

variable "network_cidr" {
  description = "CIDR range for the data network"
  type        = string
  default     = "10.0.0.0/24"
}

# Identity and Access Variables
variable "admin_email" {
  description = "Email of the admin user for BigQuery dataset access"
  type        = string
}

#Storage Configuration
variable "raw_layer_lifecycle_days" {
  description = "Number of days before raw layer data is deleted"
  type        = number
  default     = 30
}

# Data Fusion Configuration
variable "data_fusion_type" {
  description = "Type of Cloud Data Fusion instance"
  type        = string
  default     = "BASIC"
  validation {
    condition     = contains(["BASIC", "DEVELOPER", "ENTERPRISE"], var.data_fusion_type)
    error_message = "Data Fusion instance type must be BASIC, DEVELOPER, or ENTERPRISE."
  }
}

variable "composer_image_version" {
  description = "Image version for Cloud Composer environment"
  type        = string
  default     = "composer-3-airflow-2.7.3"
}