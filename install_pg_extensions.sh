#!/bin/bash
set -euxo pipefail

# calling syntax: install_pg_extensions.sh [extension1] [extension2] ...

# install extensions
EXTENSIONS="$@"
# cycle through extensions list
for EXTENSION in ${EXTENSIONS}; do    
    # special case: timescaledb
    if [ "$EXTENSION" == "timescaledb" ]; then
        # dependencies
        apt-get install apt-transport-https lsb-release wget -y

        # repository
        echo "deb https://packagecloud.io/timescale/timescaledb/debian/" \
            "$(lsb_release -c -s) main" \
            > /etc/apt/sources.list.d/timescaledb.list

        # key
        wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey \
            | gpg --dearmor > /etc/apt/trusted.gpg.d/timescaledb.gpg
        
        apt-get update
        apt-get install --yes \
            timescaledb-tools \
            timescaledb-toolkit-postgresql-${PG_MAJOR} \
            timescaledb-2-loader-postgresql-${PG_MAJOR} \
            timescaledb-2-${TIMESCALEDB_VERSION}-postgresql-${PG_MAJOR}

        # cleanup
        apt-get remove apt-transport-https lsb-release wget --auto-remove -y

        continue
    fi

    # special case: vector.rs
    if [ "$EXTENSION" == "vecto.rs" ]; then
        # pgvector.rs is offered as a deb package but not via a repository
        apt-get install apt-transport-https lsb-release wget -y

        ARCH=$(dpkg --print-architecture)

        wget --quiet https://github.com/tensorchord/pgvecto.rs/releases/download/v${VECTORS_VERSION}/vectors-pg${PG_MAJOR}_${VECTORS_VERSION}_${ARCH}.deb \
            -O vectors-pg.deb
        wget --quiet https://github.com/tensorchord/pgvecto.rs/releases/download/v${VECTORS_VERSION}/vectors-pg${PG_MAJOR}_${VECTORS_VERSION}_${ARCH}_extensions.deb \
            -O vectors-pg_extensions.deb
        wget --quiet https://github.com/tensorchord/pgvecto.rs/releases/download/v${VECTORS_VERSION}/vectors-pg${PG_MAJOR}_${VECTORS_VERSION}_${ARCH}_public.deb \
            -O vectors-pg_public.deb
        wget --quiet https://github.com/tensorchord/pgvecto.rs/releases/download/v${VECTORS_VERSION}/vectors-pg${PG_MAJOR}_${VECTORS_VERSION}_${ARCH}_vectors.deb \
            -O vectors-pg_vectors.deb

        dpkg -i vectors-pg*.deb

        # cleanup
        apt-get remove apt-transport-https lsb-release wget --auto-remove -y

        continue
    fi


    # is it an extension found in apt?
    if apt-cache show "postgresql-${PG_MAJOR}-${EXTENSION}" &> /dev/null; then
        # install the extension
        apt-get install -y "postgresql-${PG_MAJOR}-${EXTENSION}"
        continue
    fi

    # extension not found/supported
    echo "Extension '${EXTENSION}' not found/supported"
    exit 1
done
