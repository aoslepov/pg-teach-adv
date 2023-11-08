Создаём инстанс для подключения к yc

```
yc compute instance create \
  --name pg-teach-01 \
  --hostname pg-teach-01 \
  --create-boot-disk size=10G,type=network-ssd,image-folder-id=standard-images,image-family=ubuntu-2204-lts \
  --cores 2 \
  --memory 4G \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --zone ru-central1-a \
  --metadata-from-file ssh-keys=/home/aslepov/meta.txt
```


Скачиваем yandex cloud и инициализируем его предварительно залогиневшись в облаке яндекса

```
cd /usr/local/sbin/ && curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash


root@pg-teach-01:~# yc init
Welcome! This command will take you through the configuration process.
Please go to https://oauth.yandex.ru/authorize?response_type=token&client_id=XXX in order to obtain OAuth token.

Please enter OAuth token: XXX
You have one cloud available: 'cloud-ao-slepov' (id = b1gi89kth4ma2ek6b8i3). It is going to be used by default.
Please choose folder to use:
 [1] default (id = XXX)
 [2] Create a new folder
Please enter your numeric choice: 1
Your current folder has been set to 'default' (id = b1g7jn3kmfd43b53ui4s).
Do you want to configure a default Compute zone? [Y/n] n

````


Проверяем наличие сервисного аккаунта. Если его нет, то необходимо создать в яндекс клауд
```

root@pg-teach-01:~# yc iam service-account list
+----------------------+--------------+
|          ID          |     NAME     |
+----------------------+--------------+
| ajelke70oe4djhng98qn | yc-terraform |
+----------------------+--------------+
```

sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install postgresql-client-15
