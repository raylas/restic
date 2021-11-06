#!/usr/bin/env bash

wait_period=0
timeout_seconds=300
container_name=restic-test

stop_container() {
  docker stop $(docker ps | grep $container_name | awk '{print $1}')
}

clean_directories() {
  rm -rf /tmp/test-data/ /tmp/test-repo/
}

echo ":: Removing old container names '$container_name' if exists"
docker rm -f -v $container_name || true

echo ":: Creating test directories & file"
mkdir -p /tmp/{test-data,test-repo}
echo "Hello, World!" > /tmp/test-data/test-file.txt

echo ":: Build $container_name container"
docker build -t $container_name .

echo ":: Starting $container_name container"
echo ":: Backing up ./test-data/ to repository ./test-repo/ every minute"
docker run --detach --rm --name $container_name \
-e "RESTIC_PASSWORD=test" \
-e "RESTIC_TAG=test" \
-e "BACKUP_CRON=* * * * *" \
-e "RESTIC_FORGET_ARGS=--keep-last 10" \
-v /tmp/test-data:/data \
-v /tmp/test-repo:/mnt/restic \
-t $container_name

while true; do
  if [ -z "$(ls -A /tmp/test-repo/snapshots)" ]; then
    echo ":: Waiting for test repository contents"
  else
    echo ":: Snapshots found, stopping container"
    stop_container
    echo ":: Cleaning up test directories"
    clean_directories
    exit 0
  fi

  wait_period=$(($wait_period + 10))
  if [ $wait_period -gt $timeout_seconds ]; then
    echo ":: No snapshots found within $timeout_seconds seconds, stopping container"
    stop_container
    echo ":: Cleaning up test directories"
    clean_directories
    exit 1
  else
    sleep 10
  fi
done
