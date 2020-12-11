# hcloud-rke

This spins up a RKE2 cluster on hcloud.

It will create a ssh key at `ssh_key_path`.
This is needed to ssh into the cluster for ops, as well as retrieving the initial kubeconfig.

It will install
[hcloud-cloud-controller-manager](https://github.com/hetznercloud/hcloud-cloud-controller-manager),
and configure their internal nginx ingress controller to deploy services of
type `LoadBalancer` - so instead of configuring the load balancer by yourself,
it'll create one for you. This can be overridden by setting `setup_hetzner_ccm` to false.

`hcloud-cloud-controller-manager` requires an API token to be configured. As
the hcloud terraform provider does not allow to create API tokens on demand, this needs to be configured manually.

ssh into one of the controlplane nodes and run the following:
```
kubectl -n kube-system create secret generic hcloud --from-literal=token=<hcloud API token>
```

Please see `variables.tf` for a full list of configuration options.
