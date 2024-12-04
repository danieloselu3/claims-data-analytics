# Provider Configuration
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.80.0"
    }
  }
}

# Configure the Google Cloud provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Cloud Storage Bucket for Data Layers
resource "google_storage_bucket" "data_layers" {
  name          = "${var.project_id}-data-layers"
  location      = var.region
  force_destroy = true

  lifecycle_rule {
    condition {
      age = var.raw_layer_lifecycle_days
      matches_prefix = ["raw/"]
    }
    action {
      type = "delete"
    }
  }
}

# Placeholder objects to create folder-like structure in GCS
resource "google_storage_bucket_object" "raw_folder" {
  name    = "raw/"
  content = "Placeholder for raw data layer"
  bucket  = google_storage_bucket.data_layers.name
}

resource "google_storage_bucket_object" "cleanse_folder" {
  name    = "cleanse/"
  content = "Placeholder for cleansed data layer"
  bucket  = google_storage_bucket.data_layers.name
}

# BigQuery Dataset
resource "google_bigquery_dataset" "ecommerce_dataset" {
  dataset_id                 = "ecommerce_data"
  friendly_name              = "Ecommerce Data Warehouse"
  description                = "Dataset for storing processed ecommerce data"
  location                   = var.region

  access {
    role          = "OWNER"
    user_by_email = var.admin_email
  }
}

# Cloud Data Fusion Instance
resource "google_data_fusion_instance" "ecommerce_data_fusion" {
  name     = "ecommerce-data-fusion"
  type     = "BASIC"
  region   = var.region
  
  network_config {
    network = google_compute_network.data_network.name
  }
}

# Networking for Data Fusion
resource "google_compute_network" "data_network" {
  name                    = "ecommerce-data-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "data_subnetwork" {
  name          = "ecommerce-data-subnetwork"
  ip_cidr_range = var.network_cidr
  region        = var.region
  network       = google_compute_network.data_network.id
}

# Cloud Composer Environment
resource "google_composer_environment" "ecommerce_airflow" {
  name    = "ecommerce-airflow-environment"
  region  = var.region
  config {
    node_config {
      zone         = "${var.region}-a"
      machine_type = var.composer_machine_type

      network    = google_compute_network.data_network.id
      subnetwork = google_compute_subnetwork.data_subnetwork.id
    }

    software_config {
      image_version = var.composer_image_version
      
      # Optional: Add environment variables if needed
      env_variables = {
        PROJECT_ID = var.project_id
      }
    }

    workloads_config {
      scheduler {
        cpu        = 1
        memory_gb  = 1.875
      }
      web_server {
        cpu        = 1
        memory_gb  = 1.875
      }
      worker {
        cpu        = 1
        memory_gb  = 1.875
      }
    }
  }

  # Dependency to ensure network is created first
  depends_on = [
    google_compute_network.data_network,
    google_compute_subnetwork.data_subnetwork
  ]
}