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


resource "yc_etcd_compute_instance" "default" {
    for_each = var.hostnames
    name         = each.value.name
    hostname = each.value.name

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_image.id
      size     = "10"
      type     = "network-hdd"
    }
  }
  
  
  
  network_interface {
    subnet_id = yandex_vpc_subnet.internal-a.id
    nat = true
  }
  
  metadata = {
    user-data = "${file("meta.txt")}"
  }



}
