
#### Создаём вм pg-mon для монитора

```
yc compute instance create \
  --name pg-mon \
  --hostname pg-mon \
  --create-boot-disk size=10G,type=network-ssd,image-folder-id=standard-images,image-family=ubuntu-2204-lts \
  --cores 2 \
  --memory 2G \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --zone ru-central1-a \
  --metadata-from-file ssh-keys=/home/aslepov/meta.txt
```


Устанавливаем pg-auto-failover, удаляем текущий инстанс
```
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update

sudo apt-get install postgresql-15-auto-failover
sudo su postgres -c 'pg_dropcluster 15 main --stop'
```



Инициализаруем каталог для ноды monitor

```
sudo su - postgres
export PATH="$PATH:/usr/lib/postgresql/15/bin/"

postgres@pg-mon:~$ pg_autoctl create monitor  --pgdata ./monitor  --pgport 6000  --hostname $(hostname -I) --auth trust   --no-ssl -v

14:51:31 8259 WARN  No encryption is used for network traffic! This allows an attacker on the network to read all replication data.
14:51:31 8259 WARN  Using --ssl-self-signed instead of --no-ssl is recommend to achieve more security with the same ease of deployment.
14:51:31 8259 WARN  See https://www.postgresql.org/docs/current/libpq-ssl.html for details on how to improve
14:51:31 8259 INFO  Using default --ssl-mode "prefer"
14:51:31 8259 INFO  Initialising a PostgreSQL cluster at "./monitor"
14:51:31 8259 INFO  /usr/lib/postgresql/15/bin/pg_ctl initdb -s -D ./monitor --option '--auth=trust'
14:51:34 8259 INFO  Started pg_autoctl postgres service with pid 8278
14:51:34 8278 INFO   /usr/bin/pg_autoctl do service postgres --pgdata ./monitor -v
14:51:34 8259 INFO  Started pg_autoctl monitor-init service with pid 8279
14:51:34 8284 INFO   /usr/lib/postgresql/15/bin/postgres -D /var/lib/postgresql/monitor -p 6000 -h *
14:51:34 8278 INFO  Postgres is now serving PGDATA "/var/lib/postgresql/monitor" on port 6000 with pid 8284
14:51:34 8279 WARN  NOTICE:  installing required extension "btree_gist"
14:51:34 8279 INFO  Granting connection privileges on 10.128.0.0/24
14:51:34 8279 WARN  Skipping HBA edits (per --skip-pg-hba) for rule: host "pg_auto_failover" "autoctl_node" 10.128.0.0/24 trust
14:51:34 8279 INFO  Your pg_auto_failover monitor instance is now ready on port 6000.
14:51:34 8279 INFO  Monitor has been successfully initialized.
14:51:34 8259 WARN  pg_autoctl service monitor-init exited with exit status 0
14:51:34 8278 INFO  Postgres controller service received signal SIGTERM, terminating
14:51:34 8278 INFO  Stopping pg_autoctl postgres service
14:51:34 8278 INFO  /usr/lib/postgresql/15/bin/pg_ctl --pgdata /var/lib/postgresql/monitor --wait stop --mode fast
14:51:34 8259 INFO  Waiting for subprocesses to terminate.
14:51:35 8259 INFO  Stop pg_autoctl
```

Добавляем доступы
```
echo 'host    replication     all              10.128.0.0/24            trust' >>  /var/lib/postgresql/monitor/pg_hba.conf
echo 'host    all     all              10.128.0.0/24            trust' >>  /var/lib/postgresql/monitor/pg_hba.conf
```


Смотрим настройки для сервиса
```
postgres@pg-mon:~$ pg_autoctl show systemd --pgdata /var/lib/postgresql/monitor
14:54:07 8399 INFO  HINT: to complete a systemd integration, run the following commands (as root):
14:54:07 8399 INFO  pg_autoctl -q show systemd --pgdata "/var/lib/postgresql/monitor" | tee /etc/systemd/system/pgautofailover.service
14:54:07 8399 INFO  systemctl daemon-reload
14:54:07 8399 INFO  systemctl enable pgautofailover
14:54:07 8399 INFO  systemctl start pgautofailover
[Unit]
Description = pg_auto_failover

[Service]
WorkingDirectory = /var/lib/postgresql
Environment = 'PGDATA=/var/lib/postgresql/monitor'
User = postgres
ExecStart = /usr/bin/pg_autoctl run
Restart = always
StartLimitBurst = 0
ExecReload = /usr/bin/pg_autoctl reload

[Install]
WantedBy = multi-user.target
```

---

#### Создаём ноду для мастера pg-teach-01

```
yc compute instance create \
  --name pg-teach-01 \
  --hostname pg-teach-01 \
  --create-boot-disk size=10G,type=network-ssd,image-folder-id=standard-images,image-family=ubuntu-2204-lts \
  --cores 2 \
  --memory 2G \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --zone ru-central1-a \
  --metadata-from-file ssh-keys=/home/aslepov/meta.txt

sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get install postgresql-15-auto-failover
sudo su postgres -c 'pg_dropcluster 15 main --stop'
```


Инициализаруем каталог для мастера
```
sudo su - postgres
export PATH="$PATH:/usr/lib/postgresql/15/bin/"

postgres@pg-teach-01:/root$ pg_autoctl create postgres --pgdata /var/lib/postgresql/data --pgport 5432 --hostname $(hostname -I) --auth trust --no-ssl  --pgctl `which pg_ctl` --monitor postgres://autoctl_node@10.128.0.29:6000/pg_auto_failover -v

15:23:31 7368 WARN  No encryption is used for network traffic! This allows an attacker on the network to read all replication data.
15:23:31 7368 WARN  Using --ssl-self-signed instead of --no-ssl is recommend to achieve more security with the same ease of deployment.
15:23:31 7368 WARN  See https://www.postgresql.org/docs/current/libpq-ssl.html for details on how to improve
15:23:31 7368 INFO  Using default --ssl-mode "prefer"
15:23:31 7368 INFO  Started pg_autoctl postgres service with pid 7370
15:23:31 7370 INFO   /usr/bin/pg_autoctl do service postgres --pgdata /var/lib/postgresql/data -v
15:23:31 7368 INFO  Started pg_autoctl node-init service with pid 7371
15:23:31 7371 INFO  Registered node 1 "node_1" (10.128.0.8:5432) in formation "default", group 0, state "single"
15:23:31 7371 INFO  Writing keeper state file at "/var/lib/postgresql/.local/share/pg_autoctl/var/lib/postgresql/data/pg_autoctl.state"
15:23:31 7371 INFO  Writing keeper init state file at "/var/lib/postgresql/.local/share/pg_autoctl/var/lib/postgresql/data/pg_autoctl.init"
15:23:31 7371 INFO  Successfully registered as "single" to the monitor.
15:23:31 7371 INFO  FSM transition from "init" to "single": Start as a single node
15:23:31 7371 INFO  Initialising postgres as a primary
15:23:31 7371 INFO  Initialising a PostgreSQL cluster at "/var/lib/postgresql/data"
15:23:31 7371 INFO  /usr/lib/postgresql/15/bin//pg_ctl initdb -s -D /var/lib/postgresql/data --option '--auth=trust'
15:23:34 7371 WARN  could not change directory to "/root": Permission denied
15:23:34 7395 INFO   /usr/lib/postgresql/15/bin/postgres -D /var/lib/postgresql/data -p 5432 -h *
15:23:34 7371 INFO  The user "postgres" already exists, skipping.
15:23:34 7371 INFO  CREATE DATABASE postgres;
15:23:34 7371 INFO  The database "postgres" already exists, skipping.
15:23:34 7371 INFO  CREATE EXTENSION pg_stat_statements;
15:23:34 7371 INFO  Disabling synchronous replication
15:23:34 7371 INFO  Reloading Postgres configuration and HBA rules
15:23:34 7370 INFO  Postgres is now serving PGDATA "/var/lib/postgresql/data" on port 5432 with pid 7395
15:23:34 7371 WARN  Failed to resolve hostname "pg-mon" to an IP address that resolves back to the hostname on a reverse DNS lookup.
15:23:34 7371 WARN  Postgres might deny connection attempts from "pg-mon", even with the new HBA rules.
15:23:34 7371 WARN  Hint: correct setup of HBA with host names requires proper reverse DNS setup. You might want to use IP addresses.
15:23:34 7371 WARN  Using IP address "10.128.0.29" in HBA file instead of hostname "pg-mon"
15:23:34 7371 INFO  Reloading Postgres configuration and HBA rules
15:23:34 7371 INFO  Transition complete: current state is now "single"
15:23:34 7371 INFO  keeper has been successfully initialized.
15:23:35 7368 WARN  pg_autoctl service node-init exited with exit status 0
15:23:35 7370 INFO  Postgres controller service received signal SIGTERM, terminating
15:23:35 7370 INFO  Stopping pg_autoctl postgres service
15:23:35 7370 INFO  /usr/lib/postgresql/15/bin//pg_ctl --pgdata /var/lib/postgresql/data --wait stop --mode fast
15:23:35 7368 INFO  Waiting for subprocesses to terminate.
15:23:35 7368 INFO  Stop pg_autoctl
```

Смотрим настройки для сервиса и заводим его
```
pg_autoctl -q show systemd --pgdata "/var/lib/postgresql/data"

postgres@pg-teach-01:/root$ pg_autoctl -q show systemd --pgdata "/var/lib/postgresql/data"
[Unit]
Description = pg_auto_failover

[Service]
WorkingDirectory = /var/lib/postgresql
Environment = 'PGDATA=/var/lib/postgresql/data'
User = postgres
ExecStart = /usr/bin/pg_autoctl run
Restart = always
StartLimitBurst = 0
ExecReload = /usr/bin/pg_autoctl reload

[Install]
WantedBy = multi-user.target

----

echo "[Unit]
 Description = pg_auto_failover

 [Service]
 WorkingDirectory = /var/lib/postgresql
 Environment = 'PGDATA=/var/lib/postgresql/data'
 User = postgres
 ExecStart = /usr/bin/pg_autoctl run
 Restart = always
 StartLimitBurst = 0
 ExecReload = /usr/bin/pg_autoctl reload

 [Install]
 WantedBy = multi-user.target" |
tee /etc/systemd/system/pgautofailover.service

```

Добавляем доступы
```
echo 'host    replication     all              10.128.0.0/24            trust' >>  /var/lib/postgresql/data/pg_hba.conf
echo 'host    all     all              10.128.0.0/24            trust' >>  /var/lib/postgresql/data/pg_hba.conf
```

Включаем сервис
```
systemctl daemon-reload
systemctl enable pgautofailover
systemctl restart pgautofailover
```

--- 

#### Создаём ноду для реплики pg-teach-02
```
yc compute instance create \
  --name pg-teach-02 \
  --hostname pg-teach-02 \
  --create-boot-disk size=10G,type=network-ssd,image-folder-id=standard-images,image-family=ubuntu-2204-lts \
  --cores 2 \
  --memory 2G \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --zone ru-central1-a \
  --metadata-from-file ssh-keys=/home/aslepov/meta.txt
```

Устанавливаем pg-autofailover
```
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get install postgresql-15-auto-failover
sudo su postgres -c 'pg_dropcluster 15 main --stop'
```

При инициализации создаётся реплики через pg_basebackup
```
postgres@pg-teach-02:~$ pg_autoctl create postgres --pgdata /var/lib/postgresql/data --pgport 5432 --hostname $(hostname -I) --auth trust --no-ssl  --pgctl `which pg_ctl` --monitor postgres://autoctl_node@10.128.0.29:6000/pg_auto_failover -v

16:22:33 4947 WARN  No encryption is used for network traffic! This allows an attacker on the network to read all replication data.
16:22:33 4947 WARN  Using --ssl-self-signed instead of --no-ssl is recommend to achieve more security with the same ease of deployment.
16:22:33 4947 WARN  See https://www.postgresql.org/docs/current/libpq-ssl.html for details on how to improve
16:22:33 4947 INFO  Using default --ssl-mode "prefer"
16:22:33 4947 INFO  Started pg_autoctl postgres service with pid 4949
16:22:33 4949 INFO   /usr/bin/pg_autoctl do service postgres --pgdata /var/lib/postgresql/data -v
16:22:33 4947 INFO  Started pg_autoctl node-init service with pid 4950
16:22:33 4950 INFO  Registered node 2 "node_2" (10.128.0.27:5432) in formation "default", group 0, state "wait_standby"
16:22:33 4950 INFO  Writing keeper state file at "/var/lib/postgresql/.local/share/pg_autoctl/var/lib/postgresql/data/pg_autoctl.state"
16:22:33 4950 INFO  Writing keeper init state file at "/var/lib/postgresql/.local/share/pg_autoctl/var/lib/postgresql/data/pg_autoctl.init"
16:22:33 4950 INFO  Successfully registered as "wait_standby" to the monitor.
16:22:33 4950 INFO  FSM transition from "init" to "wait_standby": Start following a primary
16:22:33 4950 INFO  Transition complete: current state is now "wait_standby"
16:22:33 4950 INFO  New state for node 1 "node_1" (10.128.0.8:5432): single ➜ wait_primary
16:22:33 4950 INFO  New state for node 1 "node_1" (10.128.0.8:5432): wait_primary ➜ wait_primary
16:22:33 4950 INFO  FSM transition from "wait_standby" to "catchingup": The primary is now ready to accept a standby
16:22:33 4950 INFO  Initialising PostgreSQL as a hot standby
16:22:33 4950 INFO   /usr/lib/postgresql/15/bin/pg_basebackup -w -d 'application_name=pgautofailover_standby_2 host=10.128.0.8 port=5432 user=pgautofailover_replicator sslmode=prefer' --pgdata /var/lib/postgresql/backup/node_2 -U pgautofailover_replicator --verbose --progress --max-rate 100M --wal-method=stream --slot pgautofailover_standby_2
16:22:33 4950 INFO  pg_basebackup: initiating base backup, waiting for checkpoint to complete
16:22:34 4950 INFO  pg_basebackup: checkpoint completed
16:22:34 4950 INFO  pg_basebackup: write-ahead log start point: 0/2000028 on timeline 1
16:22:34 4950 INFO  pg_basebackup: starting background WAL receiver
16:22:34 4950 INFO  23146/23146 kB (100%), 0/1 tablespace (.../backup/node_2/global/pg_control)
16:22:35 4950 INFO  23146/23146 kB (100%), 1/1 tablespace
16:22:35 4950 INFO  pg_basebackup: write-ahead log end point: 0/2000138
16:22:35 4950 INFO  pg_basebackup: waiting for background process to finish streaming ...
16:22:35 4950 INFO  pg_basebackup: syncing data to disk ...
16:22:38 4950 INFO  pg_basebackup: renaming backup_manifest.tmp to backup_manifest
16:22:38 4950 INFO  pg_basebackup: base backup completed
16:22:38 4950 INFO  Creating the standby signal file at "/var/lib/postgresql/data/standby.signal", and replication setup at "/var/lib/postgresql/data/postgresql-auto-failover-standby.conf"
16:22:38 4950 INFO  Contents of "/var/lib/postgresql/data/postgresql-auto-failover.conf" have changed, overwriting
16:22:38 4957 INFO   /usr/lib/postgresql/15/bin/postgres -D /var/lib/postgresql/data -p 5432 -h *
16:22:38 4950 INFO  PostgreSQL started on port 5432
16:22:38 4949 INFO  Postgres is now serving PGDATA "/var/lib/postgresql/data" on port 5432 with pid 4957
16:22:38 4950 INFO  Fetched current list of 1 other nodes from the monitor to update HBA rules, including 1 changes.
16:22:38 4950 INFO  Ensuring HBA rules for node 1 "node_1" (10.128.0.8:5432)
16:22:38 4950 INFO  Adding HBA rule: host replication "pgautofailover_replicator" 10.128.0.8/32 trust
16:22:38 4950 INFO  Adding HBA rule: host "postgres" "pgautofailover_replicator" 10.128.0.8/32 trust
16:22:38 4950 INFO  Writing new HBA rules in "/var/lib/postgresql/data/pg_hba.conf"
16:22:38 4950 INFO  Reloading Postgres configuration and HBA rules
16:22:38 4950 INFO  Transition complete: current state is now "catchingup"
16:22:38 4950 INFO  keeper has been successfully initialized.
16:22:38 4947 WARN  pg_autoctl service node-init exited with exit status 0
16:22:38 4949 INFO  Postgres controller service received signal SIGTERM, terminating
16:22:38 4949 INFO  Stopping pg_autoctl postgres service
16:22:38 4949 INFO  /usr/lib/postgresql/15/bin//pg_ctl --pgdata /var/lib/postgresql/data --wait stop --mode fast
16:22:38 4947 INFO  Stop pg_autoctl
```

Аналогично заводим сервис и доступы
```

echo "[Unit]
 Description = pg_auto_failover

 [Service]
 WorkingDirectory = /var/lib/postgresql
 Environment = 'PGDATA=/var/lib/postgresql/data'
 User = postgres
 ExecStart = /usr/bin/pg_autoctl run
 Restart = always
 StartLimitBurst = 0
 ExecReload = /usr/bin/pg_autoctl reload

 [Install]
 WantedBy = multi-user.target" |
tee /etc/systemd/system/pgautofailover.service
--
echo 'host    replication     all              10.128.0.0/24            trust' >>  /var/lib/postgresql/data/pg_hba.conf
echo 'host    all     all              10.128.0.0/24            trust' >>  /var/lib/postgresql/data/pg_hba.conf
--
systemctl daemon-reload
systemctl enable pgautofailover
systemctl restart pgautofailover
```

---

#### Проверяем работу кластера

Статус нод
```
postgres@pg-mon:~$ pg_autoctl show state --pgdata ./monitor
  Name |  Node |        Host:Port |       TLI: LSN |   Connection |      Reported State |      Assigned State
-------+-------+------------------+----------------+--------------+---------------------+--------------------
node_1 |     1 |  10.128.0.8:5432 |   1: 0/3000148 |   read-write |             primary |             primary
node_2 |     2 | 10.128.0.27:5432 |   1: 0/3000148 |    read-only |           secondary |           secondary
```

Статус репликации
```
postgres@pg-mon:~$ pg_autoctl get formation settings --pgdata ./monitor
  Context |    Name |                   Setting | Value
----------+---------+---------------------------+-----------------------------------
formation | default |      number_sync_standbys | 0
  primary |  node_1 | synchronous_standby_names | 'ANY 1 (pgautofailover_standby_2)'
     node |  node_1 |        candidate priority | 50
     node |  node_2 |        candidate priority | 50
     node |  node_1 |        replication quorum | true
     node |  node_2 |        replication quorum | true
```


Смотрим uri сервиса
```
postgres@pg-mon:~$ pg_autoctl show uri --pgdata ./monitor
        Type |    Name | Connection String
-------------+---------+-------------------------------
     monitor | monitor | postgres://autoctl_node@10.128.0.29:6000/pg_auto_failover?sslmode=prefer
   formation | default | postgres://10.128.0.27:5432,10.128.0.8:5432/postgres?target_session_attrs=read-write&sslmode=prefer
```


Коннектимся и проверяем работу
```
postgres@pg-mon:~$ psql 'postgres://10.128.0.27:5432,10.128.0.8:5432/postgres?target_session_attrs=read-write&sslmode=prefer'

CREATE TABLE companies
(
  id         bigserial PRIMARY KEY,
  name       text NOT NULL,
  image_url  text,
  created_at timestamp without time zone NOT NULL,
  updated_at timestamp without time zone NOT NULL
);

\copy companies from program 'curl -o- https://examples.citusdata.com/mt_ref_arch/companies.csv' with csv
```

Проверяем чтение со слейва
```
postgres@pg-mon:~$ psql 'postgres://10.128.0.27:5432,10.128.0.8:5432/postgres?target_session_attrs=read-only&sslmode=prefer'
psql (15.4 (Ubuntu 15.4-2.pgdg22.04+1))
Type "help" for help.

postgres=# select * from companies;
postgres=# select count(*) from companies;
 count
-------
    57
```


Проверяем свитчовер
```
postgres@pg-mon:~$ pg_autoctl perform switchover --pgdata ./monitor

16:40:36 30009 INFO  Waiting 60 secs for a notification with state "primary" in formation "default" and group 0
16:40:36 30009 INFO  Listening monitor notifications about state changes in formation "default" and group 0
16:40:36 30009 INFO  Following table displays times when notifications are received
    Time |   Name |  Node |        Host:Port |       Current State |      Assigned State
---------+--------+-------+------------------+---------------------+--------------------
16:40:36 | node_1 |     1 |  10.128.0.8:5432 |             primary |            draining
16:40:36 | node_2 |     2 | 10.128.0.27:5432 |           secondary |   prepare_promotion
16:40:36 | node_2 |     2 | 10.128.0.27:5432 |   prepare_promotion |   prepare_promotion
16:40:36 | node_2 |     2 | 10.128.0.27:5432 |   prepare_promotion |    stop_replication
16:40:36 | node_1 |     1 |  10.128.0.8:5432 |             primary |      demote_timeout
16:40:36 | node_1 |     1 |  10.128.0.8:5432 |      demote_timeout |      demote_timeout
16:40:37 | node_2 |     2 | 10.128.0.27:5432 |    stop_replication |    stop_replication
16:40:37 | node_2 |     2 | 10.128.0.27:5432 |    stop_replication |        wait_primary
16:40:37 | node_1 |     1 |  10.128.0.8:5432 |      demote_timeout |             demoted
16:40:37 | node_1 |     1 |  10.128.0.8:5432 |             demoted |             demoted
16:40:37 | node_2 |     2 | 10.128.0.27:5432 |        wait_primary |        wait_primary
16:40:37 | node_1 |     1 |  10.128.0.8:5432 |             demoted |          catchingup
16:40:41 | node_1 |     1 |  10.128.0.8:5432 |          catchingup |          catchingup
16:40:42 | node_1 |     1 |  10.128.0.8:5432 |          catchingup |           secondary
16:40:42 | node_1 |     1 |  10.128.0.8:5432 |           secondary |           secondary
16:40:42 | node_2 |     2 | 10.128.0.27:5432 |        wait_primary |             primary
16:40:42 | node_1 |     1 |  10.128.0.8:5432 |           secondary |           secondary
16:40:42 | node_1 |     1 |  10.128.0.8:5432 |           secondary |           secondary
16:40:42 | node_2 |     2 | 10.128.0.27:5432 |             primary |             primary


postgres@pg-mon:~$ pg_autoctl show state --pgdata ./monitor
  Name |  Node |        Host:Port |       TLI: LSN |   Connection |      Reported State |      Assigned State
-------+-------+------------------+----------------+--------------+---------------------+--------------------
node_1 |     1 |  10.128.0.8:5432 |   2: 0/303E158 |    read-only |           secondary |           secondary
node_2 |     2 | 10.128.0.27:5432 |   2: 0/303E158 |   read-write |             primary |             primary
```
