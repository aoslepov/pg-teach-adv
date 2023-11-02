

yc compute instance create \
  --name gpdb-01 \
  --hostname gpdb-01 \
  --create-boot-disk size=15G,type=network-ssd,image-folder-id=standard-images,image-family=centos-7 \
  --cores 2 \
  --memory 2G \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --zone ru-central1-a \
  --metadata-from-file ssh-keys=/home/aslepov/meta.txt


 install -y build-essential git bison  flex
sudo apt install -y pkg-config libzstd-dev python3 python3-dev libreadline-dev libapr1-dev libevent-dev libcurl4-openssl-dev libbz2-dev libxerces-c-dev iproute2  iputils-ping python3-psutil python3-pip

yum install wget
wget https://github.com/greenplum-db/gpdb/releases/download/7.0.0/open-source-greenplum-db-7.0.0-el8-x86_64.rpmi
