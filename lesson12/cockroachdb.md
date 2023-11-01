```
yc compute instance create \
  --name pg-teach-01 \
  --hostname pg-teach-01 \
  --create-boot-disk size=50G,type=network-hdd,image-folder-id=standard-images,image-family=ubuntu-2204-lts \
  --cores 2 \
  --memory 4G \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --zone ru-central1-a \
  --metadata-from-file ssh-keys=/home/aslepov/meta.txt
---
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install postgresql-15
---
transaction_isolation = 'read uncommitted'
default_transaction_isolation = 'read uncommitted'
wal_level = minimal
max_wal_senders = 0
max_wal_size = '10 GB'
min_wal_size = '512 MB'
fsync = off
full_page_writes=off
checkpoint_timeout = '15 min'
checkpoint_completion_target = 0.9
wal_compression = off
synchronous_commit = off
max_worker_processes = 4
max_parallel_workers_per_gather = 4
max_parallel_maintenance_workers = 4
max_parallel_workers = 4
parallel_leader_participation = on
autovacuum = off
shared_buffers = '2730 MB'
work_mem = '38 MB'
maintenance_work_mem = '409 MB'
effective_cache_size = '6553 MB'
effective_io_concurrency = 200
random_page_cost = 1.2
----


create  table chicago_taxi (
taxi_id bigint,
trip_start_timestamp TIMESTAMP,
trip_end_timestamp TIMESTAMP,
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
);

-----

for i in $(ls -1 /tmp/load/chicago*.csv); do
        echo $i
        psql -d postgres -c "
BEGIN;
COPY chicago_taxi(taxi_id,trip_start_timestamp,trip_end_timestamp,trip_seconds,trip_miles,pickup_census_tract,dropoff_census_tract,pickup_community_area,dropoff_community_area,fare,tips,tolls,extras,trip_total,payment_type,company,pickup_latitude,pickup_longitude,dropoff_latitude,dropoff_longitude)
FROM '$i'
DELIMITER ','
CSV HEADER;
commit; " &
done

------

select * from pg_stat_progress_copy;


----------

 yc compute instance create \
   --name cdb-01 \
   --hostname cdb-01 \
   --create-boot-disk size=30G,type=network-ssd,image-folder-id=standard-images,image-family=ubuntu-2204-lts \
   --cores 4 \
   --memory 8G \
   --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
   --zone ru-central1-a \
   --metadata-from-file ssh-keys=/home/aslepov/meta.txt


 yc compute instance create \
    --name cdb-02 \
    --hostname cdb-02 \
    --create-boot-disk size=30G,type=network-ssd,image-folder-id=standard-images,image-family=ubuntu-2204-lts \
    --cores 2 \
    --memory 4G \
    --network-interface subnet-name=default-ru-central1-b,nat-ip-version=ipv4 \
    --zone ru-central1-b \
    --metadata-from-file ssh-keys=/home/aslepov/meta.txt

yc compute instance create \
   --name cdb-03 \
   --hostname cdb-03 \
   --create-boot-disk size=30G,type=network-hdd,image-folder-id=standard-images,image-family=ubuntu-2204-lts \
   --cores 2 \
   --memory 4G \
   --network-interface subnet-name=default-ru-central1-c,nat-ip-version=ipv4 \
   --zone ru-central1-c \
   --metadata-from-file ssh-keys=/home/aslepov/meta.txt


-- Устанавливаем cockroachdb

for i in {'62.84.117.81','84.252.141.37','51.250.47.60'}; do
ssh ubuntu@$i 'wget -qO- https://binaries.cockroachdb.com/cockroach-v21.1.6.linux-amd64.tgz -O /tmp/cockroach.tgz && sudo tar -xzvf /tmp/cockroach.tgz -C /opt && sudo mv /opt/cockroach-v21.1.6.linux-amd64 /opt/cockroach '
ssh ubuntu@$i 'sudo mkdir /opt/cockroach/{certs,my-safe-directory}'
done


-- Генерируем сертификаты на первой ноде

cdb-01 >>
cd /opt/cockroach/
./cockroach cert create-ca --certs-dir=certs --ca-key=my-safe-directory/ca.key
./cockroach cert create-node localhost cdb-01 cdb-02 cdb-03 --certs-dir=certs --ca-key=my-safe-directory/ca.key --overwrite
./cockroach cert create-client root --certs-dir=certs --ca-key=my-safe-directory/ca.key

root@cdb-01:/opt/cockroach# ./cockroach cert list --certs-dir=certs
Certificate directory: certs
  Usage  | Certificate File |    Key File     |  Expires   |                   Notes                   | Error
---------+------------------+-----------------+------------+-------------------------------------------+--------
  CA     | ca.crt           |                 | 2033/11/02 | num certs: 1                              |
  Node   | node.crt         | node.key        | 2028/10/29 | addresses: localhost,cdb-01,cdb-02,cdb-03 |
  Client | client.root.crt  | client.root.key | 2028/10/29 | user: root                                |
(3 rows)
--- заводим сервис
vim /etc/systemd/system/cockroach.service

[Unit]
Description=CockroachDB Service

[Install]
WantedBy=multi-user.target

[Service]
ExecStart=/opt/cockroach/cockroach start --certs-dir=/opt/cockroach/certs --advertise-addr=cdb-01 --join=cdb-01,cdb-02,cdb-03 --cache=.25 --max-sql-memory=.25
ExecStop=/opt/cockroach/cockroach node drain --certs-dir=/opt/cockroach/certs
SyslogIdentifier=cockroachdb
Restart=always
LimitNOFILE=35000

---


переносим /opt/cockroach/certs на cdb-02 и cdb-03


--Запускаем ноды кластера

ssh ubuntu@62.84.117.81 './opt/cockroach/cockroach start --certs-dir=/opt/cockroach/cockroach/certs --advertise-addr=cdb-01 --join=cdb-01,cdb-02,cdb-03 --cache=.25 --max-sql-memory=.25 --background'
ssh ubuntu@84.252.141.37 './opt/cockroach/cockroach start --certs-dir=/opt/cockroach/cockroach/certs --advertise-addr=cdb-01 --join=cdb-01,cdb-02,cdb-03 --cache=.25 --max-sql-memory=.25 --background'
ssh ubuntu@51.250.47.60 './opt/cockroach/cockroach start --certs-dir=/opt/cockroach/cockroach/certs --advertise-addr=cdb-01 --join=cdb-01,cdb-02,cdb-03 --cache=.25 --max-sql-memory=.25 --background'



---Инициализируем кластер

cdb-01>>
cd /opt/cockroach
root@cdb-01:/opt/cockroach# ./cockroach init --certs-dir=certs --host=cdb-01
Cluster successfully initialized
root@cdb-01:/opt/cockroach# ./cockroach node status --certs-dir=certs
  id |   address    | sql_address  |  build  |         started_at         |         updated_at         | locality | is_available | is_live
-----+--------------+--------------+---------+----------------------------+----------------------------+----------+--------------+----------
   1 | cdb-01:26257 | cdb-01:26257 | v21.1.6 | 2023-10-26 20:21:44.682438 | 2023-10-26 20:22:16.213905 |          | true         | true
   2 | cdb-03:26257 | cdb-03:26257 | v21.1.6 | 2023-10-26 20:21:45.390704 | 2023-10-26 20:22:16.907459 |          | true         | true
   3 | cdb-02:26257 | cdb-02:26257 | v21.1.6 | 2023-10-26 20:21:45.539724 | 2023-10-26 20:22:17.070153 |          | true         | true
(3 rows)
--------
./cockroach sql --certs-dir=certs

CREATE TABLE chicago_taxi (
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
);



pg-teach-01>>
pg_dump postgres --table=chicago_taxi > chicago_taxi.sql




./cockroach import table chicago_taxi pgdump /home/ubuntu/chicago_taxi.sql --certs-dir=certs

```

