export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook -u ubuntu -i hosts grenplum.yml -e "permit_root_login=yes" -b 

