# Storage Outputs
output "raw_layer_bucket_name" {
  description = "Name of the raw layer storage bucket"
  value       = google_storage_bucket.raw_layer.name
}

output "raw_layer_bucket_url" {
  description = "URL of the raw layer storage bucket"
  value       = google_storage_bucket.raw_layer.url
}

# BigQuery Outputs
output "bigquery_dataset_id" {
  description = "ID of the BigQuery dataset for ecommerce data"
  value       = google_bigquery_dataset.ecommerce_dataset.dataset_id
}

output "bigquery_dataset_self_link" {
  description = "Self link of the BigQuery dataset"
  value       = google_bigquery_dataset.ecommerce_dataset.self_link
}

# Data Fusion Outputs
output "data_fusion_instance_name" {
  description = "Name of the Cloud Data Fusion instance"
  value       = google_data_fusion_instance.ecommerce_data_fusion.name
}

output "data_fusion_instance_url" {
  description = "URL of the Cloud Data Fusion instance"
  value       = google_data_fusion_instance.ecommerce_data_fusion.service_endpoint
}

# Networking Outputs
output "data_network_name" {
  description = "Name of the data network"
  value       = google_compute_network.data_network.name
}

output "data_subnetwork_name" {
  description = "Name of the data subnetwork"
  value       = google_compute_subnetwork.data_subnetwork.name
}