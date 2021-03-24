provider "libvirt" {
}

provider "gandi" {
  # key = "<livedns apikey>"
  # sharing_id = "<sharing id>"
}

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
  #  server_url = "https://acme-staging-v02.api.letsencrypt.org/directory"
}
