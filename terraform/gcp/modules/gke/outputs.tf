output "name" {
  description = "The name of the GKE cluster"
  value       = google_container_cluster.this.name
}

output "endpoint" {
  description = "The endpoint of the GKE cluster"
  value       = google_container_cluster.this.endpoint
}

output "node_pool_name" {
  description = "The name of the default node pool"
  value       = google_container_node_pool.default.name
}
