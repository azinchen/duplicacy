#!/usr/bin/with-contenv bash

my_dir="$(dirname "${BASH_SOURCE[0]}")"
source "$my_dir/common.sh"

log_dir=""
log_file=/dev/null
mail_file=/dev/null

if [[ ! -z ${EMAIL_SMTP_SERVER} ]] && [[ ! -z ${EMAIL_TO} ]]; then
    log_dir=`mktemp -d`
    log_file=$log_dir/backup.log
    mail_file=$log_dir/mailbody.log
fi

echo ========== Run backup job at `date` ========== | tee $log_file

if [[ ! -z ${BACKUP_RANDOM_DELAY} ]] && [[ $BACKUP_RANDOM_DELAY -ne 0 ]]; then
    delay=$(((RANDOM % ($BACKUP_RANDOM_DELAY - 1)) + 1))
    echo Delay backup for $(converts $delay) | tee -a $log_file
    sleep $delay
fi

start=$(date +%s.%N)
config_dir=/config

cd $config_dir

echo "*** Backup ***" | tee -a $log_file
duplicacy $GLOBAL_OPTIONS backup $BACKUP_OPTIONS | tee -a $log_file
exitcode=$?

if [[ $exitcode -eq 0 ]] && [[ ! -z ${PRUNE_KEEP_POLICIES} ]]; then
    IFS=';'
    read -ra policies <<< $PRUNE_KEEP_POLICIES
    command=""
    for policy in ${policies[@]}; do
        command="$command -keep $policy"
    done

    echo "*** Prune chunks by policies ***" | tee -a $log_file
    sh -c "duplicacy $GLOBAL_OPTIONS prune $command" | tee -a $log_file
    exitcode=$?

    if [[ $exitcode -eq 0 ]]; then
        echo "*** Delete marked chunks ***" | tee -a $log_file
        duplicacy $GLOBAL_OPTIONS prune -exhaustive | tee -a $log_file
        exitcode=$?
    fi
fi

duration=$(echo "$(date +%s.%N) - $start" | bc)
subject=""

if [ $exitcode -eq 0 ]; then
    echo Backup COMPLETED, duration $(converts $duration) | tee -a $log_file
    subject="duplicacy job id \"$hostname:$SNAPSHOT_ID\" COMPLETED"
else
    echo Backup FAILED, code $exitcode, duration $(converts $duration) | tee -a $log_file
    subject="duplicacy job id \"$hostname:$SNAPSHOT_ID\" FAILED"
fi

"$my_dir/mailto.sh" $log_dir "$subject"

exit $exitcode
