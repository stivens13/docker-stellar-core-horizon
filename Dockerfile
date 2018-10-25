FROM stellar/base:latest

#MAINTAINER Bartek Nowotarski <bartek@stellar.org>

ENV STELLAR_CORE_VERSION 10.0.0-685-1fc018b4
ENV HORIZON_VERSION 0.1

EXPOSE 5432
EXPOSE 8000
EXPOSE 11625
EXPOSE 11626

ADD dependencies /
RUN ["chmod", "+x", "dependencies"]
RUN /dependencies

RUN apt-get install -y clang pkg-config bison flex libpq-dev clang-format pandoc perl
WORKDIR temp
RUN git clone -b current --single-branch https://github.com/BonexIO/stellar-core.git .
RUN git submodule init && git submodule update

RUN apt-get install -y autoconf
RUN apt-get install -y libtool

RUN ./autogen.sh
RUN ./configure

RUN apt-get install -y make

RUN make -j"$(nproc)" install

# install horizon

RUN wget -O horizon.tar.gz https://github.com/BonexIO/go/releases/download/horizon-v${HORIZON_VERSION}/horizon-v${HORIZON_VERSION}-linux-amd64.tar.gz
RUN tar -zxvf horizon.tar.gz
RUN mv horizon-v${HORIZON_VERSION}-linux-amd64/horizon /usr/local/bin
RUN chmod +x /usr/local/bin/horizon

WORKDIR /
RUN rm -rf temp

RUN echo "\nDone installing stellar-core and horizon...\n"


RUN ["mkdir", "-p", "/opt/stellar"]
RUN ["touch", "/opt/stellar/.docker-ephemeral"]

RUN useradd --uid 10011001 --home-dir /home/stellar --no-log-init stellar \
    && mkdir -p /home/stellar \
    && chown -R stellar:stellar /home/stellar

RUN ["ln", "-s", "/opt/stellar", "/stellar"]
RUN ["ln", "-s", "/opt/stellar/core/etc/stellar-core.cfg", "/stellar-core.cfg"]
RUN ["ln", "-s", "/opt/stellar/horizon/etc/horizon.env", "/horizon.env"]
ADD common /opt/stellar-default/common
ADD pubnet /opt/stellar-default/pubnet
ADD testnet /opt/stellar-default/testnet
ADD standalone /opt/stellar-default/standalone

ADD start /
RUN ["chmod", "+x", "start"]

ENTRYPOINT ["/init", "--", "/start" ]
