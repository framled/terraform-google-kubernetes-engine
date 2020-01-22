# For more details please see the following pages :
# https://www.terraform.io/docs/providers/google/r/container_cluster.html
# https://www.terraform.io/docs/providers/google/r/container_node_pool.html
# https://www.terraform.io/docs/providers/google/d/google_container_engine_versions.html
# https://www.terraform.io/docs/providers/google/d/google_container_registry_repository.html

##########################
###       Global       ###
##########################

# Parameters authorized:
# name (mandatory)
# env (mandatory)
variable "general" {
  type        = "map"
  description = "Global parameters"
}

variable "region" {
  type        = string
  default     = "us-east4"
  description = "Region in which to create the cluster and run Atlantis."
}

variable zone {
  type = "string"
  description = "The zone where the cluster is located. Set up this if you want a zonal cluster"
}

##########################
###       Project      ###
##########################

variable "project" {
  type        = string
  default     = ""
  description = "Project ID where Terraform is authenticated to run to create additional projects. If provided, Terraform will create the GKE and cluster inside this project. If not given, Terraform will generate a new project."
}

variable "org_id" {
  type        = string
  description = "Organization ID."
}

variable "billing_account" {
  type        = string
  description = "Billing account ID."
}

variable "project_services" {
  type = list(string)
  default = [
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "container.googleapis.com",
    "compute.googleapis.com",
    "gcp.redisenterprise.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ]
  description = "List of services to enable on the project."
}

variable "service_account_iam_roles" {
  type = list(string)
  default = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
  ]
  description = "List of IAM roles to assign to the service account."
}

variable "service_account_custom_iam_roles" {
  type        = list(string)
  default     = []
  description = "List of arbitrary additional IAM roles to attach to the service account on the cluster nodes."
}

##########################
###       Network      ###
##########################

variable network {
  type = "string"
  description = "Network for the GKE, by default would create a new network"
  default = ""
}

variable subnetwork {
  type = "string"
  description = "Network for the GKE, by default would create a new network"
  default = ""
}

##########################
###         GKE        ###
##########################
variable "kubernetes_network_ipv4_cidr" {
  type        = string
  default     = "10.0.96.0/22"
  description = "IP CIDR block for the subnetwork. This must be at least /22 and cannot overlap with any other IP CIDR ranges."
}

variable "kubernetes_pods_ipv4_cidr" {
  type        = string
  default     = "10.0.92.0/22"
  description = "IP CIDR block for pods. This must be at least /22 and cannot overlap with any other IP CIDR ranges."
}

variable "kubernetes_services_ipv4_cidr" {
  type        = string
  default     = "10.0.88.0/22"
  description = "IP CIDR block for services. This must be at least /22 and cannot overlap with any other IP CIDR ranges."
}

variable "kubernetes_masters_ipv4_cidr" {
  type        = string
  default     = "10.0.82.0/28"
  description = "IP CIDR block for the Kubernetes master nodes. This must be exactly /28 and cannot overlap with any other IP CIDR ranges."
}

variable "kubernetes_master_authorized_networks" {
  type = list(object({
    display_name = string
    cidr_block   = string
  }))

  default = [
    {
      display_name = "Anyone"
      cidr_block   = "0.0.0.0/0"
    },
  ]

  description = "List of CIDR blocks to allow access to the master's API endpoint. This is specified as a slice of objects, where each object has a display_name and cidr_block attribute. The default behavior is to allow anyone (0.0.0.0/0) access to the endpoint. You should restrict access to external IPs that need to access the cluster."
}

# For more details please see the following page:
# https://www.terraform.io/docs/providers/google/r/container_cluster.html#node_locations
variable node_locations {
  type = list(string)
  description = "List zones in which the clust's nodes are located. Nodes must be in the region of their regional cluster."
}

# Parameters authorized:
# enable_kubernetes_alpha (default: false)
# enable_legacy_abac (default: false)
# maintenance_window (default: 4:30)
# version (default: Data resource)
# monitoring_service (default: monitoring.googleapis.com/kubernetes)
# logging_service (default: logging.googleapis.com/kubernetes)
variable "master" {
  type        = "map"
  description = "Kubernetes master parameters to initialize"
}

# Parameters authorized:
# disable_horizontal_pod_autoscaling (default: false)
# disable_http_load_balancing (default: false)
# disable_network_policy_config (default: true)
variable "addons_config" {
  type = "map"
  description: "GKE addons settings"
}

# Parameters authorized:
# disabled_istio_config (default: true)
# istio_auth: (default: AUTH_MUTUAL_TLS)
variable "beta_addons_config" {
  type = "map"
  description = "Kubernetes beta addons settings"
}

# Parameters authorized:
# node_count (default: 3)
# machine_type (default: n1-standard-1)
# disk_size_gb (default: 10)
# preemptible (default: false)
# local_ssd_count (default: 0)
# oauth_scopes (default: https://www.googleapis.com/auth/compute,https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring)
# min_node_count (default: 1)
# max_node_count (default: 3)
# auto_repair (default: true)
# auto_upgrade (default: true)
# metadata (default: {})
variable "node_pool" {
  type        = "list"
  default     = []
  description = "Node pool setting to create"
}

# https://www.terraform.io/docs/providers/google/r/container_cluster.html#tags
variable "tags" {
  type        = "list"
  default     = []
  description = "The list of instance tags applied to all nodes. Tags are used to identify valid sources or targets for network firewalls"
}

# https://www.terraform.io/docs/providers/google/r/container_cluster.html#labels
variable "labels" {
  description = "The Kubernetes labels (key/value pairs) to be applied to each node"
  type        = "map"
  default     = {}
}

# https://www.terraform.io/docs/providers/google/r/container_cluster.html#metadata
variable "metadata" {
  description = "The metadata key/value pairs assigned to instances in the cluster"
  type        = "map"
  default     = {}
}
