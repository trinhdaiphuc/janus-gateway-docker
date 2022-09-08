FROM debian:bullseye-slim AS builder

RUN apt-get -y update && apt-get install -y \
    libmicrohttpd-dev  \
    libcurl4-openssl-dev  \
    liblua5.3-dev \
    libavutil-dev \
    libavformat-dev \
    libavcodec-dev \
    libjansson-dev \
    libssl-dev \
    libsofia-sip-ua-dev \
    libglib2.0-dev \
    libopus-dev \
    libogg-dev \
    libtool \
    libini-config-dev \
    libcollection-dev \
    libconfig-dev \
    pkg-config \
    gengetopt \
    autopoint automake cmake \
    build-essential \
    gtk-doc-tools \
    subversion \
    git \
    wget

RUN SRTP="2.2.0" && wget https://github.com/cisco/libsrtp/archive/v$SRTP.tar.gz && \
    tar xfv v$SRTP.tar.gz && \
    cd libsrtp-$SRTP && \
    ./configure --prefix=/usr --enable-openssl && \
    make shared_library &&  make install

# datachannel build
RUN git clone https://github.com/sctplab/usrsctp.git && \
    cd usrsctp/ && \
    ./bootstrap && \
    ./configure --prefix=/usr && \
    make && make install

RUN git clone https://gitlab.freedesktop.org/libnice/libnice && \
	cd libnice && \
	git checkout 0.1.17 && \
	./autogen.sh && \
	./configure --prefix=/usr && \
	make && \
	make install

RUN LIBWEBSOCKET="4.3.2" && wget https://github.com/warmcat/libwebsockets/archive/v$LIBWEBSOCKET.tar.gz && \
    tar xzvf v$LIBWEBSOCKET.tar.gz && \
    cd libwebsockets-$LIBWEBSOCKET && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr -DCMAKE_C_FLAGS="-fpic" -DLWS_MAX_SMP=1 -DLWS_IPV6="ON" .. && \
    make && make install

RUN git clone https://github.com/meetecho/janus-gateway.git && \
    cd janus-gateway && \
    git checkout refs/tags/v1.0.4 && \
    sh autogen.sh && \
    ./configure --prefix=/usr/local \
    --enable-post-processing \
    --enable-openssl \
    --enable-data-channels \
    --disable-rabbitmq \
    --disable-mqtt \
    --disable-unix-sockets \
    --enable-plugin-echotest \
    --enable-plugin-sip \
    --enable-plugin-videocall \
    --enable-plugin-textroom \
    --enable-websocket \
    --enable-rest \
    --enable-turn-rest-api \
    --enable-all-handlers && \
    make && make install && make configs && ldconfig

FROM nginx

COPY --from=builder \
    /usr/lib/libsrtp2.so.1 \
    /usr/lib/libnice.la \
    /usr/lib/libnice.so.10.10.0 \
    /usr/lib/libnice.so.10 \
    /usr/lib/libwebsockets.so.19 \
    /usr/lib/libusrsctp.so.2   /usr/lib/
COPY --from=builder /usr/local/bin/janus /usr/local/bin/janus-pp-rec /usr/local/bin/janus-cfgconv /usr/local/bin/
COPY --from=builder /usr/local/etc/janus /usr/local/etc/janus
COPY --from=builder /usr/local/lib/janus /usr/local/lib/janus
COPY --from=builder /usr/local/share/janus /usr/local/share/janus
COPY nginx.conf /etc/nginx/nginx.conf

RUN apt-get -y update && \
	apt-get install -y \
        libmicrohttpd12 \
        libjansson4 \
		libssl1.1 \
		libsofia-sip-ua0 \
		libglib2.0-0 \
		libopus0 \
		libogg0 \
		libcurl4 \
		liblua5.3-0 \
		libconfig9 && \
    apt-get clean && \
	rm -rf /var/lib/apt/lists/* && \
    ln -s /usr/lib/libnice.so.10.10.0 /usr/lib/libnice.so && \
    ln -s /usr/lib/libusrsctp.so.2 /usr/lib/libusrsctp.so && \
    ln -s /usr/lib/libsrtp2.so.1 /usr/lib/libsrtp2.so && \
    ln -s /usr/lib/libwebsockets.so.19 /usr/lib/libwebsockets.so

EXPOSE 10000-10200/udp
EXPOSE 8188
EXPOSE 8088
EXPOSE 8089
EXPOSE 8889
EXPOSE 8000
EXPOSE 7088
EXPOSE 7089

CMD nginx && /usr/local/bin/janus