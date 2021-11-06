FROM restic/restic:0.12.1

RUN apk add --update --no-cache \
    bash                        \
    heirloom-mailx              \
    fuse                        \
    curl

RUN mkdir -p /mnt/restic /var/spool/cron/crontabs /var/log && \
    touch /var/log/cron.log;

ENV RESTIC_REPOSITORY=/mnt/restic
ENV RESTIC_PASSWORD=""
ENV RESTIC_TAG=""
ENV NFS_TARGET=""
ENV BACKUP_CRON="0 */6 * * *"
ENV RESTIC_FORGET_ARGS=""
ENV RESTIC_JOB_ARGS=""
ENV MAILX_ARGS=""

# Backup directory
VOLUME /data

COPY backup.sh /bin/backup
COPY entrypoint.sh /entrypoint.sh

WORKDIR /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["tail","-fn0","/var/log/cron.log"]
