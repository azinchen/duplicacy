#!/usr/bin/with-contenv bash

my_dir="$(dirname "${BASH_SOURCE[0]}")"
source "$my_dir/common.sh"

log_file=$1

if [[ -z ${log_file} ]]; then
    log_file=/dev/null
fi

if [[ ! -z ${JOB_RANDOM_DELAY} ]] && [[ $JOB_RANDOM_DELAY -ne 0 ]]; then
    delay=$(((RANDOM % ($JOB_RANDOM_DELAY - 1)) + 1))
    echo Backup delayed by $(converts $delay) | tee -a $log_file
    sleep $delay
fi

exit 0
