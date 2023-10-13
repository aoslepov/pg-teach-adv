-- FDW - это расширение, доступное в PostgreSQL, которое позволяет получить доступ
--  к таблице или схеме одной базы данных из другой. 
-- FDW могут использоваться для самых разных целей:
-- Завершение цикла потока данных
-- Ваши данные могут быть разделены по базам данных, 
-- но все же связаны между собой таким образом, что возможность их объединения или 
-- агрегирования является желательной.
-- Позволяет контролировать права доступа к внешним таблицам


select dblink_connect('dbname=demo port=5432 host=158.160.40.202 user=postgres');

select * 
from dblink('select flight_id, status from flights limit 2') 
as test1(flight_id int, status text);

-- 
-- foreign
CREATE USER fdwUser WITH PASSWORD 'secret';
GRANT USAGE ON SCHEMA bookings TO fdwUser;
GRANT SELECT ON tickets TO fdwUser;

-- local
CREATE EXTENSION IF NOT EXISTS postgres_fdw;
select * from pg_extension;

-- Now we’re going to create the foreign server that we’ll import the foreign schema into. 
-- You can name this whatever you want. 
-- In this example I’ll name this one foreigndb_fdw . We’ll create the server with 
-- OPTIONS for our host, port, and the name of the foreign database as follows:

CREATE SERVER foreigndb_fdw FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host '158.160.40.202', port '5432', dbname 'new_otus');
\des
select * from pg_foreign_server;

-- Now we’re going to create the user mapping. Let’s say that all of the objects and 
-- tables in localdb are owned by localuser . 
-- We’re going to create the user mapping for the foreign schema for this user as well. 
-- I don’t recommend setting up user mapping for the postgres superuser.
-- CREATE USER localUser WITH PASSWORD 'secret';
-- CREATE USER MAPPING FOR localuser SERVER foreigndb_fdw OPTIONS (user 'fdwuser', password 'secret');
CREATE USER MAPPING FOR postgres SERVER foreigndb_fdw1 OPTIONS (user 'postgres');
select * from pg_user_mapping;
-- GRANT USAGE ON FOREIGN SERVER foreigndb_fdw TO localuser;
GRANT USAGE ON FOREIGN SERVER foreigndb_fdw1 TO postgres;

IMPORT FOREIGN SCHEMA public LIMIT TO (phonebook) FROM SERVER foreigndb_fdw1 INTO public;

-- задать пароль
-- неправильный коннект create server


CREATE FOREIGN TABLE fdw_phonebook
  (id SERIAL, name VARCHAR(64), phone VARCHAR(64))
  SERVER foreigndb_fdw
  OPTIONS (schema_name 'public', table_name 'phonebook');


-- SQL copy
wget https://edu.postgrespro.com/demo-big-en.zip
sudo apt-get install unzip
sudo unzip demo-big-en.zip -d ./datasets/
sudo -u postgres psql -f ./datasets/demo-big-en-20170815.sql

\copy (select taxi_id from taxi_trips) to /tmp/taxi_id.csv DELIMITER ',' CSV HEADER

-- pgloader (https://access.crunchydata.com/documentation/pgloader/3.6.3/pgloader-usage-examples/)
-- https://pgloader.readthedocs.io/en/latest/tutorial/tutorial.html

pgloader --type csv                                   \
         --field "taxi_id"         		              \
         --with truncate                              \
         --with "fields terminated by ','"            \
         /tmp/taxi_id.csv                             \
         postgres:///postgres?tablename=taxi

-- pg_bulkload (https://github.com/ossc-db/pg_bulkload)