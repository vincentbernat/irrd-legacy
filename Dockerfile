FROM debian:10 AS builder
RUN apt-get -qqy update \
    && apt-get install -qqy --no-install-recommends \
        autoconf \
        automake \
        byacc \
        flex \
        gcc \
        git \
        gnupg \
        libglib2.0-dev \
        make \
    && rm -rf /var/cache/apt
COPY . /app/
RUN cd /app/src \
    && mkdir m4 && autoreconf -fi \
    && ./configure --prefix=/app/irrd \
    && make \
    && make install

FROM debian:10
RUN apt-get -qqy update \
    && apt-get install -qqy --no-install-recommends \
        libglib2.0-0
RUN groupadd -r irrd && useradd --no-log-init -r -g irrd irrd
COPY --from=builder /app/irrd/ /app/irrd/
VOLUME /databases
EXPOSE 5674
EXPOSE 43
ENTRYPOINT ["/app/irrd/sbin/irrd", "-n", "-g", "irrd", "-l", "irrd", "-d", "/databases", "-f", "/databases/irrd.conf"]

# You can use the volume generated by Dockerfile.databases:
#
#   docker container create --name irrd-database registry.gitlab.com/blade-group/infra/network/irrd-legacy:data-latest
#   docker run --volumes-from=irrd-database -it --rm registry.gitlab.com/blade-group/infra/network/irrd-legacy:latest -v
