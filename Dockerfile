FROM ubuntu:18.04
# This is intended only as a base image, and only intended as an intermediate
# build phase, not a service that is run.  If run, it will immediately exit.
# It is like the Mr. Meeseeks of docker containers.  Existence is pain.

# Official 'best' and most stable setup according to PostGIS:
# PostGIS 2.5.2
# PotgreSQL 11.2
# GEOS 3.7.1
# SFCGAL 1.3.6
# GDAL 2.4.1
# PROJ 6.0.0
# Versions in bionic beaver repos are out of date.
RUN apt-get update
RUN apt-get install -y wget less systemd gnupg software-properties-common

# 1.  Install Postgresql 11.2
RUN touch /etc/apt/sources.list.d/pgdg.list
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main" > /etc/apt/sources.list.d/pgdg.list
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN apt-get update
RUN apt-get -y install postgresql-11 postgresql-server-dev-11

# 2.  Sanity check. Docker build phase will fail if postgres isn't working.
USER postgres
RUN /usr/lib/postgresql/11/bin/pg_ctl -D /etc/postgresql/11/main start 
EXPOSE 5432
USER root

# 3.  Install GDAL 2.4.1
RUN add-apt-repository ppa:ubuntugis/ubuntugis-unstable && apt-get update
RUN apt-get update
RUN apt-get install -y gdal-bin libgdal-dev

# 4.  Install GEOS 3.7.1
RUN apt-get install -y netcat build-essential libxml2 libxml2-dev libprotobuf-c1 libprotobuf-c-dev  \
     libprotobuf-dev protobuf-compiler protobuf-c-compiler
RUN wget http://download.osgeo.org/geos/geos-3.7.1.tar.bz2
RUN tar -xvjf geos-3.7.1.tar.bz2
RUN (export CPLUS_INCLUDE_PATH=/usr/include/gdal; \
     export C_INCLUDE_PATH=/usr/include/gdal; \ 
     cd geos-3.7.1 && ./configure && make -j`cat /proc/cpuinfo | awk '/^processor/{print $3}' | wc -l` && make install)
RUN rm -rf geos-3.7.1
RUN rm geos-3.7.1.tar.bz2

# 5.  Install PostGIS 2.5.2
RUN wget https://download.osgeo.org/postgis/source/postgis-2.5.2.tar.gz
RUN tar -xvzf postgis-2.5.2.tar.gz
RUN (export CPLUS_INCLUDE_PATH=/usr/include/gdal; \ 
     export C_INCLUDE_PATH=/usr/include/gdal; \
     cd postgis-2.5.2 && ./configure && make -j`cat /proc/cpuinfo | awk '/^processor/{print $3}' | wc -l` && make install)
RUN rm -rf postgis-2.5.2
RUN rm postgis-2.5.2.tar.gz

RUN apt-get install -y cmake unzip
RUN wget https://github.com/isciences/exactextract/archive/master.zip
RUN unzip master.zip 
RUN cd exactextract-master && mkdir cmake-build-release && cd cmake-build-release && cmake -DCMAKE_BUILD_TYPE=Release .. && \
    make && make install
RUN rm -rf exactextract-master
RUN rm master.zip



CMD ["true"]
