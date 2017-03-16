FROM centos:7
MAINTAINER Karl Stoney <me@karlstoney.com>

# iputils causes the build to fail because of some incompatibility between
# docker hosts running on ubuntu, aufs and centos.
# Details: https://github.com/docker/docker/issues/6980
RUN yum -y -q update && \
    yum -y -q remove iputils && \
    yum -y -q install wget epel-release openssl openssl-devel tar unzip \
							libffi-devel python-devel redhat-rpm-config \
							gcc gcc-c++ make zlib-devel pcre-devel ca-certificates && \
    yum -y -q clean all

# Setup the nginx user and groups
RUN groupadd nginx && \
    useradd -g nginx nginx

# Download LUA JIT
RUN cd /tmp && \
		wget --quiet http://luajit.org/download/LuaJIT-2.1.0-beta2.tar.gz && \
		tar xzf Lua* && \
		cd Lua* && \
		make && \
		make install && \
		rm -rf /tmp/Lua*

ENV LUAJIT_LIB=/usr/local/lib
ENV LUAJIT_INC=/usr/local/include/luajit-2.1

# Download NGX Dev kit
RUN cd /tmp && \
		wget --quiet https://github.com/simpl/ngx_devel_kit/archive/v0.3.0.tar.gz && \
		tar xzf v0.3.0* && \
		mv ngx_devel_kit* /usr/local/src/ngx-devel-kit && \
		rm -f v0.3.0*

# Download NGX_Lua
RUN cd /tmp && \
		wget --quiet https://github.com/openresty/lua-nginx-module/archive/v0.10.7.tar.gz && \
		tar xzf v0.10.7* && \
		mv lua-nginx-module* /usr/local/src/lua-nginx-module && \
		rm -f v0.10.7*

# Download the latest source and build it
RUN nginxVersion="1.11.10" && \
    cd /usr/local/src && \
    wget --quiet http://nginx.org/download/nginx-$nginxVersion.tar.gz && \
    tar -xzf nginx-$nginxVersion.tar.gz && \
    ln -sf nginx-$nginxVersion nginx && \
    cd nginx && \
    ./configure \
      --with-ld-opt="-Wl,-rpath,$LUAJIT_LIB" \
      --add-module=/usr/local/src/lua-nginx-module 					\
      --add-module=/usr/local/src/ngx-devel-kit							\
      --user=nginx                          								\
      --group=nginx                        	 								\
      --prefix=/usr/share/nginx                   					\
      --sbin-path=/usr/sbin/nginx           								\
      --conf-path=/etc/nginx/nginx.conf     								\
      --pid-path=/var/run/nginx/nginx.pid         					\
      --lock-path=/var/run/nginx/nginx.lock       					\
      --error-log-path=/var/log/nginx/error.log 						\
      --http-log-path=/var/log/nginx/access.log 						\
      --with-http_gzip_static_module        								\
      --with-http_stub_status_module        								\
      --with-http_ssl_module                								\
      --with-pcre                           								\
      --with-file-aio                       								\
      --with-http_realip_module             								\
      --without-http_scgi_module            								\
      --without-http_uwsgi_module           								\
      --without-http_fastcgi_module      								 && \
    make && \
    make install && \
    rm -rf /usr/local/src/nginx*

# Add latest pip
RUN wget --quiet https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py

# Download and setup lets encrypt
RUN yum -y -q install git-core && \
    pip install 'acme>=0.4.1,<0.9' && \
    mkdir -p /tmp/src && \
    git clone https://github.com/zenhack/simp_le /tmp/src/simp_le && \
    cd /tmp/src/simp_le && \
    python ./setup.py install && \
    yum -y -q remove git-core && \
    yum -y -q clean all

# Remove build tools from a public facing weberver
RUN yum -y -q remove gcc gcc-c++ make && \
    yum -y -q install openssl

# Setup directories and ownership, as well as allowing nginx to bind to low ports
RUN mkdir -p /var/log/nginx && \
    mkdir -p /var/run/nginx && \
    mkdir -p /usr/share/nginx && \
    mkdir -p /etc/nginx/conf.d && \
    mkdir -p /usr/local/etc/nginx && \
    mkdir -p /etc/letsencrypt && \
    mkdir -p /mnt/live && \
    mkdir -p /mnt/html && \
    rm -rf /usr/share/nginx/html && \
    ln -sf /mnt/live /etc/letsencrypt/live && \
    ln -sf /mnt/html /usr/share/nginx/html && \
    chown -R nginx:nginx /var/log/nginx && \
    chown -R nginx:nginx /var/run/nginx && \
    chown -R nginx:nginx /usr/share/nginx && \
    chown -R nginx:nginx /etc/nginx && \
    chown -R nginx:nginx /usr/local/etc/nginx && \
    chown -R nginx:nginx /etc/letsencrypt && \
    chown -R nginx:nginx /mnt

# Get nodejs repos
RUN curl --silent --location https://rpm.nodesource.com/setup_7.x | bash -
RUN yum -y -q install nodejs
RUN npm install -g handlebars
RUN mkdir -p /template
COPY template/package.json /template/package.json
RUN cd /template && \
    npm install

# Setup NGINX configuration
COPY nginx.conf /etc/nginx/nginx.conf
COPY ssl.default.conf /usr/local/etc/nginx
COPY redirect.default.conf /usr/local/etc/nginx

EXPOSE 80
EXPOSE 443

COPY scripts/* /usr/local/bin/
COPY template/template.js /template/template.js

RUN setcap 'cap_net_bind_service=+ep' /usr/sbin/nginx

CMD ["/usr/local/bin/start_nginx.sh"]
