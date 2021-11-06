#!/usr/bin/env bash

lastLogFile="/var/log/backup-last.log"
lastMailLogFile="/var/log/mail-last.log"

copyErrorLog() {
  cp ${lastLogFile} /var/log/backup-error-last.log
}

logLast() {
  echo "$1" >> ${lastLogFile}
}

if [ -f "/hooks/pre-backup.sh" ]; then
    echo ":: Starting pre-backup script"
    /hooks/pre-backup.sh
else
    echo ":: Pre-backup script not found"
fi

start=`date +%s`
rm -f ${lastLogFile} ${lastMailLogFile}
echo ":: Starting Backup at $(date +"%Y-%m-%d %H:%M:%S")"
echo ":: Starting Backup at $(date)" >> ${lastLogFile}
logLast "BACKUP_CRON: ${BACKUP_CRON}"
logLast "RESTIC_TAG: ${RESTIC_TAG}"
logLast "RESTIC_FORGET_ARGS: ${RESTIC_FORGET_ARGS}"
logLast "RESTIC_JOB_ARGS: ${RESTIC_JOB_ARGS}"
logLast "RESTIC_REPOSITORY: ${RESTIC_REPOSITORY}"
logLast "AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID}"
logLast "B2_ACCOUNT_ID: ${B2_ACCOUNT_ID}"

# Do not save full backup log to logfile, but to backup-last.log
restic backup /data ${RESTIC_JOB_ARGS} --tag=${RESTIC_TAG?":: Missing environment variable RESTIC_TAG"} >> ${lastLogFile} 2>&1
backupRC=$?
logLast ":: Finished backup at $(date)"
if [[ $backupRC == 0 ]]; then
    echo ":: Backup successful"
else
    echo ":: Backup failed with status: ${backupRC}"
    restic unlock
    copyErrorLog
fi

if [[ $backupRC == 0 ]] && [ -n "${RESTIC_FORGET_ARGS}" ]; then
    echo ":: Forget about old snapshots based on args: ${RESTIC_FORGET_ARGS}"
    restic forget ${RESTIC_FORGET_ARGS} >> ${lastLogFile} 2>&1
    rc=$?
    logLast ":: Forgotten at $(date)"
    if [[ $rc == 0 ]]; then
        echo ":: Forget successful"
    else
        echo ":: Forget failed with status: ${rc}"
        restic unlock
        copyErrorLog
    fi
fi

end=`date +%s`
echo ":: Finished backup at $(date +"%Y-%m-%d %H:%M:%S") after $((end-start)) seconds"

if [ -n "${MAILX_ARGS}" ]; then
    sh -c "mailx -v -S sendwait ${MAILX_ARGS} < ${lastLogFile} > ${lastMailLogFile} 2>&1"
    if [ $? == 0 ]; then
        echo ":: Mail notification successfully sent"
    else
        echo ":: Sending mail notification FAILED"
        echo ":: Check ${lastMailLogFile} for further information"
    fi
fi

if [ -f "/hooks/post-backup.sh" ]; then
    echo ":: Starting post-backup script"
    /hooks/post-backup.sh $backupRC
else
    echo ":: Post-backup script not found"
fi
