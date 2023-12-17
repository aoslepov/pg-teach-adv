```
yc compute instance create \
  --name test-pg \
  --hostname test-pg \
  --create-boot-disk size=30G,type=network-hdd,image-folder-id=standard-images,image-family=ubuntu-2004-lts \
  --cores 2 \
  --memory 2G \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --zone ru-central1-a \
  --metadata-from-file ssh-keys=/home/aslepov/meta.txt


#install libraries
sudo apt update && sudo apt upgrade -y -q && echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main"
sudo tee -a /etc/apt/sources.list.d/pgdg.list && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc
apt update
apt-get install libpq-dev postgresql-server-dev-all git mc cmake gcc openssl libssl-dev

#promotheus-c client

wget https://github.com/digitalocean/prometheus-client-c/releases/download/v0.1.3/libpromhttp-dev-0.1.3-Linux.deb
wget https://github.com/digitalocean/prometheus-client-c/releases/download/v0.1.3/libprom-dev-0.1.3-Linux.deb

apt install ./libprom-dev-0.1.3-Linux.deb ./libpromhttp-dev-0.1.3-Linux.deb

#install odyssey
wget https://github.com/yandex/odyssey/archive/refs/tags/1.3.tar.gz
make build_release
make install



#install prometheus
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install postgresql-16

create user admin with password 'passwd' login superuser;

https://github.com/yandex/odyssey/tree/master?tab=readme-ov-file
https://blog.programs74.ru/how-to-install-yandex-odyssey/

```
