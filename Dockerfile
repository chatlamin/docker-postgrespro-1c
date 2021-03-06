FROM ubuntu:xenial

ENV SERVER_VERSION 9.4

ENV DEBIAN_FRONTEND noninteractive

RUN groupadd postgres --gid=999 \
  && useradd --gid postgres --uid=999 postgres

ENV GOSU_VERSION 1.7
RUN apt-get -qq update \
  && apt-get -qq install --yes --no-install-recommends ca-certificates wget locales \
  && wget --quiet -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
  && chmod +x /usr/local/bin/gosu \
  && gosu nobody true

RUN localedef --inputfile ru_RU --force --charmap UTF-8 --alias-file /usr/share/locale/locale.alias ru_RU.UTF-8
ENV LANG ru_RU.utf8

# common settings
ENV MAX_CONNECTIONS 500
ENV WAL_KEEP_SEGMENTS 256
ENV MAX_WAL_SENDERS 100

# master/slave settings
ENV REPLICATION_ROLE master
ENV REPLICATION_USER replication
ENV REPLICATION_PASSWORD ""

# slave settings
ENV POSTGRES_MASTER_SERVICE_HOST localhost
ENV POSTGRES_MASTER_SERVICE_PORT 5432

ENV PATH /usr/lib/postgresql/$SERVER_VERSION/bin:$PATH
ENV PGDATA /data
RUN echo deb http://1c.postgrespro.ru/deb/ xenial main > /etc/apt/sources.list.d/postgrespro-1c.list \
  && wget --quiet -O- http://1c.postgrespro.ru/keys/GPG-KEY-POSTGRESPRO-1C-92 | apt-key add - \
  && apt-get -qq update \
  && apt-get -qq install --yes --no-install-recommends postgresql-common-pro-1c \
  && sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf \
  && apt-get -qq install --yes --no-install-recommends postgresql-pro-1c-$SERVER_VERSION

RUN mkdir --parent /var/run/postgresql \
  && chown --recursive postgres:postgres /var/run/postgresql \
  && chmod g+s /var/run/postgresql \
  && mkdir --parent "$PGDATA" \
  && chown --recursive postgres:postgres "$PGDATA" \
  && mkdir /docker-entrypoint-initdb.d

COPY container/docker-entrypoint.sh /
COPY 10-config.sh /docker-entrypoint-initdb.d/
COPY 20-replication.sh /docker-entrypoint-initdb.d



ENTRYPOINT ["/docker-entrypoint.sh"]

VOLUME $PGDATA

EXPOSE 5432

# Evaluate vars inside PGDATA at runtime.
# For example HOSTNAME in 'ENV PGDATA=/mnt/$HOSTNAME'
# is resolved runtime rather then during build
RUN sed -i 's/set -e/set -e -x\nPGDATA=$(eval echo "$PGDATA")/' /docker-entrypoint.sh


CMD ["postgres"]
