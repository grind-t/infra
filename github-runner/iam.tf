resource "yandex_iam_service_account" "runner_sa" {
  name      = "${local.name_prefix}-sa"
  folder_id = var.folder_id
}

resource "yandex_resourcemanager_folder_iam_member" "runner_sa_compute_admin" {
  folder_id = var.folder_id
  role      = "compute.admin"
  member    = "serviceAccount:${yandex_iam_service_account.runner_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "runner_sa_vpc_user" {
  folder_id = var.folder_id
  role      = "vpc.user"
  member    = "serviceAccount:${yandex_iam_service_account.runner_sa.id}"
}
