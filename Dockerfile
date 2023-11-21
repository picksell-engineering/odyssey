FROM debian:bullseye as builder

WORKDIR /tmp/

RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    curl \
    lsb-release \
    ca-certificates \
    libssl-dev \
    gnupg \
    openssl \
    build-essential \
    cmake \
    gcc \
    gdb \
    git \
    libpam-dev \
    libzstd-dev \
    zlib1g-dev \
    valgrind 

RUN curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \
    postgresql-common \
    postgresql-server-dev-all 

COPY . odyssey

RUN set -ex \
    && cd odyssey \
    && mkdir build && cd build \
    && cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_DEBIAN=1 -DUSE_SCRAM=1 .. \
    && make

FROM debian:bullseye

RUN set -ex \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    libssl-dev  \
    openssl \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --from=builder /usr/local/lib /usr/local/lib
COPY --from=builder /usr/local/include /usr/local/include
COPY --from=builder /tmp/odyssey/build/sources/odyssey /usr/local/bin/

RUN mkdir /etc/odyssey

COPY odyssey.conf /etc/odyssey/odyssey.conf

EXPOSE 6432

ENTRYPOINT ["/usr/local/bin/odyssey", "/etc/odyssey/odyssey.conf"]