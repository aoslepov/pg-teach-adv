#export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook -u ubuntu -i hosts etcd.yml -e "permit_root_login=yes" -b 
#export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook -u ubuntu -i hosts citus.yml -e "permit_root_login=yes" -b
export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook -u ubuntu -i hosts haproxy.yml -e "permit_root_login=yes" -b
