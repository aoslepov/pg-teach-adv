#! /bin/bash

# Check we are a root
if [ "$EUID" -ne 0 ]
    then echo "Please run this script as root"
    exit
fi

REPO="/etc/apt/sources.list.d/greenplum-ubuntu-db-bionic.list"
PIN="/etc/apt/preferences.d/99-greenplum"

echo "Add required repositories"
touch \$REPO
cat > \$REPO <<REPOS
deb http://ppa.launchpad.net/greenplum/db/ubuntu bionic main
deb http://ru.archive.ubuntu.com/ubuntu bionic main
REPOS

echo "Configure repositories"
touch \$PIN
cat > \$PIN <<PIN_REPO
Package: *
Pin: release v=18.04
Pin-Priority: 1
PIN_REPO

echo "Repositories described in \$REPO"
echo "Repositories configuration in \$PIN"
echo "Installing greenplum"

apt update && apt install greenplum-db-6 -y

