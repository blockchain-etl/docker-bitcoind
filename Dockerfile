FROM ubuntu:bionic
MAINTAINER Kyle Manna <kyle@kylemanna.com>

ARG USER_ID
ARG GROUP_ID

ENV HOME /bitcoin

# add user with specified (or default) user/group ids
ENV USER_ID ${USER_ID:-1000}
ENV GROUP_ID ${GROUP_ID:-1000}
# you may pick VERSION(#L2) and SHASUM(#L45) from https://github.com/bitcoin-core/packaging/blob/master/snap/snapcraft.yaml
# check VERSION matches SHASUM
ENV VERSION 0.20.0
ENV SHASUM 691ef3f61934a525dc2f007010a3a522b99b487aaf3f66f1f2014b254ae79666
ENV ARCH x86_64-linux-gnu

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -g ${GROUP_ID} bitcoin \
	&& useradd -u ${USER_ID} -g bitcoin -s /bin/bash -m -d /bitcoin bitcoin

# grab gosu for easy step-down from root
RUN set -x && apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      wget \
      gosu && \
    cd /tmp && \
    wget https://bitcoincore.org/bin/bitcoin-core-${VERSION}/SHA256SUMS.asc && \
    wget https://bitcoincore.org/bin/bitcoin-core-${VERSION}/bitcoin-${VERSION}.tar.gz && \
    wget https://bitcoincore.org/bin/bitcoin-core-${VERSION}/bitcoin-${VERSION}-${ARCH}.tar.gz && \
    echo "$SHASUM  SHA256SUMS.asc" | sha256sum --check && \
    sha256sum --ignore-missing --check SHA256SUMS.asc && \
    tar -xf bitcoin-${VERSION}-${ARCH}.tar.gz && \
    tar -xf bitcoin-${VERSION}.tar.gz && \
    echo "Running tests ..." && \
    bitcoin-${VERSION}/bin/test_bitcoin && \
    install -m 0755 -D -t /usr/local/bin bitcoin-${VERSION}/bin/bitcoind && \
    install -m 0755 -D -t /usr/local/bin bitcoin-${VERSION}/bin/bitcoin-cli && \
    cd / && \
    apt-get purge -y \
    		ca-certificates \
    		wget && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD ./bin /usr/local/bin

VOLUME ["/bitcoin"]

EXPOSE 8332 8333 18332 18333

WORKDIR /bitcoin

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["btc_oneshot"]
