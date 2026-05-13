output "subnet_id" {
  description = "Use as subnet-id in yc-actions/yc-github-runner"
  value       = yandex_vpc_subnet.main.id
}

output "runner_service_account_id" {
  description = "Service account ID for generating a JSON key (yc-sa-json-credentials)"
  value       = yandex_iam_service_account.runner_sa.id
}
