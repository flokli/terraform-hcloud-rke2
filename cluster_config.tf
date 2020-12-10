# This generates a ssh private key the rke installer uses
resource "tls_private_key" "rke" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

locals {
  # This creates RKE's cluster.yml
  # See https://rancher.com/docs/rke/latest/en/config-options/ for all options.
  cluster_config = {
    #ssh_key_path: "id_rke",
    ignore_docker_version =  true
    nodes = concat(
      [for idx, node in hcloud_server.controlplane : {
        address           = node.ipv4_address,
        internal_address  = hcloud_server_network.controlplane[idx].ip
        hostname_override = node.name,
        user              = "rke",
        ssh_key = tls_private_key.rke.private_key_pem,
        role = concat(
          ["controlplane"],
          (var.controlplane_has_etcd ? ["etcd"] : []),
          (var.controlplane_has_worker ? ["worker"] : [])
        )
      }],
      [for idx, node in hcloud_server.etcd : {
        address           = node.ipv4_address,
        internal_address  = hcloud_server_network.etcd[idx].ip
        hostname_override = node.name,
        user              = "rke",
        ssh_key = tls_private_key.rke.private_key_pem,
        role              = ["etcd"],
      }],
      [for idx, node in hcloud_server.worker : {
        address           = node.ipv4_address,
        internal_address  = hcloud_server_network.worker[idx].ip
        hostname_override = node.name,
        user              = "rke",
        ssh_key = tls_private_key.rke.private_key_pem,
        role              = ["worker"],
      }]
    )

    network = {
      plugin = "calico"
    }

    #authentication = {
    #  strategy = "x509"
    #  sans: [
    #    hcloud_load_balancer.controlplane.ipv4,
    #    hcloud_load_balancer.controlplane.ipv6
    #  ] // TODO: check if need to add the public ips here, too
    #  // TODO: provide a variable to pass in a DNS hostname too!
    #  //
    #}
    // TODO: allow passing more options here
  }
}

resource "local_file" "cluster_yml" {
  filename = var.cluster_config_path
  sensitive_content  = yamlencode(local.cluster_config)
}

# TODO: remove
resource "local_file" "id_rke" {
  filename = "id_rke"
  sensitive_content  = tls_private_key.rke.private_key_pem
  file_permission = "0600"
}

output "cluster_yml" {
  value     = yamlencode(local.cluster_config)
  sensitive = true
}
