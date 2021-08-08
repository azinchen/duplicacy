#!/usr/bin/with-contenv bash
# shellcheck shell=bash disable=SC1008

backup_pid_file=/var/run/duplicacy_backup.pid
prune_pid_file=/var/run/duplicacy_prune.pid

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

create_backup_pid_file()
{
    # Expect PID as the first parmater
    pid=${1}
    echo Creating backup pid file, "${backup_pid_file}", with pid="${pid}" | tee -a "$log_file"
    echo "${pid}" > "${backup_pid_file}"
}

remove_backup_pid_file()
{
    echo Removing backup pid file, "${backup_pid_file}"
    rm "${backup_pid_file}"
}

operation_in_progress()
{
    # Expect the name of the operation as the first parameter
    operation=${1}

    if [ -f ${backup_pid_file} ]; then
        echo A backup is in progress with PID="$(cat ${backup_pid_file})". Skipping "${operation}" | tee -a "$log_file"
        return 0
    fi

    if [ -f ${prune_pid_file} ]; then
        echo A prune is in progress with PID="$(cat ${prune_pid_file})". Skipping "${operation}" | tee -a "$log_file"
        return 0
    fi

    # No operation in progress
    return 127
}

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

echo ========== Run backup job at "$(date)" ========== | tee "$log_file"

if operation_in_progress backup; then
    duration=0
    exitcode=127
else
    # Use the scripts pid as the pid for simplicity
    create_backup_pid_file ${$}
    trap remove_backup_pid_file INT TERM EXIT

    delay.sh "$log_file"

    start=$(date +%s.%N)

    if [[ -n ${PRE_BACKUP_SCRIPT} ]]; then
        if [[ -f ${PRE_BACKUP_SCRIPT} ]]; then
            echo Run pre backup script | tee -a "$log_file"
            export log_file my_dir # Variables I require in my pre backup script
            sh -c "${PRE_BACKUP_SCRIPT}" | tee -a "$log_file"
            exitcode=${PIPESTATUS[0]}
        else
            echo Pre backup script defined, but file not found | tee -a "$log_file"
            # Command not found exit code (https://tldp.org/LDP/abs/html/exitcodes.html)
            exitcode=127
        fi
    else
        # No pre backup script so call it a success
        exitcode=0
    fi

    if [ $exitcode -eq 0 ]; then
        config_dir=/config

        cd "$config_dir" || exit 128

        sh -c "nice -n $PRIORITY_LEVEL duplicacy $GLOBAL_OPTIONS backup $BACKUP_OPTIONS" | tee -a "$log_file"
        exitcode=${PIPESTATUS[0]}

        if [[ -n ${POST_BACKUP_SCRIPT} ]]; then
            if [[ -f ${POST_BACKUP_SCRIPT} ]]; then
                echo Run post backup script | tee -a "$log_file"
                export log_file exitcode duration my_dir # Variables I require in my post backup script
                sh -c "${POST_BACKUP_SCRIPT}" | tee -a "$log_file"
            else
                echo Post backup script defined, but file not found | tee -a "$log_file"
            fi
        fi
    else
        echo Pre backup script FAILED, code "$exitcode", | tee -a "$log_file"
    fi

    duration=$(echo "$(date +%s.%N) - $start" | bc)
fi

if [ "$exitcode" -eq 0 ]; then
    echo Backup COMPLETED, duration "$(converts "$duration")", log size "$(wc -l < "$log_file")" lines | tee -a "$log_file"
    subject="duplicacy backup job id \"$hostname:$SNAPSHOT_ID\" COMPLETED"
else
    echo Backup FAILED, code "$exitcode", duration "$(converts "$duration")", log size "$(wc -l < "$log_file")" lines | tee -a "$log_file"
    subject="duplicacy backup job id \"$hostname:$SNAPSHOT_ID\" FAILED"
fi

mailto.sh "$log_dir" "$subject"

exit "$exitcode"
