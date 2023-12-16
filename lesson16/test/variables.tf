

variable "hostnames" {
    default = {
        "one" = {
            "name" = "etcd-01"
        },
        "two" = {
            "name" = "etcd-02"
        }
    }
}


# disk
data "yandex_compute_image" "ubuntu_image" {
  family = "ubuntu-2004-lts"
}


# network
resource "yandex_vpc_network" "internal" {
  name = "internal"
}

resource "yandex_vpc_subnet" "internal-a" {
  name           = "internal-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.internal.id
  v4_cidr_blocks = ["10.128.0.0/24"]
}

