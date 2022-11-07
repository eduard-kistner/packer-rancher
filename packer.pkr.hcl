variable "access_token" {
  default = env("TOKEN")
}

variable "build" {
  default = env("BUILD_NUMBER")
}

source "vagrant" "debian11" {
  add_force    = true
  communicator = "ssh"
  provider     = "virtualbox"
  source_path  = "generic/debian11"
}

build {
  sources = ["source.vagrant.debian11"]

  provisioner "shell" {
    execute_command = "echo 'vagrant' | {{ .Vars }} sudo -S -E bash '{{ .Path }}'"
    scripts         = [
        "scripts/install_k8s_tools.sh",
        "scripts/install_rancher.sh"
    ]
  }

  post-processor "vagrant" {
    provider_override   = "virtualbox"
  }

  post-processor "vagrant-cloud" {
    access_token = "${var.access_token}"
    box_tag      = "el8ctric/docker"
    version      = "0.1.${var.build}"
  }
}
