# This ultimately generates userdata_fedora_docker, which ensures servers have
# docker installed, and `tls_private_key.rke` is able to ssh in as the `ssh`
# user.

locals {
  # This is a cloudconfig snippet, configuring a rke user that can run docker,
  # is part of the users group and can sudo without password.
  # It's used by the RKE installer to ssh in and set itself up.
  cloudconfig_fedora_users = [
    "default", {
      "name" : "rke",
      "groups" : ["users", "docker"],
      "sudo" : "ALL=(ALL) NOPASSWD:ALL",
      "ssh_authorized_keys" : [tls_private_key.rke.public_key_openssh],
    }
  ]

  # These are the cloudconfig commands required to install and enable docker, then reboot once
  cloudconfig_runcmd_fedora_docker = [
    ["cloud-init-per", "once", "dnf-install-moby-engine", "dnf", "install", "-y", "moby-engine"],
    ["cloud-init-per", "once", "systemctl-enable-docker", "systemctl", "enable", "docker"],
    ["cloud-init-per", "once", "grubby-disable-unified-cgroup", "grubby", "--update-kernel=ALL", "--args=\"systemd.unified_cgroup_hierarchy=0\""],
    ["cloud-init-per", "once", "reboot-after-unified-cgroup", "systemctl", "reboot"],
  ]

  # This assembles the above two commands to a cloudconfig yaml.
  cloudconfig_fedora_docker = {
    "users" : local.cloudconfig_fedora_users
    "groups" : ["docker"],
    "runcmd" : local.cloudconfig_runcmd_fedora_docker
  }

  # This assembles the cloudconfig_fedora_docker yaml to a long string, to be
  # consumed in user_data for servers.
  userdata_fedora_docker = "#cloud-config\n${yamlencode(local.cloudconfig_fedora_docker)}"



  # TODO: make this either ubuntu or fedora
  cloudconfig_ubuntu_users = [
    "default", {
      "name" : "rke",
      "groups" : ["users", "docker"],
      "sudo" : "ALL=(ALL) NOPASSWD:ALL",
      "ssh_authorized_keys" : [tls_private_key.rke.public_key_openssh],
    }
  ]

  # This assembles the above two commands to a cloudconfig yaml.
  cloudconfig_ubuntu_docker = {
    "packages": [
      "apt-transport-https",
      "ca-certificates",
      "curl",
      "software-properties-common",
      #"docker-ce=19.03"
      "docker-ce=5:19.03.0~3-0~ubuntu-bionic"
    ]
    "apt": { "sources": { "docker-ppa.list": { source: "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable", keyid: "9DC858229FC7DD38854AE2D88D81803C0EBFCD88"} } }
    "users" : local.cloudconfig_ubuntu_users
    "groups" : ["docker"],
    "runcmd" : [
      ["cloud-init-per", "once", "apt-mark-hold", "apt-mark", "hold", "docker-ce"],
    ]
  }

  # This assembles the cloudconfig_fedora_docker yaml to a long string, to be
  # consumed in user_data for servers.
  userdata_ubuntu_docker = "#cloud-config\n${yamlencode(local.cloudconfig_ubuntu_docker)}"
}


