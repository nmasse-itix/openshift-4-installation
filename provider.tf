provider "libvirt" {
  uri = "qemu:///system"
}

provider "gandi" {
  # key = "<livedns apikey>"
  # sharing_id = "<sharing id>"
}

locals {
  # See post-install.tf
  libvirt_server   = "hp-ml350.itix.fr"
  libvirt_username = "nicolas"
}
