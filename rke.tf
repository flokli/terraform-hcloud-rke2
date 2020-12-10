resource "null_resource" "deploy_rke" {
  depends_on = [
    hcloud_server.controlplane,
    hcloud_server.etcd,
    hcloud_server.worker
  ]

  #provisioner "local-exec" {
  #  # I need to pass a file here. And I don't want tf to persist this to disk.
  #  # why not copy over the file?
  #  #  just splice it into cloud-init?
  #  # This runs on the operator box. rke up ssh'es in.
  #  # I don't want to write the file to the CWD, as this should be importable as a tf module
  #  # tf also has no nice way to persist a temporary file
  #  # so how do I pass it in via some bash named pipe?
  #  command = "rke up --config ${var.cluster_config_path}"
  #}
}
