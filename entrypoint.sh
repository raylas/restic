#!/usr/bin/env bash

echo ":: Starting container"

echo ":: Setting up environment"
# Check if restic password exists
if [[ -z $RESTIC_PASSWORD && ! -f "/run/secrets/restic_password" ]]; then
  echo "The restic password cannot be found."
  echo "The following must be set:"
  echo "- RESTIC_PASSWORD (will also check /run/secrets/restic_password)"
  exit 1
elif [[ -z $RESTIC_PASSWORD ]]; then
  export RESTIC_PASSWORD=$(cat /run/secrets/restic_password)
fi

# Check if B2 account ID exists
if [[ -z $B2_ACCOUNT_ID && ! -f "/run/secrets/b2_account_id" ]]; then
  echo "The B2 account ID cannot be found."
  echo "The following must be set:"
  echo "- B2_ACCOUNT_ID (will also check /run/secrets/b2_account_id)"
elif [[ -z $B2_ACCOUNT_ID ]]; then
  export B2_ACCOUNT_ID=$(cat /run/secrets/b2_account_id)
fi

# Check if B2 account key exists
if [[ -z $B2_ACCOUNT_KEY && ! -f "/run/secrets/b2_account_key" ]]; then
  echo "The B2 account KEY cannot be found."
  echo "The following must be set:"
  echo "- B2_ACCOUNT_KEY (will also check /run/secrets/b2_account_key)"
elif [[ -z $B2_ACCOUNT_KEY ]]; then
  export B2_ACCOUNT_KEY=$(cat /run/secrets/b2_account_key)
fi

# Check for NFS configuration
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
