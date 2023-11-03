```

-- создаём ноды для 3 мастеров и 3 tservers на них
for i in {1..3}; do
yc compute instance create \
  --name ybdb-0$i \
  --hostname ybdb-0$i \
  --create-boot-disk size=40G,type=network-ssd,image-folder-id=standard-images,image-family=ubuntu-2204-lts \
  --cores 4 \
  --memory 8G \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --zone ru-central1-a \
  --metadata-from-file ssh-keys=/home/aslepov/meta.txt
done


https://docs.yugabyte.com/preview/deploy/manual-deployment/system-config/

-- ставим лимиты

for i in {'158.160.114.70','158.160.99.122','51.250.11.59'}; do
ssh -o StrictHostKeyChecking=no ubuntu@$i ' echo "
*                -       core            unlimited
*                -       data            unlimited
*                -       fsize           unlimited
*                -       sigpending      119934
*                -       memlock         64
*                -       rss             unlimited
*                -       nofile          1048576
*                -       msgqueue        819200
*                -       stack           8192
*                -       cpu             unlimited
*                -       nproc           12000
*                -       locks           unlimited
" | sudo tee /etc/security/limits.d/ybdb_limits.conf  '
done

-- устанавливаем доп пакеты
for i in {'158.160.114.70','158.160.99.122','51.250.11.59'}; do
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo apt install -y python-is-python3 mc'
done

-- скачиваем дистрибутив, устанавливаем
-- запускаем сборку
for i in {'158.160.114.70','158.160.99.122','51.250.11.59'}; do
ssh -o StrictHostKeyChecking=no ubuntu@$i ' sudo wget wget https://downloads.yugabyte.com/releases/2.18.4.0/yugabyte-2.18.4.0-b52-linux-x86_64.tar.gz -O /opt/ybdb.tar.gz  '
ssh -o StrictHostKeyChecking=no ubuntu@$i 'cd /opt && sudo tar -xzvf /opt/ybdb.tar.gz '
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo rm /opt/ybdb.tar.gz'
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo /opt/yugabyte-2.18.4.0/bin/post_install.sh'
done




-- создаём пользователя и каналог с данными, даём права
for i in {'158.160.114.70','158.160.99.122','51.250.11.59'}; do
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo groupadd yugabyte; sudo useradd yugabyte -r -m -g yugabyte '
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo chsh -s /bin/bash yugabyte '
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo mkdir -p /data/disk1'
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo chown -R yugabyte:yugabyte /data ; sudo chown -R yugabyte:yugabyte /opt/yugabyte-*'
done

-- копируем файлы сервиса для мастеров
for i in {'158.160.114.70','158.160.99.122','51.250.11.59'}; do
ssh -o StrictHostKeyChecking=no ubuntu@$i 'echo "
[Unit]
Wants=network-online.target
After=network-online.target
Description=yugabyte-master

[Service]
RestartForceExitStatus=SIGPIPE
#EnvironmentFile=/etc/sysconfig/mycompany_env
StartLimitInterval=0
ExecStart=/bin/bash -c \"/opt/yugabyte-2.18.4.0/bin/yb-master \
--fs_data_dirs /data/disk1 \
--rpc_bind_addresses $(hostname -I| sed "s/[ \t]*$//g"):7100 \
--master_addresses 10.128.0.14:7100,10.128.0.16:7100,10.128.0.18:7100 \
--placement_cloud=gce \
--placement_region=gce-us-east1 \
--placement_zone=us-east1-c \"
LimitCORE=infinity
TimeoutStartSec=30
WorkingDirectory=/data
LimitNOFILE=1048576
LimitNPROC=12000
RestartSec=5
PermissionsStartOnly=True
User=yugabyte
TimeoutStopSec=300

[Install]
WantedBy=multi-user.target " | sudo tee /etc/systemd/system/yugabyte-master.service'
done

-- запусаем мастер сервисы
for i in {'158.160.114.70','158.160.99.122','51.250.11.59'}; do
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo systemctl daemon-reload '
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo systemctl start yugabyte-master.service  '
sleep 5
done


-- копируем конфиг файл сервиса для tserver

  for i in {'158.160.114.70','158.160.99.122','51.250.11.59'}; do
  ssh -o StrictHostKeyChecking=no ubuntu@$i 'echo "
  [Unit]
  Wants=network-online.target
  After=network-online.target
  Description=yugabyte-tserver

  [Service]
  RestartForceExitStatus=SIGPIPE
  #EnvironmentFile=/etc/sysconfig/mycompany_env
  StartLimitInterval=0
  ExecStart=/bin/bash -c \"/opt/yugabyte-2.18.4.0/bin/yb-tserver \
  --tserver_master_addrs 10.128.0.14:7100,10.128.0.16:7100,10.128.0.18:7100 \
  --fs_data_dirs /data/disk1 \
  --rpc_bind_addresses $(hostname -I| sed "s/[ \t]*$//g"):9200 \
  --webserver_interface=$(hostname -I| sed "s/[ \t]*$//g") \
  --webserver_port=9000 \
  --enable_ysql \
  --pgsql_proxy_bind_address $(hostname -I| sed "s/[ \t]*$//g"):5433 \
  --cql_proxy_bind_address $(hostname -I| sed "s/[ \t]*$//g"):9042 \
  --placement_cloud=gce \
  --placement_region=gce-us-east1 \
  --placement_zone=us-east1-c \"
  LimitCORE=infinity
  TimeoutStartSec=30
  WorkingDirectory=/data
  LimitNOFILE=1048576
  LimitNPROC=12000
  RestartSec=5
  PermissionsStartOnly=True
  User=yugabyte
  TimeoutStopSec=300

  [Install]
  WantedBy=multi-user.target " | sudo tee /etc/systemd/system/yugabyte-tserver.service'
  done

  -- запусаем tserver сервисы
  for i in {'158.160.114.70','158.160.99.122','51.250.11.59'}; do
  ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo systemctl daemon-reload '
  ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo systemctl start yugabyte-tserver.service'
  sleep 5
  done


  ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo systemctl restart yugabyte-tserver.service'
    sleep 10


/opt/yugabyte-2.18.4.0/bin/ysqlsh -h 10.128.0.14



postgres=# create database taxi;
CREATE DATABASE
postgres=# \c taxi;

CREATE TABLE public.chicago_taxi (
    taxi_id bigint,
    trip_start_timestamp timestamp without time zone,
    trip_end_timestamp timestamp without time zone,
    trip_seconds bigint,
    trip_miles numeric,
    pickup_census_tract bigint,
    dropoff_census_tract bigint,
    pickup_community_area bigint,
    dropoff_community_area bigint,
    fare numeric,
    tips numeric,
    tolls numeric,
    extras numeric,
    trip_total numeric,
    payment_type text,
    company text,
    pickup_latitude numeric,
    pickup_longitude numeric,
    dropoff_latitude numeric,
    dropoff_longitude numeric
) ;


COPY chicago_taxi FROM '/data/chicago_taxi_migrate.csv' DELIMITER ',' CSV HEADER;

vacuum analyze chicago_taxi;
create index idx_taxi_id on chicago_taxi(taxi_id);
create index idx_dates on chicago_taxi(trip_start_timestamp,trip_end_timestamp);


-- выборка рандомной записи по индексу
select taxi_id from chicago_taxi order by random() limit 1;
Time: 76760.890 ms (01:16.761)

--выборка данных за неделю
postgres=# select taxi_id,trip_start_timestamp,trip_end_timestamp from chicago_taxi where trip_start_timestamp between date'2016-02-01' and date'2016-02-07';
Time: 20667.269 ms (00:20.667)


Для сравнения, в postgres были следующие результаты
-- выборка рандомной записи по индексу
select taxi_id from chicago_taxi order by random() limit 1;
Time: 5949.964 ms (00:05.950)

--выборка данных за неделю
postgres=# select taxi_id,trip_start_timestamp,trip_end_timestamp from chicago_taxi where trip_start_timestamp between date'2016-02-01' and date'2016-02-07';
Time: 69201.562 ms (01:09.202)
```
