```

for i in {1..2}; do
yc compute instance create \
  --name citus-coord-0$i \
  --hostname citus-coord-0$i \
  --create-boot-disk size=15G,type=network-hdd,image-folder-id=standard-images,image-family=ubuntu-2204-lts \
  --cores 2 \
  --memory 2G \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --zone ru-central1-a \
  --metadata-from-file ssh-keys=/home/aslepov/meta.txt
done


for i in {1..2}; do
yc compute instance create \
  --name citus-worker-0$i \
  --hostname citus-worker-0$i \
  --create-boot-disk size=15G,type=network-hdd,image-folder-id=standard-images,image-family=ubuntu-2204-lts \
  --cores 2 \
  --memory 2G \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --zone ru-central1-a \
  --metadata-from-file ssh-keys=/home/aslepov/meta.txt
done



for i in {'158.160.126.144','158.160.53.202','158.160.105.227','158.160.100.109'}; do
#add repo
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo curl https://install.citusdata.com/community/deb.sh | sudo bash'
#install
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo apt-get -y install postgresql-16-citus-12.1'
#add libraries
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo pg_conftool 16 main set shared_preload_libraries citus'
#set param listen addresse
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo pg_conftool 16 main set listen_addresses '*''
# add access
ssh -o StrictHostKeyChecking=no ubuntu@$i " echo '
host    all             all             127.0.0.1/32            trust
host    all             all             0.0.0.0/0              trust '  | sudo  tee -a /etc/postgresql/16/main/pg_hba.conf"
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo service postgresql restart'
#create extension (FOR each database)
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo -i -u postgres psql -c "CREATE EXTENSION citus;"'
done


for i in {'158.160.126.144','158.160.53.202','158.160.105.227','158.160.100.109'}; do
ssh -o StrictHostKeyChecking=no ubuntu@$i " echo 'host    all             all             0.0.0.0/0              trust '  | sudo  tee -a /etc/postgresql/16/main/pg_hba.conf"
echo 'host    replication             postgres             0.0.0.0/0              trust '  | sudo  tee -a /etc/postgresql/16/main/pg_hba.conf
sudo -i -u postgres psql -d bank -c "select pg_reload_conf();"
done


# создаём бд на кажой ноде, включая координатор
for i in {'158.160.126.144','158.160.53.202','158.160.105.227','158.160.100.109'}; do
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo -i -u postgres psql -c "CREATE database bank;"'
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo -i -u postgres psql -d bank -c "CREATE EXTENSION citus;"'
done


# заходим на ноды и проставляем имена нод
ssh ubuntu@158.160.126.144
sudo -i -u postgres psql -d bank
ALTER SYSTEM SET citus.local_hostname TO 'citus-coord-01';
select pg_reload_conf();

ssh ubuntu@158.160.53.202
sudo -i -u postgres psql -d bank
ALTER SYSTEM SET citus.local_hostname TO 'citus-coord-02';
select pg_reload_conf();


ssh ubuntu@158.160.105.227
sudo -i -u postgres psql -d bank
ALTER SYSTEM SET citus.local_hostname TO 'citus-worker-01';
select pg_reload_conf();


ssh ubuntu@158.160.100.109
sudo -i -u postgres psql -d bank
ALTER SYSTEM SET citus.local_hostname TO 'citus-worker-02';
select pg_reload_conf();



# заходим на ноды координатора и помечаем ноды как координатор
citus-coord-01>>
sudo -i -u postgres psql -d bank
SELECT citus_set_coordinator_host('citus-coord-01', 5432);

citus-coord-02>>
sudo -i -u postgres psql -d bank
SELECT citus_set_coordinator_host('citus-coord-02', 5432);



# добавляем воркеры в бд на координаторе
ssh citus-01>>
sudo -i -u postgres psql -d bank -c "SELECT * from citus_add_node('citus-worker-01', 5432);"
sudo -i -u postgres psql -d bank -c "SELECT * from citus_add_node('citus-worker-02', 5432);"
sudo -i -u postgres psql -d bank -c "alter system set citus.shard_replication_factor=2;"
sudo -i -u postgres psql -d bank -c "select pg_reload_conf();"


sudo -i -u postgres psql -d bank -c "SELECT * FROM citus_get_active_worker_nodes();"
 node_name | node_port
-----------+-----------
 citus-02  |      5432
 citus-03  |      5432
(2 rows)

-- создаём тестовую таблицу с данными на координаторе
bank# create table test1(i int);
bank# insert into test1 values (1),(2),(3);

-- шарируем таблицу
select create_distributed_table('test1','i');

-- чистим локальные данные
SELECT truncate_local_data_after_distributing_table($$public.test1$$);

bank=# select * from pg_dist_shard;
 logicalrelid | shardid | shardstorage | shardminvalue | shardmaxvalue
--------------+---------+--------------+---------------+---------------
 test1        |  102008 | t            | -2147483648   | -2013265921
 test1        |  102009 | t            | -2013265920   | -1879048193
 test1        |  102010 | t            | -1879048192   | -1744830465
 test1        |  102011 | t            | -1744830464   | -1610612737
 test1        |  102012 | t            | -1610612736   | -1476395009
...

select * from citus_shards;
table_name | shardid |  shard_name  | citus_table_type | colocation_id | nodename | nodeport | shard_size
------------+---------+--------------+------------------+---------------+----------+----------+------------
 test1      |  102008 | test1_102008 | distributed      |             1 | citus-02 |     5432 |       8192
 test1      |  102008 | test1_102008 | distributed      |             1 | citus-03 |     5432 |       8192
 test1      |  102009 | test1_102009 | distributed      |             1 | citus-02 |     5432 |      24576
 test1      |  102009 | test1_102009 | distributed      |             1 | citus-03 |     5432 |      24576
 test1      |  102010 | test1_102010 | distributed      |             1 | citus-03 |     5432 |       8192
 test1      |  102010 | test1_102010 | distributed      |             1 | citus-02 |     5432 |       8192
 test1      |  102011 | test1_102011 | distributed      |             1 | citus-02 |     5432 |       8192
 test1      |  102011 | test1_102011 | distributed      |             1 | citus-03 |     5432 |       8192
 test1      |  102012 | test1_102012 | distributed      |             1 | citus-02 |     5432 |       8192
 test1      |  102012 | test1_102012 | distributed      |             1 | citus-03 |     5432 |       8192
 test1      |  102013 | test1_102013 | distributed      |             1 | citus-02 |     5432 |       8192
 test1      |  102013 | test1_102013 | distributed      |             1 | citus-03 |     5432 |       8192
 test1      |  102014 | test1_102014 | distributed      |             1 | citus-02 |     5432 |       8192
 test1      |  102014 | test1_102014 | distributed      |             1 | citus-03 |     5432 |       8192
 test1      |  102015 | test1_102015 | distributed      |             1 | citus-03 |     5432 |       8192


-- перебалансировка шардов
select rebalance_table_shards('test1');


https://www.interdb.jp/blog/pgsql/citus_01/


--создаём стендбай координатор
-- координатор стендбай

yc compute instance create \
  --name citus-04 \
  --hostname citus-04 \
  --create-boot-disk size=15G,type=network-hdd,image-folder-id=standard-images,image-family=ubuntu-2204-lts \
  --cores 2 \
  --memory 2G \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --zone ru-central1-a \
  --metadata-from-file ssh-keys=/home/aslepov/meta.txt

-- разворачиваем и настраиваем координатор стендбай
ssh -o StrictHostKeyChecking=no ubuntu@158.160.123.124 'sudo curl https://install.citusdata.com/community/deb.sh | sudo bash'
ssh -o StrictHostKeyChecking=no ubuntu@158.160.123.124 'sudo apt-get -y install postgresql-16-citus-12.1'
ssh -o StrictHostKeyChecking=no ubuntu@158.160.123.124 'sudo pg_conftool 16 main set shared_preload_libraries citus'
ssh -o StrictHostKeyChecking=no ubuntu@158.160.123.124 'sudo pg_conftool 16 main set listen_addresses '*''
ssh -o StrictHostKeyChecking=no ubuntu@158.160.123.124 " echo '
host    all             all             127.0.0.1/32            trust
host    all             all             10.128.0.0/32              trust '  | sudo  tee -a /etc/postgresql/16/main/pg_hba.conf"
ssh -o StrictHostKeyChecking=no ubuntu@158.160.123.124 'sudo service postgresql restart'

citus04 >>
sudo su postgres

postgres@citus-04:/root$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 online postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
postgres@citus-04:/root$ pg_ctlcluster 16 main stop
Warning: stopping the cluster using pg_ctlcluster will mark the systemd unit as failed. Consider using systemctl:
  sudo systemctl stop postgresql@16-main
postgres@citus-04:/root$ rm -r /var/lib/postgresql/16/main


-- снимаем бекап с основного координатора
pg_basebackup -h citus-01 -D /var/lib/postgresql/16/main -X stream

touch /var/lib/postgresql/16/main/standby.signal
vim /etc/postgresql/16/main/conf.d/recovery.conf
primary_conninfo = 'host=citus-01 user=postgres port=5432 sslmode=disable sslcompression=1'

postgres@citus-04:/root$ pg_lsclusters
Ver Cluster Port Status          Owner    Data directory              Log file
16  main    5432 online,recovery postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log


-- переключаем мастера координатора

citus-01>>
pg_ctlcluster 16 main stop

citus-04>>
pg_ctlcluster 16 main promote


ERROR:  execution cannot recover from multiple connection failures. Last node failed citus-02:5432
```
