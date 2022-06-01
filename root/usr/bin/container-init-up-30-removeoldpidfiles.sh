#!/command/with-contenv bash

backup_pid_file=/var/run/duplicacy_backup.pid
prune_pid_file=/var/run/duplicacy_prune.pid

if [ -f ${backup_pid_file} ]; then
    echo Unfinished backup task found. Removing backup pid file, ${backup_pid_file}
    rm "${backup_pid_file}"
fi

if [ -f ${prune_pid_file} ]; then
    echo Unfinished prune task found. Removing prune pid file, ${prune_pid_file}
    rm "${prune_pid_file}"
fi

exit 0
