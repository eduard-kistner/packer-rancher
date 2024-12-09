variable "access_token" {
  default = env("TOKEN")
}

variable "build" {
  default = env("BUILD_NUMBER")
}

packer {
  required_plugins {
    vagrant = {
      version = "~> 1"
      source = "github.com/hashicorp/vagrant"
    }
  }
}

source "vagrant" "debian11" {
  add_force    = true
  communicator = "ssh"
  provider     = "virtualbox"
  source_path  = "generic/debian12"
  template     = "config/Vagrantfile.template"
}

build {
  sources = ["source.vagrant.debian11"]

  provisioner "shell" {
    execute_command = "echo 'vagrant' | {{ .Vars }} sudo -S -E bash '{{ .Path }}'"
    scripts         = [
        "scripts/install.sh"
    ]
  }

  post-processor "vagrant" {
    provider_override   = "virtualbox"
    keep_input_artifact = true
    output              = "package.box"
  }

  post-processor "vagrant-cloud" {
    access_token = "${var.access_token}"
    box_tag      = "el8ctric/rancher"
    version      = "0.1.${var.build}"
    architecture = "amd64"
  }
}
