variable "access_token" {
  default = env("TOKEN")
}

variable "build" {
  default = env("BUILD_NUMBER")
}

variable "hcp_client_id" {
  type    = string
  default = "${env("HCP_CLIENT_ID")}"
}

variable "hcp_client_secret" {
  type    = string
  default = "${env("HCP_CLIENT_SECRET")}"
}

packer {
  required_plugins {
    vagrant = {
      version = "~> 1"
      source = "github.com/hashicorp/vagrant"
    }
  }
}

source "vagrant" "debian12" {
  add_force    = true
  communicator = "ssh"
  provider     = "virtualbox"
  source_path  = "generic/debian12"
  template     = "config/Vagrantfile.template"
  output_dir   = "packer_build"
}

build {
  sources = ["source.vagrant.debian12"]

  provisioner "shell" {
    execute_command = "echo 'vagrant' | {{ .Vars }} sudo -S -E bash '{{ .Path }}'"
    scripts         = [
        "scripts/install.sh"
    ]
  }

  post-processor "vagrant-registry" {
    client_id     = "${var.hcp_client_id}"
    client_secret = "${var.hcp_client_secret}"
    box_tag       = "el8ctric/rancher"
    version       = "0.1.${var.build}"
    architecture  = "amd64"
  }
}
