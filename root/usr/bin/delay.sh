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

log_file=$1

if [[ -z ${log_file} ]]; then
    log_file=/dev/null
fi

if [[ -n ${JOB_RANDOM_DELAY} ]] && [[ $JOB_RANDOM_DELAY -ne 0 ]]; then
    delay=$(((RANDOM % (JOB_RANDOM_DELAY - 1)) + 1))
    echo Backup delayed by "$(converts "$delay")" | tee -a "$log_file"
    sleep $delay
fi

exit 0
