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

echo ========== Run prune job at `date` ========== | tee $log_file

if operation_in_progress prune; then
    duration=0
    exitcode=127
else
    # Use the scripts pid as the pid for simplicity
    create_prune_pid_file ${$}
    trap remove_prune_pid_file INT TERM EXIT

    "$my_dir/delay.sh" $log_file

    start=$(date +%s.%N)
    config_dir=/config

    cd $config_dir

    IFS=';'
    read -ra policies <<< $PRUNE_KEEP_POLICIES
    command="$PRUNE_OPTIONS"
    for policy in ${policies[@]}; do
        command="$command -keep $policy"
    done

    sh -c "nice -n $PRIORITY_LEVEL duplicacy $GLOBAL_OPTIONS prune $command" | tee -a $log_file
    exitcode=${PIPESTATUS[0]}

    if [[ ! -z ${POST_PRUNE_SCRIPT} ]];  then
        if [[ -f ${POST_PRUNE_SCRIPT} ]]; then
            echo Run post prune script | tee -a $log_file
            export log_file exitcode duration my_dir # Variables I require in my post prune script
            sh -c "${POST_PRUNE_SCRIPT}" | tee -a $log_file
        else
            echo Post prune script defined, but file not found | tee -a $log_file
        fi
    fi

    duration=$(echo "$(date +%s.%N) - $start" | bc)
fi

if [ $exitcode -eq 0 ]; then
    echo Prune COMPLETED, duration $(converts $duration) | tee -a $log_file
    subject="duplicacy prune job id \"$hostname:$SNAPSHOT_ID\" COMPLETED"
else
    echo Prune FAILED, code $exitcode, duration $(converts $duration) | tee -a $log_file
    subject="duplicacy prune job id \"$hostname:$SNAPSHOT_ID\" FAILED"
fi

"$my_dir/mailto.sh" $log_dir "$subject"

exit $exitcode
