# Google Kubernetes Engine (GKE) cluster

Compatible provider `3.5.0` (**stable**)

## Examples

* 1 cluster, 1 default node pool (2 nodes (10GB/node) n1-standard-1), latest version of Kubernetes for each node,
* Default Google network (`default`).

```hcl
module "gke-cluster" {
  source = "github.com/framled/kubernetes-engine/google"
  version = "2.5.0"

  general = {
    name = "mycluster"
    env  = "prod"
    location = "europe-west1-b"
  }

  master = {}
}
```

* 1 cluster, 1 default node pool (3 nodes & n1-standard-1), 2 extra node pool & latest version of Kubernetes for each node,
* Custom Google network.

```hcl
module "gke-cluster" {
  source = "google-terraform-modules/kubernetes-engine/google"
  version = "2.5.0"

  general = {
    name = "mycluster"
    env  = "prod"
    location = "europe-west1-b"
  }

  master = {
    network    = "${google_compute_network.vpc.self_link}"
    subnetwork = "${google_compute_subnetwork.subnetwork-tools.self_link}"
  }

  default_node_pool = {
    node_count = 3
    remove     = false
  }

  # Optional in case we have a default pool
  node_pool = [
    {
      machine_type   = "g1-small"
      disk_size_gb   = 20
      node_count     = 3
      min_node_count = 2
      max_node_count = 4
    },
    {
      disk_size_gb   = 30
      node_count     = 2
      min_node_count = 1
      max_node_count = 3
    },
  ]
}
```


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| general | Global parameters | map | - | yes |
| region | Region in which to create the cluster and run Atlantis. | string | `us-east4`| no |
| zone | The zone where the cluster is located. Set up this if you want a zonal cluster | string | `` | no |
| project | Project ID where Terraform is authenticated to run to create additional projects. If provided, Terraform will create the GKE and cluster inside this project. If not given, Terraform will generate a new project. | string | ``| yes |
| org_id | Organization ID. | string | - | yes |
| billing_account | Billing account ID. | `string` | - | yes |
| project_services | List of services to enable on the project. | list(string) | `list` |  no |
| service_account_iam_roles | List of IAM roles to assign to the service account. | list(string) | `["roles/logging.logWriter","roles/monitoring.metricWriter","roles/monitoring.viewer"]` |  no |
| service_account_custom_iam_roles | List of arbitrary additional IAM roles to attach to the service account on the cluster nodes. | list(string) | `` |  no |
| network | Network for the GKE, by default would create a new network | string | `` |  yes |
| subnetwork | Network for the GKE, by default would create a new network | string | `` |  yes |
| kubernetes_network_ipv4_cidr | IP CIDR block for the subnetwork. This must be at least /22 and cannot overlap with any other IP CIDR ranges. | string | `10.0.96.0/22` | no | 
| kubernetes_pods_ipv4_cidr | IP CIDR block for pods. This must be at least /22 and cannot overlap with any other IP CIDR ranges. | string | `10.0.92.0/22` | no |
| kubernetes_services_ipv4_cidr | IP CIDR block for services. This must be at least /22 and cannot overlap with any other IP CIDR ranges. | string | `10.0.88.0/22` | no |
| kubernetes_masters_ipv4_cidr | IP CIDR block for the Kubernetes master nodes. This must be exactly /28 and cannot overlap with any other IP CIDR ranges. | string | `10.0.82.0/28` | no |
| kubernetes_master_authorized_networks | List of CIDR blocks to allow access to the master's API endpoint. This is specified as a slice of objects, where each object has a display_name and cidr_block attribute. The default behavior is to allow anyone (0.0.0.0/0) access to the endpoint. You should restrict access to external IPs that need to access the cluster. | list(string) | `[{display_name = "Anyone", cidr_block = "0.0.0.0/0"}` | no |
| node_locations | List zones in which the cluster nodes are located. Nodes must be in the region of their regional cluster. | list(string) | `<map>` | no |
| master | Kubernetes master parameters to initialize | map | `<map>` | yes |
| addons_config | GKE addons settings | map | `<map>` | no |
| beta_addons_config | GKE beta addons settings | map | `<map>` | no |
| node_pool | Node pool setting to create | map | `<map>` | no |
| labels | The Kubernetes labels (key/value pairs) to be applied to each node | map | `<map>` | no |
| tags | The list of instance tags applied to all nodes. Tags are used to identify valid sources or targets for network firewalls | list | `<list>` | no |


## Outputs

| Name | Description |
|------|-------------|
| client_certificate | Base64 encoded public certificate used by clients to authenticate to the cluster endpoint |
| client_key | Base64 encoded private key used by clients to authenticate to the cluster endpoint |
| cluster_ca_certificate | Base64 encoded public certificate that is the root of trust for the cluster |
| cluster_name | The full name of this Kubernetes cluster |
| endpoint | The IP address of this cluster's Kubernetes master |
| gcr_url | This data source fetches the project name, and provides the appropriate URLs to use for container registry for this project |
| instance_group_urls | List of instance group URLs which have been assigned to the cluster |
| maintenance_window | Duration of the time window, automatically chosen to be smallest possible in the given scenario. Duration will be in RFC3339 format PTnHnMnS |
| master_version | The current version of the master in the cluster. |

