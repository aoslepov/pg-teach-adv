### pgpool + replmngr in kubernetes Yandex Cloud

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


Устанавливаем kubctl, helm и psql  
```
cd /usr/local/sbin/ && curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && chmod +x kubectl
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && chmod 700 get_helm.sh && ./get_helm.sh
sudo apt install postgresql-client
```

Подключаем kubctl к кластеру k8s в YC  
```
yc managed-kubernetes cluster get-credentials k8s-pg --external
kubectl config view
```

Разворпачиваем кластер replmng+pgpool  
```
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install my-release bitnami/postgresql-ha
```



Проверяем
```
yc container cluster list
yc container cluster list-node-groups cat1ggiqmhqanat634rk
yc compute disk list

kubectl get all --ignore-not-found
kubectl get nodes --ignore-not-found

kubectl get all # проверяю statefullset три ноды вверху и внизу
kubectl get all -A
kubectl get pods
kubectl get nodes
kubectl get pv # A Kubernetes persistent volume (PV) is an object that allows pods to access persistent storage on a storage device, defined via a Kubernetes StorageClass
kubectl get all -o wide # смотрим, куда на какие ноды распределились
yc compute disk list
```

Получаем креды 
```
export POSTGRES_PASSWORD=$(kubectl get secret --namespace default my-release-postgresql-ha-postgresql -o jsonpath="{.data.password}" | base64 -d)
echo $POSTGRES_PASSWORD
export REPMGR_PASSWORD=$(kubectl get secret --namespace default my-release-postgresql-ha-postgresql -o jsonpath="{.data.repmgr-password}" | base64 -d)
echo $REPMGR_PASSWORD
```

Коннектимся к мастеру  
```
kubectl run my-release-postgresql-ha-client --rm --tty -i --restart='Never' --namespace default --image docker.io/bitnami/postgresql-repmgr:16.0.0-debian-11-r11 --env="PGPASSWORD=$POSTGRES_PASSWORD"  --command -- psql -h my-release-postgresql-ha-pgpool -p 5432 -U postgres -d postgres
```

Получаем статус кластера  
```
kubectl exec -it pod/my-release-postgresql-ha-postgresql-1 -- /opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh repmgr -f /opt/bitnami/repmgr/conf/repmgr.conf cluster show
```


Организуем доступ к сервису извне
```
# добавление внешнего лоад балансера helm upgrade --set service.type=LoadBalancer, чтобы получить доступ извне

# https://github.com/bitnami/charts/blob/master/bitnami/postgresql-ha/README.md
export POSTGRES_PASSWORD=$(kubectl get secret --namespace default my-release-postgresql-ha-postgresql -o jsonpath="{.data.password}" | base64 -d)
export REPMGR_PASSWORD=$(kubectl get secret --namespace "default" my-release-postgresql-ha-postgresql -o jsonpath="{.data.repmgr-password}" | base64 --decode)
export ADMIN_PASSWORD=$(kubectl get secret --namespace "default" my-release-postgresql-ha-pgpool -o jsonpath="{.data.admin-password}" | base64 --decode)

helm upgrade my-release bitnami/postgresql-ha --set service.type=LoadBalancer --set postgresql.password=$POSTGRES_PASSWORD --set postgresql.repmgrPassword=$REPMGR_PASSWORD --set pgpool.adminPassword=$ADMIN_PASSWORD

root@pg-teach-01:~# export SERVICE_IP=$(kubectl get svc --namespace default my-release-postgresql-ha-pgpool --template "{{ range (index .status.loadBalancer.ingress 0) }}{{.}}{{ end }}")
root@pg-teach-01:~# echo $SERVICE_IP
51.250.96.208
export POSTGRES_PASSWORD=$(kubectl get secret --namespace default my-release-postgresql-ha-postgresql -o jsonpath="{.data.password}" | base64 -d)

PGPASSWORD=$POSTGRES_PASSWORD psql -h $SERVICE_IP -p 5432 -U postgres -d postgres
```




