resource "google_container_cluster" "this" {
  name                     = var.cluster_name
  location                 = var.region
  project                  = var.project_id
  network                  = var.network
  subnetwork               = var.subnet
  remove_default_node_pool = true
  initial_node_count       = 1

  deletion_protection      = false

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  release_channel { channel = "REGULAR" }
  enable_shielded_nodes = true
}

resource "google_container_node_pool" "default" {
  name     = "${var.cluster_name}-pool"
  cluster  = google_container_cluster.this.name
  location = var.region
  project  = var.project_id

  node_config {
    machine_type = var.machine_type
    spot         = var.spot_nodes
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    metadata     = { disable-legacy-endpoints = "true" }
  }

  autoscaling {
    min_node_count = var.min_nodes
    max_node_count = var.max_nodes
  }

  management {
    auto_upgrade = true
    auto_repair  = true
  }
}
