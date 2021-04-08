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

"$my_dir/delay.sh" $log_file

if [[ ! -z ${PRE_BACKUP_SCRIPT} ]]; then
    if [[ -f ${PRE_BACKUP_SCRIPT} ]]; then
        echo Run pre backup script | tee -a $log_file
        export log_file my_dir # Variables I require in my pre backup script
        sh -c "${PRE_BACKUP_SCRIPT}"
        exitcode = ${PIPESTATUS[0]
    else
        echo Pre backup script defined, but file not found | tee -a $log_file
        # Command not found exit code (https://tldp.org/LDP/abs/html/exitcodes.html)
        exitcode = 127
    fi
fi

if [ $exitcode -eq 0 ]; then
    start=$(date +%s.%N)
    config_dir=/config

    cd $config_dir

    nice -n $PRIORITY_LEVEL duplicacy $GLOBAL_OPTIONS backup $BACKUP_OPTIONS | tee -a $log_file
    exitcode=${PIPESTATUS[0]}

    duration=$(echo "$(date +%s.%N) - $start" | bc)
    subject=""

    if [ $exitcode -eq 0 ]; then
        echo Backup COMPLETED, duration $(converts $duration) | tee -a $log_file
        subject="duplicacy backup job id \"$hostname:$SNAPSHOT_ID\" COMPLETED"
    else
        echo Backup FAILED, code $exitcode, duration $(converts $duration) | tee -a $log_file
        subject="duplicacy backup job id \"$hostname:$SNAPSHOT_ID\" FAILED"
    fi

    if [[ ! -z ${POST_BACKUP_SCRIPT} ]]; then
        if [[ -f ${POST_BACKUP_SCRIPT} ]]; then
            echo Run post backup script | tee -a $log_file
            export log_file exitcode duration my_dir # Variables I require in my post backup script
            sh -c "${POST_BACKUP_SCRIPT}"
        else
            echo Post backup script defined, but file not found | tee -a $log_file
        fi
    fi
else
    echo Pre backup script FAILED, code $exitcode, | tee -a $log_file
fi

"$my_dir/mailto.sh" $log_dir "$subject"

exit $exitcode
