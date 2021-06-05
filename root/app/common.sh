#!/usr/bin/with-contenv bash

hostname=""

if [[ ! -z ${EMAIL_HOSTNAME_ALIAS} ]]; then
    hostname=$EMAIL_HOSTNAME_ALIAS
else
    hostname=`hostname`
fi

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

operation_in_progress()
{
    # Expect the name of the operation as the first parameter
    operation=${1}

    if [ -f ${backup_pid_file} ]; then
        echo A backup is in progress with PID=$(cat ${backup_pid_file}). Skipping ${operation} | tee -a $log_file
        return 0
    fi

    if [ -f ${prune_pid_file} ]; then
        echo A prune is in progress with PID=$(cat ${prune_pid_file}). Skipping ${operation} | tee -a $log_file
        return 0
    fi

    # No operation in progress
    return 127
}

create_backup_pid_file()
{
    # Expect PID as the first parmater
    pid=${1}
    echo Creating backup pid file, ${backup_pid_file}, with pid=${pid} | tee -a $log_file
    echo ${pid} > "${backup_pid_file}"
}

create_prune_pid_file()
{
    # Expect PID as the first parmater
    pid=${1}
    echo Creating prune pid file, ${prune_pid_file}, with pid=${pid} | tee -a $log_file
    echo ${pid} > "${prune_pid_file}"
}

remove_backup_pid_file()
{
    echo Removing backup pid file, ${backup_pid_file} | tee -a $log_file
    rm "${backup_pid_file}"
}

remove_prune_pid_file()
{
    echo Removing prune pid file, ${prune_pid_file} | tee -a $log_file
    rm "${prune_pid_file}"
}
