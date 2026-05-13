resource "yandex_vpc_network" "main" {
  name      = "${local.name_prefix}-network"
  folder_id = var.folder_id
}

# NAT gateway provides outbound internet without public IPs on runner VMs
resource "yandex_vpc_gateway" "nat" {
  name      = "${local.name_prefix}-nat"
  folder_id = var.folder_id
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "main" {
  name       = "${local.name_prefix}-rt"
  folder_id  = var.folder_id
  network_id = yandex_vpc_network.main.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat.id
  }
}

resource "yandex_vpc_subnet" "main" {
  name           = "${local.name_prefix}-subnet"
  folder_id      = var.folder_id
  zone           = var.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.subnet_cidr]
  route_table_id = yandex_vpc_route_table.main.id
}
