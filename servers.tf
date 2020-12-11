resource "hcloud_ssh_key" "root" {
  name       = "root-${random_pet.cluster_name.id}"
  public_key = tls_private_key.root.public_key_openssh
}

# These are controlplane nodes, running etcd.
# They optionally also run worker payloads.
resource "hcloud_server" "controlplane" {
  count       = var.num_controlplane
  name        = "controlplane-${random_pet.cluster_name.id}-${count.index}"
  image       = "fedora-32"
  server_type = "cx11"
  ssh_keys    = [hcloud_ssh_key.root.name]
  location    = "nbg1"
  labels = merge(
    { "role-controlplane" = "1" },
    var.controlplane_has_worker ? { "role-worker" = "1" } : {}
  )
  user_data = count.index == 0 ? local.userdata_server_bootstrap : local.userdata_server
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

# These are worker-only nodes
resource "hcloud_server" "worker" {
  count       = var.num_workers
  name        = "worker-${random_pet.cluster_name.id}-${count.index}"
  image       = "fedora-32"
  server_type = "cx11"
  ssh_keys    = [hcloud_ssh_key.root.name]
  location    = "nbg1"
  labels      = { "role-worker" = "1" }
  user_data   = local.userdata_agent
}

# Attach worker nodes to the private network.
# Even though they might be able to reach other nodes through their public IPs,
# the private network (on hetzner at least) is way faster.
resource "hcloud_server_network" "worker" {
  count     = var.num_workers
  server_id = hcloud_server.worker[count.index].id
  subnet_id = hcloud_network_subnet.nodes.id
}

output "worker_ips" {
  value = hcloud_server.worker[*].ipv4_address
}
