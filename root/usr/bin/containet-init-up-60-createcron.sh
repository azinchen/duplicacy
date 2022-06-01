#!/command/with-contenv bash

cron_file=/var/spool/cron/crontabs/root

rm -f $cron_file
touch $cron_file

if [[ "${BACKUP_CRON}" ]]; then
    echo "$BACKUP_CRON backup.sh" >> $cron_file
fi

if [[ "${PRUNE_CRON}" ]]; then
    echo "$PRUNE_CRON prune.sh" >> $cron_file
fi

if [[ "${BACKUP_END_CRON}" ]]; then
    echo "$BACKUP_END_CRON end_backup.sh" >> $cron_file
fi

exit 0
