[etcd]
etcd-01 ansible_host=84.201.130.86
etcd-02 ansible_host=51.250.105.89
etcd-03 ansible_host=51.250.36.198

[citus_coord]
citus-coord-01 ansible_host=84.201.174.161 citus_groupid=0
citus-coord-02 ansible_host=84.201.155.22 citus_groupid=0

[citus_worker]
citus-worker-01 ansible_host=158.160.62.235 citus_groupid=1
citus-worker-02 ansible_host=51.250.11.23 citus_groupid=2
citus-worker-03 ansible_host=51.250.100.148 citus_groupid=2

[citus_all:children]
citus_coord
citus_worker

[haproxy]
haproxy-01 ansible_host=84.201.175.40
haproxy-02 ansible_host=84.201.161.164

[monitoring]
monitoring ansible_host=84.252.129.162

==========
TASK [../ROLES/ETCD : debug] ***************************************************************************
ok: [etcd-01] => {
    "msg": {
        "changed": true,
        "cmd": "etcdctl cluster-health",
        "delta": "0:00:00.078861",
        "end": "2024-01-01 18:12:08.187040",
        "failed": false,
        "rc": 0,
        "start": "2024-01-01 18:12:08.108179",
        "stderr": "",
        "stderr_lines": [],
        "stdout": "member 59373f848611e28 is healthy: got healthy result from http://etcd-03:2379\nmember 3e78f89a3c845269 is healthy: got healthy result from http://etcd-02:2379\nmember 4e2079d9addd66f0 is healthy: got healthy result from http://etcd-01:2379\ncluster is healthy",
        "stdout_lines": [
            "member 59373f848611e28 is healthy: got healthy result from http://etcd-03:2379",
            "member 3e78f89a3c845269 is healthy: got healthy result from http://etcd-02:2379",
            "member 4e2079d9addd66f0 is healthy: got healthy result from http://etcd-01:2379",
            "cluster is healthy"
        ]
    }
}
==================

root@citus-coord-01:~# patronictl -c /etc/patroni.yml list
+ Citus cluster: cituscluster ----------+--------------+-----------+----+-----------+
| Group | Member          | Host        | Role         | State     | TL | Lag in MB |
+-------+-----------------+-------------+--------------+-----------+----+-----------+
|     0 | citus-coord-01  | 10.128.0.9  | Leader       | running   |  1 |           |
|     0 | citus-coord-02  | 10.129.0.23 | Sync Standby | streaming |  1 |         0 |
|     1 | citus-worker-01 | 10.128.0.27 | Leader       | running   |  1 |           |
|     2 | citus-worker-02 | 10.128.0.25 | Leader       | running   |  1 |           |
|     2 | citus-worker-03 | 10.129.0.19 | Sync Standby | streaming |  1 |         0 |
+-------+-----------------+-------------+--------------+-----------+----+-----------+

=============

root@haproxy-01:/etc/haproxy# PGPASSWORD=otus123 pgbench -U postgres --host=127.0.0.1 --port=5000 -i citus
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
generating data (client-side)...
100000 of 100000 tuples (100%) done (elapsed 0.04 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 0.64 s (drop tables 0.00 s, create tables 0.04 s, client-side generate 0.32 s, vacuum 0.08 s, primary keys 0.19 s).

root@haproxy-01:/etc/haproxy# psql "postgresql://postgres@127.0.0.1:5000/citus"
Password for user postgres: 
psql (16.1 (Ubuntu 16.1-1.pgdg20.04+1))
Type "help" for help.

citus=# SELECT create_distributed_table('pgbench_accounts', 'aid');
NOTICE:  Copying data from local table...
NOTICE:  copying the data has completed
DETAIL:  The local data in the table is no longer visible, but is still on disk.
HINT:  To remove the local data, run: SELECT truncate_local_data_after_distributing_table($$public.pgbench_accounts$$)
 create_distributed_table 
--------------------------
 
(1 row)

citus=# SELECT truncate_local_data_after_distributing_table($$public.pgbench_accounts$$);
 truncate_local_data_after_distributing_table 
----------------------------------------------
 
(1 row)

citus=# SELECT create_distributed_table('pgbench_branches', 'bid');
NOTICE:  Copying data from local table...
NOTICE:  copying the data has completed
DETAIL:  The local data in the table is no longer visible, but is still on disk.
HINT:  To remove the local data, run: SELECT truncate_local_data_after_distributing_table($$public.pgbench_branches$$)
 create_distributed_table 
--------------------------
 
(1 row)

citus=# SELECT truncate_local_data_after_distributing_table($$public.pgbench_branches$$);
 truncate_local_data_after_distributing_table 
----------------------------------------------
 
(1 row)

citus=# SELECT create_distributed_table('pgbench_history', 'tid');
 create_distributed_table 
--------------------------
 
(1 row)

citus=# SELECT truncate_local_data_after_distributing_table($$public.pgbench_history$$);
 truncate_local_data_after_distributing_table 
----------------------------------------------
 
(1 row)

citus=# SELECT create_distributed_table('pgbench_tellers', 'tid');
NOTICE:  Copying data from local table...
NOTICE:  copying the data has completed
DETAIL:  The local data in the table is no longer visible, but is still on disk.
HINT:  To remove the local data, run: SELECT truncate_local_data_after_distributing_table($$public.pgbench_tellers$$)
 create_distributed_table 
--------------------------
 
(1 row)

citus=# SELECT truncate_local_data_after_distributing_table($$public.pgbench_tellers$$);
 truncate_local_data_after_distributing_table 
----------------------------------------------
 


-- запускаем тест
PGPASSWORD=otus123 pgbench -U postgres --host=127.0.0.1 --port=5001 -c10 -C --jobs=4 --progress=4 --time=3600 --verbose-errors  citus


=====

-- устанавливаем файтор репликации
citus=# alter system set citus.shard_replication_factor=2;
ALTER SYSTEM
citus=# select pg_reload_conf();

SELECT rebalance_table_shards();


citus monitoring
https://docs.citusdata.com/en/v10.2/cloud/monitoring.html




-- распределение в кластере
citus=# select table_name,nodename,pg_size_pretty(sum(shard_size)) from citus_shards group by table_name,nodename order by table_name, nodename;
    table_name    |  nodename   | pg_size_pretty 
------------------+-------------+----------------
 pgbench_history  | 10.128.0.25 | 3048 kB
 pgbench_history  | 10.128.0.27 | 3048 kB
 pgbench_tellers  | 10.128.0.25 | 688 kB
 pgbench_tellers  | 10.128.0.27 | 688 kB
 pgbench_accounts | 10.128.0.25 | 18 MB
 pgbench_accounts | 10.128.0.27 | 18 MB
 pgbench_branches | 10.128.0.25 | 304 kB
 pgbench_branches | 10.128.0.27 | 304 kB



-- роли в кластере и статусы нод
citus=# select * from pg_dist_node;
 nodeid | groupid |  nodename   | nodeport | noderack | hasmetadata | isactive | noderole | nodecluster | metadatasynced | shouldhaveshards 
--------+---------+-------------+----------+----------+-------------+----------+----------+-------------+----------------+------------------
      1 |       0 | 10.128.0.9  |     5432 | default  | t           | t        | primary  | default     | t              | f
      2 |       1 | 10.128.0.27 |     5432 | default  | t           | t        | primary  | default     | t              | t
      3 |       2 | 10.128.0.25 |     5432 | default  | t           | t        | primary  | default     | t              | t


-- статистика по таблицам
citus=# select * from citus_tables;
    table_name    | citus_table_type | distribution_column | colocation_id | table_size | shard_count | table_owner | access_method 
------------------+------------------+---------------------+---------------+------------+-------------+-------------+---------------
 pgbench_accounts | distributed      | aid                 |             2 | 37 MB      |          32 | postgres    | heap
 pgbench_branches | distributed      | bid                 |             2 | 608 kB     |          32 | postgres    | heap
 pgbench_history  | distributed      | tid                 |             2 | 5992 kB    |          32 | postgres    | heap
 pgbench_tellers  | distributed      | tid                 |             2 | 1376 kB    |          32 | postgres    | heap


-- фактор репликации

citus=# select * from pg_dist_colocation;
 colocationid | shardcount | replicationfactor | distributioncolumntype | distributioncolumncollation 
--------------+------------+-------------------+------------------------+-----------------------------
            2 |         32 |                 2 |                     23 |                           0


citus=# SELECT logicalrelid AS tablename,
       count(*)/count(DISTINCT ps.shardid) AS replication_factor
FROM pg_dist_shard_placement ps
JOIN pg_dist_shard p ON ps.shardid=p.shardid
GROUP BY logicalrelid;
    tablename     | replication_factor 
------------------+--------------------
 pgbench_history  |                  2
 pgbench_tellers  |                  2
 pgbench_accounts |                  2
 pgbench_branches |                  2


-- стратегия балансировки
citus=# select * from pg_dist_rebalance_strategy;
      name      | default_strategy |      shard_cost_function      | node_capacity_function |  shard_allowed_on_node_function  | default_threshold | minimum_threshold | improvement_threshold 
----------------+------------------+-------------------------------+------------------------+----------------------------------+-------------------+-------------------+-----------------------
 by_shard_count | f                | citus_shard_cost_1            | citus_node_capacity_1  | citus_shard_allowed_on_node_true |                 0 |                 0 |                     0
 by_disk_size   | t                | citus_shard_cost_by_disk_size | citus_node_capacity_1  | citus_shard_allowed_on_node_true |               0.1 |              0.01 |                   0.5


-- распределение запросов по клиентам
citus=# SELECT client_addr, count(*) as cnt   FROM citus_stat_activity  WHERE is_worker_query='t' and state='active' GROUP BY client_addr ;
 client_addr | cnt 
-------------+-----
 10.128.0.9  |  11


citus=# SELECT * from citus_remote_connection_stats();
  hostname   | port | database_name | connection_count_to_node 
-------------+------+---------------+--------------------------
 10.128.0.27 | 5432 | citus         |                       14
 10.128.0.25 | 5432 | citus         |                       14
 10.128.0.9  | 5432 | citus         |                        3

citus=# select * from citus_lock_waits;

 waiting_gpid | blocking_gpid |                             blocked_statement                              |                 current_statement_in_blocking_process                  | waiting_nodeid | blocking_nodeid 
--------------+---------------+----------------------------------------------------------------------------+------------------------------------------------------------------------+----------------+-----------------
  10000031043 |   10000031035 | END;                                                                       | UPDATE pgbench_branches SET bbalance = bbalance + -4763 WHERE bid = 1; |              1 |               1
  10000031044 |   10000031041 | UPDATE pgbench_branches SET bbalance = bbalance + -4894 WHERE bid = 1;     | UPDATE pgbench_branches SET bbalance = bbalance + 1719 WHERE bid = 1;  |              1 |               1
  10000031044 |   10000031038 | UPDATE pgbench_branches SET bbalance = bbalance + -4894 WHERE bid = 1;     | UPDATE pgbench_branches SET bbalance = bbalance + 3972 WHERE bid = 1;  |              1 |               1
  10000031041 |   10000031038 | UPDATE pgbench_branches SET bbalance = bbalance + 1719 WHERE bid = 1;      | UPDATE pgbench_branches SET bbalance = bbalance + 3972 WHERE bid = 1;  |              1 |               1
  10000031040 |   10000031039 | UPDATE pgbench_accounts SET abalance = abalance + -4056 WHERE aid = 42984; | UPDATE pgbench_tellers SET tbalance = tbalance + -4526 WHERE tid = 9;  |              1 |               1
  10000031035 |   10000031044 | UPDATE pgbench_branches SET bbalance = bbalance + -4763 WHERE bid = 1;     | UPDATE pgbench_branches SET bbalance = bbalance + -4894 WHERE bid = 1; |              1 | 

===========

> switchower worker group 2

root@citus-coord-01:~# patronictl -c /etc/patroni.yml switchover
Current cluster topology
+ Citus cluster: cituscluster ----------+--------------+-----------+----+-----------+
| Group | Member          | Host        | Role         | State     | TL | Lag in MB |
+-------+-----------------+-------------+--------------+-----------+----+-----------+
|     0 | citus-coord-01  | 10.128.0.9  | Leader       | running   |  1 |           |
|     0 | citus-coord-02  | 10.129.0.23 | Sync Standby | streaming |  1 |         0 |
|     1 | citus-worker-01 | 10.128.0.27 | Leader       | running   |  1 |           |
|     2 | citus-worker-02 | 10.128.0.25 | Leader       | running   |  1 |           |
|     2 | citus-worker-03 | 10.129.0.19 | Sync Standby | streaming |  1 |         0 |
+-------+-----------------+-------------+--------------+-----------+----+-----------+
Citus group: 2
Primary [citus-worker-02]: citus-worker-02
Candidate ['citus-worker-03'] []: citus-worker-03
When should the switchover take place (e.g. 2024-01-01T22:09 )  [now]: now
Are you sure you want to switchover cluster cituscluster, demoting current leader citus-worker-02? [y/N]: y
i2024-01-01 21:09:47.02499 Successfully switched over to "citus-worker-03"

root@citus-coord-01:~# patronictl -c /etc/patroni.yml list
+ Citus cluster: cituscluster ----------+--------------+-----------+----+-----------+
| Group | Member          | Host        | Role         | State     | TL | Lag in MB |
+-------+-----------------+-------------+--------------+-----------+----+-----------+
|     0 | citus-coord-01  | 10.128.0.9  | Leader       | running   |  1 |           |
|     0 | citus-coord-02  | 10.129.0.23 | Sync Standby | streaming |  1 |         0 |
|     1 | citus-worker-01 | 10.128.0.27 | Leader       | running   |  1 |           |
|     2 | citus-worker-02 | 10.128.0.25 | Sync Standby | streaming |  2 |         0 |
|     2 | citus-worker-03 | 10.129.0.19 | Leader       | running   |  2 |           |
+-------+-----------------+-------------+--------------+-----------+----+-----------+

===
switchover coordinator
root@citus-coord-01:~# patronictl -c /etc/patroni.yml switchover
Current cluster topology
+ Citus cluster: cituscluster ----------+--------------+-----------+----+-----------+
| Group | Member          | Host        | Role         | State     | TL | Lag in MB |
+-------+-----------------+-------------+--------------+-----------+----+-----------+
|     0 | citus-coord-01  | 10.128.0.9  | Leader       | running   |  1 |           |
|     0 | citus-coord-02  | 10.129.0.23 | Sync Standby | streaming |  1 |         0 |
|     1 | citus-worker-01 | 10.128.0.27 | Leader       | running   |  1 |           |
|     2 | citus-worker-02 | 10.128.0.25 | Sync Standby | streaming |  2 |         0 |
|     2 | citus-worker-03 | 10.129.0.19 | Leader       | running   |  2 |           |
+-------+-----------------+-------------+--------------+-----------+----+-----------+
Citus group: 0
Primary [citus-coord-01]: citus-coord-01
Candidate ['citus-coord-02'] []: citus-coord-02
When should the switchover take place (e.g. 2024-01-01T22:12 )  [now]: now
Are you sure you want to switchover cluster cituscluster, demoting current leader citus-coord-01? [y/N]: y
2024-01-01 21:12:13.76626 Successfully switched over to "citus-coord-02"

root@citus-coord-01:~# patronictl -c /etc/patroni.yml list
+ Citus cluster: cituscluster ----------+--------------+-----------+----+-----------+
| Group | Member          | Host        | Role         | State     | TL | Lag in MB |
+-------+-----------------+-------------+--------------+-----------+----+-----------+
|     0 | citus-coord-01  | 10.128.0.9  | Sync Standby | streaming |  2 |         0 |
|     0 | citus-coord-02  | 10.129.0.23 | Leader       | running   |  2 |           |
|     1 | citus-worker-01 | 10.128.0.27 | Leader       | running   |  1 |           |
|     2 | citus-worker-02 | 10.128.0.25 | Sync Standby | streaming |  2 |         0 |
|     2 | citus-worker-03 | 10.129.0.19 | Leader       | running   |  2 |           |
+-------+-----------------+-------------+--------------+-----------+----+-----------+

==
убиваем процесс  патрони на citus-worker-02

root@citus-coord-01:~# patronictl -c /etc/patroni.yml list
+ Citus cluster: cituscluster ----------+--------------+-----------+----+-----------+
| Group | Member          | Host        | Role         | State     | TL | Lag in MB |
+-------+-----------------+-------------+--------------+-----------+----+-----------+
|     0 | citus-coord-01  | 10.128.0.9  | Sync Standby | streaming |  2 |         0 |
|     0 | citus-coord-02  | 10.129.0.23 | Leader       | running   |  2 |           |
|     1 | citus-worker-01 | 10.128.0.27 | Leader       | running   |  1 |           |
|     2 | citus-worker-03 | 10.129.0.19 | Leader       | running   |  2 |           |
+-------+-----------------+-------------+--------------+-----------+----+-----------+

запускаем патрони на citus-worker-02 , смотрим что воркер вернулся в качестве реплики
root@citus-coord-01:~# patronictl -c /etc/patroni.yml list
+ Citus cluster: cituscluster ----------+--------------+-----------+----+-----------+
| Group | Member          | Host        | Role         | State     | TL | Lag in MB |
+-------+-----------------+-------------+--------------+-----------+----+-----------+
|     0 | citus-coord-01  | 10.128.0.9  | Sync Standby | streaming |  2 |         0 |
|     0 | citus-coord-02  | 10.129.0.23 | Leader       | running   |  2 |           |
|     1 | citus-worker-01 | 10.128.0.27 | Leader       | running   |  1 |           |
|     2 | citus-worker-02 | 10.128.0.25 | Sync Standby | streaming |  2 |         0 |
|     2 | citus-worker-03 | 10.129.0.19 | Leader       | running   |  2 |           |
+-------+-----------------+-------------+--------------+-----------+----+-----------+

-==TEST==============
root@haproxy-01:/etc/haproxy# PGPASSWORD=otus123 pgbench -U postgres --host=127.0.0.1 --port=5000 -c10 -C --jobs=4 --progress=4 --time=60 --verbose-errors  citus
pgbench (16.1 (Ubuntu 16.1-1.pgdg20.04+1))
starting vacuum...end.
progress: 4.0 s, 17.5 tps, lat 494.960 ms stddev 280.511, 0 failed
progress: 8.0 s, 20.0 tps, lat 458.757 ms stddev 223.972, 0 failed
progress: 12.0 s, 18.3 tps, lat 515.264 ms stddev 332.860, 0 failed
progress: 16.0 s, 15.0 tps, lat 645.632 ms stddev 318.170, 0 failed
progress: 20.0 s, 14.3 tps, lat 673.140 ms stddev 359.799, 0 failed
progress: 24.0 s, 11.7 tps, lat 708.723 ms stddev 382.300, 0 failed
progress: 28.0 s, 12.7 tps, lat 855.793 ms stddev 559.858, 0 failed
progress: 32.0 s, 13.5 tps, lat 663.010 ms stddev 295.210, 0 failed
progress: 36.0 s, 14.8 tps, lat 696.552 ms stddev 439.483, 0 failed
progress: 40.0 s, 14.8 tps, lat 642.548 ms stddev 319.515, 0 failed
progress: 44.0 s, 15.0 tps, lat 645.566 ms stddev 362.767, 0 failed
progress: 48.0 s, 14.2 tps, lat 665.407 ms stddev 267.891, 0 failed
progress: 52.0 s, 14.5 tps, lat 661.387 ms stddev 284.231, 0 failed
progress: 56.0 s, 10.5 tps, lat 897.120 ms stddev 503.266, 0 failed
progress: 60.0 s, 15.0 tps, lat 652.553 ms stddev 374.787, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 10
number of threads: 4
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 897
number of failed transactions: 0 (0.000%)
latency average = 643.056 ms
latency stddev = 371.321 ms
average connection time = 29.022 ms
tps = 14.795519 (including reconnection times)



