
## provider 
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



resource "yandex_compute_instance" "vm-1" {
  name     = "pg-teach-yc"
  hostname = "pg-teach-yc"

  resources {
    cores  = 2
    memory = 4
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


  provisioner "remote-exec" {
    inline = ["# Connected!"]
    connection {
      host = self.network_interface.0.nat_ip_address
      user = "ubuntu"
    }
  }

  provisioner "local-exec" {
    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
    }
    command = "ansible-playbook -u ubuntu -i '${self.network_interface.0.nat_ip_address},' ansible-postgres-install.yml"
  }



}



output "pg_teach_01_ansible_host" {
  value = yandex_compute_instance.vm-1.network_interface.0.nat_ip_address
}

