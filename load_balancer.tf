# This creates a load balancer for our controlplane.
resource "hcloud_load_balancer" "controlplane" {
  name               = "load-balancer"
  load_balancer_type = "lb11"
  location           = "nbg1"
}

# This attaches the load balancer to the controlplane network
resource "hcloud_load_balancer_network" "controlplane" {
  load_balancer_id = hcloud_load_balancer.controlplane.id
  network_id       = hcloud_network.nodes.id
}

# This adds a new controlplane target to the loadbalancer, which balances among
# all servers with the "role-controlplane" label set.
resource "hcloud_load_balancer_target" "controlplane" {
  type             = "label_selector"
  load_balancer_id = hcloud_load_balancer.controlplane.id
  label_selector   = "role-controlplane=1"
  use_private_ip   = true
  depends_on = [
    hcloud_load_balancer_network.controlplane
  ]
}

# This registers a service at port 6443
resource "hcloud_load_balancer_service" "controlplane_service" {
  load_balancer_id = hcloud_load_balancer.controlplane.id
  protocol         = "tcp"
  listen_port      = "6443"
  destination_port = "6443"
}

output "controlplane_ipv4" {
  value = hcloud_load_balancer.controlplane.ipv4
}

output "controlplane_ipv6" {
  value = hcloud_load_balancer.controlplane.ipv6
}
