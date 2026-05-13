output "subnet_id" {
  value = yandex_vpc_subnet.main.id
}

output "folder_id" {
  value = var.folder_id
}

output "zone" {
  value = var.zone
}

output "sa_json_credentials" {
  description = "Put this value into GitHub secret YC_SA_JSON_CREDENTIALS"
  sensitive   = true
  value = jsonencode({
    id                 = yandex_iam_service_account_key.runner_sa_key.id
    service_account_id = yandex_iam_service_account.runner_sa.id
    created_at         = yandex_iam_service_account_key.runner_sa_key.created_at
    key_algorithm      = yandex_iam_service_account_key.runner_sa_key.key_algorithm
    public_key         = yandex_iam_service_account_key.runner_sa_key.public_key
    private_key        = yandex_iam_service_account_key.runner_sa_key.private_key
  })
}
