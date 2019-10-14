#!/usr/bin/with-contenv bash

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

echo ========== Run backup job ==========

start=$(date +%s.%N)
config_dir=/config

cd $config_dir

echo "*** Backup ***"
duplicacy backup -threads $THREADS_NUM
exitcode=$?

if [[ $exitcode -eq 0 ]] && [[ ! -z "${PRUNE_KEEP_POLICIES}" ]]; then
    IFS=';'
    read -ra policies <<< "$PRUNE_KEEP_POLICIES"
    command=""
    for policy in "${policies[@]}"; do
        command="$command -keep $policy"
    done

    echo "*** Prune chunks by policies ***"
    sh -c "duplicacy prune $command -threads $THREADS_NUM"
    exitcode=$?

    if [[ $exitcode -eq 0 ]]; then
        echo "*** Delete marked chunks ***"
        duplicacy prune -exhaustive -threads $THREADS_NUM
        exitcode=$?
    fi
fi

duration=$(echo "$(date +%s.%N) - $start" | bc)

if [ $exitcode -ne 0 ]; then
    echo Backup FAILED, code $exitcode, lasted $(converts $duration)
else
    echo Backup COMPLETED, lasted $(converts $duration)
fi

exit $exitcode
