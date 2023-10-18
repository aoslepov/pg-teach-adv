curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
exit
ssh connect
yc init

# в первом окне 
# install kubectl
sudo apt-get update && sudo apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl

sudo apt install postgresql-client

# https://cloud.yandex.ru/docs/managed-kubernetes/quickstart
# https://cloud.yandex.ru/docs/managed-kubernetes/operations/kubernetes-cluster/kubernetes-cluster-create

yc managed-kubernetes cluster get-credentials test-k8s-cluster --external
kubectl config view

yc container cluster list
yc container cluster list-node-groups cat1ggiqmhqanat634rk
yc compute disk list

kubectl get all --ignore-not-found
kubectl get nodes --ignore-not-found

# install helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install my-release bitnami/postgresql-ha

kubectl get all # проверяю statefullset три ноды вверху и внизу
kubectl get all -A
kubectl get pods
kubectl get nodes
kubectl get pv # A Kubernetes persistent volume (PV) is an object that allows pods to access persistent storage on a storage device, defined via a Kubernetes StorageClass
kubectl get all -o wide # смотрим, куда на какие ноды распределились 

yc compute disk list

export POSTGRES_PASSWORD=$(kubectl get secret --namespace default my-release-postgresql-ha-postgresql -o jsonpath="{.data.password}" | base64 -d)
export REPMGR_PASSWORD=$(kubectl get secret --namespace default my-release-postgresql-ha-postgresql -o jsonpath="{.data.repmgr-password}" | base64 -d)
echo $POSTGRES_PASSWORD #MkNHpVFUQW
echo $REPMGR_PASSWORD #dhoeNsb9ja

# kubectl run my-release-postgresql-ha-client --rm --tty -i --restart='Never' --namespace default --image docker.io/bitnami/postgresql-repmgr:15.3.0-debian-11-r6 --env="PGPASSWORD=$POSTGRES_PASSWORD"  \
#         --command -- psql -h my-release-postgresql-ha-pgpool -p 5432 -U postgres -d postgres

# kubectl port-forward --namespace default svc/my-release-postgresql-ha-pgpool 5432:5432 & psql -h 127.0.0.1 -p 5432 -U postgres -d postgres


# в первом окне 
kubectl port-forward --namespace default svc/my-release-postgresql-ha-pgpool 5432:5432

# во втором окне
psql -h 127.0.0.1 -p 5432 -U postgres -d postgres # PGPASSWORD=$POSTGRES_PASSWORD psql -h $SERVICE_IP -p 5432 -U postgres -d postgres
\l

# в третьем окне 
kubectl delete pod/my-release-postgresql-ha-postgresql-0 # убьем мастер и пробуем подключиться во втором окне
kubectl get all

kubectl delete pod/my-release-postgresql-ha-postgresql-1 # убьем слейв и пробуем подключиться во втором окне



# зайдем на подик pg_pool
kubectl exec -it pod/my-release-postgresql-ha-pgpool-76f7d7dd7-52ck4 -- bash
# настройка HA+pgpool
#  http://support.ptc.com/help/thingworx_hc/thingworx_8_hc/ru/index.html#page/ThingWorx/Help/ThingWorxHighAvailability/InstallingandConfiguringPostgreSQLHA.html
find / -name pgpool.conf
cat /opt/bitnami/pgpool/conf/pgpool.conf

psql -U postgres -p 5432 -h localhost


# repmgr
# https://github.com/EnterpriseDB/repmgr
# not working
# kubectl exec -it pod/pgsql-ha-postgresql-ha-postgresql-0 -- bash
# repmgr -f /etc/repmgr.conf cluster show

# find / -name repmgr.conf
# cat /opt/bitnami/repmgr/conf/repmgr.conf

# kubectl exec -it pod/pgsql-ha-postgresql-ha-postgresql-1 -- repmgr -f /etc/repmgr.conf cluster show
# 

kubectl exec -it pod/my-release-postgresql-ha-postgresql-1 -- /opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh repmgr -f /opt/bitnami/repmgr/conf/repmgr.conf cluster show


# добавление внешнего лоад балансера helm upgrade --set service.type=LoadBalancer, чтобы получить доступ извне

# https://github.com/bitnami/charts/blob/master/bitnami/postgresql-ha/README.md

export POSTGRES_PASSWORD=$(kubectl get secret --namespace default my-release-postgresql-ha-postgresql -o jsonpath="{.data.password}" | base64 -d)
export REPMGR_PASSWORD=$(kubectl get secret --namespace "default" my-release-postgresql-ha-postgresql -o jsonpath="{.data.repmgr-password}" | base64 --decode)
export ADMIN_PASSWORD=$(kubectl get secret --namespace "default" my-release-postgresql-ha-pgpool -o jsonpath="{.data.admin-password}" | base64 --decode)

helm upgrade my-release bitnami/postgresql-ha --set service.type=LoadBalancer --set postgresql.password=$POSTGRES_PASSWORD --set postgresql.repmgrPassword=$REPMGR_PASSWORD --set pgpool.adminPassword=$ADMIN_PASSWORD

kubectl get all # смотрим на статус external api у pgpool

export SERVICE_IP=$(kubectl get svc --namespace default my-release-postgresql-ha-pgpool --template "{{ range (index .status.loadBalancer.ingress 0) }}{{.}}{{ end }}")

# export POSTGRES_PASSWORD=$(kubectl get secret --namespace default my-release-postgresql-ha-postgresql -o jsonpath="{.data.postgresql-password}" | base64 --decode)
# починили чарт, раньше нужно было включать опцию
# export PGSSLMODE=allow

# пробуем подключиться с любой ноды
PGPASSWORD=$POSTGRES_PASSWORD psql -h $SERVICE_IP -p 5432 -U postgres -d postgres


yc container clusters list
yc container clusters delete cat1ggiqmhqanat634rk

# посмотрим, что осталось от кластера
yc compute disks list
