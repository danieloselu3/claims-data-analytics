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

# Cloud Storage Buckets for Raw, Cleanse, and Serve Layers
resource "google_storage_bucket" "raw_layer" {
  name          = "${var.project_id}-raw-layer"
  location      = var.region
  force_destroy = true

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "delete"
    }
  }
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