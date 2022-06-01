#!/command/with-contenv bash

exitcode=0

if [[ $RUN_JOB_IMMEDIATELY == "yes" ]] || [[ $RUN_JOB_IMMEDIATELY == "YES" ]]; then
    if [[ "${BACKUP_CRON}" ]]; then
        backup.sh
        exitcode=$?
    fi

    if [[ "${PRUNE_CRON}" ]] && [[ $exitcode -eq 0 ]]; then
        prune.sh
        exitcode=$?
    fi
fi

exit $exitcode
