locals {
  name_prefix = "${var.general["name"]}-${var.general["env"]}"
  location = coalesce(var.region, var.zone)
}

# Create the project if one isn't specified
resource "google_project" "project" {
  count           = var.project != "" ? 0 : 1
  name            = var.project
  project_id      = var.project.hex
  org_id          = var.org_id
  billing_account = var.billing_account
}

# Or use an existing project, if defined
data "google_project" "project" {
  project_id = var.project != "" ? var.project : google_project.project[0].project_id
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


# Create the vault service account
resource "google_service_account" "vault-server" {
  account_id   = "vault-server"
  display_name = "Vault Server"
  project      = data.google_project.project.project_id
}

# Create a service account key
resource "google_service_account_key" "vault" {
  service_account_id = google_service_account.vault-server.name
}

# Add the service account to the project
resource "google_project_iam_member" "service-account" {
  count   = length(var.service_account_iam_roles)
  project = data.google_project.project.project_id
  role    = element(var.service_account_iam_roles, count.index)
  member  = "serviceAccount:${google_service_account.vault-server.email}"
}

# Add user-specified roles
resource "google_project_iam_member" "service-account-custom" {
  count   = length(var.service_account_custom_iam_roles)
  project = data.google_project.project.project_id
  role    = element(var.service_account_custom_iam_roles, count.index)
  member  = "serviceAccount:${google_service_account.vault-server.email}"
}