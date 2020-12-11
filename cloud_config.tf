# This token is used to bootstrap the cluster and join new nodes
resource "random_string" "rke2_token" {
  length = 64
}

locals {
  # configure rke2_server_url to controlplane_hostname if set, else to the ipv4 of the controlplane load balancer
  rke2_server_url = "https://${var.controlplane_hostname != null ? var.controlplane_hostname : hcloud_load_balancer.controlplane.ipv4}:9345"


  # Configure both the controlplane loadbalancers' IPv4 and IPv6 addresses as
  # SANs, and optionally the controlplane_hostname if set.
  rke2_tls_san = concat(
    [hcloud_load_balancer.controlplane.ipv4, hcloud_load_balancer.controlplane.ipv6],
    var.controlplane_hostname != null ? [var.controlplane_hostname] : []
  )

  # TODO: internal networking!

  userdata_server_bootstrap = module.rke2_cloudconfig_server_bootstrap.userdata
  userdata_server           = module.rke2_cloudconfig_server.userdata
  userdata_agent            = module.rke2_cloudconfig_agent.userdata

  k8s_extra_config = {
    kubelet-arg = var.setup_hetzner_ccm ? [
      "cloud-provider=external"
    ] : []
  }

  # This installs the Hetzner Cloud Controller Manager if enabled (the default)
  #
  # We can't provide additional files in /var/lib/rancher/rke2/server/manifests during startup,
  # as these get overwritten on startup apparently
  # Until addons are supported in RKE2 (https://github.com/rancher/rke2/issues/568), let's NOT
  # do that.
  install_script_post = ! var.setup_hetzner_ccm ? "" : <<-EOS
    curl -sfL https://raw.githubusercontent.com/hetznercloud/hcloud-cloud-controller-manager/v1.8.1/deploy/ccm.yaml > /var/lib/rancher/custom_rke2_addons/hetzner_ccm.yaml
    cat << EOF > /var/lib/rancher/custom_rke2_addons/nginx-use-loadbalancer.yaml
     apiVersion: helm.cattle.io/v1
     kind: HelmChartConfig
     metadata:
       name: rke2-ingress-nginx
       namespace: kube-system
     spec:
       valuesContent: |-
         controller:
           kind: Deployment
           autoscaling:
             enabled: true
             minReplicas: 2
             maxReplicas: 5
           hostNetwork: false
           service:
             enabled: true
             type: LoadBalancer
             externalTrafficPolicy: Local
             annotations:
               load-balancer.hetzner.cloud/location: nbg1
    EOF
  EOS
}

module "rke2_cloudconfig_server_bootstrap" {
  source              = "./cloudconfig-rke2"
  rke2_token          = random_string.rke2_token.result
  server_tls_san      = local.rke2_tls_san
  node_taint          = (! var.controlplane_has_worker) ? ["CriticalAddonsOnly=true:NoExecute"] : []
  install_rke2_type   = "server"
  install_script_post = local.install_script_post
  extra_config        = local.k8s_extra_config
}

module "rke2_cloudconfig_server" {
  source              = "./cloudconfig-rke2"
  rke2_token          = random_string.rke2_token.result
  server_tls_san      = local.rke2_tls_san
  node_taint          = (! var.controlplane_has_worker) ? ["CriticalAddonsOnly=true:NoExecute"] : []
  install_rke2_type   = "server"
  server_url          = local.rke2_server_url
  install_script_post = local.install_script_post
  extra_config        = local.k8s_extra_config
}

module "rke2_cloudconfig_agent" {
  source              = "./cloudconfig-rke2"
  rke2_token          = random_string.rke2_token.result
  install_rke2_type   = "agent"
  server_url          = local.rke2_server_url
  install_script_post = local.install_script_post
  extra_config        = local.k8s_extra_config
}

