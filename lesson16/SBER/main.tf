terraform {
  required_providers {
    sbercloud = {
      source = "sbercloud-terraform/sbercloud"
      version = "1.0.0"
    }
  }
}

//Настраиваем провайдера
provider "sbercloud" {
  region = "ru-moscow-1" //указываем регион. Пока что он один
  access_key = "276V4IGT66VALK7UT39B" //тут нужно указать ваш ключ
  secret_key = "YZHuJ8FdwuxUNbURzDxiWgK2kwMxS6vSqi7sPSLY" //тут нужно указать ваш пароль
}

resource "sbercloud_vpc" "test_vpc" {
  name = "test_vpc" //имя VPC, которое будет создано, может отличаться от имени объекта
  cidr = "172.30.0.0/23" // сама сеть
}
