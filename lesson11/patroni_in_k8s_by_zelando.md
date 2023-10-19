### Развовачиваем patroni в kubernetes при помощи чарта zelando

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


Скачиваем yandex cloud и подключемся к облаку
```
cd /usr/local/sbin/ && curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash

root@pg-teach-01:~# yc init
Welcome! This command will take you through the configuration process.
Please go to https://oauth.yandex.ru/authorize?response_type=token&client_id=XXX in order to obtain OAuth token.

Please enter OAuth token: XXX
You have one cloud available: 'cloud-ao-slepov' (id = XXX). It is going to be used by default.
Please choose folder to use:
 [1] default (id = b1g7jn3kmfd43b53ui4s)
 [2] Create a new folder
Please enter your numeric choice: 1
Your current folder has been set to 'default' (id = XXX).
Do you want to configure a default Compute zone? [Y/n] n

root@pg-teach-01:~# yc iam service-account list
+----------------------+--------------+
|          ID          |     NAME     |
+----------------------+--------------+
| ajelke70oe4djhng98qn | yc-terraform |
+----------------------+--------------+
```


Устанавливаем psql, helm, kubctl  
```
cd /usr/local/sbin/ && curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && chmod +x kubectl
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && chmod 700 get_helm.sh && ./get_helm.sh
sudo apt install postgresql-client
```

Подключаем kubctl к облаку  
````
yc managed-kubernetes cluster get-credentials k8s-pg --external

root@pg-teach-01:/usr/local/sbin# kubectl api-resources
NAME                              SHORTNAMES          APIVERSION                             NAMESPACED   KIND
bindings                                              v1                                     true         Binding
componentstatuses                 cs                  v1                                     false        ComponentStatus
configmaps                        cm                  v1                                     true         ConfigMap
endpoints                         ep                  v1                                     true         Endpoints
events                            ev                  v1                                     true         Event
...


root@pg-teach-01:/home/ubuntu/postgres-operator# yc container cluster list
+----------------------+--------+---------------------+---------+---------+------------------------+---------------------+
|          ID          |  NAME  |     CREATED AT      | HEALTH  | STATUS  |   EXTERNAL ENDPOINT    |  INTERNAL ENDPOINT  |
+----------------------+--------+---------------------+---------+---------+------------------------+---------------------+
| catjmq82h37b7al0um6k | k8s-pg | 2023-10-18 20:11:19 | HEALTHY | RUNNING | https://84.201.166.246 | https://10.128.0.16 |
+----------------------+--------+---------------------+---------+---------+------------------------+---------------------+

root@pg-teach-01:/home/ubuntu/postgres-operator# yc container cluster list-node-groups catjmq82h37b7al0um6k
+----------------------+----------+----------------------+---------------------+---------+------+
|          ID          |   NAME   |  INSTANCE GROUP ID   |     CREATED AT      | STATUS  | SIZE |
+----------------------+----------+----------------------+---------------------+---------+------+
| cat6reeqc5qvruj722a4 | pg-teach | cl1dvg1j60es9hatspph | 2023-10-18 20:20:35 | RUNNING |    3 |
+----------------------+----------+----------------------+---------------------+---------+------+

root@pg-teach-01:/home/ubuntu/postgres-operator# yc compute disk list
+----------------------+------+--------------+---------------+--------+----------------------+-----------------+-------------+
|          ID          | NAME |     SIZE     |     ZONE      | STATUS |     INSTANCE IDS     | PLACEMENT GROUP | DESCRIPTION |
+----------------------+------+--------------+---------------+--------+----------------------+-----------------+-------------+
| ef3q0hu58sl8m57lm2c3 |      | 103079215104 | ru-central1-c | READY  | ef3efsv0q7jmj9o2cqev |                 |             |
| epdcj8rsgd3rtntbin0j |      | 103079215104 | ru-central1-b | READY  | epd525t2e9hdp5udo7h6 |                 |             |
| fhm0aucdecoqrovbtqtf |      |  10737418240 | ru-central1-a | READY  | fhmhgfb1sev4pmisab1f |                 |             |
| fhmssh47guttk7e6e2g8 |      | 103079215104 | ru-central1-a | READY  | fhmdm6b81ercd15ed11l |                 |             |
+----------------------+------+--------------+---------------+--------+----------------------+-----------------+-------------+
```

Разворачиваем оператор postgresql из репы
```
git clone https://github.com/zalando/postgres-operator && cd postgres-operator
root@pg-teach-01:/home/ubuntu/postgres-operator# helm install postgres-operator ./charts/postgres-operator
NAME: postgres-operator
LAST DEPLOYED: Wed Oct 18 20:56:40 2023
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
To verify that postgres-operator has started, run:

  kubectl --namespace=default get pods -l "app.kubernetes.io/name=postgres-operator"

root@pg-teach-01:/home/ubuntu/postgres-operator# kubectl --namespace=default get pods -l "app.kubernetes.io/name=postgres-operator"
NAME                                 READY   STATUS    RESTARTS   AGE
postgres-operator-75d59c7fcb-bqmtq   1/1     Running   0          3m1s
```

Разворачиваем ui для оператора  
```
root@pg-teach-01:/home/ubuntu/postgres-operator# helm install postgres-operator-ui ./charts/postgres-operator-ui
NAME: postgres-operator-ui
LAST DEPLOYED: Wed Oct 18 21:00:53 2023
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
To verify that postgres-operator has started, run:

  kubectl --namespace=default get pods -l "app.kubernetes.io/name=postgres-operator-ui"

root@pg-teach-01:/home/ubuntu/postgres-operator# kubectl --namespace=default get pods -l "app.kubernetes.io/name=postgres-operator-ui"
NAME                                    READY   STATUS    RESTARTS   AGE
postgres-operator-ui-7c4d9f9c45-27chh   1/1     Running   0          53s
```

Проверяем  
```
root@pg-teach-01:/home/ubuntu/postgres-operator# kubectl get all --ignore-not-found
NAME                                        READY   STATUS    RESTARTS   AGE
pod/postgres-operator-75d59c7fcb-bqmtq      1/1     Running   0          6m9s
pod/postgres-operator-ui-7c4d9f9c45-27chh   1/1     Running   0          116s

NAME                           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/kubernetes             ClusterIP   10.96.128.1     <none>        443/TCP    47m
service/postgres-operator      ClusterIP   10.96.150.232   <none>        8080/TCP   6m9s
service/postgres-operator-ui   ClusterIP   10.96.168.4     <none>        80/TCP     116s

NAME                                   READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/postgres-operator      1/1     1            1           6m9s
deployment.apps/postgres-operator-ui   1/1     1            1           116s

NAME                                              DESIRED   CURRENT   READY   AGE
replicaset.apps/postgres-operator-75d59c7fcb      1         1         1       6m9s
replicaset.apps/postgres-operator-ui-7c4d9f9c45   1         1         1       116s

NAME                                                    IMAGE                             CLUSTER-LABEL   SERVICE-ACCOUNT   MIN-INSTANCES   AGE
operatorconfiguration.acid.zalan.do/postgres-operator   ghcr.io/zalando/spilo-15:3.0-p1   cluster-name    postgres-pod      -1              6m7s
```


Создаём лоад балансер для деплоймента  
```
kubectl expose deployment postgres-operator-ui --type=LoadBalancer --name=pg-ui
```

Заходим на ардес/порт pg-ui и создаём новый кластер http://84.201.140.19:8081/#new  
[zelando-1.png](zelando-1.png)
[zelando-2.png](zelando-2.png)

Проверяем развёртывание  
```
root@pg-teach-01:/home/ubuntu/postgres-operator# kubectl get all -A --ignore-not-found
NAMESPACE     NAME                                          READY   STATUS    RESTARTS   AGE
default       pod/pg-patroni-0                              1/1     Running   0          2m9s
default       pod/pg-patroni-1                              1/1     Running   0          106s
default       pod/pg-patroni-pooler-658d4ff4c-6jfh2         1/1     Running   0          11s
default       pod/pg-patroni-pooler-658d4ff4c-jfhz5         1/1     Running   0          10s
default       pod/pg-patroni-pooler-repl-7b84975789-fp4n8   1/1     Running   0          10s
default       pod/pg-patroni-pooler-repl-7b84975789-sk79w   1/1     Running   0          10s
default       pod/postgres-operator-75d59c7fcb-bqmtq        1/1     Running   0          30m
default       pod/postgres-operator-ui-7c4d9f9c45-27chh     1/1     Running   0          26m
kube-system   pod/coredns-7c4497977d-jjtvh                  1/1     Running   0          71m
kube-system   pod/coredns-7c4497977d-vhb66                  1/1     Running   0          64m
kube-system   pod/ip-masq-agent-6ttjj                       1/1     Running   0          64m
kube-system   pod/ip-masq-agent-6wpsr                       1/1     Running   0          64m
kube-system   pod/ip-masq-agent-gthdz                       1/1     Running   0          64m
kube-system   pod/kube-dns-autoscaler-689576d9f4-4ppvj      1/1     Running   0          71m
kube-system   pod/kube-proxy-dh454                          1/1     Running   0          64m
kube-system   pod/kube-proxy-tt592                          1/1     Running   0          64m
kube-system   pod/kube-proxy-xvd7d                          1/1     Running   0          64m
kube-system   pod/metrics-server-75d8b888d8-ll8xj           2/2     Running   0          64m
kube-system   pod/npd-v0.8.0-mjvz5                          1/1     Running   0          64m
kube-system   pod/npd-v0.8.0-v6pks                          1/1     Running   0          64m
kube-system   pod/npd-v0.8.0-vp92r                          1/1     Running   0          64m
kube-system   pod/yc-disk-csi-node-v2-8mhkw                 6/6     Running   0          64m
kube-system   pod/yc-disk-csi-node-v2-vd7zb                 6/6     Running   0          64m
kube-system   pod/yc-disk-csi-node-v2-vj7nr                 6/6     Running   0          64m

NAMESPACE     NAME                             TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                  AGE
default       service/kubernetes               ClusterIP      10.96.128.1     <none>        443/TCP                  71m
default       service/pg-patroni               LoadBalancer   10.96.223.91    <pending>     5432:30418/TCP           2m9s
default       service/pg-patroni-config        ClusterIP      None            <none>        <none>                   104s
default       service/pg-patroni-pooler        LoadBalancer   10.96.147.150   <pending>     5432:31507/TCP           10s
default       service/pg-patroni-pooler-repl   LoadBalancer   10.96.177.128   <pending>     5432:32497/TCP           10s
default       service/pg-patroni-repl          LoadBalancer   10.96.195.129   <pending>     5432:30985/TCP           2m9s
default       service/postgres-operator        ClusterIP      10.96.150.232   <none>        8080/TCP                 30m
default       service/postgres-operator-ui     ClusterIP      10.96.168.4     <none>        80/TCP                   26m
kube-system   service/kube-dns                 ClusterIP      10.96.128.2     <none>        53/UDP,53/TCP,9153/TCP   71m
kube-system   service/metrics-server           ClusterIP      10.96.247.204   <none>        443/TCP                  71m

NAMESPACE     NAME                                            DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                                                                        AGE
kube-system   daemonset.apps/ip-masq-agent                    3         3         3       3            3           beta.kubernetes.io/os=linux,node.kubernetes.io/masq-agent-ds-ready=true              71m
kube-system   daemonset.apps/kube-proxy                       3         3         3       3            3           kubernetes.io/os=linux,node.kubernetes.io/kube-proxy-ds-ready=true                   71m
kube-system   daemonset.apps/npd-v0.8.0                       3         3         3       3            3           beta.kubernetes.io/os=linux,node.kubernetes.io/node-problem-detector-ds-ready=true   71m
kube-system   daemonset.apps/nvidia-device-plugin-daemonset   0         0         0       0            0           beta.kubernetes.io/os=linux,node.kubernetes.io/nvidia-device-plugin-ds-ready=true    71m
kube-system   daemonset.apps/yc-disk-csi-node                 0         0         0       0            0           <none>                                                                               71m
kube-system   daemonset.apps/yc-disk-csi-node-v2              3         3         3       3            3           yandex.cloud/pci-topology=k8s                                                        71m

NAMESPACE     NAME                                     READY   UP-TO-DATE   AVAILABLE   AGE
default       deployment.apps/pg-patroni-pooler        2/2     2            2           11s
default       deployment.apps/pg-patroni-pooler-repl   2/2     2            2           10s
default       deployment.apps/postgres-operator        1/1     1            1           30m
default       deployment.apps/postgres-operator-ui     1/1     1            1           26m
kube-system   deployment.apps/coredns                  2/2     2            2           71m
kube-system   deployment.apps/kube-dns-autoscaler      1/1     1            1           71m
kube-system   deployment.apps/metrics-server           1/1     1            1           71m

NAMESPACE     NAME                                                DESIRED   CURRENT   READY   AGE
default       replicaset.apps/pg-patroni-pooler-658d4ff4c         2         2         2       11s
default       replicaset.apps/pg-patroni-pooler-repl-7b84975789   2         2         2       10s
default       replicaset.apps/postgres-operator-75d59c7fcb        1         1         1       30m
default       replicaset.apps/postgres-operator-ui-7c4d9f9c45     1         1         1       26m
kube-system   replicaset.apps/coredns-7c4497977d                  2         2         2       71m
kube-system   replicaset.apps/kube-dns-autoscaler-689576d9f4      1         1         1       71m
kube-system   replicaset.apps/metrics-server-64d75c78c6           0         0         0       71m
kube-system   replicaset.apps/metrics-server-75d8b888d8           1         1         1       64m

NAMESPACE   NAME                          READY   AGE
default     statefulset.apps/pg-patroni   2/2     2m9s

NAMESPACE   NAME                                  TEAM   VERSION   PODS   VOLUME   CPU-REQUEST   MEMORY-REQUEST   AGE     STATUS
default     postgresql.acid.zalan.do/pg-patroni   acid   15        2      10Gi     100m          100Mi            2m10s   Running

NAMESPACE   NAME                                                    IMAGE                             CLUSTER-LABEL   SERVICE-ACCOUNT   MIN-INSTANCES   AGE
default     operatorconfiguration.acid.zalan.do/postgres-operator   ghcr.io/zalando/spilo-15:3.0-p1   cluster-name    postgres-pod      -1              30m
```


Проверить статус нод в для оператора можно проверить командой  
```
root@pg-teach-01:/home/ubuntu/postgres-operator# kubectl get pods -l spilo-role -L spilo-role
NAME                                      READY   STATUS    RESTARTS   AGE   SPILO-ROLE
pg-patroni-0                              1/1     Running   0          27m   master
pg-patroni-1                              1/1     Running   0          27m   replica
pg-patroni-pooler-658d4ff4c-6jfh2         1/1     Running   0          25m   master
pg-patroni-pooler-658d4ff4c-jfhz5         1/1     Running   0          25m   master
pg-patroni-pooler-repl-7b84975789-fp4n8   1/1     Running   0          25m   replica
pg-patroni-pooler-repl-7b84975789-sk79w   1/1     Running   0          25m   replica

root@pg-teach-01:/home/ubuntu/postgres-operator# kubectl get svc -l spilo-role -L spilo-role
NAME              TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE   SPILO-ROLE
pg-patroni        LoadBalancer   10.96.223.91    <pending>     5432:30418/TCP   28m   master
pg-patroni-repl   LoadBalancer   10.96.195.129   <pending>     5432:30985/TCP   28m   replica
```

Получем креды для мастера постгрес (без баунсера)  
```
root@pg-teach-01:/home/ubuntu/postgres-operator# kubectl get secrets
NAME                                                       TYPE                 DATA   AGE
pooler.pg-patroni.credentials.postgresql.acid.zalan.do     Opaque               2      30m
postgres.pg-patroni.credentials.postgresql.acid.zalan.do   Opaque               2      30m
sh.helm.release.v1.postgres-operator-ui.v1                 helm.sh/release.v1   1      54m
sh.helm.release.v1.postgres-operator.v1                    helm.sh/release.v1   1      58m
standby.pg-patroni.credentials.postgresql.acid.zalan.do    Opaque               2      30m


export PGHOST="127.0.0.1"
export PGPORT="5432"

export PGPASSWORD=$(kubectl get secret postgres.pg-patroni.credentials.postgresql.acid.zalan.do -o 'jsonpath={.data.password}' | base64 -d)
export PGSSLMODE=require
```


Пробрасываем порт и подключаемся к мастеру  
```
kubectl port-forward service/pg-patroni 5432:5432



root@pg-teach-01:/home/ubuntu/postgres-operator# psql -U postgres
psql (14.9 (Ubuntu 14.9-0ubuntu0.22.04.1), server 15.2 (Ubuntu 15.2-1.pgdg22.04+1))
WARNING: psql major version 14, server major version 15.
         Some psql features might not work.
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
Type "help" for help.

postgres=# \l
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges
-----------+----------+----------+-------------+-------------+-----------------------
 postgres  | postgres | UTF8     | en_US.utf-8 | en_US.utf-8 |
 template0 | postgres | UTF8     | en_US.utf-8 | en_US.utf-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.utf-8 | en_US.utf-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
(3 rows)

postgres=# create database test;
CREATE DATABASE
```

Подключаемся к ноде постгрес, смотрим статус патрони
```

root@pg-teach-01:/home/ubuntu/postgres-operator# kubectl exec -ti pod/pg-patroni-1 -- bash

 ____        _ _
/ ___| _ __ (_) | ___
\___ \| '_ \| | |/ _ \
 ___) | |_) | | | (_) |
|____/| .__/|_|_|\___/
      |_|

This container is managed by runit, when stopping/starting services use sv

Examples:

sv stop cron
sv restart patroni

Current status: (sv status /etc/service/*)

run: /etc/service/patroni: (pid 33) 3316s
run: /etc/service/pgqd: (pid 32) 3316s
root@pg-patroni-1:/home/postgres# patronictl list
+ Cluster: pg-patroni --------+---------+---------+----+-----------+
| Member       | Host         | Role    | State   | TL | Lag in MB |
+--------------+--------------+---------+---------+----+-----------+
| pg-patroni-0 | 10.112.128.7 | Leader  | running |  1 |           |
| pg-patroni-1 | 10.112.129.6 | Replica | running |  1 |         0 |
+--------------+--------------+---------+---------+----+-----------+
```

Создаём балансер для пуллера и получаем креды для него
```
root@pg-teach-01:~# kubectl expose deployment pg-patroni-pooler --type=LoadBalancer --name=pg-connect
service/pg-connect exposed
root@pg-teach-01:~# kubectl get services
NAME                     TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)          AGE
kubernetes               ClusterIP      10.96.128.1     <none>           443/TCP          159m
pg-connect               LoadBalancer   10.96.138.14    51.250.100.204   5432:31758/TCP   17m
pg-patroni               LoadBalancer   10.96.223.91    <pending>        5432:30418/TCP   89m
pg-patroni-config        ClusterIP      None            <none>           <none>           89m
pg-patroni-pooler        LoadBalancer   10.96.147.150   <pending>        5432:31507/TCP   87m
pg-patroni-pooler-repl   LoadBalancer   10.96.177.128   <pending>        5432:32497/TCP   87m
pg-patroni-repl          LoadBalancer   10.96.195.129   <pending>        5432:30985/TCP   89m
pg-ui                    LoadBalancer   10.96.181.192   84.201.140.19    8081:32100/TCP   78m
postgres-operator        ClusterIP      10.96.150.232   <none>           8080/TCP         117m
postgres-operator-ui     ClusterIP      10.96.168.4     <none>           80/TCP           11

export PGHOST="51.250.100.204"
export PGPORT="5432"
export PGPASSWORD=$(kubectl get secret pooler.pg-patroni.credentials.postgresql.acid.zalan.do -o 'jsonpath={.data.password}' | base64 -d)
export PGSSLMODE=require
```

Подключаемся к постгресу через пуллер (юзер pooler)  
```

root@pg-teach-01:/home/ubuntu/postgres-operator# psql -U pooler -d test
psql (14.9 (Ubuntu 14.9-0ubuntu0.22.04.1), server 15.2 (Ubuntu 15.2-1.pgdg22.04+1))
WARNING: psql major version 14, server major version 15.
         Some psql features might not work.
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
Type "help" for help.

test=>
```
