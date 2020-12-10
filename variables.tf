variable "num_controlplane" {
  type        = number
  description = "The number of controlplane nodes to deloy"
  default     = 3
}

variable "controlplane_has_worker" {
  type        = bool
  description = "Whether to register the controlplane node as a worker node too"
  default     = false
}

variable "controlplane_has_etcd" {
  type        = bool
  description = "Whether to deploy etcd on the controlplane nodes"
  default     = false
}

variable "num_etcd" {
  type        = number
  description = "How many pure etcd nodes to deploy. Ignored if controlplane_has_etcd is true"
  default     = 3
}

variable "num_workers" {
  type        = number
  description = "How many pure worker nodes to deploy, in addition to controlplane nodes (where workload runs too if controlplane_has_worker)"
  default     = 3
}

variable "cluster_config_path" {
  type        = string
  description = "The path to persist the cluster.yaml file to. RKE will create this file, and a statefile alongside."
  default     = "cluster.yml"
}
