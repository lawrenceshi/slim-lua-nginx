ARG BUILD_IMAGE=localhost/modsngx
ARG BUILD_IMAGE_TAG=beta_builder

ARG BASE_IMAGE=docker.io/library/nginx
ARG BASE_IMAGE_TAG=mainline

FROM ${BUILD_IMAGE}:${BUILD_IMAGE_TAG} AS builder

RUN :

FROM ${BASE_IMAGE}:${BASE_IMAGE_TAG} AS production

ENV SOURCE_CODE_PATH=/usr/src
ENV NGINX_PREFIX=/etc/nginx
ENV LUA_MODULE_PATH=/usr/local/
ENV COMPILED_INSTALL_PREFIX=/usr/local

ENV LUA_VERSION=5.1

# COPY libcoraza
COPY --from=builder ${COMPILED_INSTALL_PREFIX}/lib/libcoraza*.so* ${COMPILED_INSTALL_PREFIX}/lib/

# COPY Coraza Nginx Module
COPY --from=builder ${SOURCE_CODE_PATH}/nginx/objs/ngx_http_coraza_module*.so* /usr/lib/nginx/modules/

# COPY LuaJIT
COPY --from=builder ${COMPILED_INSTALL_PREFIX}/lib/libluajit*.so* ${COMPILED_INSTALL_PREFIX}/lib/

# COPY Ngx-Devel-Kit
COPY --from=builder ${SOURCE_CODE_PATH}/nginx/objs/ndk_http_module*.so* /usr/lib/nginx/modules/

# COPY Lua Nginx Module
COPY --from=builder ${SOURCE_CODE_PATH}/nginx/objs/ngx_http_lua_module*.so* /usr/lib/nginx/modules/

# COPY Lua Cjson
COPY --from=builder ${COMPILED_INSTALL_PREFIX}/lib/lua/${LUA_VERSION}/cjson*.so* ${COMPILED_INSTALL_PREFIX}/lib/lua/${LUA_VERSION}/

# COPY GeoIp2
COPY --from=builder ${SOURCE_CODE_PATH}/nginx/objs/ngx_stream_geoip2_module*.so* /usr/lib/nginx/modules/

# COPY libmaxminddb
COPY --from=builder ${COMPILED_INSTALL_PREFIX}/lib/libmaxminddb*.so* ${COMPILED_INSTALL_PREFIX}/lib/

# COPY fancyindex
COPY --from=builder ${SOURCE_CODE_PATH}/nginx/objs/ngx_http_fancyindex_module*.so* /usr/lib/nginx/modules/

# COPY headersmore
COPY --from=builder ${SOURCE_CODE_PATH}/nginx/objs/ngx_http_headers_more_filter_module*.so* /usr/lib/nginx/modules/

# COPY rtmp
COPY --from=builder ${SOURCE_CODE_PATH}/nginx/objs/ngx_rtmp_module*.so* /usr/lib/nginx/modules/

# COPY zstd
COPY --from=builder ${SOURCE_CODE_PATH}/nginx/objs/ngx_http_zstd_*_module*.so* /usr/lib/nginx/modules/

# COPY ngx_brotli
COPY --from=builder ${SOURCE_CODE_PATH}/nginx/objs/ngx_http_brotli_*_module*.so* /usr/lib/nginx/modules/

# Copy the crowdsec-nginx-bouncer
# Refer to https://github.com/crowdsecurity/cs-nginx-bouncer/blob/main/install.sh
# The user should handle /etc/crowdsec/bouncers/crowdsec-nginx-bouncer.conf file on there own in the crowdsec image.
ENV CROWDSEC_LIB_PATH=${COMPILED_INSTALL_PREFIX}"/lua/crowdsec"
ARG CROWDSEC_DATA_PATH="/var/lib/crowdsec/lua/"
RUN mkdir -p ${CROWDSEC_LIB_PATH}/plugins/crowdsec/ &&\
mkdir -p ${CROWDSEC_DATA_PATH}/templates/
COPY --from=builder ${SOURCE_CODE_PATH}/cs-nginx-bouncer/nginx/crowdsec_nginx.conf /etc/nginx/conf.d/crowdsec_nginx.conf
COPY --from=builder ${SOURCE_CODE_PATH}/cs-nginx-bouncer/lua-mod/lib ${CROWDSEC_LIB_PATH}
COPY --from=builder ${SOURCE_CODE_PATH}/cs-nginx-bouncer/lua-mod/templates/ ${CROWDSEC_DATA_PATH}/templates/

# COPY Lua Modules
COPY --from=builder ${LUA_MODULE_PATH}/lib/lua/${LUA_VERSION}/ ${LUA_MODULE_PATH}/lib/lua/${LUA_VERSION}

# Fresh .so file cache
RUN ldconfig