variable "folder_id" {
  type    = string
  default = "b1g8kl47hogpklpcjgbh"
}

variable "zone" {
  type    = string
  default = "ru-central1-a"
}

variable "github_org" {
  type        = string
  description = "GitHub organization or personal account name (e.g. my-org or my-username)"
}

variable "github_entity_type" {
  type        = string
  default     = "org"
  description = "Either 'org' (GitHub organization) or 'user' (personal account)"

  validation {
    condition     = contains(["org", "user"], var.github_entity_type)
    error_message = "Must be 'org' or 'user'."
  }
}

variable "runner_labels" {
  type        = string
  default     = "yc-ephemeral"
  description = "Comma-separated runner labels. Workflows must request this label."
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

variable "function_memory_mb" {
  type    = number
  default = 256
}

variable "function_timeout_s" {
  type    = number
  default = 30
}

variable "github_pat" {
  type        = string
  sensitive   = true
  description = "GitHub PAT with manage_runners:org permission"
}

variable "webhook_secret" {
  type        = string
  sensitive   = true
  description = "HMAC-SHA256 secret to verify GitHub webhook payloads"
}
