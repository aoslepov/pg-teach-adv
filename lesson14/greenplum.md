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
for i in {'51.250.72.133','51.250.11.200','62.84.114.85','51.250.72.16'}; do
ssh -o StrictHostKeyChecking=no ubuntu@$i 'echo $(hostname)'
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo wget https://github.com/greenplum-db/gpdb/releases/download/6.25.3/greenplum-db-6.25.3-ubuntu18.04-amd64.deb && sudo apt -y install ./greenplum-db-6.25.3-ubuntu18.04-amd64.deb'
done

for i in {'51.250.72.133','51.250.11.200','62.84.114.85','51.250.72.16'}; do
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo apt update'
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo apt install software-properties-common'
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo add-apt-repository ppa:greenplum/db'
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo apt update'
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo apt install -y greenplum-db-6 mc'
done


for i in {'51.250.72.133','51.250.11.200','62.84.114.85','51.250.72.16'}; do
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo groupadd gpadmin; sudo useradd gpadmin -r -m -g gpadmin '
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo chsh -s /bin/bash gpadmin '
done


for i in {'51.250.72.133','51.250.11.200','62.84.114.85','51.250.72.16'}; do
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo su gpadmin -c "ssh-keygen"'
done


for i in {'51.250.72.133','51.250.11.200','62.84.114.85','51.250.72.16'}; do
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo cat /home/gpadmin/.ssh/id_rsa.pub'
done


for i in {'51.250.72.133','51.250.11.200','62.84.114.85','51.250.72.16'}; do
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo echo "
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDR1cBapT+RRC6T6miaj4WQYvZSTTaTTwEMIb2fInGS9EC4SdiJWVBPvJICgYdpAyANAaI0J2SvhCqVjzttR3jBeQWyuJ/myja44QKvAByQwLw79XLrCt4+29oIDU2zeWKwUl5cj4nRUKs1K7g4J14yBrMeuhrD5rnAtQZ0Aeq7Qh4XPT6iAejAAcEqXFynPT4k9t9ZdlAlFtUOQUMev5v8jk0D7K2I/foQtU9e3xZ02qcNptQiKsca9sb19+siajajvaY4U1zWMUCzBkNossGSKgzmJZWq3NAt3ZSg2IAUzDymxpI4iU1SXBJwRhwyLBWzS3DDunrElI8ib5lXrKq5 gpadmin@gpdb-master
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsFoJmCPFLBbMrzY88YdXAI/rwI/5hnOzg7Dluqj2JoOzuUtGXUkdtGp6ejTTT0g5s0+TN90SD6bZBI3iX5TGqODIk8tR5BvKgEjEmc272g0zRq0JWL5ohkt2buO71tQ3Kyu4UFz9JdL64+H6r/x9MpMnOHP6jsYEP9XV4DXrzQ0hLnsqVXGgJM5aMtUWNSBRfhvsqpqg3FeeKpBp8aauVCH72LB1ACsAwcMkVbUfDT7wSg1Ks9qBEiEQZwbd8ehTrxq+qSv1TYDs90mn8PhJdrGlxySa+iXJ27GxHWyQhcLD1VILpfCEtEnnSC76vEYLn2jPV/4lc60yq0k/JThz7 gpadmin@gpdb-01
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDhldApyZLDicEOfv2u9zQRgts7KrC6pP0NH1A18i6aAVBDawnnpRLrYD+wLcWs/dQfB+Lj06NuVR/cjs+U4XT1QWrdHLULqeqGq2k1w0R/h7IoZYFI4b2vEp7gi/9xFSvKOk/QPsI5mKNjDrL96gNx1gKEy1QfmE8IMmMS0PlDtwm+aZDRQxlRMPgKw/3/2HZxNogfidVCP/MLIfGDFixIx/hvLdiCv43Fu2N+Pk6WkqgCoKZOSi0MLe6KzeWrrfNMm3BiJpEeo01lgNmNkNkgLxp5BCh8DXGYdxN/SKENv2GE6NvwbBuU7EVRzidlMfCh1lpvedxy3a/nddIVhfqF gpadmin@gpdb-02
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDYNxvnpgaYYXXq3bjCWvckuQ1cg7gnQDf4SoRmVph0PKANXtjmyAH7yW48XYjH4qjkv/BAVl/Uapa02RcFbocowyQdbuxdtsdM4mJsTyFmdYiEqi6HviIr6Z4wfGGwsrgEIYXrdvspWXoi+dvfH5fBajNcCPLvJLfBjvVfbZL5RwZ4BLrXqI3lg1e1uvU+Nxrw/LqZEf4h56Q645MBIFPgYiG2zitoeumlgbeOaFeWANQqXCgUCjW0tMD4jLce0We6J938VfJ7bV0USGmKeemuvjGDe//NSzeES0u0tfBiCFejXC42oPzUFe13IsioeCn8T6s23l5b2BDSOHcKWYfF gpadmin@gpdb-03
" > /tmp/keys'
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo su gpadmin -c "cat /tmp/keys | tee /home/gpadmin/.ssh/authorized_keys; chmod 600 /home/gpadmin/.ssh/authorized_keys "'
done

????
ssh -o StrictHostKeyChecking=no ubuntu@84.201.130.181 'sudo su gpadmin -c "ssh gpdb-01; exit; ssh gpdb-02; exit; ssh gpdb-03; exit;"  '

ssh -o StrictHostKeyChecking=no ubuntu@51.250.72.133 ' sudo wget https://raw.githubusercontent.com/aoslepov/pg-teach-adv/main/lesson14/configs/gpinitsystem_config -O /opt/greenplum-db-6.25.3/gpinitsystem_config && sudo chown gpadmin:gpadmin /opt/greenplum-db-6.25.3/gpinitsystem_config'



for i in {'51.250.72.133','51.250.11.200','62.84.114.85','51.250.72.16'}; do
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo mkdir /data ; sudo chown -R gpadmin:gpadmin /data '
ssh -o StrictHostKeyChecking=no ubuntu@$i ' echo "
gpdb-master
gpdb-01
gpdb-02
gpdb-03
" | sudo tee /opt/greenplum-db-6.25.3/hostfile  '
ssh -o StrictHostKeyChecking=no ubuntu@$i 'echo ". /opt/greenplum-db-6.25.3/greenplum_path.sh" | sudo tee -a /home/gpadmin/.profile'
done


for i in {'51.250.72.133','51.250.11.200','62.84.114.85','51.250.72.16'}; do
ssh -o StrictHostKeyChecking=no ubuntu@$i 'echo ". /opt/greenplum-db-6.25.3/greenplum_path.sh" | sudo tee -a /home/gpadmin/.bashrc'
ssh -o StrictHostKeyChecking=no ubuntu@$i 'echo "export MASTER_DATA_DIRECTORY=/data/gpseg-1" | sudo tee -a /home/gpadmin/.bashrc'
done


for i in {'51.250.72.133','51.250.11.200','62.84.114.85','51.250.72.16'}; do
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo chown -R gpadmin:gpadmin /opt/greenplum-db-*'
done


pg-master>>
sudo su gpadmin

gpssh-exkeys -f $GPHOME/hostfile
[STEP 1 of 5] create local ID and authorize on local host
  ... /home/gpadmin/.ssh/id_rsa file exists ... key generation skipped

[STEP 2 of 5] keyscan all hosts and update known_hosts file

[STEP 3 of 5] retrieving credentials from remote hosts
  ... send to gpdb-01
  ... send to gpdb-02
  ... send to gpdb-03

[STEP 4 of 5] determine common authentication file content

[STEP 5 of 5] copy authentication files to all remote hosts
  ... finished key exchange with gpdb-01
  ... finished key exchange with gpdb-02
  ... finished key exchange with gpdb-03

[INFO] completed successfully


gpinitsystem -c /opt/greenplum-db-6.25.3/gpinitsystem_config
------
0231102:22:03:13:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Checking configuration parameters, please wait...
20231102:22:03:13:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Reading Greenplum configuration file /opt/greenplum-db-6.25.3/gpinitsystem_config
20231102:22:03:13:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Locale has not been set in /opt/greenplum-db-6.25.3/gpinitsystem_config, will set to default value
20231102:22:03:13:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Locale set to en_US.utf8
20231102:22:03:13:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-No DATABASE_NAME set, will exit following template1 updates
20231102:22:03:13:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-MASTER_MAX_CONNECT not set, will set to default value 250
20231102:22:03:13:008149 gpinitsystem:gpdb-master:gpadmin-[WARN]:-Master open file limit is 1024 should be >= 65535
20231102:22:03:13:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Checking configuration parameters, Completed
20231102:22:03:13:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Commencing multi-home checks, please wait...
....
20231102:22:03:14:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Configuring build for standard array
20231102:22:03:14:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Commencing multi-home checks, Completed
20231102:22:03:14:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Building primary segment instance array, please wait...
....
20231102:22:03:17:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Checking Master host
20231102:22:03:17:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Checking new segment hosts, please wait...
20231102:22:03:17:008149 gpinitsystem:gpdb-master:gpadmin-[WARN]:-Host gpdb-master open files limit is 1024 should be >= 65535
20231102:22:03:19:008149 gpinitsystem:gpdb-master:gpadmin-[WARN]:-Host gpdb-master open files limit is 1024 should be >= 65535
20231102:22:03:20:008149 gpinitsystem:gpdb-master:gpadmin-[WARN]:-Host gpdb-master open files limit is 1024 should be >= 65535
20231102:22:03:21:008149 gpinitsystem:gpdb-master:gpadmin-[WARN]:-Host gpdb-master open files limit is 1024 should be >= 65535
....
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Checking new segment hosts, Completed
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Greenplum Database Creation Parameters
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:---------------------------------------
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Master Configuration
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:---------------------------------------
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Master instance name       = Greenplum Data Platform
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Master hostname            = gpdb-master
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Master port                = 5432
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Master instance dir        = /data/gpseg-1
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Master LOCALE              = en_US.utf8
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Greenplum segment prefix   = gpseg
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Master Database            =
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Master connections         = 250
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Master buffers             = 128000kB
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Segment connections        = 750
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Segment buffers            = 128000kB
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Checkpoint segments        = 8
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Encoding                   = UNICODE
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Postgres param file        = Off
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Initdb to be used          = /opt/greenplum-db-6.25.3/bin/initdb
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-GP_LIBRARY_PATH is         = /opt/greenplum-db-6.25.3/lib
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-HEAP_CHECKSUM is           = on
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-HBA_HOSTNAMES is           = 0
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[WARN]:-Ulimit check               = Warnings generated, see log file <<<<<
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Array host connect type    = Single hostname per node
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Master IP address [1]      = ::1
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Master IP address [2]      = 10.128.0.7
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Master IP address [3]      = fe80::d20d:13ff:fe5d:8bc9
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Standby Master             = Not Configured
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Number of primary segments = 1
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Total Database segments    = 4
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Trusted shell              = ssh
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Number segment hosts       = 4
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Mirroring config           = OFF
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:----------------------------------------
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Greenplum Primary Segment Configuration
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:----------------------------------------
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-gpdb-master 	6000 	gpdb-master 	/data/gpseg0 	2
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-gpdb-01 	6000 	gpdb-01 	/data/gpseg1 	3
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-gpdb-02 	6000 	gpdb-02 	/data/gpseg2 	4
20231102:22:03:26:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-gpdb-03 	6000 	gpdb-03 	/data/gpseg3 	5

Continue with Greenplum creation Yy|Nn (default=N):
> y
20231102:22:03:29:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Building the Master instance database, please wait...
20231102:22:03:41:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Starting the Master in admin mode
20231102:22:03:41:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Commencing parallel build of primary segment instances
20231102:22:03:41:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Spawning parallel processes    batch [1], please wait...
....
20231102:22:03:41:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Waiting for parallel processes batch [1], please wait...
......................
20231102:22:04:03:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:------------------------------------------------
20231102:22:04:03:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Parallel process exit status
20231102:22:04:03:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:------------------------------------------------
20231102:22:04:03:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Total processes marked as completed           = 4
20231102:22:04:03:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Total processes marked as killed              = 0
20231102:22:04:04:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Total processes marked as failed              = 0
20231102:22:04:04:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:------------------------------------------------
20231102:22:04:04:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Removing back out file
20231102:22:04:04:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-No errors generated from parallel processes
20231102:22:04:04:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Restarting the Greenplum instance in production mode
20231102:22:04:04:013359 gpstop:gpdb-master:gpadmin-[INFO]:-Starting gpstop with args: -a -l /home/gpadmin/gpAdminLogs -m -d /data/gpseg-1
20231102:22:04:04:013359 gpstop:gpdb-master:gpadmin-[INFO]:-Gathering information and validating the environment...
20231102:22:04:04:013359 gpstop:gpdb-master:gpadmin-[INFO]:-Obtaining Greenplum Master catalog information
20231102:22:04:04:013359 gpstop:gpdb-master:gpadmin-[INFO]:-Obtaining Segment details from master...
20231102:22:04:04:013359 gpstop:gpdb-master:gpadmin-[INFO]:-Greenplum Version: 'postgres (Greenplum Database) 6.25.3 build commit:367edc6b4dfd909fe38fc288ade9e294d74e3f9a Open Source'
20231102:22:04:04:013359 gpstop:gpdb-master:gpadmin-[INFO]:-Commencing Master instance shutdown with mode='smart'
20231102:22:04:04:013359 gpstop:gpdb-master:gpadmin-[INFO]:-Master segment instance directory=/data/gpseg-1
20231102:22:04:04:013359 gpstop:gpdb-master:gpadmin-[INFO]:-Stopping master segment and waiting for user connections to finish ...
server shutting down
20231102:22:04:05:013359 gpstop:gpdb-master:gpadmin-[INFO]:-Attempting forceful termination of any leftover master process
20231102:22:04:05:013359 gpstop:gpdb-master:gpadmin-[INFO]:-Terminating processes for segment /data/gpseg-1
20231102:22:04:07:013756 gpstart:gpdb-master:gpadmin-[INFO]:-Starting gpstart with args: -a -l /home/gpadmin/gpAdminLogs -d /data/gpseg-1
20231102:22:04:07:013756 gpstart:gpdb-master:gpadmin-[INFO]:-Gathering information and validating the environment...
20231102:22:04:07:013756 gpstart:gpdb-master:gpadmin-[INFO]:-Greenplum Binary Version: 'postgres (Greenplum Database) 6.25.3 build commit:367edc6b4dfd909fe38fc288ade9e294d74e3f9a Open Source'
20231102:22:04:07:013756 gpstart:gpdb-master:gpadmin-[INFO]:-Greenplum Catalog Version: '301908232'
20231102:22:04:07:013756 gpstart:gpdb-master:gpadmin-[INFO]:-Starting Master instance in admin mode
20231102:22:04:08:013756 gpstart:gpdb-master:gpadmin-[INFO]:-Obtaining Greenplum Master catalog information
20231102:22:04:08:013756 gpstart:gpdb-master:gpadmin-[INFO]:-Obtaining Segment details from master...
20231102:22:04:08:013756 gpstart:gpdb-master:gpadmin-[INFO]:-Setting new master era
20231102:22:04:08:013756 gpstart:gpdb-master:gpadmin-[INFO]:-Master Started...
20231102:22:04:08:013756 gpstart:gpdb-master:gpadmin-[INFO]:-Shutting down master
20231102:22:04:10:013756 gpstart:gpdb-master:gpadmin-[INFO]:-Commencing parallel segment instance startup, please wait...
.
20231102:22:04:12:013756 gpstart:gpdb-master:gpadmin-[INFO]:-Process results...
20231102:22:04:12:013756 gpstart:gpdb-master:gpadmin-[INFO]:-----------------------------------------------------
20231102:22:04:12:013756 gpstart:gpdb-master:gpadmin-[INFO]:-   Successful segment starts                                            = 4
20231102:22:04:12:013756 gpstart:gpdb-master:gpadmin-[INFO]:-   Failed segment starts                                                = 0
20231102:22:04:12:013756 gpstart:gpdb-master:gpadmin-[INFO]:-   Skipped segment starts (segments are marked down in configuration)   = 0
20231102:22:04:12:013756 gpstart:gpdb-master:gpadmin-[INFO]:-----------------------------------------------------
20231102:22:04:12:013756 gpstart:gpdb-master:gpadmin-[INFO]:-Successfully started 4 of 4 segment instances
20231102:22:04:12:013756 gpstart:gpdb-master:gpadmin-[INFO]:-----------------------------------------------------
20231102:22:04:12:013756 gpstart:gpdb-master:gpadmin-[INFO]:-Starting Master instance gpdb-master directory /data/gpseg-1
20231102:22:04:12:013756 gpstart:gpdb-master:gpadmin-[INFO]:-Command pg_ctl reports Master gpdb-master instance active
20231102:22:04:12:013756 gpstart:gpdb-master:gpadmin-[INFO]:-Connecting to dbname='template1' connect_timeout=15
20231102:22:04:12:013756 gpstart:gpdb-master:gpadmin-[INFO]:-No standby master configured.  skipping...
20231102:22:04:12:013756 gpstart:gpdb-master:gpadmin-[INFO]:-Database successfully started
20231102:22:04:12:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Completed restart of Greenplum instance in production mode
20231102:22:04:12:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Scanning utility log file for any warning messages
20231102:22:04:12:008149 gpinitsystem:gpdb-master:gpadmin-[WARN]:-*******************************************************
20231102:22:04:12:008149 gpinitsystem:gpdb-master:gpadmin-[WARN]:-Scan of log file indicates that some warnings or errors
20231102:22:04:12:008149 gpinitsystem:gpdb-master:gpadmin-[WARN]:-were generated during the array creation
20231102:22:04:12:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Please review contents of log file
20231102:22:04:12:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-/home/gpadmin/gpAdminLogs/gpinitsystem_20231102.log
20231102:22:04:12:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-To determine level of criticality
20231102:22:04:12:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-These messages could be from a previous run of the utility
20231102:22:04:12:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-that was called today!
20231102:22:04:12:008149 gpinitsystem:gpdb-master:gpadmin-[WARN]:-*******************************************************
20231102:22:04:12:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Greenplum Database instance successfully created
20231102:22:04:12:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-------------------------------------------------------
20231102:22:04:12:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-To complete the environment configuration, please
20231102:22:04:12:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-update gpadmin .bashrc file with the following
20231102:22:04:12:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-1. Ensure that the greenplum_path.sh file is sourced
20231102:22:04:12:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-2. Add "export MASTER_DATA_DIRECTORY=/data/gpseg-1"
20231102:22:04:12:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-   to access the Greenplum scripts for this instance:
20231102:22:04:12:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-   or, use -d /data/gpseg-1 option for the Greenplum scripts
20231102:22:04:12:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-   Example gpstate -d /data/gpseg-1
20231102:22:04:12:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Script log file = /home/gpadmin/gpAdminLogs/gpinitsystem_20231102.log
20231102:22:04:12:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-To remove instance, run gpdeletesystem utility
20231102:22:04:12:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-To initialize a Standby Master Segment for this Greenplum instance
20231102:22:04:12:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Review options for gpinitstandby
20231102:22:04:12:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-------------------------------------------------------
20231102:22:04:12:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-The Master /data/gpseg-1/pg_hba.conf post gpinitsystem
20231102:22:04:12:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-has been configured to allow all hosts within this new
20231102:22:04:12:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-array to intercommunicate. Any hosts external to this
20231102:22:04:12:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-new array must be explicitly added to this file
20231102:22:04:12:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-Refer to the Greenplum Admin support guide which is
20231102:22:04:12:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-located in the /opt/greenplum-db-6.25.3/docs directory
20231102:22:04:12:008149 gpinitsystem:gpdb-master:gpadmin-[INFO]:-------------------------------------------------------



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



--выборка данных за неделю
postgres=# select taxi_id,trip_start_timestamp,trip_end_timestamp from chicago_taxi where trip_start_timestamp between date'2016-02-01' and date'2016-02-07';


. /opt/greenplum-db-6.25.3/greenplum_path.sh


WARNING:  interconnect may encountered a network error, please check your network  (seg2 slice1 10.128.0.29:6000 pid=9785)
DETAIL:  Failed to send packet (seq 1) to 127.0.1.1:40123 (pid 3310 cid -1) after 100 retries.


for i in {'51.250.72.133','51.250.11.200','62.84.114.85','51.250.72.16'}; do
ssh -o StrictHostKeyChecking=no ubuntu@$i 'sudo chsh -s /bin/bash gpadmin '
done


WARNING:  interconnect may encountered a network error, please check your network  (seg1 slice1 10.128.0.18:6000 pid=14172)
DETAIL:  Failed to send packet (seq 1) to 127.0.1.1:43723 (pid 5663 cid -1) after 100 retries.
WARNING:  interconnect may encountered a network error, please check your network  (seg3 slice1 10.128.0.19:6000 pid=14628)
DETAIL:  Failed to send packet (seq 1) to 127.0.1.1:43723 (pid 5663 cid -1) after 100 retries.
WARNING:  interconnect may encountered a network error, please check your network  (seg2 slice1 10.128.0.27:6000 pid=14770)
DETAIL:  Failed to send packet (seq 1) to 127.0.1.1:43723 (pid 5663 cid -1) after 100 retries.


gpinitsystem -c gpinitsystem_config -h hostfile_gpinitsystem

hostfile_gpinitsystem

gpconfig -c gp_interconnect_transmit_timeout -v 600
gpconfig -c gp_interconnect_queue_depth -v 10

gpconfig -c gp_log_interconnect -v verbose --skipvalidation
gpconfig -c log_min_messages -v debug1
gpstop -au


gp_max_packet_size
```

