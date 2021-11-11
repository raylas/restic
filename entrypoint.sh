#!/usr/bin/env bash

# Parse _FILE suffixed variables
file_env() {
    local var="$1"
    local fileVar="${var}_FILE"
    local def="${2:-}"
    if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
        echo ":: Both $var and $fileVar are set (but are exclusive)"
    fi
    local val="$def"
    if [ "${!var:-}" ]; then
        val="${!var}"
    elif [ "${!fileVar:-}" ]; then
        val="$(< "${!fileVar}")"
    fi
    export "$var"="$val"
    unset "$fileVar"
}

echo ":: Starting container"

echo ":: Setting up environment"
file_env "RESTIC_PASSWORD"
file_env "B2_ACCOUNT_ID"
file_env "B2_ACCOUNT_KEY"

# Check for NFS configuration
if [ -n "${NFS_TARGET}" ]; then
    echo ":: Mounting NFS based on NFS_TARGET: ${NFS_TARGET}"
    mount -o nolock -v ${NFS_TARGET} /mnt/restic
fi

# List snapshots
restic snapshots &>/dev/null

status=$?
echo ":: Repository status: $status"

if [ $status != 0 ]; then
    echo ":: Restic repository '${RESTIC_REPOSITORY}' does not exist, initializing"
    restic init

    init_status=$?
    echo ":: Repository initialization status: $init_status"

    if [ $init_status != 0 ]; then
        echo ":: Failed to initialization the repository: '${RESTIC_REPOSITORY}'"
        exit 1
    fi
fi

echo ":: Setting up backup schedule with cron expression: ${BACKUP_CRON}"
echo "${BACKUP_CRON} /usr/bin/flock -n /var/run/backup.lock /bin/backup >> /var/log/cron.log 2>&1" > /var/spool/cron/crontabs/root

# Some insurance
touch /var/log/cron.log

# Start the cron daemon
crond

echo ":: Container started"

exec "$@"
