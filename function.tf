data "archive_file" "webhook_handler" {
  type        = "zip"
  source_dir  = "${path.module}/functions/webhook_handler"
  output_path = "${path.module}/functions/webhook_handler.zip"
}

resource "yandex_function" "webhook" {
  name               = "${local.name_prefix}-webhook"
  folder_id          = var.folder_id
  runtime            = "python312"
  entrypoint         = "main.handler"
  memory             = var.function_memory_mb
  execution_timeout  = tostring(var.function_timeout_s)
  service_account_id = yandex_iam_service_account.fn_sa.id

  content {
    zip_filename = data.archive_file.webhook_handler.output_path
  }

  user_hash = data.archive_file.webhook_handler.output_sha256

  environment = {
    FOLDER_ID        = var.folder_id
    SUBNET_ID        = yandex_vpc_subnet.main.id
    RUNNER_SA_ID     = yandex_iam_service_account.runner_sa.id
    GITHUB_ORG         = var.github_org
    GITHUB_ENTITY_TYPE = var.github_entity_type
    RUNNER_LABELS    = var.runner_labels
    RUNNER_CORES     = tostring(var.runner_cores)
    RUNNER_MEMORY_MB = tostring(local.runner_memory_mb)
    RUNNER_DISK_GB   = tostring(var.runner_disk_gb)
    RUNNER_DISK_TYPE = var.runner_disk_type
    RUNNER_IMAGE_ID  = var.runner_image_id
    ZONE             = var.zone
  }

  secrets {
    id                   = yandex_lockbox_secret.runner_secrets.id
    version_id           = yandex_lockbox_secret_version.runner_secrets.id
    key                  = "WEBHOOK_SECRET"
    environment_variable = "WEBHOOK_SECRET"
  }

  secrets {
    id                   = yandex_lockbox_secret.runner_secrets.id
    version_id           = yandex_lockbox_secret_version.runner_secrets.id
    key                  = "GITHUB_PAT"
    environment_variable = "GITHUB_PAT"
  }

  # Lockbox IAM must be ready before function version is created
  depends_on = [yandex_lockbox_secret_iam_member.fn_sa_lockbox]
}

resource "yandex_function_iam_binding" "public_invoke" {
  function_id = yandex_function.webhook.id
  role        = "functions.functionInvoker"
  members     = ["system:allUsers"]
}
