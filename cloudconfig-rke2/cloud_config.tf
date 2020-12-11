locals {
  rke2_config = yamlencode(merge(
    {
      "node-taint" : var.node_taint
      "tls-san" : var.server_tls_san
    },
    # Set 'server' on all nodes where it's passed in
    (var.server_url != null) ? { "server" : var.server_url } : {},
    # If rke2_token is passed, set it
    (var.rke2_token != null) ? { "token" : var.rke2_token } : {},
    var.extra_config
  ))

  # This will download and execute the RKE installer, and configure systemd to
  # start it on the next boot.
  # It will also create and setup the `kubeconfig` tooling, a poormans alternative
  # for RKE2 addons, that can be dropped into /var/lib/rancher/custom_rke2_addons until
  # https://github.com/rancher/rke2/issues/590 is resolved.
  # We need to reboot once to disable unified_cgroup_hierarchy
  rke2_install_script = <<-EOT
    #!/usr/bin/env bash
    ${var.install_script_pre}
    curl -sfL https://get.rke2.io | INSTALL_RKE2_CHANNEL="${var.install_rke2_channel}" INSTALL_RKE2_TYPE="${var.install_rke2_type}" sh -
    mkdir -p /var/lib/rancher/custom_rke2_addons
    ${var.install_script_post}

    # enable this, so after rebooting into cgroupsv1 it'll boot up
    systemctl enable rke2-${var.install_rke2_type}.service
    systemctl enable kubeconfig.path
  EOT

  systemd_kubeconfig_path = <<-EOA
    [Path]
    PathExists=/etc/rancher/rke2/rke2.yaml

    [Install]
    WantedBy=paths.target
  EOA

  systemd_kubeconfig_service = <<-EOB
    [Unit]
    ConditionPathIsDirectory=/var/lib/rancher/custom_rke2_addons
    ConditionPathExistsGlob=/var/lib/rancher/custom_rke2_addons/*

    [Service]
    Type=oneshot
    Restart=on-failure
    RestartSec=5s
    Environment=KUBECONFIG=/etc/rancher/rke2/rke2.yaml
    ExecStart=/var/lib/rancher/rke2/bin/kubectl apply -f /var/lib/rancher/custom_rke2_addons
  EOB

  cloud_config = {
    "write_files" : [
      # This is a cloudconfig fragment, that will ensure the install script
      # is available at /usr/local/bin/install-rke2.sh
      {
        "path" : "/usr/local/bin/install-rke2.sh",
        "permissions" : "0700",
        "content" : local.rke2_install_script,
        }, {
        "path" : "/etc/rancher/rke2/config.yaml",
        "permissions" : "0600",
        "content" : local.rke2_config,
        }, {
        "path" : "/etc/profile.d/rke.sh",
        "permissions" : "0644",
        "content" : <<-EOE
          export PATH="/var/lib/rancher/rke2/bin:$PATH"
          export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
        EOE
        }, {
        "path" : "/etc/systemd/system/kubeconfig.path",
        "permissions" : "0644",
        "content" : local.systemd_kubeconfig_path
        }, {
        "path" : "/etc/systemd/system/kubeconfig.service",
        "permissions" : "0644",
        "content" : local.systemd_kubeconfig_service
      }
    ],
    "runcmd" : [
      # This will tell cloud-init to once run the install-rke2.sh, reconfigure
      # the bootloader for to disable unified_cgroup_hierarchy, then reboot.
      ["cloud-init-per", "once", "install-rke2-unit", "/usr/local/bin/install-rke2.sh"],
      ["cloud-init-per", "once", "grubby-disable-unified-cgroup", "grubby", "--update-kernel=ALL", "--args=\"systemd.unified_cgroup_hierarchy=0\""],
      ["cloud-init-per", "once", "reboot-after-unified-cgroup", "systemctl", "reboot"]
    ]
  }

  userdata = "#cloud-config\n${yamlencode(local.cloud_config)}"
}

output "userdata" {
  value = local.userdata
}
