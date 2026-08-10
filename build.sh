#!/bin/sh

# ARG BASE_IMAGE=docker.io/library/nginx
# ARG BASE_IMAGE_TAG=mainline

# ARG BUILD_BASE_IMAGE=docker.io/library/nginx
# ARG BUILD_BASE_IMAGE_TAG=mainline

# ARG SOURCE_CODE_PATH=/usr/src
# ARG NGINX_PREFIX=/etc/nginx
# ARG LUA_MODULE_PATH=${NGINX_PREFIX}/lua
# ARG COMPILED_INSTALL_PREFIX=/usr/local

# If the user is in an environment where GitHub is blocked, they can use a mirror by setting this ARG. (If they can find a mirror.)
# ARG GITHUB_URL=github.com
# ARG GITHUB_API_URL=api.${GITHUB_URL}

# ARG CUSTOM_PRE_BUILD_CMD=":"

${CUSTOM_PRE_BUILD_CMD}

### ----------
### FUNCTIONS
### ----------

print_info() {
    case "${PRINT_INFO}" in
        "true"|"True")
        printf "\033[32m[INFO]\033[0m %s \n" "${1}"
        ;;
    esac
}

print_warning() {
    printf "\033[33m[WARNING]\033[0m %s \n" "${1}"
}

print_error() {
    printf "\033[31m[ERROR]\033[0m %s \n" "${1}"
}

print_error_exit(){
    print_error "${1}"
    exit "${2}"
}

branch_empty_notice(){
    print_error_exit "${1} is required. Please set ${1} to a valid branch name." "2"
}

arg_empty_notice(){
    print_error_exit "${1} ${2} required. Please set ${1} to a valid ${3}."
}

if_invalid_notice(){
    print_error_exit "${1} must be set to either \"true\", \"True\", \"false\", or \"False\". Other values are not accepted." "2"
}

git_clone(){
    print_info "Downloading ${2}, branch ${1}, into ${SOURCE_CODE_PATH}/${3}/"
    git clone --recurse-submodules -j8 --depth 1 --single-branch --branch "${1}" "${2}" "${SOURCE_CODE_PATH}/${3}/"
}

get_releases(){

    # 1. Get releases from api
    # 2. Use jq to extract the required download URL
    # 3. Use curl to download the file
    # 4. Check digest
    # 5. Retry if not correct
    # 6. Fail if the second attempt fails

    print_info "Downloading ${1} release tag ${2}, into ${SOURCE_CODE_PATH}/${3}, ${4}"

    __github_api_key_result="$(curl -fsSL "https://${GITHUB_API_URL}/repos/${1}/releases/${2}")"
    
    curl -LSo "/tmp/__${2}_${3}_releases.tar.gz" "$(printf "%s \n" "${__github_api_key_result}" | jq -r '.assets[0].browser_download_url')"

    # REMEMBER: ${1} includes a path separator!
    printf "%s  %s" "$(printf "%s \n" "${__github_api_key_result}" | jq -r '.assets[0].digest'| cut -d ':' -f 2)" "/tmp/__${2}_${3}_releases.tar.gz" > "/tmp/__${2}_${3}.sha256"


    if ! sha256sum -c "/tmp/__${2}_${3}.sha256"; then
        case "${4}" in
            "")
            print_warning "We detected a checksum mismatch. Retrying"
            get_releases "${1}" "${2}" "${3}" "__retry"
            ;;
            "__retry")
            print_error_exit "We have a problem downloading repo ${1} release tag ${2}. The checksum does not match. Please check your Internet connection or run this script again." "1"
            ;;
        esac
    fi

    mkdir -p "${SOURCE_CODE_PATH}/${3}"
    tar -xf "/tmp/__${2}_${3}_releases.tar.gz"  -C "${SOURCE_CODE_PATH}/${3}/" --strip-components=1
    
}

print_info "Hello!"

case "${QUIT_WHEN_ERROR}" in
    "true"|"True")
    # Exit when error
    set -e
    ;;
    *)
    set +e
esac

# ARG PACKAGE_MANAGER=apt-get
# ARG CUSTOM_PACKAGE_MIRROR_SETUP=":"

"${CUSTOM_PACKAGE_MIRROR_SETUP}"

if [ -z "${PACKAGE_MANAGER}" ]; then
    arg_empty_notice "PACKAGE_MANAGER" "a" "package manager"
fi

if [ -z "${SOURCE_CODE_PATH}" ] || [ -z "${NGINX_PREFIX}" ] || [ -z "${LUA_MODULE_PATH}" ] || [ -z "${COMPILED_INSTALL_PREFIX}" ]; then
    arg_empty_notice "All of SOURCE_CODE_PATH, NGINX_PREFIX, LUA_MODULE_PATH, or COMPILED_INSTALL_PREFIX" "are" "path"
else
    mkdir -p "${SOURCE_CODE_PATH}"
    mkdir -p "${NGINX_PREFIX}"
    mkdir -p "${LUA_MODULE_PATH}"
    mkdir -p "${COMPILED_INSTALL_PREFIX}"
fi


case "${PACKAGE_MANAGER}" in
    "apt-get"|"apt")
    "${PACKAGE_MANAGER}" update -y
    "${PACKAGE_MANAGER}" upgrade -y
    "${PACKAGE_MANAGER}" install --no-install-recommends --no-install-suggests -y \
    curl \
    jq \
    tar \
    git \
    golang \
    gcc \
    make \
    libc6-dev \
    libtool \
    libpcre2-dev \
    libssl-dev \
    apt-utils \
    autoconf \
    automake \
    build-essential \
    libcurl4-openssl-dev \
    libgeoip-dev \
    liblmdb-dev \
    libxml2-dev \
    libyajl-dev \
    pkgconf \
    zlib1g-dev \
    libzstd-dev  \
    libxml2-dev \
    libxslt1-dev \
    ca-certificates # \
    # wget \
    ;;

    "apk")
    "${PACKAGE_MANAGER}" update
    "${PACKAGE_MANAGER}" add --no-cache --virtual .build-deps \
    curl \
    jq \
    tar \
    git \
    go \
    gcc \
    g++ \
    make \
    musl-dev \
    libtool \
    build-base \
    curl-dev \
    geoip-dev \
    lmdb-dev \
    pcre-dev \
    pcre2-dev \
    libxml2-dev \
    yajl-dev \
    pkgconf \
    zlib-dev \
    zlib-dev \
    openssl-dev \
    linux-headers \
    autoconf \
    m4 \
    automake \
    zstd-dev \
    libxml2-dev \
    libxslt-dev \
    ca-certificates #\
    # bash \
    # wget
    ;;

    "dnf")
    print_warning "This part has not been tested and is very likely to fail."
    # Never tested
    "${PACKAGE_MANAGER}" update -y
    "${PACKAGE_MANAGER}" install -y \
    curl \
    jq \
    tar \
    git \
    golang \
    gcc \
    gcc-c++ \
    make \
    glibc-devel \
    libtool \
    pcre2-devel \
    zlib-devel \
    openssl-devel \
    autoconf \
    automake \
    libcurl-devel \
    GeoIP-devel \
    lmdb-devel \
    pcre-devel \
    yajl-devel \
    pkgconf \
    zlib-devel \
    libzstd-devel \
    libxml2-devel \
    libxslt-devel \
    ca-certificates # \
    # wget \
    ;;

    "skip")
    :
    ;;

    *)
    print_warning "${PACKAGE_MANAGER} is unsupported, we will try, but it is very likely to fail."
    "${PACKAGE_MANAGER}" update
    "${PACKAGE_MANAGER}" install -y \
    curl \
    jq \
    git \
    golang \
    gcc \
    make \
    libc6-dev \
    libtool \
    libpcre2-dev \
    zlib1g-dev \
    libssl-dev \
    autoconf \
    automake \
    build-essential \
    libcurl4-openssl-dev \
    libgeoip-dev \
    liblmdb-dev \
    libpcre++-dev \
    libxml2-dev \
    libyajl-dev \
    pkgconf \
    libzstd-dev \
    ca-certificates #\
    # wget \
    ;;

esac

# --- Compiling and Installing Coraza for NGINX ---
# Download and build https://github.com/corazawaf/libcoraza
# ARG IF_LIBCORAZA=true
# ARG LIBCORAZA_BRANCH=main

case "${IF_LIBCORAZA}" in

    "true"|"True")

    case "${LIBCORAZA_BRANCH}" in
        "")
        branch_empty_notice "LIBCORAZA_BRANCH"
        ;;
        "latest"|"master"|"default")
        # Rewrite non-standard branch name
        export LIBCORAZA_BRANCH=main
        ;;
        *)
        # Keep user-provided branch
        :
        ;;
    esac

    git_clone "${LIBCORAZA_BRANCH}" "https://${GITHUB_URL}/corazawaf/libcoraza.git" "libcoraza"

    cd "${SOURCE_CODE_PATH}/libcoraza"

    ./build.sh
    ./configure --prefix="${COMPILED_INSTALL_PREFIX}"
    make -j"$(nproc)"
    make install

    ;;

    "false"|"False")
    :
    ;;

    *)
    if_invalid_notice "IF_LIBCORAZA"
    ;;

esac

# Download https://github.com/corazawaf/coraza-nginx
# ARG CORAZA_NGINX_BRANCH=main
# ARG IF_CORAZA_NGINX=true
cd "${SOURCE_CODE_PATH}/"

case "${IF_CORAZA_NGINX}" in 
    "true"|"True")

    case "${CORAZA_NGINX_BRANCH}" in 
        "")
        branch_empty_notice "CORAZA_NGINX_BRANCH"
        ;;
        "latest"|"master"|"default")
        # Rewrite non-standard branch name
        export CORAZA_NGINX_BRANCH=main
        ;;
    
    *)
    # Keep user-provided branch
    :
    ;;

    esac

    git_clone "${CORAZA_NGINX_BRANCH}" "https://${GITHUB_URL}/corazawaf/coraza-nginx.git" "coraza-nginx"

    ;;

    "false"|"False")
    :
    ;;

    *)
    if_invalid_notice "IF_CORAZA_NGINX"
    ;;

esac

# Download and Compile the ngx-lua module
# ARG IF_LUAJIT=true
# ARG LUAJIT_BRANCH=v2.1-agentzh

case "${IF_LUAJIT}" in 
    "true"|"True")

    case "${LUAJIT_BRANCH}" in
        "")
        branch_empty_notice "LUAJIT_BRANCH"
        ;;

        "default")
        export LUAJIT_BRANCH=v2.1-agentzh
        ;;

        "master"|"main")
        print_warning "LuaJit does not have a main or master branch, the default branch is v2.1-agentzh. We will still try, but it is very likely to fail."
        ;;

        *)
        # Keep user-provided branch
        :
        ;;

    esac

    git_clone "${LUAJIT_BRANCH}" "https://${GITHUB_URL}/openresty/luajit2.git" "luajit2"

    cd "${SOURCE_CODE_PATH}/luajit2/"

    make -j"$(nproc)" && make install

    ;;

    "false"|"False")
    :
    ;;

    *)
    if_invalid_notice "IF_LUAJIT"
    ;;

esac

# Download the lua modules
# ARG IF_NGX_DEVEL_KIT=true
# ARG NGX_DEVEL_KIT_BRANCH=master

cd "${SOURCE_CODE_PATH}"

case "${IF_NGX_DEVEL_KIT}" in 
    "true"|"True")

    case "${NGX_DEVEL_KIT_BRANCH}" in 
        "")
        branch_empty_notice "NGX_DEVEL_KIT_BRANCH"
        ;;

        "main"|"latest"|"default")
        # Rewrite non-standard branch name
        export NGX_DEVEL_KIT_BRANCH=master
        ;;

        *)
        # Keep user-provided branch
        :
        ;;

    esac

    git_clone "${NGX_DEVEL_KIT_BRANCH}" "https://${GITHUB_URL}/vision5/ngx_devel_kit.git" "ngx_devel_kit"

    ;;

    "false"|"False")
    :
    ;;

    *)
    if_invalid_notice "IF_NGX_DEVEL_KIT"
    ;;

esac

# Download https://github.com/openresty/lua-nginx-module
# ARG IF_LUA_NGINX_MODULE
# ARG LUA_NGINX_MODULE_BRANCH=master

cd "${SOURCE_CODE_PATH}"

case "${IF_LUA_NGINX_MODULE}" in 
    "true"|"True")

    case "${LUA_NGINX_MODULE_BRANCH}" in
        "")
        branch_empty_notice "LUA_NGINX_MODULE_BRANCH"
        ;;
        "main"|"latest"|"default")
        # Rewrite non-standard branch name
        export LUA_NGINX_MODULE_BRANCH=master
        ;;
        *)
        # Keep user-provided branch
        :
        ;;
    esac

    git_clone "${LUA_NGINX_MODULE_BRANCH}" "https://${GITHUB_URL}/openresty/lua-nginx-module.git" "lua-nginx-module"
    ;;

    "false"|"False")
    :
    ;;

    *)
    if_invalid_notice "IF_LUA_NGINX_MODULE"
    ;;
    
esac

# Download https://github.com/openresty/lua-resty-core
# ARG IF_LUA_RESTY_CORE=true
# ARG LUA_RESTY_CORE_BRANCH=master

cd "${SOURCE_CODE_PATH}/"

case "${IF_LUA_RESTY_CORE}" in
    "true"|"True")
    
    case "${LUA_RESTY_CORE_BRANCH}" in
        "")
        branch_empty_notice "LUA_RESTY_CORE_BRANCH"
        ;;
        "main"|"latest"|"default")
        # Rewrite non-standard branch name
        export LUA_RESTY_CORE_BRANCH=master
        ;;
        *)
        # Keep user-provided branch
        :
        ;;
    esac

    git_clone "${LUA_RESTY_CORE_BRANCH}" "https://${GITHUB_URL}/openresty/lua-resty-core.git" "lua-resty-core"

    cd "${SOURCE_CODE_PATH}/lua-resty-core/"

    make install PREFIX="${LUA_MODULE_PATH}"
    ;;

    "false"|"False")
    :
    ;;

    *)
    if_invalid_notice "IF_LUA_RESTY_CORE"
    ;;
esac


cd "${SOURCE_CODE_PATH}/"

# Download https://github.com/openresty/lua-resty-lrucache
# ARG IF_LUA_RESTY_LRUCACHE=true
# ARG LUA_RESTY_LRUCACHE_BRANCH=master

case "${IF_LUA_RESTY_LRUCACHE}" in
    "true"|"True")
    case "${LUA_RESTY_LRUCACHE_BRANCH}" in
        "")
        branch_empty_notice "LUA_RESTY_LRUCACHE_BRANCH"
        ;;
        "main"|"latest"|"default")
        # Rewrite non-standard branch name
        export LUA_RESTY_LRUCACHE_BRANCH=master
        ;;
        *)
        # Keep user-provided branch
        :
        ;;
    esac

    git_clone "${LUA_RESTY_LRUCACHE_BRANCH}" "https://${GITHUB_URL}/openresty/lua-resty-lrucache.git" "lua-resty-lrucache"

    ;;

    "false"|"False")
    :
    ;;

    *)
    if_invalid_notice "IF_LUA_RESTY_LRUCACHE"
    ;;

esac

# Download https://github.com/openresty/lua-resty-lock
# ARG IF_LUA_RESTY_LOCK=true
# ARG LUA_RESTY_LOCK_BRANCH=master

cd "${SOURCE_CODE_PATH}/"

case "${IF_LUA_RESTY_LOCK}" in 
    "true"|"True")
    case "${LUA_RESTY_LOCK_BRANCH}" in
        "")
        branch_empty_notice "LUA_RESTY_LOCK_BRANCH"
        ;;
        
        "main"|"latest"|"default")
        # Rewrite non-standard branch name
        export LUA_RESTY_LOCK_BRANCH=master
        ;;

        *)
        # Keep user-provided branch
        :
        ;;
    esac

    git_clone "${LUA_RESTY_LOCK_BRANCH}" "https://${GITHUB_URL}/openresty/lua-resty-lock.git" "lua-resty-lock"

    cd "${SOURCE_CODE_PATH}/lua-resty-lock"
    
    make install PREFIX="${LUA_MODULE_PATH}"
    ;;

    "false"|"False")
    :
    ;;

    *)
    if_invalid_notice "IF_LUA_RESTY_LOCK"

esac

# Download https://github.com/openresty/lua-resty-limit-traffic
# ARG IF_LUA_RESTY_LIMIT_TRAFFIC=true
# ARG LUA_RESTY_LIMIT_TRAFFIC_BRANCH=master

case "${IF_LUA_RESTY_LIMIT_TRAFFIC}" in
    "true"|"True")

    case "${LUA_RESTY_LIMIT_TRAFFIC_BRANCH}" in
        "")
        branch_empty_notice "LUA_RESTY_LIMIT_TRAFFIC_BRANCH"
        ;;
        "main"|"latest"|"default")
        # Rewrite non-standard branch name
        export LUA_RESTY_LIMIT_TRAFFIC_BRANCH=master
        ;;
        *)
        # Keep user-provided branch
        :
        ;;
    esac

    git_clone "${LUA_RESTY_LIMIT_TRAFFIC_BRANCH}" "https://${GITHUB_URL}/openresty/lua-resty-limit-traffic.git" "lua-resty-limit-traffic"

    cd "${SOURCE_CODE_PATH}/lua-resty-limit-traffic"

    make install PREFIX="${LUA_MODULE_PATH}"
    ;;

    "false"|"False")
    :
    ;;

    *)
    if_invalid_notice "IF_LUA_RESTY_LIMIT_TRAFFIC"
    ;;

esac

# Download https://github.com/openresty/lua-resty-redis
# ARG IF_LUA_RESTY_REDIS=true
# ARG LUA_RESTY_REDIS_BRANCH=master

case "${IF_LUA_RESTY_REDIS}" in
    "true"|"True")

    case "${LUA_RESTY_REDIS_BRANCH}" in
        "")
        branch_empty_notice "LUA_RESTY_REDIS_BRANCH"
        ;;
        "main"|"latest"|"default")
        # Rewrite non-standard branch name
        export LUA_RESTY_REDIS_BRANCH=master
        ;;
        *)
        # Keep user-provided branch
        :
        ;;
    esac

    git_clone "${LUA_RESTY_REDIS_BRANCH}" "https://${GITHUB_URL}/openresty/lua-resty-redis.git" "lua-resty-redis"

    cd "${SOURCE_CODE_PATH}/lua-resty-redis"

    make install PREFIX="${LUA_MODULE_PATH}"
    ;;

    "false"|"False")
    :
    ;;

    *)
    if_invalid_notice "IF_LUA_RESTY_REDIS"
    ;;

esac

# Download https://github.com/cloudflare/lua-resty-cookie
# ARG IF_LUA_RESTY_COOKIE=true
# ARG LUA_RESTY_COOKIE_BRANCH=master

case "${IF_LUA_RESTY_COOKIE}" in
    "true"|"True")

    case "${LUA_RESTY_COOKIE_BRANCH}" in
        "")
        branch_empty_notice "LUA_RESTY_COOKIE_BRANCH"
        ;;
        "main"|"latest"|"default")
        # Rewrite non-standard branch name
        export LUA_RESTY_COOKIE_BRANCH=master
        ;;
        *)
        # Keep user-provided branch
        :
        ;;
    esac

    git_clone "${LUA_RESTY_COOKIE_BRANCH}" "https://${GITHUB_URL}/cloudflare/lua-resty-cookie.git" "lua-resty-cookie"

    cd "${SOURCE_CODE_PATH}/lua-resty-cookie"

    make install PREFIX="${LUA_MODULE_PATH}"
    ;;

    "false"|"False")
    :
    ;;

    *)
    if_invalid_notice "IF_LUA_RESTY_COOKIE"
    ;;

esac

# Download https://github.com/openresty/lua-resty-upstream-healthcheck
# ARG IF_LUA_RESTY_UPSTREAM_HEALTHCHECK=true
# ARG LUA_RESTY_UPSTREAM_HEALTHCHECK_BRANCH=master

case "${IF_LUA_RESTY_UPSTREAM_HEALTHCHECK}" in
    "true"|"True")

    case "${LUA_RESTY_UPSTREAM_HEALTHCHECK_BRANCH}" in
        "")
        branch_empty_notice "LUA_RESTY_UPSTREAM_HEALTHCHECK_BRANCH"
        ;;
        "main"|"latest"|"default")
        # Rewrite non-standard branch name
        export LUA_RESTY_UPSTREAM_HEALTHCHECK_BRANCH=master
        ;;
        *)
        # Keep user-provided branch
        :
        ;;
    esac

    git_clone "${LUA_RESTY_UPSTREAM_HEALTHCHECK_BRANCH}" "https://${GITHUB_URL}/openresty/lua-resty-upstream-healthcheck.git" "lua-resty-upstream-healthcheck"

    cd "${SOURCE_CODE_PATH}/lua-resty-upstream-healthcheck"

    make install PREFIX="${LUA_MODULE_PATH}"
    ;;

    "false"|"False")
    :
    ;;

    *)
    if_invalid_notice "IF_LUA_RESTY_UPSTREAM_HEALTHCHECK"
    ;;

esac

# Download https://github.com/ledgetech/lua-resty-http/
# ARG IF_LUA_RESTY_HTTP=true
# ARG LUA_RESTY_HTTP_BRANCH=master

case "${IF_LUA_RESTY_HTTP}" in
    "true"|"True")

    case "${LUA_RESTY_HTTP_BRANCH}" in
        "")
        branch_empty_notice "LUA_RESTY_HTTP_BRANCH"
        ;;
        "main"|"latest"|"default")
        # Rewrite non-standard branch name
        export LUA_RESTY_HTTP_BRANCH=master
        ;;
        *)
        # Keep user-provided branch
        :
        ;;
    esac

    git_clone "${LUA_RESTY_HTTP_BRANCH}" "https://${GITHUB_URL}/ledgetech/lua-resty-http.git" "lua-resty-http"

    cd "${SOURCE_CODE_PATH}/lua-resty-http"

    make install PREFIX="${LUA_MODULE_PATH}"
    ;;

    "false"|"False")
    :
    ;;

    *)
    if_invalid_notice "IF_LUA_RESTY_HTTP"
    ;;

esac

# Download https://github.com/openresty/lua-resty-string
# ARG IF_LUA_RESTY_STRING=true
# ARG LUA_RESTY_STRING_BRANCH=master

case "${IF_LUA_RESTY_STRING}" in
    "true"|"True")

    case "${LUA_RESTY_STRING_BRANCH}" in
        "")
        branch_empty_notice "LUA_RESTY_STRING_BRANCH"
        ;;
        "main"|"latest"|"default")
        # Rewrite non-standard branch name
        export LUA_RESTY_STRING_BRANCH=master
        ;;
        *)
        # Keep user-provided branch
        :
        ;;
    esac

    git_clone "${LUA_RESTY_STRING_BRANCH}" "https://${GITHUB_URL}/openresty/lua-resty-string.git" "lua-resty-string"

    cd "${SOURCE_CODE_PATH}/lua-resty-string"

    make install PREFIX="${LUA_MODULE_PATH}"
    ;;

    "false"|"False")
    :
    ;;

    *)
    if_invalid_notice "IF_LUA_RESTY_STRING"
    ;;

esac

# Download https://github.com/fffonion/lua-resty-openssl
# ARG IF_LUA_RESTY_OPENSSL=true
# ARG LUA_RESTY_OPENSSL_BRANCH=master

case "${IF_LUA_RESTY_OPENSSL}" in
    "true"|"True")

    case "${LUA_RESTY_OPENSSL_BRANCH}" in
        "")
        branch_empty_notice "LUA_RESTY_OPENSSL_BRANCH"
        ;;
        "main"|"latest"|"default")
        # Rewrite non-standard branch name
        export LUA_RESTY_OPENSSL_BRANCH=master
        ;;
        *)
        # Keep user-provided branch
        :
        ;;
    esac

    git_clone "${LUA_RESTY_OPENSSL_BRANCH}" "https://${GITHUB_URL}/fffonion/lua-resty-openssl.git" "lua-resty-openssl"

    cd "${SOURCE_CODE_PATH}/lua-resty-openssl"

    make install PREFIX="${LUA_MODULE_PATH}"
    ;;

    "false"|"False")
    :
    ;;

    *)
    if_invalid_notice "IF_LUA_RESTY_OPENSSL"
    ;;

esac

# Download https://github.com/bungle/lua-resty-session
# ARG IF_LUA_RESTY_SESSION=true
# ARG LUA_RESTY_SESSION_BRANCH=master

case "${IF_LUA_RESTY_SESSION}" in
    "true"|"True")

    case "${LUA_RESTY_SESSION_BRANCH}" in
        "")
        branch_empty_notice "LUA_RESTY_SESSION_BRANCH"
        ;;
        "main"|"latest"|"default")
        # Rewrite non-standard branch name
        export LUA_RESTY_SESSION_BRANCH=master
        ;;
        *)
        # Keep user-provided branch
        :
        ;;
    esac

    git_clone "${LUA_RESTY_SESSION_BRANCH}" "https://${GITHUB_URL}/bungle/lua-resty-session.git" "lua-resty-session"

    cd "${SOURCE_CODE_PATH}/lua-resty-session"

    mkdir -p "${LUA_MODULE_PATH}/lib/lua/${LUA_VERSION}/resty/session/"
    cp -r lib/resty/session/* "${LUA_MODULE_PATH}/lib/lua/${LUA_VERSION}/resty/session/"

    ;;

    "false"|"False")
    :
    ;;

    *)
    if_invalid_notice "IF_LUA_RESTY_SESSION"
    ;;

esac

# Download https://github.com/cdbattags/lua-resty-jwt
# ARG IF_LUA_RESTY_JWT=true
# ARG LUA_RESTY_JWT_BRANCH=master

case "${IF_LUA_RESTY_JWT}" in
    "true"|"True")

    case "${LUA_RESTY_JWT_BRANCH}" in
        "")
        branch_empty_notice "LUA_RESTY_JWT_BRANCH"
        ;;
        "main"|"latest"|"default")
        # Rewrite non-standard branch name
        export LUA_RESTY_JWT_BRANCH=master
        ;;
        *)
        # Keep user-provided branch
        :
        ;;
    esac

    git_clone "${LUA_RESTY_JWT_BRANCH}" "https://${GITHUB_URL}/cdbattags/lua-resty-jwt.git" "lua-resty-jwt"

    cd "${SOURCE_CODE_PATH}/lua-resty-jwt"

    mkdir -p "${LUA_MODULE_PATH}/lib/lua/${LUA_VERSION}/resty/"
    cp -r lib/resty/* "${LUA_MODULE_PATH}/lib/lua/${LUA_VERSION}/resty/"

    ;;

    "false"|"False")
    :
    ;;

    *)
    if_invalid_notice "IF_LUA_RESTY_JWT"
    ;;

esac

# Download and Compile https://github.com/mpx/lua-cjson, but using the https://github.com/openresty/lua-cjson/ fork
# ARG IF_LUA_CJSON=true
# ARG LUA_CJSON_BRANCH=master
cd "${SOURCE_CODE_PATH}/"

case "${IF_LUA_CJSON}" in 
    "true"|"True")
    case "${LUA_CJSON_BRANCH}" in 
        "")
        branch_empty_notice "LUA_CJSON_BRANCH"
        ;;
        "main"|"latest"|"default")
        # Rewrite non-standard branch name
        export LUA_CJSON_BRANCH=master
        ;;
        *)
        # Keep user-provided branch
        :
        ;;
    esac

    git_clone "${LUA_CJSON_BRANCH}" "https://${GITHUB_URL}/openresty/lua-cjson.git" "lua-cjson"

    cd "${SOURCE_CODE_PATH}/lua-cjson/"

    make -j"$(nproc)" \
    LUA_VERSION="${LUA_VERSION}" \
    CFLAGS="-O3 -Wall -pedantic -DNDEBUG -I ${COMPILED_INSTALL_PREFIX}/include/luajit-2.1" \
    PREFIX="${COMPILED_INSTALL_PREFIX}"

    make install

    ;;

    "false"|"False")
    :
    ;;

    *)
    if_invalid_notice "IF_LUA_CJSON"
    ;;
esac

# Download https://github.com/leev/ngx_http_geoip2_module
# ARG IF_NGX_HTTP_GEOIP2_MODULE=true
# ARG NGX_HTTP_GEOIP2_MODULE_BRANCH=master
cd "${SOURCE_CODE_PATH}/"
case "${IF_NGX_HTTP_GEOIP2_MODULE}" in 
    "true"|"True")
    case "${NGX_HTTP_GEOIP2_MODULE_BRANCH}" in 
        "")
        branch_empty_notice "NGX_HTTP_GEOIP2_MODULE_BRANCH"
        ;;
        "main"|"latest"|"default")
        # Rewrite non-standard branch name
        export NGX_HTTP_GEOIP2_MODULE_BRANCH=master
        ;;
        *)
        # Keep user-provided branch
        :
        ;;
    esac

    git_clone "${NGX_HTTP_GEOIP2_MODULE_BRANCH}" "https://${GITHUB_URL}/leev/ngx_http_geoip2_module.git" "ngx_http_geoip2_module"

    ;;

    "false"|"False")
    :
    ;;

    *)
    if_invalid_notice "IF_NGX_HTTP_GEOIP2_MODULE"
    ;;
esac


# Download and Compile https://github.com/maxmind/libmaxminddb
# ARG IF_LIBMAXMINDDB=true
# ARG LIBMAXMINDDB_VERSION=master

cd "${SOURCE_CODE_PATH}/"

case "${IF_LIBMAXMINDDB}" in 
    "true"|"True")
    case "${LIBMAXMINDDB_VERSION}" in 
        "")
        branch_empty_notice "LIBMAXMINDDB_VERSION"
        ;;
        "master"|"main"|"default")
        # Rewrite non-standard release tag name
        export LIBMAXMINDDB_VERSION=latest
        ;;
        *)
        # Keep user-provided tag 
        :
        ;;
    esac

    get_releases "maxmind/libmaxminddb" "${LIBMAXMINDDB_VERSION}" "libmaxminddb"

    cd "${SOURCE_CODE_PATH}/libmaxminddb/"

    # ./bootstrap
    ./configure --prefix="${COMPILED_INSTALL_PREFIX}"
    make -j"$(nproc)"
    make check
    make install

    ;;

    "false"|"False")
    :
    ;;

    *)
    if_invalid_notice "IF_LIBMAXMINDDB"
    ;;
esac

# Download https://github.com/aperezdc/ngx-fancyindex
# ARG IF_NGX_FANCYINDEX=true
# ARG NGX_FANCYINDEX_BRANCH=master

case "${IF_NGX_FANCYINDEX}" in 
    "true"|"True")

    case "${NGX_FANCYINDEX_BRANCH}" in 
        "")
        branch_empty_notice "NGX_FANCYINDEX_BRANCH"
        ;;

        "main"|"latest"|"default")
        # Rewrite non-standard branch name
        export NGX_FANCYINDEX_BRANCH=master
        ;;

        *)
        # Keep user-provided branch
        :
        ;;
    esac

    git_clone "${NGX_FANCYINDEX_BRANCH}" "https://${GITHUB_URL}/aperezdc/ngx-fancyindex.git" "ngx-fancyindex"

    ;;

    "false"|"False")
    :    
    ;;

    *)
    if_invalid_notice "IF_NGX_FANCYINDEX"
    ;;
esac

# Download https://github.com/nginx/njs
# ARG IF_NJS=true
# ARG NJS_BRANCH=master

case "${IF_NJS}" in 
    "true"|"True")

    case "${NJS_BRANCH}" in 
        "")
        branch_empty_notice "NJS_BRANCH"
        ;;

        "main"|"latest"|"default")
        # Rewrite non-standard branch name
        export NJS_BRANCH=master
        ;;

        *)
        # Keep user-provided branch
        :
        ;;
    esac

    git_clone "${NJS_BRANCH}" "https://${GITHUB_URL}/nginx/njs.git" "njs"

    cd "${SOURCE_CODE_PATH}/njs/"

    ;;

    "false"|"False")
    :    
    ;;

    *)
    if_invalid_notice "IF_NJS"
    ;;
esac


# Download https://github.com/openresty/headers-more-nginx-module
# ARG IF_HEADERS_MORE_NGINX_MODULE=true
# ARG HEADERS_MORE_NGINX_MODULE_BRANCH=master

cd "${SOURCE_CODE_PATH}/"

case "${IF_HEADERS_MORE_NGINX_MODULE}" in 
    "true"|"True")

    case "${HEADERS_MORE_NGINX_MODULE_BRANCH}" in 
        "")
        branch_empty_notice "HEADERS_MORE_NGINX_MODULE_BRANCH"
        ;;

        "main"|"latest"|"default")
        # Rewrite non-standard branch name
        export HEADERS_MORE_NGINX_MODULE_BRANCH=master
        ;;

        *)
        # Keep user-provided branch
        :
        ;;
    esac

    git_clone "${HEADERS_MORE_NGINX_MODULE_BRANCH}" "https://${GITHUB_URL}/openresty/headers-more-nginx-module.git" "headers-more-nginx-module"

    ;;

    "false"|"False")
    :    
    ;;

    *)
    if_invalid_notice "IF_HEADERS_MORE_NGINX_MODULE"
    ;;
esac

# Download https://github.com/arut/nginx-rtmp-module
# ARG IF_NGINX_RTMP_MODULE=true
# ARG NGINX_RTMP_MODULE_BRANCH=master

case "${IF_NGINX_RTMP_MODULE}" in 
    "true"|"True")

    case "${NGINX_RTMP_MODULE_BRANCH}" in 
        "")
        branch_empty_notice "NGINX_RTMP_MODULE_BRANCH"
        ;;

        "main"|"latest"|"default")
        # Rewrite non-standard branch name
        export NGINX_RTMP_MODULE_BRANCH=master
        ;;

        *)
        # Keep user-provided branch
        :
        ;;
    esac

    git_clone "${NGINX_RTMP_MODULE_BRANCH}" "https://${GITHUB_URL}/arut/nginx-rtmp-module.git" "nginx-rtmp-module"

    ;;

    "false"|"False")
    :    
    ;;

    *)
    if_invalid_notice "IF_NGINX_RTMP_MODULE"
    ;;
esac

# Download https://github.com/tokers/zstd-nginx-module
# ARG IF_ZSTD_NGINX_MODULE=true
# ARG ZSTD_NGINX_MODULE_BRANCH=master

case "${IF_ZSTD_NGINX_MODULE}" in 
    "true"|"True")

    case "${ZSTD_NGINX_MODULE_BRANCH}" in 
        "")
        branch_empty_notice "ZSTD_NGINX_MODULE_BRANCH"
        ;;

        "main"|"latest"|"default")
        # Rewrite non-standard branch name
        export ZSTD_NGINX_MODULE_BRANCH=master
        ;;

        *)
        # Keep user-provided branch
        :
        ;;
    esac

    git_clone "${ZSTD_NGINX_MODULE_BRANCH}" "https://${GITHUB_URL}/tokers/zstd-nginx-module.git" "zstd-nginx-module"

    ;;

    "false"|"False")
    :    
    ;;

    *)
    if_invalid_notice "IF_ZSTD_NGINX_MODULE"
    ;;
esac

# Download https://github.com/google/ngx_brotli
# ARG IF_NGX_BROTLI=true
# ARG NGX_BROTLI_BRANCH=master
case "${IF_NGX_BROTLI}" in 
    "true"|"True")

    case "${NGX_BROTLI_BRANCH}" in 
        "")
        branch_empty_notice "NGX_BROTLI_BRANCH"
        ;;

        "main"|"latest"|"default")
        # Rewrite non-standard branch name
        export NGX_BROTLI_BRANCH=master
        ;;

        *)
        # Keep user-provided branch
        :
        ;;
    esac

    git_clone "${NGX_BROTLI_BRANCH}" "https://${GITHUB_URL}/google/ngx_brotli.git" "ngx_brotli"

    ;;

    "false"|"False")
    :    
    ;;

    *)
    if_invalid_notice "IF_NGX_BROTLI"
    ;;
esac

# Download https://github.com/crowdsecurity/cs-nginx-bouncer
# ARG IF_CROWDSEC_NGINX_BOUNCER=true
# ARG CROWDSEC_NGINX_BOUNCER_VERSION=latest

cd "${SOURCE_CODE_PATH}/"

case "${IF_CROWDSEC_NGINX_BOUNCER}" in 
    "true"|"True")

    case "${CROWDSEC_NGINX_BOUNCER_VERSION}" in 
        "")
        branch_empty_notice "CROWDSEC_NGINX_BOUNCER_VERSION"
        ;;

        "main"|"master"|"default")
        # Rewrite non-standard release tag name
        export CROWDSEC_NGINX_BOUNCER_VERSION=latest
        ;;

        *)
        # Keep user-provided tag
        :
        ;;
    esac

    get_releases "crowdsecurity/cs-nginx-bouncer" "${CROWDSEC_NGINX_BOUNCER_VERSION}" "cs-nginx-bouncer"
    ;;

    "false"|"False")
    :    
    ;;

    *)
    if_invalid_notice "IF_CROWDSEC_NGINX_BOUNCER"
    ;;
esac

#### Download, Compile and Install NGINX
# ARG IF_NGINX=true
# ARG DEFAULT_NGINX_VERSION=1.31.3
# ARG LUAJIT_LIB=${COMPILED_INSTALL_PREFIX}/lib
# ARG LUAJIT_INC=${COMPILED_INSTALL_PREFIX}/include/luajit-2.1
# ARG FORCE_NGINX_VERSION=""
# ARG CONFIGURE_FLAGS="--prefix=${NGINX_PREFIX} --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/run/nginx.pid --lock-path=/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nginx --group=nginx --with-compat --with-file-aio --with-threads --with-http_addition_module --with-http_auth_request_module --with-http_dav_module --with-http_flv_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_mp4_module --with-http_random_index_module --with-http_realip_module --with-http_secure_link_module --with-http_slice_module --with-http_ssl_module --with-http_stub_status_module --with-http_sub_module --with-http_v2_module --with-http_v3_module --with-mail --with-mail_ssl_module --with-stream --with-stream_realip_module --with-stream_ssl_module --with-stream_ssl_preread_module --with-cc-opt='-g -O2 -Werror=implicit-function-declaration -fstack-protector-strong -fstack-clash-protection -Wformat -Werror=format-security -fcf-protection -Wp,-D_FORTIFY_SOURCE=2 -fPIC' --with-ld-opt='-Wl,-z,relro -Wl,-z,now -Wl,--as-needed -pie"
# ARG NGINX_MODULE_OPTION="-dynamic"
# ARG NGINX_MAKE_OPTION="modules"

cd "${SOURCE_CODE_PATH}/"

case "${IF_NGINX}" in 
    "true"|"True")

    if [ -n "${FORCE_NGINX_VERSION}" ]; then
        export NGINX_VERSION="${FORCE_NGINX_VERSION}"
    elif [ -z "${NGINX_VERSION}" ]; then
        export NGINX_VERSION="${DEFAULT_NGINX_VERSION}"
    fi

    curl -LSo "${SOURCE_CODE_PATH}/__nginx_${NGINX_VERSION}.tar.gz" "https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"
    mkdir -p "${SOURCE_CODE_PATH}/Nginx"
    tar -xf "${SOURCE_CODE_PATH}/__nginx_${NGINX_VERSION}.tar.gz" -C "${SOURCE_CODE_PATH}/Nginx" --strip-components=1
    
    cd "${SOURCE_CODE_PATH}/Nginx"

    case "${IF_CORAZA_NGINX}" in
        "true"|"True")
        export INTERNAL_CORAZA_CONFIG_COMMAND="--add${NGINX_MODULE_OPTION}-module=${SOURCE_CODE_PATH}/coraza-nginx"
        ;;
    esac

    case "${IF_NGX_DEVEL_KIT}" in
        "true"|"True")
        export INTERNAL_NGX_DEVEL_KIT_CONFIG_COMMAND="--add${NGINX_MODULE_OPTION}-module=${SOURCE_CODE_PATH}/ngx_devel_kit/"
        ;;
    esac

    case "${IF_LUA_NGINX_MODULE}" in 
        "true"|"True")
        export INTERNAL_LUA_NGINX_MODULE_CONFIG_COMMAND="--add${NGINX_MODULE_OPTION}-module=${SOURCE_CODE_PATH}/lua-nginx-module"
        ;;
    esac

    case "${IF_NGX_HTTP_GEOIP2_MODULE}" in
        "true"|"True")
        export INTERNAL_NGX_HTTP_GEOIP2_MODULE_CONFIG_COMMAND="--add${NGINX_MODULE_OPTION}-module=${SOURCE_CODE_PATH}/ngx_http_geoip2_module"
        ;;
    esac

    case "${IF_NGX_FANCYINDEX}" in
        "true"|"True")
        export INTERNAL_NGX_FANCYINDEX_CONFIG_COMMAND="--add${NGINX_MODULE_OPTION}-module=${SOURCE_CODE_PATH}/ngx-fancyindex"
        ;;
    esac

    case "${IF_NJS}" in
        "true"|"True")
        export INTERNAL_NJS_CONFIG_COMMAND="--add${NGINX_MODULE_OPTION}-module=${SOURCE_CODE_PATH}/njs/nginx"
        # NJS enables QuickJS by default. We do not need QuickJS.
        # Refer to to https://github.com/nginx/njs/blob/master/nginx/config
        export NJS_QUICKJS=NO
        ;;
    esac

    case "${IF_HEADERS_MORE_NGINX_MODULE}" in
        "true"|"True")
        export INTERNAL_HEADERS_MORE_NGINX_MODULE_CONFIG_COMMAND="--add${NGINX_MODULE_OPTION}-module=${SOURCE_CODE_PATH}/headers-more-nginx-module"
        ;;
    esac

    case "${IF_NGINX_RTMP_MODULE}" in
        "true"|"True")
        export INTERNAL_NGINX_RTMP_MODULE_CONFIG_COMMAND="--add${NGINX_MODULE_OPTION}-module=${SOURCE_CODE_PATH}/nginx-rtmp-module"
        ;;
    esac

    case "${IF_ZSTD_NGINX_MODULE}" in
        "true"|"True")
        export INTERNAL_ZSTD_NGINX_MODULE_CONFIG_COMMAND="--add${NGINX_MODULE_OPTION}-module=${SOURCE_CODE_PATH}/zstd-nginx-module"
        ;;
    esac

    case "${IF_NGX_BROTLI}" in
        "true"|"True")
        export INTERNAL_NGX_BROTLI_CONFIG_COMMAND="--add${NGINX_MODULE_OPTION}-module=${SOURCE_CODE_PATH}/ngx_brotli"
        ;;
    esac
    
    # shellcheck disable=SC2086
    # CONFIGURE_FLAGS intentionally contains multiple arguments. Word splitting is required to pass each configure option separately, and empty optional arguments are ignored.
    ./configure ${CONFIGURE_FLAGS} --with-cc-opt='-g -O2 -Werror=implicit-function-declaration -fstack-protector-strong -fstack-clash-protection -Wformat -Werror=format-security -fcf-protection -Wp,-D_FORTIFY_SOURCE=2 -fPIC' --with-ld-opt='-Wl,-z,relro -Wl,-z,now -Wl,--as-needed -pie' \
    ${INTERNAL_CORAZA_CONFIG_COMMAND} \
    ${INTERNAL_NGX_DEVEL_KIT_CONFIG_COMMAND} \
    ${INTERNAL_LUA_NGINX_MODULE_CONFIG_COMMAND} \
    ${INTERNAL_NGX_HTTP_GEOIP2_MODULE_CONFIG_COMMAND} \
    ${INTERNAL_NGX_FANCYINDEX_CONFIG_COMMAND} \
    ${INTERNAL_NJS_CONFIG_COMMAND} \
    ${INTERNAL_HEADERS_MORE_NGINX_MODULE_CONFIG_COMMAND} \
    ${INTERNAL_NGINX_RTMP_MODULE_CONFIG_COMMAND} \
    ${INTERNAL_ZSTD_NGINX_MODULE_CONFIG_COMMAND} \
    ${INTERNAL_NGX_BROTLI_CONFIG_COMMAND}

    make -j"$(nproc)" "${NGINX_MAKE_OPTION}"
    
    ;;
    "false"|"False")
    print_warning "You have chosen not to compile Nginx. Please make sure this is intentional."
    ;;
    *)
    if_invalid_notice "IF_NGINX"
    ;;
esac


# Clean up
# ARG IF_CLEANUP=true
# This is in the builder stage, so we don't have to clean up, but we should.

case "${IF_CLEANUP}" in
    "true"|"True")
    case "${PACKAGE_MANAGER}" in
        "apt-get"|"apt")
        "${PACKAGE_MANAGER}" remove --purge --auto-remove -y \
        curl \
        jq \
        git \
        golang \
        gcc \
        make \
        libc6-dev \
        libtool \
        libpcre2-dev \
        zlib1g-dev \
        libssl-dev \
        apt-utils \
        autoconf \
        automake \
        build-essential \
        libcurl4-openssl-dev \
        libgeoip-dev \
        liblmdb-dev \
        libxml2-dev \
        libyajl-dev \
        pkgconf \
        libzstd-dev \
        libxml2-dev \
        libxslt1-dev \
        ca-certificates #\
        # wget \
        rm -rf /var/lib/apt/lists/* /etc/apt/sources.list.d/nginx.list
        ;;
        "apk")
        apk del .build-deps
        ;;
        "dnf")
        # Never tested
        "${PACKAGE_MANAGER}" remove -y \
        jq \
        tar \
        git \
        golang \
        gcc \
        gcc-c++ \
        make \
        glibc-devel \
        libtool \
        autoconf \
        automake \
        libcurl-devel \
        GeoIP-devel \
        lmdb-devel \
        pcre-devel \
        yajl-devel \
        zlib-devel \
        libzstd-devel \
        libxml2-devel \
        libxslt-devel \
        pcre2-devel #\
        # wget \
        "${PACKAGE_MANAGER}" clean all
        ;;

        "skip")
        :
        ;;

        *)
        print_warning "${PACKAGE_MANAGER} is unsupported, we will try, but it is very likely to fail."
        # Clean Up, so errors don't really matters.
        set +e
        "${PACKAGE_MANAGER}" remove -y \
        curl \
        jq \
        git \
        golang \
        gcc \
        make \
        libc6-dev \
        libtool \
        libpcre2-dev \
        zlib1g-dev \
        libssl-dev \
        autoconf \
        automake \
        build-essential \
        libcurl4-openssl-dev \
        libgeoip-dev \
        liblmdb-dev \
        libpcre++-dev \
        libxml2-dev \
        libyajl-dev \
        libzstd-dev \
        pkgconf \
        ca-certificates #\
        # wget \
        "${PACKAGE_MANAGER}" clean

        case "${QUIT_WHEN_ERROR}" in
            "true"|"True")
            # Exit when error
            set -e
            ;;
            *)
            set +e
        esac
        ;;
    esac

    # Clean up /tmp
    rm -rf /tmp/*
    # Delete the script itself.
    rm -rf "$0"
    ;;

esac

ldconfig

# ARG CUSTOM_EXIT_CMD=":"

${CUSTOM_EXIT_CMD}

print_info "Goodbye!"