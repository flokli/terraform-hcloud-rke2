# This creates a ssh private key that can be used for root login.
# It's mostly there to make hcloud not send emails :-)
resource "tls_private_key" "root" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "random_pet" "ssh_key_root" {
}

resource "hcloud_ssh_key" "root" {
  name       = "root-${random_pet.ssh_key_root.id}"
  public_key = tls_private_key.root.public_key_openssh
}

# These are controlplane nodes.
# They optionally also run worker payloads and etcd.
resource "hcloud_server" "controlplane" {
  count       = var.num_controlplane
  name        = "controlplane-${count.index}"
  image       = "ubuntu-20.04"
  server_type = "cpx41"
  ssh_keys    = [hcloud_ssh_key.root.name]
  location    = "nbg1"
  labels = merge(
    { "role-controlplane" = "1" },
    var.controlplane_has_etcd ? { "role-etcd" = "1" } : {},
    var.controlplane_has_worker ? { "role-worker" = "1" } : {}
  )
  user_data = local.userdata_ubuntu_docker
}

# Attach controlplane nodes to the private network.
resource "hcloud_server_network" "controlplane" {
  count     = var.num_controlplane
  server_id = hcloud_server.controlplane[count.index].id
  subnet_id = hcloud_network_subnet.nodes.id
}

output "controlplane_ips" {
  value = hcloud_server.controlplane[*].ipv4_address
}

# These are etcd-only nodes. We only deploy them if controlplane_has_etcd is
# false.
resource "hcloud_server" "etcd" {
  count       = var.controlplane_has_etcd ? 0 : var.num_etcd
  name        = "etcd-${count.index}"
  image       = "ubuntu-20.04"
  server_type = "cpx21"
  ssh_keys    = [hcloud_ssh_key.root.name]
  location    = "nbg1"
  labels = { "role-etcd" = "1" }
  user_data   = local.userdata_ubuntu_docker
}

output "etcd_ips" {
  value = hcloud_server.etcd[*].ipv4_address
}

# Attach etcd nodes to the private network.
resource "hcloud_server_network" "etcd" {
  count     = var.controlplane_has_etcd ? 0 : var.num_etcd
  server_id = hcloud_server.etcd[count.index].id
  subnet_id = hcloud_network_subnet.nodes.id
}

# These are worker-only nodes
resource "hcloud_server" "worker" {
  count       = var.num_workers
  name        = "worker-${count.index}"
  image       = "ubuntu-20.04"
  server_type = "cpx41"
  ssh_keys    = [hcloud_ssh_key.root.name]
  location    = "nbg1"
  labels = { "role-worker" = "1" }
  user_data   = local.userdata_ubuntu_docker
}

# Attach worker nodes to the private network.
# TODO: do we need worker nodes to be on the same private network? Or shouldn't
# they just go via the public endpoint? How does that work with controlplane_has_worker?
resource "hcloud_server_network" "worker" {
  count     = var.num_workers
  server_id = hcloud_server.worker[count.index].id
  subnet_id = hcloud_network_subnet.nodes.id
}

output "worker_ips" {
  value = hcloud_server.worker[*].ipv4_address
}
