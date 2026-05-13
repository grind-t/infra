variable "folder_id" {
  type    = string
  default = "b1g606qspnhgrua2djkm"
}

variable "zone" {
  type    = string
  default = "ru-central1-a"
}

variable "runner_cores" {
  type    = number
  default = 2
}

variable "runner_memory_gb" {
  type    = number
  default = 4
}

variable "runner_disk_gb" {
  type    = number
  default = 20
}

variable "runner_disk_type" {
  type    = string
  default = "network-ssd"
}

variable "runner_image_id" {
  type        = string
  default     = "fd8fc3q8qr0cgjqk2v94"
  description = "Ubuntu 22.04 LTS standard image ID"
}

variable "subnet_cidr" {
  type    = string
  default = "10.10.0.0/24"
}
