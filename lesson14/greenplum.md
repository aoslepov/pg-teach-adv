```
yc compute instance create \
  --name gpdb-master \
  --hostname gpdb-master \
  --create-boot-disk size=15G,type=network-ssd,image-folder-id=standard-images,image-family=ubuntu-1804-lts \
  --cores 4 \
  --memory 8G \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --zone ru-central1-a \
  --metadata-from-file ssh-keys=/home/aslepov/meta.txt



for i in {1..3}; do
yc compute instance create \
  --name gpdb-0$i \
  --hostname gpdb-0$i \
  --create-boot-disk size=15G,type=network-ssd,image-folder-id=standard-images,image-family=ubuntu-1804-lts \
  --cores 2 \
  --memory 2G \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --zone ru-central1-a \
  --metadata-from-file ssh-keys=/home/aslepov/meta.txt
done

-- старая версия
for i in {'158.160.55.88','130.193.37.81','158.160.112.192','158.160.110.182'}; do
ssh -o StrictHostKeyChecking=no ubuntu@$i 'echo $(hostname)'
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo wget https://github.com/greenplum-db/gpdb/releases/download/6.25.3/greenplum-db-6.25.3-ubuntu18.04-amd64.deb && sudo apt -y install ./greenplum-db-6.25.3-ubuntu18.04-amd64.deb'
done

for i in {'158.160.55.88','130.193.37.81','158.160.112.192','158.160.110.182'}; do
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo apt update'
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo apt install -y software-properties-common'
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo add-apt-repository ppa:greenplum/db'
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo apt update'
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo apt install -y greenplum-db-6 mc'
done


for i in {'158.160.55.88','130.193.37.81','158.160.112.192','158.160.110.182'}; do
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo groupadd gpadmin; sudo useradd gpadmin -r -m -g gpadmin '
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo chsh -s /bin/bash gpadmin '
done


for i in {'158.160.55.88','130.193.37.81','158.160.112.192','158.160.110.182'}; do
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo su gpadmin -c "ssh-keygen"'
done


for i in {'158.160.55.88','130.193.37.81','158.160.112.192','158.160.110.182'}; do
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo cat /home/gpadmin/.ssh/id_rsa.pub'
done


for i in {'158.160.55.88','130.193.37.81','158.160.112.192','158.160.110.182'}; do
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo echo "
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCnnxOtocXsNUCeQ7gF3yewYQ2Be1i7x7DAqShIxYjX3qVPq26fYT3oObN+BV6JZFABjev5uAv/1sx1dhqF6OJEhNui5z4JiYg7lD8mhSH05/fxTJbLoShFFHDC3jOzhFJhMOE9xORHS0p4CX/AKUs9VufNhxBnt3fAo3je3JTvD8HmvQpLmfYGDM5cVJSywKvL0bef215rYUhVMDJA5U2ksI3cZoOuFW4kHLEqKUDYrKs5rDhC1/a4vXyY9l3Qn2KFA78zdeJ1HBQW+w+HqEN+UvHfMTooP3cqcC5bdqNO3ZFdhKnhIItuL4wDSgvMSkdeV2r3ax25FwEO6xcY9uxB gpadmin@gpdb-master
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDjEiSsgXXvIsXc+VCMONRSEoZYpgqTbnlN0amtkQ/A66MhNJyrbMfjLXGANeFg9VW6TMN3WzJdq3BHXyABY0P3VLE8o7gGqTObkol8leKCrNkDD/NGbvbCe6JXUY0IDoPKfjAmwugwCVb1/iTgVetsDgsMnA9rOPYxagMXYHEvs0UfzshDfZqrbSjCQwKviydnFE9oo+xhawJrTeHmJ7llDJskdApyDmWB4QfWKcSUSBWH28oVC6ZhV/7zcfWQjHzP55r9xUAYxmYv0h+YiXl/xetz/L+kUY6fKUgTSUdrnnsH88o59GwstFvYA/xie2Ro1TLQZp80rHwofPIuK4vX gpadmin@gpdb-01
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDpt+nxBie71Kl/RaNBRtLJzg713PaNXDTF4u0O8s1x6lcukfFZbNrEBEt/dO8i9EWZf00d0pVRkUhYP0eX1KhodXnJxP5h7qFjAZ3VMeXQbZ5U5Xp6FKIZVWpNj2d9r32ZAs2WfZ9YMHsyK0C3MHmsAZ/7X1dEnh2i9v31mM3yKmxYhdxUEx1e8wKmhr7N5hD6pWMBFYlYv8c24RfBNrl5UTciVSTn0sQeIwuUQS8Xvfc+Dkgz+0t/U20e33Xb6Dx9VCIBjoLqAqnfJ3fmjUit3wHfIuf+DYs3v44cl4usCO3gZ+cnnOvqPpf13UhtfKSkDm+0QZzHPA8sFF57z5Xx gpadmin@gpdb-02
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC9xMFIsNZs1nVboxfQOgGklrvlHasQ8HMcVUACPATNZOkovLiXLK9GWvWW9A4jXhslTriz2Hgi0ORM5/qySLZet+b5snOxySBd81/FE3Er6vgiFzj/kac9ossHlDxPLzgnLP/pLqDt/+Fm0USJ+SeRb7Pz6z47vnjxEF9ct7BJTRlCUjplSEcK4pBHdjadv8HBLk9mY3ftSbqKSlbmJ+05SE8ic1tYzk3Ay+7Ae5VfDymyg5vzd37NjOnlqqz0ObnGbXochZudK8riuYqgLLDcc0PKrQJ/S6HLJJuAEGwTk0ORuKQ2YK0KDrYrWSZy3k1tkTQdTplhHjbA/YqvVvBN gpadmin@gpdb-03
" > /tmp/keys'
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo su gpadmin -c "cat /tmp/keys | tee /home/gpadmin/.ssh/authorized_keys; chmod 600 /home/gpadmin/.ssh/authorized_keys "'
done

for i in {'158.160.55.88','130.193.37.81','158.160.112.192','158.160.110.182'}; do
ssh -o StrictHostKeyChecking=no ubuntu@$i 'echo "
10.128.0.3   mdw
10.128.0.32 sdw1
10.128.0.11 sdw2
10.128.0.36 sdw3" | sudo tee -a /etc/hosts'
done



????
ssh -o StrictHostKeyChecking=no ubuntu@84.201.130.181 'sudo su gpadmin -c "ssh gpdb-01; exit; ssh gpdb-02; exit; ssh gpdb-03; exit;"  '





for i in {'158.160.55.88','130.193.37.81','158.160.112.192','158.160.110.182'}; do
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo mkdir /data ; sudo chown -R gpadmin:gpadmin /data '
ssh -o StrictHostKeyChecking=no ubuntu@$i ' echo "
mdw
sdw1
sdw2
sdw3
" | sudo tee /opt/greenplum-db-6.25.3/hostfile  '
ssh -o StrictHostKeyChecking=no ubuntu@$i 'echo ". /opt/greenplum-db-6.25.3/greenplum_path.sh" | sudo tee -a /home/gpadmin/.profile'
done


for i in {'158.160.55.88','130.193.37.81','158.160.112.192','158.160.110.182'}; do
ssh -o StrictHostKeyChecking=no ubuntu@$i 'echo ". /opt/greenplum-db-6.25.3/greenplum_path.sh" | sudo tee -a /home/gpadmin/.bashrc'
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo chown -R gpadmin:gpadmin /opt/greenplum-db-*'
done



for i in {'158.160.55.88','130.193.37.81','158.160.112.192','158.160.110.182'}; do
ssh -o StrictHostKeyChecking=no ubuntu@$i ' sudo wget https://raw.githubusercontent.com/aoslepov/pg-teach-adv/main/lesson14/configs/greenplun_sysctl.conf -O /tmp/10-greenplun_sysctl.conf '
ssh -o StrictHostKeyChecking=no ubuntu@$i ' cat /tmp/10-greenplun_sysctl.conf | sudo tee -a /etc/sysctl.conf && sudo sysctl -p '
done


for i in {'158.160.55.88','130.193.37.81','158.160.112.192','158.160.110.182'}; do
ssh -o StrictHostKeyChecking=no ubuntu@$i ' echo "
* soft nofile 524288
* hard nofile 524288
* soft nproc 131072
* hard nproc 131072
" | sudo tee /etc/security/limits.d/greenplun.conf  '
done

pg-master>>

ssh -o StrictHostKeyChecking=no ubuntu@158.160.55.88 'echo "export MASTER_DATA_DIRECTORY=/data/gpseg-1" | sudo tee -a /home/gpadmin/.bashrc'
ssh -o StrictHostKeyChecking=no ubuntu@158.160.55.88 ' sudo wget https://raw.githubusercontent.com/aoslepov/pg-teach-adv/main/lesson14/configs/gpinitsystem_config -O /opt/greenplum-db-6.25.3/gpinitsystem_config && sudo chown gpadmin:gpadmin /opt/greenplum-db-6.25.3/gpinitsystem_config'




pg-master>>
sudo su gpadmin

gpssh-exkeys -f $GPHOME/hostfile
[STEP 1 of 5] create local ID and authorize on local host
  ... /home/gpadmin/.ssh/id_rsa file exists ... key generation skipped

[STEP 2 of 5] keyscan all hosts and update known_hosts file

[STEP 3 of 5] retrieving credentials from remote hosts
  ... send to mdw
  ... send to sdw1
  ... send to sdw2
  ... send to sdw3

[STEP 4 of 5] determine common authentication file content

[STEP 5 of 5] copy authentication files to all remote hosts
  ... finished key exchange with mdw
  ... finished key exchange with sdw1
  ... finished key exchange with sdw2
  ... finished key exchange with sdw3

[INFO] completed successfully


/opt/greenplum-db-6.25.3$ gpinitsystem -c /opt/greenplum-db-6.25.3/gpinitsystem_config -h /opt/greenplum-db-6.25.3/hostfile
--
20231103:07:57:55:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Checking configuration parameters, please wait...
20231103:07:57:55:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Reading Greenplum configuration file /opt/greenplum-db-6.25.3/gpinitsystem_config
20231103:07:57:55:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Locale has not been set in /opt/greenplum-db-6.25.3/gpinitsystem_config, will set to default value
20231103:07:57:55:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Locale set to en_US.utf8
20231103:07:57:55:007466 gpinitsystem:gpdb-master:gpadmin-[WARN]:-Master hostname mdw does not match hostname output
20231103:07:57:55:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Checking to see if mdw can be resolved on this host
20231103:07:57:55:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Can resolve mdw to this host
20231103:07:57:55:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-No DATABASE_NAME set, will exit following template1 updates
20231103:07:57:55:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-MASTER_MAX_CONNECT not set, will set to default value 250
20231103:07:57:55:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Checking configuration parameters, Completed
20231103:07:57:55:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Commencing multi-home checks, please wait...
....
20231103:07:57:56:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Configuring build for standard array
20231103:07:57:56:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Commencing multi-home checks, Completed
20231103:07:57:56:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Building primary segment instance array, please wait...
....
20231103:07:57:59:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Checking Master host
20231103:07:57:59:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Checking new segment hosts, please wait...
....
20231103:07:58:08:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Checking new segment hosts, Completed
20231103:07:58:08:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Greenplum Database Creation Parameters
20231103:07:58:08:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:---------------------------------------
20231103:07:58:08:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Master Configuration
20231103:07:58:08:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:---------------------------------------
20231103:07:58:08:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Master instance name       = Greenplum Data Platform
20231103:07:58:08:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Master hostname            = mdw
20231103:07:58:08:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Master port                = 5432
20231103:07:58:08:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Master instance dir        = /data/gpseg-1
20231103:07:58:08:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Master LOCALE              = en_US.utf8
20231103:07:58:08:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Greenplum segment prefix   = gpseg
20231103:07:58:08:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Master Database            =
20231103:07:58:08:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Master connections         = 250
20231103:07:58:08:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Master buffers             = 128000kB
20231103:07:58:08:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Segment connections        = 750
20231103:07:58:08:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Segment buffers            = 128000kB
20231103:07:58:08:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Checkpoint segments        = 8
20231103:07:58:08:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Encoding                   = UNICODE
20231103:07:58:08:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Postgres param file        = Off
20231103:07:58:08:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Initdb to be used          = /opt/greenplum-db-6.25.3/bin/initdb
20231103:07:58:08:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-GP_LIBRARY_PATH is         = /opt/greenplum-db-6.25.3/lib
20231103:07:58:08:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-HEAP_CHECKSUM is           = on
20231103:07:58:08:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-HBA_HOSTNAMES is           = 0
20231103:07:58:08:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Ulimit check               = Passed
20231103:07:58:08:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Array host connect type    = Single hostname per node
20231103:07:58:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Master IP address [1]      = ::1
20231103:07:58:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Master IP address [2]      = 10.128.0.3
20231103:07:58:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Master IP address [3]      = fe80::d20d:13ff:fe26:ce94
20231103:07:58:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Standby Master             = Not Configured
20231103:07:58:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Number of primary segments = 1
20231103:07:58:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Total Database segments    = 4
20231103:07:58:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Trusted shell              = ssh
20231103:07:58:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Number segment hosts       = 4
20231103:07:58:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Mirroring config           = OFF
20231103:07:58:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:----------------------------------------
20231103:07:58:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Greenplum Primary Segment Configuration
20231103:07:58:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:----------------------------------------
20231103:07:58:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-gpdb-master 	6000 	mdw 	/data/gpseg0 	2
20231103:07:58:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-gpdb-01 	6000 	sdw1 	/data/gpseg1 	3
20231103:07:58:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-gpdb-02 	6000 	sdw2 	/data/gpseg2 	4
20231103:07:58:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-gpdb-03 	6000 	sdw3 	/data/gpseg3 	5

Continue with Greenplum creation Yy|Nn (default=N):
> y
20231103:07:58:26:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Building the Master instance database, please wait...
20231103:07:58:39:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Starting the Master in admin mode
20231103:07:58:39:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Commencing parallel build of primary segment instances
20231103:07:58:39:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Spawning parallel processes    batch [1], please wait...
....
20231103:07:58:40:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Waiting for parallel processes batch [1], please wait...
.....................
20231103:07:59:01:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:------------------------------------------------
20231103:07:59:01:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Parallel process exit status
20231103:07:59:01:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:------------------------------------------------
20231103:07:59:01:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Total processes marked as completed           = 4
20231103:07:59:01:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Total processes marked as killed              = 0
20231103:07:59:01:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Total processes marked as failed              = 0
20231103:07:59:01:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:------------------------------------------------
20231103:07:59:01:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Removing back out file
20231103:07:59:01:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-No errors generated from parallel processes
20231103:07:59:01:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Restarting the Greenplum instance in production mode
20231103:07:59:01:012695 gpstop:gpdb-master:gpadmin-[INFO]:-Starting gpstop with args: -a -l /home/gpadmin/gpAdminLogs -m -d /data/gpseg-1
20231103:07:59:01:012695 gpstop:gpdb-master:gpadmin-[INFO]:-Gathering information and validating the environment...
20231103:07:59:01:012695 gpstop:gpdb-master:gpadmin-[INFO]:-Obtaining Greenplum Master catalog information
20231103:07:59:01:012695 gpstop:gpdb-master:gpadmin-[INFO]:-Obtaining Segment details from master...
20231103:07:59:01:012695 gpstop:gpdb-master:gpadmin-[INFO]:-Greenplum Version: 'postgres (Greenplum Database) 6.25.3 build commit:367edc6b4dfd909fe38fc288ade9e294d74e3f9a Open Source'
20231103:07:59:01:012695 gpstop:gpdb-master:gpadmin-[INFO]:-Commencing Master instance shutdown with mode='smart'
20231103:07:59:01:012695 gpstop:gpdb-master:gpadmin-[INFO]:-Master segment instance directory=/data/gpseg-1
20231103:07:59:01:012695 gpstop:gpdb-master:gpadmin-[INFO]:-Stopping master segment and waiting for user connections to finish ...
server shutting down
20231103:07:59:03:012695 gpstop:gpdb-master:gpadmin-[INFO]:-Attempting forceful termination of any leftover master process
20231103:07:59:03:012695 gpstop:gpdb-master:gpadmin-[INFO]:-Terminating processes for segment /data/gpseg-1
20231103:07:59:05:013092 gpstart:gpdb-master:gpadmin-[INFO]:-Starting gpstart with args: -a -l /home/gpadmin/gpAdminLogs -d /data/gpseg-1
20231103:07:59:05:013092 gpstart:gpdb-master:gpadmin-[INFO]:-Gathering information and validating the environment...
20231103:07:59:05:013092 gpstart:gpdb-master:gpadmin-[INFO]:-Greenplum Binary Version: 'postgres (Greenplum Database) 6.25.3 build commit:367edc6b4dfd909fe38fc288ade9e294d74e3f9a Open Source'
20231103:07:59:05:013092 gpstart:gpdb-master:gpadmin-[INFO]:-Greenplum Catalog Version: '301908232'
20231103:07:59:05:013092 gpstart:gpdb-master:gpadmin-[INFO]:-Starting Master instance in admin mode
20231103:07:59:05:013092 gpstart:gpdb-master:gpadmin-[INFO]:-Obtaining Greenplum Master catalog information
20231103:07:59:05:013092 gpstart:gpdb-master:gpadmin-[INFO]:-Obtaining Segment details from master...
20231103:07:59:05:013092 gpstart:gpdb-master:gpadmin-[INFO]:-Setting new master era
20231103:07:59:05:013092 gpstart:gpdb-master:gpadmin-[INFO]:-Master Started...
20231103:07:59:05:013092 gpstart:gpdb-master:gpadmin-[INFO]:-Shutting down master
20231103:07:59:08:013092 gpstart:gpdb-master:gpadmin-[INFO]:-Commencing parallel segment instance startup, please wait...
20231103:07:59:09:013092 gpstart:gpdb-master:gpadmin-[INFO]:-Process results...
20231103:07:59:09:013092 gpstart:gpdb-master:gpadmin-[INFO]:-----------------------------------------------------
20231103:07:59:09:013092 gpstart:gpdb-master:gpadmin-[INFO]:-   Successful segment starts                                            = 4
20231103:07:59:09:013092 gpstart:gpdb-master:gpadmin-[INFO]:-   Failed segment starts                                                = 0
20231103:07:59:09:013092 gpstart:gpdb-master:gpadmin-[INFO]:-   Skipped segment starts (segments are marked down in configuration)   = 0
20231103:07:59:09:013092 gpstart:gpdb-master:gpadmin-[INFO]:-----------------------------------------------------
20231103:07:59:09:013092 gpstart:gpdb-master:gpadmin-[INFO]:-Successfully started 4 of 4 segment instances
20231103:07:59:09:013092 gpstart:gpdb-master:gpadmin-[INFO]:-----------------------------------------------------
20231103:07:59:09:013092 gpstart:gpdb-master:gpadmin-[INFO]:-Starting Master instance mdw directory /data/gpseg-1
20231103:07:59:09:013092 gpstart:gpdb-master:gpadmin-[INFO]:-Command pg_ctl reports Master mdw instance active
20231103:07:59:09:013092 gpstart:gpdb-master:gpadmin-[INFO]:-Connecting to dbname='template1' connect_timeout=15
20231103:07:59:09:013092 gpstart:gpdb-master:gpadmin-[INFO]:-No standby master configured.  skipping...
20231103:07:59:09:013092 gpstart:gpdb-master:gpadmin-[INFO]:-Database successfully started
20231103:07:59:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Completed restart of Greenplum instance in production mode
20231103:07:59:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Scanning utility log file for any warning messages
20231103:07:59:09:007466 gpinitsystem:gpdb-master:gpadmin-[WARN]:-*******************************************************
20231103:07:59:09:007466 gpinitsystem:gpdb-master:gpadmin-[WARN]:-Scan of log file indicates that some warnings or errors
20231103:07:59:09:007466 gpinitsystem:gpdb-master:gpadmin-[WARN]:-were generated during the array creation
20231103:07:59:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Please review contents of log file
20231103:07:59:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-/home/gpadmin/gpAdminLogs/gpinitsystem_20231103.log
20231103:07:59:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-To determine level of criticality
20231103:07:59:09:007466 gpinitsystem:gpdb-master:gpadmin-[WARN]:-*******************************************************
20231103:07:59:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Greenplum Database instance successfully created
20231103:07:59:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-------------------------------------------------------
20231103:07:59:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-To complete the environment configuration, please
20231103:07:59:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-update gpadmin .bashrc file with the following
20231103:07:59:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-1. Ensure that the greenplum_path.sh file is sourced
20231103:07:59:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-2. Add "export MASTER_DATA_DIRECTORY=/data/gpseg-1"
20231103:07:59:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-   to access the Greenplum scripts for this instance:
20231103:07:59:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-   or, use -d /data/gpseg-1 option for the Greenplum scripts
20231103:07:59:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-   Example gpstate -d /data/gpseg-1
20231103:07:59:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Script log file = /home/gpadmin/gpAdminLogs/gpinitsystem_20231103.log
20231103:07:59:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-To remove instance, run gpdeletesystem utility
20231103:07:59:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-To initialize a Standby Master Segment for this Greenplum instance
20231103:07:59:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Review options for gpinitstandby
20231103:07:59:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-------------------------------------------------------
20231103:07:59:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-The Master /data/gpseg-1/pg_hba.conf post gpinitsystem
20231103:07:59:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-has been configured to allow all hosts within this new
20231103:07:59:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-array to intercommunicate. Any hosts external to this
20231103:07:59:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-new array must be explicitly added to this file
20231103:07:59:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Refer to the Greenplum Admin support guide which is
20231103:07:59:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-located in the /opt/greenplum-db-6.25.3/docs directory
20231103:07:59:09:007466 gpinitsystem:gpdb-master:gpadmin-[INFO]:-------------------------------------------------------

gpstate
---
20231103:07:59:32:013798 gpstate:gpdb-master:gpadmin-[INFO]:-Starting gpstate with args:
20231103:07:59:32:013798 gpstate:gpdb-master:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.25.3 build commit:367edc6b4dfd909fe38fc288ade9e294d74e3f9a Open Source'
20231103:07:59:32:013798 gpstate:gpdb-master:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.26 (Greenplum Database 6.25.3 build commit:367edc6b4dfd909fe38fc288ade9e294d74e3f9a Open Source) on x86_64-unknown-linux-gnu, compiled by gcc (Ubuntu 7.5.0-3ubuntu1~18.04) 7.5.0, 64-bit compiled on Oct  4 2023 23:27:38'
20231103:07:59:32:013798 gpstate:gpdb-master:gpadmin-[INFO]:-Obtaining Segment details from master...
20231103:07:59:32:013798 gpstate:gpdb-master:gpadmin-[INFO]:-Gathering data from segments...
20231103:07:59:32:013798 gpstate:gpdb-master:gpadmin-[INFO]:-Greenplum instance status summary
20231103:07:59:32:013798 gpstate:gpdb-master:gpadmin-[INFO]:-----------------------------------------------------
20231103:07:59:32:013798 gpstate:gpdb-master:gpadmin-[INFO]:-   Master instance                                = Active
20231103:07:59:32:013798 gpstate:gpdb-master:gpadmin-[INFO]:-   Master standby                                 = No master standby configured
20231103:07:59:32:013798 gpstate:gpdb-master:gpadmin-[INFO]:-   Total segment instance count from metadata     = 4
20231103:07:59:32:013798 gpstate:gpdb-master:gpadmin-[INFO]:-----------------------------------------------------
20231103:07:59:32:013798 gpstate:gpdb-master:gpadmin-[INFO]:-   Primary Segment Status
20231103:07:59:32:013798 gpstate:gpdb-master:gpadmin-[INFO]:-----------------------------------------------------
20231103:07:59:32:013798 gpstate:gpdb-master:gpadmin-[INFO]:-   Total primary segments                         = 4
20231103:07:59:32:013798 gpstate:gpdb-master:gpadmin-[INFO]:-   Total primary segment valid (at master)        = 4
20231103:07:59:32:013798 gpstate:gpdb-master:gpadmin-[INFO]:-   Total primary segment failures (at master)     = 0
20231103:07:59:32:013798 gpstate:gpdb-master:gpadmin-[INFO]:-   Total number of postmaster.pid files missing   = 0
20231103:07:59:32:013798 gpstate:gpdb-master:gpadmin-[INFO]:-   Total number of postmaster.pid files found     = 4
20231103:07:59:32:013798 gpstate:gpdb-master:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs missing    = 0
20231103:07:59:32:013798 gpstate:gpdb-master:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs found      = 4
20231103:07:59:32:013798 gpstate:gpdb-master:gpadmin-[INFO]:-   Total number of /tmp lock files missing        = 0
20231103:07:59:32:013798 gpstate:gpdb-master:gpadmin-[INFO]:-   Total number of /tmp lock files found          = 4
20231103:07:59:32:013798 gpstate:gpdb-master:gpadmin-[INFO]:-   Total number postmaster processes missing      = 0
20231103:07:59:32:013798 gpstate:gpdb-master:gpadmin-[INFO]:-   Total number postmaster processes found        = 4
20231103:07:59:32:013798 gpstate:gpdb-master:gpadmin-[INFO]:-----------------------------------------------------
20231103:07:59:32:013798 gpstate:gpdb-master:gpadmin-[INFO]:-   Mirror Segment Status
20231103:07:59:32:013798 gpstate:gpdb-master:gpadmin-[INFO]:-----------------------------------------------------
20231103:07:59:32:013798 gpstate:gpdb-master:gpadmin-[INFO]:-   Mirrors not configured on this array
20231103:07:59:32:013798 gpstate:gpdb-master:gpadmin-[INFO]:-----------------------------------------------------



$ psql -d postgres
psql (9.4.26)
Type "help" for help.

postgres=# create database taxi;
CREATE DATABASE
postgres=# \c taxi;

CREATE TABLE public.chicago_taxi (
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
) distributed by (taxi_id,trip_start_timestamp,trip_end_timestamp);


taxi=# select * from gp_segment_configuration;
 dbid | content | role | preferred_role | mode | status | port |  hostname   |   address   |    datadir
------+---------+------+----------------+------+--------+------+-------------+-------------+---------------
    1 |      -1 | p    | p              | n    | u      | 5432 | gpdb-master | gpdb-master | /data/gpseg-1
    3 |       1 | p    | p              | n    | u      | 6000 | gpdb-01     | gpdb-01     | /data/gpseg1
    4 |       2 | p    | p              | n    | u      | 6000 | gpdb-02     | gpdb-02     | /data/gpseg2
    5 |       3 | p    | p              | n    | u      | 6000 | gpdb-03     | gpdb-03     | /data/gpseg3
    2 |       0 | p    | p              | n    | u      | 6000 | gpdb-master | gpdb-master | /data/gpseg0


COPY chicago_taxi FROM '/data/chicago_taxi_migrate.csv' DELIMITER ',' CSV HEADER;


vacuum analyze chicago_taxi;
create index idx_taxi_id on chicago_taxi(taxi_id);
create index idx_dates on chicago_taxi(trip_start_timestamp,trip_end_timestamp);

-- выборка рандомной записи по индексу
select taxi_id from chicago_taxi order by random() limit 1;
Time: 1650.593 ms

--выборка данных за неделю
postgres=# select taxi_id,trip_start_timestamp,trip_end_timestamp from chicago_taxi where trip_start_timestamp between date'2016-02-01' and date'2016-02-07';
Time: 479.928 ms



Для сравнения, в postgres были следующие результаты
-- выборка рандомной записи по индексу
select taxi_id from chicago_taxi order by random() limit 1;
Time: 5949.964 ms (00:05.950)

--выборка данных за неделю
postgres=# select taxi_id,trip_start_timestamp,trip_end_timestamp from chicago_taxi where trip_start_timestamp between date'2016-02-01' and date'2016-02-07';
Time: 69201.562 ms (01:09.202)
```
