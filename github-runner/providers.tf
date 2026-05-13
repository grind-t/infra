terraform {
  required_version = ">= 1.0"
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.129"
    }
  }
}

provider "yandex" {
  folder_id = var.folder_id
  zone      = var.zone
}
