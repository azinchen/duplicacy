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

log_dir=""
log_file=/dev/null
mail_file=/dev/null

if [[ ! -z ${EMAIL_SMTP_SERVER} ]] && [[ ! -z ${EMAIL_TO} ]]; then
    log_dir=`mktemp -d`
    log_file=$log_dir/backup.log
    mail_file=$log_dir/mailbody.log
fi

echo ========== Run backup job at `date` ========== | tee $log_file

start=$(date +%s.%N)
config_dir=/config

cd $config_dir

echo "*** Backup ***" | tee -a $log_file
duplicacy backup -threads $THREADS_NUM | tee -a $log_file
exitcode=$?

if [[ $exitcode -eq 0 ]] && [[ ! -z ${PRUNE_KEEP_POLICIES} ]]; then
    IFS=';'
    read -ra policies <<< $PRUNE_KEEP_POLICIES
    command=""
    for policy in ${policies[@]}; do
        command="$command -keep $policy"
    done

    echo "*** Prune chunks by policies ***" | tee -a $log_file
    sh -c "duplicacy prune $command -threads $THREADS_NUM" | tee -a $log_file
    exitcode=$?

    if [[ $exitcode -eq 0 ]]; then
        echo "*** Delete marked chunks ***" | tee -a $log_file
        duplicacy prune -exhaustive -threads $THREADS_NUM | tee -a $log_file
        exitcode=$?
    fi
fi

duration=$(echo "$(date +%s.%N) - $start" | bc)
subject=""

if [ $exitcode -eq 0 ]; then
    echo Backup COMPLETED, duration $(converts $duration) | tee -a $log_file
    subject="duplicacy job COMPLETED, id $SNAPSHOT_ID url $STORAGE_URL"
else
    echo Backup FAILED, code $exitcode, duration $(converts $duration) | tee -a $log_file
    subject="duplicacy job FAILED, id $SNAPSHOT_ID url $STORAGE_URL"
fi

if [[ ! -z ${EMAIL_SMTP_SERVER} ]] && [[ ! -z ${EMAIL_TO} ]]; then
    echo "To: $EMAIL_TO" >> $mail_file
    echo "Subject: $subject" >> $mail_file
    echo "" >> $mail_file

    if [[ `wc -l $log_file | awk '{ print $1 }'` -gt $((2*$EMAIL_LOG_LINES_IN_BODY)) ]]; then
        head -$EMAIL_LOG_LINES_IN_BODY $log_file >> $mail_file
        echo "..." >> $mail_file
        tail -n $EMAIL_LOG_LINES_IN_BODY $log_file >> $mail_file
    else
        cat $log_file >> $mail_file
    fi

    zip_log_file=$log_dir/backuplog.zip
    zipout=`zip -j $zip_log_file $log_file`

    if [ $exitcode -ne 0 ]; then
        echo $zipout
    fi

    cat $mail_file | (cat - && uuencode $zip_log_file backuplog.zip) | ssmtp -F "" $EMAIL_TO

    rm -rf $log_dir
fi

exit $exitcode
