
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
