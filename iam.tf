# Service account for the Cloud Function: creates/deletes runner VMs
resource "yandex_iam_service_account" "fn_sa" {
  name      = "${local.name_prefix}-fn-sa"
  folder_id = var.folder_id
}

# Service account for runner VMs: allows self-deletion only
resource "yandex_iam_service_account" "runner_sa" {
  name      = "${local.name_prefix}-vm-sa"
  folder_id = var.folder_id
}

resource "yandex_resourcemanager_folder_iam_member" "fn_sa_compute_admin" {
  folder_id = var.folder_id
  role      = "compute.admin"
  member    = "serviceAccount:${yandex_iam_service_account.fn_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "fn_sa_vpc_user" {
  folder_id = var.folder_id
  role      = "vpc.user"
  member    = "serviceAccount:${yandex_iam_service_account.fn_sa.id}"
}

# Allows fn_sa to attach runner_sa to newly created VMs
resource "yandex_iam_service_account_iam_member" "fn_sa_uses_runner_sa" {
  service_account_id = yandex_iam_service_account.runner_sa.id
  role               = "iam.serviceAccounts.user"
  member             = "serviceAccount:${yandex_iam_service_account.fn_sa.id}"
}

resource "yandex_lockbox_secret_iam_member" "fn_sa_lockbox" {
  secret_id = yandex_lockbox_secret.runner_secrets.id
  role      = "lockbox.payloadViewer"
  member    = "serviceAccount:${yandex_iam_service_account.fn_sa.id}"
}

# compute.operator: can delete/stop instances but cannot create them
resource "yandex_resourcemanager_folder_iam_member" "runner_sa_compute_operator" {
  folder_id = var.folder_id
  role      = "compute.operator"
  member    = "serviceAccount:${yandex_iam_service_account.runner_sa.id}"
}
