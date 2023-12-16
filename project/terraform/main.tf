terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = "ru-central1-a"
}

#network
data "yandex_vpc_network" "default" {
  name = "default"
}

data "yandex_vpc_subnet" "default-ru-central1-a" {
  name = "default-ru-central1-a"
}

data "yandex_vpc_subnet" "default-ru-central1-b" {
  name = "default-ru-central1-b"
}

data "yandex_vpc_subnet" "default-ru-central1-c" {
  name = "default-ru-central1-c"
}




resource "yandex_compute_instance" "zone_a_hostnames" {
  for_each = var.zone_a_hostnames
  name     = each.value.name
  hostname = each.value.name
#  allow_stopping_for_update = true
  zone  = "ru-central1-a"

  resources {
    cores  = each.value.cores
    memory = each.value.mem
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_image.id
      size     = "10"
      type     = "network-hdd"
    }
  }
  
  network_interface {
    subnet_id = data.yandex_vpc_subnet.default-ru-central1-a.id
    nat = true
  }
  
  metadata = {
    user-data = "${file("meta.txt")}"
  }

}


resource "yandex_compute_instance" "zone_b_hostnames" {
  for_each = var.zone_b_hostnames
  name     = each.value.name
  hostname = each.value.name
#  allow_stopping_for_update = true
  zone  = "ru-central1-b"

  resources {
    cores  = each.value.cores
    memory = each.value.mem
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_image.id
      size     = "10"
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id = data.yandex_vpc_subnet.default-ru-central1-b.id
    nat = true
  }

  metadata = {
    user-data = "${file("meta.txt")}"
  }

}




resource "yandex_compute_instance" "zone_c_hostnames" {
  for_each = var.zone_c_hostnames
  name     = each.value.name
  hostname = each.value.name
#  allow_stopping_for_update = true
  zone  = "ru-central1-c"

  resources {
    cores  = each.value.cores
    memory = each.value.mem
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_image.id
      size     = "10"
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id = data.yandex_vpc_subnet.default-ru-central1-c.id
    nat = true
  }

  metadata = {
    user-data = "${file("meta.txt")}"
  }

}
