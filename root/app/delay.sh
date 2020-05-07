#!/usr/bin/with-contenv bash

my_dir="$(dirname "${BASH_SOURCE[0]}")"
source "$my_dir/common.sh"

if [[ ! -z ${BACKUP_RANDOM_DELAY} ]] && [[ $BACKUP_RANDOM_DELAY -ne 0 ]]; then
    delay=$(((RANDOM % ($BACKUP_RANDOM_DELAY - 1)) + 1))
    echo Delay backup for $(converts $delay) | tee -a $log_file
    sleep $delay
fi

exit 0
