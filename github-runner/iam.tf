resource "yandex_iam_service_account" "runner_sa" {
  name      = "${local.name_prefix}-sa"
  folder_id = var.folder_id
}

resource "yandex_resourcemanager_folder_iam_member" "runner_sa_editor" {
  folder_id = var.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.runner_sa.id}"
}
