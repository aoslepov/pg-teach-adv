### Citus+Patroni 
[ссылка](https://habr.com/ru/companies/otus/articles/755032/)  


#### ETCD
Создаём ноды etcd
```
yc compute instance create \
  --name etcd-01 \
  --hostname etcd-01 \
  --create-boot-disk size=10G,type=network-hdd,image-folder-id=standard-images,image-family=ubuntu-2204-lts \
  --cores 2 \
  --memory 2G \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --zone ru-central1-a \
  --metadata-from-file ssh-keys=/home/aslepov/meta.txt
```

Создаём координаторы
```
for i in {1..2}; do
yc compute instance create \
  --name citus-coord-0$i \
  --hostname citus-coord-0$i \
  --create-boot-disk size=10G,type=network-hdd,image-folder-id=standard-images,image-family=ubuntu-2204-lts \
  --cores 2 \
  --memory 2G \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --zone ru-central1-a \
  --metadata-from-file ssh-keys=/home/aslepov/meta.txt
done
```



Ставим etcd
```
-- ставим etcd
ssh ubuntu@158.160.107.34 'sudo apt update && sudo apt upgrade -y && sudo apt install -y etcd && sudo systemctl stop etcd && sudo systemctl stop etcd'
ssh ubuntu@158.160.107.34 'sudo tee /etc/default/etcd << END
ETCD_NAME="$(hostname)"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://$(hostname):2379"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://$(hostname):2380"
ETCD_INITIAL_CLUSTER_TOKEN="PatroniCluster"
ETCD_INITIAL_CLUSTER="etcd-01=http://etcd-01:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_DATA_DIR="/var/lib/etcd"
END'
ssh ubuntu@158.160.107.34 'sudo systemctl enable etcd; sudo systemctl start etcd'
ssh ubuntu@158.160.107.34 'sudo etcdctl cluster-health'
```

### CITUS COORDINATORS

Настраиваем координаторы цитус
```
for i in {'158.160.35.235','158.160.45.198'}; do
ssh ubuntu@$i 'echo $(hostname)'
##ставим постгрес-цитус
ssh ubuntu@$i 'sudo curl https://install.citusdata.com/community/deb.sh | sudo bash'
ssh ubuntu@$i 'sudo apt-get -y install postgresql-16-citus-12.1'
ssh ubuntu@$i 'sudo -u postgres pg_ctlcluster 16 main stop && sudo -u postgres pg_dropcluster 16 main '
#ставим пакеты
ssh ubuntu@$i 'sudo apt install -y python3-pip libpq-dev python3-dev python3-psycopg2'
ssh ubuntu@$i 'sudo pip3 install  psycopg2-binary patroni[etcd]'

#копируем конфиг и конфигурим
ssh ubuntu@$i 'sudo wget https://raw.githubusercontent.com/aoslepov/pg-teach-adv/main/lesson15/citus-patroni/patroni.service -O "/etc/systemd/system/patroni.service"'
ssh ubuntu@$i 'sudo wget https://raw.githubusercontent.com/aoslepov/pg-teach-adv/main/lesson15/citus-patroni/patroni.yml -O "/etc/patroni.yml"'
ssh ubuntu@$i 'curr_host=$(hostname -I| sed "s/[ \t]*$//g") && sudo sed "s/SED_CURRENT_ADDRESS/$curr_host/g" -i /etc/patroni.yml'
ssh ubuntu@$i 'sudo sed "s/SED_CURRENT_HOSTNAME/$(hostname)/g" -i /etc/patroni.yml'
ssh ubuntu@$i 'sudo sed "s/SED_ETCD_HOSTS/etcd-01:2379/g" -i /etc/patroni.yml'
ssh ubuntu@$i 'sudo sed "s/SED_PG_VERSION/16/g" -i /etc/patroni.yml'
ssh ubuntu@$i 'sudo systemctl daemon-reload && sudo systemctl enable patroni'
done
```

Настройка параметров координаторов
```
for i in {'158.160.35.235','158.160.45.198'}; do
ssh ubuntu@$i 'sudo wget https://raw.githubusercontent.com/aoslepov/pg-teach-adv/main/lesson15/citus-patroni/patroni.yml -O "/etc/patroni.yml"'
ssh ubuntu@$i 'curr_host=$(hostname -I| sed "s/[ \t]*$//g") && sudo sed "s/SED_CURRENT_ADDRESS/$curr_host/g" -i /etc/patroni.yml'
ssh ubuntu@$i 'sudo sed "s/SED_CURRENT_HOSTNAME/$(hostname)/g" -i /etc/patroni.yml'
ssh ubuntu@$i 'sudo sed "s/SED_ETCD_HOSTS/etcd-01:2379/g" -i /etc/patroni.yml'
ssh ubuntu@$i 'sudo sed "s/SED_PG_VERSION/16/g" -i /etc/patroni.yml'
#для координатора группа 0
ssh ubuntu@$i 'sudo sed "s/SED_GROUI_ID_NUM/0/g" -i /etc/patroni.yml'
done
```

запускаем по очереди координаторы  

---

#### CITUS WORKERS


Разворачиваем воркеры(лидеры и реплики)
```
for i in {1..3}; do
yc compute instance create \
  --name citus-work-0$i \
  --hostname citus-work-0$i \
  --create-boot-disk size=10G,type=network-hdd,image-folder-id=standard-images,image-family=ubuntu-2204-lts \
  --cores 2 \
  --memory 2G \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --zone ru-central1-a \
  --metadata-from-file ssh-keys=/home/aslepov/meta.txt
done
```

Устанавливаем и настраиваем цитус
```
for i in {'158.160.41.179','158.160.44.207','62.84.126.23'}; do
ssh ubuntu@$i 'echo $(hostname)'
##ставим постгрес-цитус
ssh ubuntu@$i 'sudo curl https://install.citusdata.com/community/deb.sh | sudo bash'
ssh ubuntu@$i 'sudo apt-get -y install postgresql-16-citus-12.1'
ssh ubuntu@$i 'sudo -u postgres pg_ctlcluster 16 main stop && sudo -u postgres pg_dropcluster 16 main '
#ставим пакеты
ssh ubuntu@$i 'sudo apt install -y python3-pip libpq-dev python3-dev python3-psycopg2'
ssh ubuntu@$i 'sudo pip3 install  psycopg2-binary patroni[etcd]'

#копируем конфиг и конфигурим
ssh ubuntu@$i 'sudo wget https://raw.githubusercontent.com/aoslepov/pg-teach-adv/main/lesson15/citus-patroni/patroni.service -O "/etc/systemd/system/patroni.service"'
ssh ubuntu@$i 'sudo wget https://raw.githubusercontent.com/aoslepov/pg-teach-adv/main/lesson15/citus-patroni/patroni.yml -O "/etc/patroni.yml"'
ssh ubuntu@$i 'curr_host=$(hostname -I| sed "s/[ \t]*$//g") && sudo sed "s/SED_CURRENT_ADDRESS/$curr_host/g" -i /etc/patroni.yml'
ssh ubuntu@$i 'sudo sed "s/SED_CURRENT_HOSTNAME/$(hostname)/g" -i /etc/patroni.yml'
ssh ubuntu@$i 'sudo sed "s/SED_ETCD_HOSTS/etcd-01:2379/g" -i /etc/patroni.yml'
ssh ubuntu@$i 'sudo sed "s/SED_PG_VERSION/16/g" -i /etc/patroni.yml'
ssh ubuntu@$i 'sudo systemctl daemon-reload && sudo systemctl enable patroni'
done
```

Настраиваем группы для воркеров-лидеров
```
# для лидеров-воркеров разные группы
ssh ubuntu@158.160.41.179 'sudo sed "s/SED_GROUI_ID_NUM/1/g" -i /etc/patroni.yml'
ssh ubuntu@158.160.44.207 'sudo sed "s/SED_GROUI_ID_NUM/2/g" -i /etc/patroni.yml'
```

запускаем воркеры-лидеры  

---


Загружаем тестовые данные
```
root@citus-coord-01:/tmp# patronictl -c /etc/patroni.yml list
+ Citus cluster: pgteachcluster -------+--------------+-----------+----+-----------+
| Group | Member         | Host        | Role         | State     | TL | Lag in MB |
+-------+----------------+-------------+--------------+-----------+----+-----------+
|     0 | citus-coord-01 | 10.128.0.8  | Leader       | running   |  1 |           |
|     0 | citus-coord-02 | 10.128.0.18 | Sync Standby | streaming |  1 |         0 |
|     1 | citus-work-01  | 10.128.0.24 | Leader       | running   |  1 |           |
|     2 | citus-work-02  | 10.128.0.36 | Leader       | running   |  2 |           |
+-------+----------------+-------------+--------------+-----------+----+-----------+


cd /tmp && wget https://storage.googleapis.com/postgres13/1000000SalesRecords.csv


root@citus-coord-01:/etc# psql -U postgres -h 10.128.0.8 -d citus


CREATE TABLE test (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    Region VARCHAR(50),
    Country VARCHAR(50),
    ItemType VARCHAR(50),
    SalesChannel VARCHAR(20),
    OrderPriority VARCHAR(10),
    OrderDate VARCHAR(10),
    OrderID int,
    ShipDate VARCHAR(10),
    UnitsSold int,
    UnitPrice decimal(12,2),
    UnitCost decimal(12,2),
    TotalRevenue decimal(12,2),
    TotalCost decimal(12,2),
    TotalProfit decimal(12,2)
);


-- шардируем
SELECT create_distributed_table('test', 'id');

--загражаем
copy test (Region,Country,ItemType,SalesChannel,OrderPriority,OrderDate,OrderID,ShipDate,UnitsSold,UnitPrice,UnitCost,TotalRevenue,TotalCost,TotalProfit) FROM '/tmp/1000000SalesRecords.csv' DELIMITER ',' CSV HEADER;

-- чистим данные с координатора
SELECT truncate_local_data_after_distributing_table($$public.test$$);

-- смотрим скорость запросов
citus=# select shipdate, count(*) from test group by shipdate order by count(*) desc limit 10;
  shipdate  | count
------------+-------
 8/14/2015  |   420
 10/7/2010  |   412
 10/20/2016 |   411
 5/24/2016  |   410
 3/27/2011  |   410
 12/23/2015 |   409
 4/5/2010   |   409
 3/4/2017   |   407
 12/1/2011  |   407
 8/29/2010  |   407
```


Добавляем реплику в группу 1  
```

ssh ubuntu@62.84.126.23 'sudo sed "s/SED_GROUI_ID_NUM/1/g" -i /etc/patroni.yml'
--запускаем реплику


root@citus-coord-01:~# patronictl -c /etc/patroni.yml list
+ Citus cluster: pgteachcluster -------+--------------+-----------+----+-----------+
| Group | Member         | Host        | Role         | State     | TL | Lag in MB |
+-------+----------------+-------------+--------------+-----------+----+-----------+
|     0 | citus-coord-01 | 10.128.0.8  | Leader       | running   |  1 |           |
|     0 | citus-coord-02 | 10.128.0.18 | Sync Standby | streaming |  1 |         0 |
|     1 | citus-work-01  | 10.128.0.24 | Leader       | running   |  1 |           |
|     1 | citus-work-03  | 10.128.0.11 | Sync Standby | streaming |  1 |         0 |
|     2 | citus-work-02  | 10.128.0.36 | Leader       | running   |  2 |           |
+-------+----------------+-------------+--------------+-----------+----+-----------+

-- ребаланс
SELECT rebalance_table_shards('test');


citus=# select * from citus_shards;
 table_name | shardid | shard_name  | citus_table_type | colocation_id |  nodename   | nodeport | shard_size
------------+---------+-------------+------------------+---------------+-------------+----------+------------
 test       |  102008 | test_102008 | distributed      |             1 | 10.128.0.24 |     5432 |    6471680
 test       |  102009 | test_102009 | distributed      |             1 | 10.128.0.24 |     5432 |    6545408
 test       |  102010 | test_102010 | distributed      |             1 | 10.128.0.36 |     5432 |    6660096
 test       |  102011 | test_102011 | distributed      |             1 | 10.128.0.24 |     5432 |    6520832
 test       |  102012 | test_102012 | distributed      |             1 | 10.128.0.24 |     5432 |    6610944
 test       |  102013 | test_102013 | distributed      |             1 | 10.128.0.36 |     5432 |    6676480
 test       |  102014 | test_102014 | distributed      |             1 | 10.128.0.36 |     5432 |    6660096
 test       |  102015 | test_102015 | distributed      |             1 | 10.128.0.36 |     5432 |    6701056
 test       |  102016 | test_102016 | distributed      |             1 | 10.128.0.24 |     5432 |    6561792
 test       |  102017 | test_102017 | distributed      |             1 | 10.128.0.24 |     5432 |    6561792
 test       |  102018 | test_102018 | distributed      |             1 | 10.128.0.36 |     5432 |    6660096
 test       |  102019 | test_102019 | distributed      |             1 | 10.128.0.36 |     5432 |    6668288
 test       |  102020 | test_102020 | distributed      |             1 | 10.128.0.36 |     5432 |    6660096
 test       |  102021 | test_102021 | distributed      |             1 | 10.128.0.36 |     5432 |    6668288
 test       |  102022 | test_102022 | distributed      |             1 | 10.128.0.24 |     5432 |    6496256
 test       |  102023 | test_102023 | distributed      |             1 | 10.128.0.24 |     5432 |    6537216
 test       |  102024 | test_102024 | distributed      |             1 | 10.128.0.24 |     5432 |    6512640
 test       |  102025 | test_102025 | distributed      |             1 | 10.128.0.24 |     5432 |    6512640
 test       |  102026 | test_102026 | distributed      |             1 | 10.128.0.36 |     5432 |    6643712
 test       |  102027 | test_102027 | distributed      |             1 | 10.128.0.24 |     5432 |    6602752
 test       |  102028 | test_102028 | distributed      |             1 | 10.128.0.36 |     5432 |    6643712
 test       |  102029 | test_102029 | distributed      |             1 | 10.128.0.24 |     5432 |    6619136
 test       |  102030 | test_102030 | distributed      |             1 | 10.128.0.24 |     5432 |    6602752
 test       |  102031 | test_102031 | distributed      |             1 | 10.128.0.24 |     5432 |    6643712
 test       |  102032 | test_102032 | distributed      |             1 | 10.128.0.36 |     5432 |    6660096
 test       |  102033 | test_102033 | distributed      |             1 | 10.128.0.24 |     5432 |    6496256
 test       |  102034 | test_102034 | distributed      |             1 | 10.128.0.24 |     5432 |    6529024
 test       |  102035 | test_102035 | distributed      |             1 | 10.128.0.36 |     5432 |    6676480
 test       |  102036 | test_102036 | distributed      |             1 | 10.128.0.36 |     5432 |    6660096
 test       |  102037 | test_102037 | distributed      |             1 | 10.128.0.36 |     5432 |    6660096
 test       |  102038 | test_102038 | distributed      |             1 | 10.128.0.24 |     5432 |    6569984
 test       |  102039 | test_102039 | distributed      |             1 | 10.128.0.36 |     5432 |    6651904

- уровень репликации
alter system set citus.shard_replication_factor=2;
```

### TEST FAILOVER/SWITCHOVWER

  
```
-- останавливаем координатор 1
root@citus-coord-01:~# systemctl stop patroni

root@citus-coord-02:~# patronictl -c /etc/patroni.yml list
+ Citus cluster: pgteachcluster -------+--------------+-----------+----+-----------+
| Group | Member         | Host        | Role         | State     | TL | Lag in MB |
+-------+----------------+-------------+--------------+-----------+----+-----------+
|     0 | citus-coord-02 | 10.128.0.18 | Leader       | running   |  2 |           |
|     1 | citus-work-01  | 10.128.0.24 | Leader       | running   |  1 |           |
|     1 | citus-work-03  | 10.128.0.11 | Sync Standby | streaming |  1 |         0 |
|     2 | citus-work-02  | 10.128.0.36 | Leader       | running   |  2 |           |
+-------+----------------+-------------+--------------+-----------+----+-----------+

-- смотрим что можем подключиться и работать через координатор 2
root@citus-coord-02:~# psql -U postgres -d citus -h 10.128.0.18

citus=# select shipdate, count(*) from test group by shipdate order by count(*) desc limit 10;
  shipdate  | count
------------+-------
 8/14/2015  |   420
 10/7/2010  |   412
 10/20/2016 |   411
 5/24/2016  |   410
 3/27/2011  |   410
 12/23/2015 |   409
 4/5/2010   |   409
 3/4/2017   |   407
 12/1/2011  |   407
 8/29/2010  |   407

citus=# alter table test add column tmp integer;


-- возвращаем координатор 1
root@citus-coord-01:~# systemctl start patroni

root@citus-coord-01:~# patronictl -c /etc/patroni.yml list
+ Citus cluster: pgteachcluster -------+--------------+-----------+----+-----------+
| Group | Member         | Host        | Role         | State     | TL | Lag in MB |
+-------+----------------+-------------+--------------+-----------+----+-----------+
|     0 | citus-coord-01 | 10.128.0.8  | Sync Standby | streaming |  2 |         0 |
|     0 | citus-coord-02 | 10.128.0.18 | Leader       | running   |  2 |           |
|     1 | citus-work-01  | 10.128.0.24 | Leader       | running   |  1 |           |
|     1 | citus-work-03  | 10.128.0.11 | Sync Standby | streaming |  1 |         0 |
|     2 | citus-work-02  | 10.128.0.36 | Leader       | running   |  2 |           |
+-------+----------------+-------------+--------------+-----------+----+-----------+

-- переключаем лидера координатора обратно на citus-coord-01
root@citus-coord-02:~# patronictl -c /etc/patroni.yml switchover
Current cluster topology
+ Citus cluster: pgteachcluster -------+--------------+-----------+----+-----------+
| Group | Member         | Host        | Role         | State     | TL | Lag in MB |
+-------+----------------+-------------+--------------+-----------+----+-----------+
|     0 | citus-coord-01 | 10.128.0.8  | Sync Standby | streaming |  2 |         0 |
|     0 | citus-coord-02 | 10.128.0.18 | Leader       | running   |  2 |           |
|     1 | citus-work-01  | 10.128.0.24 | Leader       | running   |  1 |           |
|     1 | citus-work-03  | 10.128.0.11 | Sync Standby | streaming |  1 |         0 |
|     2 | citus-work-02  | 10.128.0.36 | Leader       | running   |  2 |           |
+-------+----------------+-------------+--------------+-----------+----+-----------+
Citus group: 0
Primary [citus-coord-02]: citus-coord-02
Candidate ['citus-coord-01'] []: citus-coord-01
When should the switchover take place (e.g. 2023-11-12T20:48 )  [now]:
Are you sure you want to switchover cluster pgteachcluster, demoting current leader citus-coord-02? [y/N]: y
2023-11-12 19:48:33.34424 Successfully switched over to "citus-coord-01"
+ Citus cluster: pgteachcluster (group: 0, 7300628740432543999) ----+
| Member         | Host        | Role    | State   | TL | Lag in MB |
+----------------+-------------+---------+---------+----+-----------+
| citus-coord-01 | 10.128.0.8  | Leader  | running |  2 |           |
| citus-coord-02 | 10.128.0.18 | Replica | stopped |    |   unknown |
+----------------+-------------+---------+---------+----+-----------+

root@citus-coord-02:~# patronictl -c /etc/patroni.yml list
+ Citus cluster: pgteachcluster -------+--------------+-----------+----+-----------+
| Group | Member         | Host        | Role         | State     | TL | Lag in MB |
+-------+----------------+-------------+--------------+-----------+----+-----------+
|     0 | citus-coord-01 | 10.128.0.8  | Leader       | running   |  3 |           |
|     0 | citus-coord-02 | 10.128.0.18 | Sync Standby | streaming |  3 |         0 |
|     1 | citus-work-01  | 10.128.0.24 | Leader       | running   |  1 |           |
|     1 | citus-work-03  | 10.128.0.11 | Sync Standby | streaming |  1 |         0 |
|     2 | citus-work-02  | 10.128.0.36 | Leader       | running   |  2 |           |
+-------+----------------+-------------+--------------+-----------+----+-----------+

-- меняем мастера в группе 1 воркеров

root@citus-coord-01:~# patronictl -c /etc/patroni.yml switchover
Current cluster topology
+ Citus cluster: pgteachcluster -------+--------------+-----------+----+-----------+
| Group | Member         | Host        | Role         | State     | TL | Lag in MB |
+-------+----------------+-------------+--------------+-----------+----+-----------+
|     0 | citus-coord-01 | 10.128.0.8  | Leader       | running   |  3 |           |
|     0 | citus-coord-02 | 10.128.0.18 | Sync Standby | streaming |  3 |         0 |
|     1 | citus-work-01  | 10.128.0.24 | Leader       | running   |  1 |           |
|     1 | citus-work-03  | 10.128.0.11 | Sync Standby | streaming |  1 |         0 |
|     2 | citus-work-02  | 10.128.0.36 | Leader       | running   |  2 |           |
+-------+----------------+-------------+--------------+-----------+----+-----------+
Citus group: 1
Primary [citus-work-01]: citus-work-01
Candidate ['citus-work-03'] []: citus-work-03
When should the switchover take place (e.g. 2023-11-12T20:50 )  [now]:
Are you sure you want to switchover cluster pgteachcluster, demoting current leader citus-work-01? [y/N]: y
2023-11-12 19:50:22.13745 Successfully switched over to "citus-work-03"
+ Citus cluster: pgteachcluster (group: 1, 7300639212015214620) ---+
| Member        | Host        | Role    | State   | TL | Lag in MB |
+---------------+-------------+---------+---------+----+-----------+
| citus-work-01 | 10.128.0.24 | Replica | stopped |    |   unknown |
| citus-work-03 | 10.128.0.11 | Leader  | running |  1 |           |
+---------------+-------------+---------+---------+----+-----------+

root@citus-coord-01:~# patronictl -c /etc/patroni.yml list
+ Citus cluster: pgteachcluster -------+--------------+-----------+----+-----------+
| Group | Member         | Host        | Role         | State     | TL | Lag in MB |
+-------+----------------+-------------+--------------+-----------+----+-----------+
|     0 | citus-coord-01 | 10.128.0.8  | Leader       | running   |  3 |           |
|     0 | citus-coord-02 | 10.128.0.18 | Sync Standby | streaming |  3 |         0 |
|     1 | citus-work-01  | 10.128.0.24 | Sync Standby | streaming |  2 |         0 |
|     1 | citus-work-03  | 10.128.0.11 | Leader       | running   |  2 |           |
|     2 | citus-work-02  | 10.128.0.36 | Leader       | running   |  2 |           |
+-------+----------------+-------------+--------------+-----------+----+-----------+
```

Прокси для сервиса
```

yc compute instance create \
  --name citus-haproxy-01 \
  --hostname citus-haproxy-01 \
  --create-boot-disk size=10G,type=network-hdd,image-folder-id=standard-images,image-family=ubuntu-2204-lts \
  --cores 2 \
  --memory 2G \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --zone ru-central1-a \
  --metadata-from-file ssh-keys=/home/aslepov/meta.txt




ssh ubuntu@84.201.130.76 'sudo apt install haproxy'
ssh ubuntu@84.201.130.76 'sudo wget https://raw.githubusercontent.com/aoslepov/pg-teach-adv/main/lesson15/citus-patroni/haproxy.cfg -O /etc/haproxy/haproxy.cfg'
ssh ubuntu@84.201.130.76 'sudo haproxy -c -f /etc/haproxy/haproxy.cfg && sudo systemctl restart haproxy'
```


