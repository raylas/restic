#!/usr/bin/env bash

echo ":: Starting container"

if [ -n "${NFS_TARGET}" ]; then
    echo ":: Mounting NFS based on NFS_TARGET: ${NFS_TARGET}"
    mount -o nolock -v ${NFS_TARGET} /mnt/restic
fi

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
