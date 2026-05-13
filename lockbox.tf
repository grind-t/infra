resource "yandex_lockbox_secret" "runner_secrets" {
  name      = "${local.name_prefix}-secrets"
  folder_id = var.folder_id
}

resource "yandex_lockbox_secret_version" "runner_secrets" {
  secret_id = yandex_lockbox_secret.runner_secrets.id
  entries {
    key        = "WEBHOOK_SECRET"
    text_value = var.webhook_secret
  }
  entries {
    key        = "GITHUB_PAT"
    text_value = var.github_pat
  }
}
