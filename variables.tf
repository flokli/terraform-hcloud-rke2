variable "num_controlplane" {
  type        = number
  description = "The number of controlplane nodes to deloy"
  default     = 3
}

variable "controlplane_has_worker" {
  type        = bool
  description = "Whether to register the controlplane node as a worker node too"
  default     = true
}

variable "num_workers" {
  type        = number
  description = "How many pure worker nodes to deploy, in addition to controlplane nodes (where workload runs too if controlplane_has_worker)"
  default     = 3
}

variable "controlplane_hostname" {
  type        = string
  description = "The DNS hostname pointing to the load balancer created here. If set, nodes will be configured to contact it, instead of its IPv4 address. Make sure to pass this in as a string, and when creating the record, use the controlplane_ipv4 output as a value, so you can create the record while machines are booting up (and this module returned)"
  default     = null
}

variable "setup_hetzner_ccm" {
  type        = bool
  description = "Whether to set up hcloud-cloud-controller-manager and configure the nginx ingress controller to make use of it"
  default     = true
}

variable "ssh_key_path" {
  type        = string
  description = "The path to persist the ssh key path to."
  default     = "id_root"
}
