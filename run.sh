#!/bin/sh
#Run master:
docker run -p 5432:5432 --name postgres-master chatlamin/postgrespro-1c \
           --net host \
           --detach \
           -env POSTGRES_INITDB_XLOGDIR=/master/xlog \
           --env POSTGRES_PASSWORD=password \
           --volume /home/adminiztrator/docker-data/postgres/master:/data \
           --volume /media/hdd/postgres-log/master:/master/xlog \
           --volume /etc/localtime:/etc/localtime:ro \
           
#Run slave:
docker run -p 5433:5432 --link postgres-master --name postgres-slave chatlamin/postgrespro-1c \
           --net host \
           --detach \
           -env POSTGRES_MASTER_SERVICE_HOST=postgres-master \
           -env REPLICATION_ROLE=slave \
           -env POSTGRES_INITDB_XLOGDIR=/slave/xlog \
           --env POSTGRES_PASSWORD=password \
           --volume /home/adminiztrator/docker-data/postgres/slave:/data \
           --volume /media/hdd/postgres-log/slave:/slave/xlog \
           --volume /etc/localtime:/etc/localtime:ro \
           
