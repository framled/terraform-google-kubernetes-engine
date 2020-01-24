# use a defined project
data "google_project" "project" {
  project_id = var.project
}

# Enable required services on the project
resource "google_project_service" "service" {
  count   = length(var.project_services)
  project = data.google_project.project.project_id
  service = element(var.project_services, count.index)

  # Do not disable the service on destroy. On destroy, we are going to
  # destroy the project, but we need the APIs available to destroy the
  # underlying resources.
  disable_on_destroy = false
}

resource "random_string" "cluster_service_account_suffix" {
  upper   = false
  lower   = true
  special = false
  length  = 4
}

# Create the vault service account
resource "google_service_account" "service_account" {
  account_id   = "tf-gke-${substr(var.general["name"], 0, min(15, length(var.general["name"])))}-${random_string.cluster_service_account_suffix.result}"
  project      = data.google_project.project.project_id
  display_name = "Terraform-managed service account for cluster ${local.name_prefix}"
}

# Create a service account key
resource "google_service_account_key" "service_account_key" {
  service_account_id = google_service_account.service_account.name
}

# Add user-specified roles
resource "google_project_iam_member" "cluster_service_account-log_writer" {
  project = data.google_project.project.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "cluster_service_account-metric_writer" {
  project = data.google_project.project.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "cluster_service_account-monitoring_viewer" {
  project = data.google_project.project.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "cluster_service_account-gcr" {
  project = data.google_project.project.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}
