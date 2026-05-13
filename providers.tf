terraform {
  required_version = ">= 1.0"
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.129"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "yandex" {
  folder_id = var.folder_id
  zone      = var.zone
}
