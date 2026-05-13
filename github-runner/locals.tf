locals {
  name_prefix      = "gh-runner"
  runner_memory_mb = var.runner_memory_gb * 1024
}
