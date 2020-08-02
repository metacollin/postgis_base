FROM ubuntu:19.10
# This is intended only as a base image, and only intended as an intermediate
# build phase, not a service that is run.  If run, it will immediately exit.
# It is like the Mr. Meeseeks of docker containers.  Existence is pain.

RUN apt-get update
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y wget less systemd gnupg software-properties-common

RUN touch /etc/apt/sources.list.d/pgdg.list
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ eoan-pgdg main" > /etc/apt/sources.list.d/pgdg.list
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN apt-get update
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install postgresql-12 postgresql-server-dev-12 netcat build-essential libxml2 libxml2-dev libprotobuf-c1 libprotobuf-c-dev  \
     libprotobuf-dev protobuf-compiler protobuf-c-compiler libsqlite3-dev pkg-config sqlite3 libjson-c-dev

USER postgres
RUN /usr/lib/postgresql/12/bin/pg_ctl -D /etc/postgresql/12/main start 
EXPOSE 5432
USER root

RUN wget https://github.com/OSGeo/PROJ/releases/download/6.3.2/proj-6.3.2.tar.gz
RUN tar -xvzf proj-6.3.2.tar.gz
RUN cd proj-6.3.2 && ./configure && make -j`cat /proc/cpuinfo | awk '/^processor/{print $3}' | wc -l`  && make install
RUN rm -rf proj-6.3.2
RUN rm -rf proj-6.3.2.tar.gz

RUN wget https://github.com/OSGeo/gdal/releases/download/v3.1.0/gdal-3.1.0.tar.gz 
RUN tar -xvzf gdal-3.1.0.tar.gz
RUN cd gdal-3.1.0 && ./configure --with-proj=/usr/local && make -j`cat /proc/cpuinfo | awk '/^processor/{print $3}' | wc -l`  && make install
RUN rm -rf gdal-3.1.0
RUN rm -rf gdal-3.1.0.tar.gz

RUN wget http://download.osgeo.org/geos/geos-3.8.1.tar.bz2
RUN tar -xvjf geos-3.8.1.tar.bz2
RUN cd geos-3.8.1 && ./configure && make -j`cat /proc/cpuinfo | awk '/^processor/{print $3}' | wc -l`  && make install
RUN rm -rf geos-3.8.1
RUN rm geos-3.8.1.tar.bz2

RUN wget http://download.osgeo.org/postgis/source/postgis-3.0.1.tar.gz
RUN tar -xvzf postgis-3.0.1.tar.gz
RUN (export CPLUS_INCLUDE_PATH=/usr/include/gdal; \
     export C_INCLUDE_PATH=/usr/include/gdal; \
     cd postgis-3.0.1 && ./configure && make -j`cat /proc/cpuinfo | awk '/^processor/{print $3}' | wc -l` && make install)
RUN rm -rf postgis-3.0.1
RUN rm postgis-3.0.1.tar.gz

RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y cmake unzip
RUN wget https://github.com/isciences/exactextract/archive/master.zip
RUN unzip master.zip 
RUN cd exactextract-master && mkdir cmake-build-release && cd cmake-build-release && cmake -DCMAKE_BUILD_TYPE=Release .. && \
    make && make install
RUN rm -rf exactextract-master
RUN rm master.zip
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y ruby ruby-dev curl pixz parallel pv zstd && \
    gem install toml-rb hash_dot pg tty-logger parallel pastel
RUN DEBIAN_FRONTEND="noninteractive" apt-get remove -y build-essential


CMD ["true"]
