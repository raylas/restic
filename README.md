# Restic
A custom Docker image to automate [restic backups](https://restic.github.io/)

This container runs restic backups in regular intervals. 

* Easy setup and maintanance
* Support for different targets (tested with: Local, NFS, SFTP, AWS, B2)
* Support for `restic mount` inside the container to browse the backup files

**Container**: [raylas/restic](https://hub.docker.com/r/raylas/restic)

## Hooks

If you need to execute a script before or after each backup, 
you need to add your hook script in the container folder `/hooks`:
```
-v ~/hooks:/hooks
```
Call your pre-backup script `pre-backup.sh` and post backup script `post-backup.sh`

## Usage
Test:
```sh
$ make test
```

Build for linux/amd64:
```sh
$ make build-amd64
```

Build for linux/arm64:
```sh
$ make build-arm64
```

Clean up:
```sh
$ make clean
```

### Manual backups
To execute a backup manually independent of the CRON run:
```sh
docker exec -ti restic-backup /bin/backup
```
    
Backup a single file or directory:
```sh
docker exec -ti restic-backup restic backup /data/path/to/dir --tag my-tag
```

### Restore
You might want to mount a separate hostvolume at e.g. `/restore` to not override existing data while restoring. 

Get your snapshot ID with:
```sh
docker exec -ti restic-backup restic snapshots
``` 

Restore:
```sh
docker exec -ti restic-backup-var restic restore --include /data/path/to/files --target / abcdef12
```

The target is `/` since all data backed up should be inside the host mounted `/data` dir. If you mount `/restore` you should set `--target /restore` and data will end up in `/restore/data/path/to/files`.


## Environment variables
* `RESTIC_REPOSITORY` - the location of the restic repository. Default `/mnt/restic`. For S3: `s3:https://s3.amazonaws.com/BUCKET_NAME`
* `RESTIC_PASSWORD` - the password for the restic repository. Will also be used for restic init during first start when the repository is not initialized.
* `RESTIC_TAG` - Optional. To tag the images created by the container.
* `NFS_TARGET` - Optional. If set the given NFS is mounted, i.e. `mount -o nolock -v ${NFS_TARGET} /mnt/restic`. `RESTIC_REPOSITORY` must remain it's default value!
* `BACKUP_CRON` - A cron expression to run the backup. Note: cron daemon uses UTC time zone. Default: `0 */6 * * *` aka every 6 hours.
* `RESTIC_FORGET_ARGS` - Optional. Only if specified `restic forget` is run with the given arguments after each backup. Example value: `-e "RESTIC_FORGET_ARGS=--prune --keep-last 10 --keep-hourly 24 --keep-daily 7 --keep-weekly 52 --keep-monthly 120 --keep-yearly 100"`
* `RESTIC_JOB_ARGS` - Optional. Allows to specify extra arguments to the back up job such as limiting bandwith with `--limit-upload` or excluding file masks with `--exclude`.
* `AWS_ACCESS_KEY_ID` - Optional. When using restic with AWS S3 storage.
* `AWS_SECRET_ACCESS_KEY` - Optional. When using restic with AWS S3 storage.
* `B2_ACCOUNT_ID` - Optional. When using restic with Backblaze B2 storage.
* `B2_ACCOUNT_KEY` - Optional. When using restic with Backblaze B2 storage.
* `MAILX_ARGS` - Optional. If specified, the content of `/var/log/backup-last.log` is sent via mail after each backup using an *external SMTP*. To have maximum flexibility, you have to specify the mail/smtp parameters by your own. Have a look at the [mailx manpage](https://linux.die.net/man/1/mailx) for further information. Example value: `-e "MAILX_ARGS=-r 'from@example.de' -s 'Result of the last restic backup run' -S smtp='smtp.example.com:587' -S smtp-use-starttls -S smtp-auth=login -S smtp-auth-user='username' -S smtp-auth-password='password' 'to@example.com'"`.

## Volumes
* `/data` - This is the data that gets backed up. Just [mount](https://docs.docker.com/engine/reference/run/#volume-shared-filesystems) it to wherever you want.

## Set the hostname
Since restic saves the hostname with each snapshot and the hostname of a docker container is derived from it's id you might want to customize this by setting the hostname of the container to another value.

Set `--hostname` in the [network settings](https://docs.docker.com/engine/reference/run/#network-settings)

## Backup via SFTP
Since restic needs a **password less login** to the SFTP server make sure you can do `sftp user@host` from inside the container. If you can do so from your host system, the easiest way is to just mount your `.ssh` folder conaining the authorized cert into the container by specifying `-v ~/.ssh:/root/.ssh` as argument for `docker run`.

Now you can simply specify the restic repository to be an [SFTP repository](https://restic.readthedocs.io/en/stable/Manual/#create-an-sftp-repository).

```
-e "RESTIC_REPOSITORY=sftp:user@host:/tmp/backup"
```
