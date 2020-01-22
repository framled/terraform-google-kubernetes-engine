locals {
  name_prefix = "${var.general["name"]}-${var.general["env"]}"
  location = coalesce(var.region, var.zone)
}

# This file contains all the interactions with Google Cloud
provider "google" {
  region  = var.region
  project = var.project
}

provider "google-beta" {
  region  = var.region
  project = var.project
}

# This data source fetches the project name, and provides the appropriate URLs to use for container registry for this project.
# https://www.terraform.io/docs/providers/google/d/google_container_registry_repository.html
data "google_container_registry_repository" "registry" {}

# Provides access to available Google Container Engine versions in a zone for a given project.
# https://www.terraform.io/docs/providers/google/d/google_container_engine_versions.html
data "google_container_engine_versions" "engine_version" {
  location = local.location
}

# Manages a Node Pool resource within GKE
# https://www.terraform.io/docs/providers/google/r/container_node_pool.html
resource "google_container_node_pool" "new_container_cluster_node_pool" {
  count = length(var.node_pool)

  project               = data.google_project.project.project_id
  name                  = "${local.name_prefix}-${local.location}-pool-${count.index}"
  location              = local.location
  cluster               = google_container_cluster.new_container_cluster.name
  initial_node_count    = lookup(var.node_pool, "node_count", 2)
  node_count            = lookup(var.node_pool[count.index], "node_count", 3)

  node_config {
    disk_size_gb    = lookup(var.node_pool[count.index], "disk_size_gb", 10)
    disk_type       = lookup(var.node_pool[count.index], "disk_type", "pd-standard")
    image_type      = lookup(var.node_pool[count.index], "image", "COS")
    local_ssd_count = lookup(var.node_pool[count.index], "local_ssd_count", 0)
    machine_type    = lookup(var.node_pool[count.index], "machine_type", "n1-standard-1")

    oauth_scopes    = split(",", lookup(var.node_pool[count.index], "oauth_scopes", "https://www.googleapis.com/auth/compute,https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring"))
    preemptible     = lookup(var.node_pool[count.index], "preemptible", false)
    service_account = lookup(var.node_pool[count.index], "service_account", "default")
    labels          = var.labels
    tags            = var.tags
    metadata        = var.metadata
  }

  autoscaling {
    min_node_count = lookup(var.node_pool[count.index], "min_node_count", 2)
    max_node_count = lookup(var.node_pool[count.index], "max_node_count", 3)
  }

  management {
    auto_repair  = lookup(var.node_pool[count.index], "auto_repair", true)
    auto_upgrade = lookup(var.node_pool[count.index], "auto_upgrade", true)
  }

  upgrade_settings {
    max_surge = lookup(var.node_pool[count.index], "upgrade_max_surge", 1)
    max_unavailable = lookup(var.node_pool[count.index], "upgrade_max_unavailable", 1)
  }
}

# Creates a Google Kubernetes Engine (GKE) cluster
# https://www.terraform.io/docs/providers/google/r/container_cluster.html
resource "google_container_cluster" "new_container_cluster" {
  name                      = "${local.name_prefix}-${var.general["location"]}-master"
  description               = "Kubernetes ${var.general["name"]} in ${var.general["location"]}"
  location                  = local.location
  project                   = data.google_project.project.project_id

  network                   = data.google_compute_network.network.self_link
  subnetwork                = data.google_compute_subnetwork.subnetwork.self_link
  node_locations            = var.node_locations
  initial_node_count        = lookup(var.node_pool, "node_count", 2)
  remove_default_node_pool  = lookup(var.node_pool, "remove", false)

  addons_config {
    horizontal_pod_autoscaling {
      disabled = lookup(var.addons_config, "disable_horizontal_pod_autoscaling", false)
    }

    http_load_balancing {
      disabled = lookup(var.addons_config, "disable_http_load_balancing", false)
    }

    network_policy_config {
      disabled = lookup(var.addons_config, "disable_network_policy_config", true)
    }

    istio_config {
      disabled = lookup(var.beta_addons_config, "disable_istio_config", true)
      auth = lookup(var.beta_addons_config, "istio_auth_mutual_tls", true)
    }
  }

  # this have to be here :/, twice
  network_policy {
    enabled = !lookup(var.addons_config, "disable_network_policy_config", true)
  }

  # cluster_ipv4_cidr - default
  enable_kubernetes_alpha = lookup(var.master, "enable_kubernetes_alpha", false)
  enable_legacy_abac      = lookup(var.master, "enable_legacy_abac", false)

  # Allocate IPs in our subnetwork
  ip_allocation_policy {
    cluster_secondary_range_name  = google_compute_subnetwork.subnetwork.secondary_ip_range[0].range_name
    services_secondary_range_name = google_compute_subnetwork.subnetwork.secondary_ip_range[1].range_name
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = lookup(var.master, "maintenance_window", "04:30")
    }
  }

  # master_authorized_networks_config - disable (security)
  min_master_version = lookup(var.master, "version", data.google_container_engine_versions.engine_version.latest_master_version)
  node_version       = lookup(var.master, "version", data.google_container_engine_versions.engine_version.latest_node_version)
  monitoring_service = lookup(var.master, "monitoring_service", "monitoring.googleapis.com/kubernetes")
  logging_service    = lookup(var.master, "logging_service", "logging.googleapis.com/kubernetes")

  # Disable basic authentication and cert-based authentication.
  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # Specify the list of CIDRs which can access the master's API
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.kubernetes_master_authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  # Configure the cluster to be private (not have public facing IPs)
  private_cluster_config {
    # This field is misleading. This prevents access to the master API from
    # any external IP. While that might represent the most secure
    # configuration, it is not ideal for most setups. As such, we disable the
    # private endpoint (allow the public endpoint) and restrict which CIDRs
    # can talk to that endpoint.
    enable_private_endpoint = false

    enable_private_nodes   = true
    master_ipv4_cidr_block = var.kubernetes_masters_ipv4_cidr
  }
}
