output "webhook_url" {
  description = "Set this as the GitHub webhook payload URL (content type: application/json, events: Workflow jobs)"
  value       = "https://functions.yandexcloud.net/${yandex_function.webhook.id}"
}

output "lockbox_secret_id" {
  description = "Lockbox secret ID (WEBHOOK_SECRET and GITHUB_PAT are managed by Terraform)"
  value       = yandex_lockbox_secret.runner_secrets.id
}

output "function_id" {
  value = yandex_function.webhook.id
}

output "runner_subnet_id" {
  value = yandex_vpc_subnet.main.id
}
