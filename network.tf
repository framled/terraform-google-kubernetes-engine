# Create a network for GKE
resource "google_compute_network" "network" {
  count = var.network != "" ? 0 : 1
  name = "${local.name_prefix}-network"
  project = data.google_project.project.project_id
  auto_create_subnetworks = false

  depends_on = [google_project_service.service]
}

# Create subnets
resource "google_compute_subnetwork" "subnetwork" {
  count = var.subnetwork != "" ? 0 : 1
  name = "${local.name_prefix}-subnetwork"
  project = data.google_project.project.project_id
  network = google_compute_network.network[count.index].self_link
  region = var.region
  ip_cidr_range = var.kubernetes_network_ipv4_cidr

  private_ip_google_access = true

  secondary_ip_range {
    range_name = "${local.name_prefix}-gke-pods"
    ip_cidr_range = var.kubernetes_pods_ipv4_cidr
  }

  secondary_ip_range {
    range_name = "${local.name_prefix}-gke-svcs"
    ip_cidr_range = var.kubernetes_services_ipv4_cidr
  }
}

data "google_compute_network" "network" {
  depends_on = [google_project_service.service]
  project = data.google_project.project.project_id
  name = var.network != "" ? var.network : google_compute_network.network[0].name
}

data "google_compute_subnetwork" "subnetwork" {
  depends_on = [google_project_service.service]
  project = data.google_project.project.project_id
  name = var.subnetwork != "" ? var.subnetwork : google_compute_subnetwork.subnetwork[0].name
}