#!/usr/bin/with-contenv bash
# shellcheck shell=bash disable=SC1008

converts()
{
    T=$1
    D=$((T/60/60/24))
    H=$((T/60/60%24))
    M=$((T/60%60))
    S=$((T%60))

    if [[ ${D} != 0 ]]; then
        if [[ $D -eq "1" ]]; then
            printf '%d day %02d:%02d:%02d' $D $H $M $S
        else
            printf '%d days %02d:%02d:%02d' $D $H $M $S
        fi
    else
        printf '%02d:%02d:%02d' $H $M $S
    fi
}

create_prune_pid_file()
{
    # Expect PID as the first parmater
    pid=${1}
    echo Creating prune pid file, "${prune_pid_file}", with pid="${pid}" | tee -a "$log_file"
    echo "${pid}" > "${prune_pid_file}"
}

remove_prune_pid_file()
{
    echo Removing prune pid file, "${prune_pid_file}"
    rm "${prune_pid_file}"
}

operation_in_progress()
{
    # Expect the name of the operation as the first parameter
    operation=${1}

    if [ -f "${backup_pid_file}" ]; then
        echo A backup is in progress with PID="$(cat "${backup_pid_file}")". Skipping "${operation}" | tee -a "$log_file"
        return 0
    fi

    if [ -f "${prune_pid_file}" ]; then
        echo A prune is in progress with PID="$(cat "${prune_pid_file}")". Skipping "${operation}" | tee -a "$log_file"
        return 0
    fi

    # No operation in progress
    return 127
}

backup_pid_file=/var/run/duplicacy_backup.pid
prune_pid_file=/var/run/duplicacy_prune.pid

my_dir="$(dirname "${BASH_SOURCE[0]}")"

hostname=""

if [[ -n ${EMAIL_HOSTNAME_ALIAS} ]]; then
    hostname=$EMAIL_HOSTNAME_ALIAS
else
    hostname=$(hostname)
fi

log_dir=""
log_file=/dev/null

if [[ -n ${EMAIL_SMTP_SERVER} ]] && [[ -n ${EMAIL_TO} ]]; then
    log_dir=$(mktemp -d)
    log_file=$log_dir/backup.log
fi

echo ========== Run prune job at "$(date)" ========== | tee "$log_file"

if operation_in_progress prune; then
    duration=0
    exitcode=127
else
    # Use the scripts pid as the pid for simplicity
    create_prune_pid_file ${$}
    trap remove_prune_pid_file INT TERM EXIT

    delay.sh "$log_file"

    start=$(date +%s.%N)
    config_dir=/config

    cd "$config_dir" || exit 128

    IFS=';'
    read -ra policies <<< "$PRUNE_KEEP_POLICIES"
    command="$PRUNE_OPTIONS"
    for policy in "${policies[@]}"; do
        command="$command -keep $policy"
    done

    sh -c "nice -n $PRIORITY_LEVEL duplicacy $GLOBAL_OPTIONS prune $command" | tee -a "$log_file"
    exitcode=${PIPESTATUS[0]}

    if [[ -n ${POST_PRUNE_SCRIPT} ]];  then
        if [[ -f ${POST_PRUNE_SCRIPT} ]]; then
            echo Run post prune script | tee -a "$log_file"
            export log_file exitcode duration my_dir # Variables I require in my post prune script
            sh -c "${POST_PRUNE_SCRIPT}" | tee -a "$log_file"
        else
            echo Post prune script defined, but file not found | tee -a "$log_file"
        fi
    fi

    duration=$(echo "$(date +%s.%N) - $start" | bc)
fi

if [ "$exitcode" -eq 0 ]; then
    echo Prune COMPLETED, duration "$(converts "$duration")", log size "$(wc -l < "$log_file")" lines | tee -a "$log_file"
    subject="duplicacy prune job id \"$hostname:$SNAPSHOT_ID\" COMPLETED"
else
    echo Prune FAILED, code "$exitcode", duration "$(converts "$duration")", log size "$(wc -l < "$log_file")" lines | tee -a "$log_file"
    subject="duplicacy prune job id \"$hostname:$SNAPSHOT_ID\" FAILED"
fi

mailto.sh "$log_dir" "$subject"

exit "$exitcode"
