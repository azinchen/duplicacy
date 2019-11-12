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

if [[ ! -z ${BACKUP_RANDOM_DELAY} ]] && [[ $BACKUP_RANDOM_DELAY -ne 0 ]]; then
    delay=$(((RANDOM % ($BACKUP_RANDOM_DELAY - 1)) + 1))
    echo Delay backup for $(converts $delay) | tee -a $log_file
    sleep $delay
fi

start=$(date +%s.%N)
config_dir=/config

cd $config_dir

echo "*** Backup ***" | tee -a $log_file
duplicacy $GLOBAL_OPTIONS backup $BACKUP_OPTIONS | tee -a $log_file
exitcode=$?

if [[ $exitcode -eq 0 ]] && [[ ! -z ${PRUNE_KEEP_POLICIES} ]]; then
    IFS=';'
    read -ra policies <<< $PRUNE_KEEP_POLICIES
    command=""
    for policy in ${policies[@]}; do
        command="$command -keep $policy"
    done

    echo "*** Prune chunks by policies ***" | tee -a $log_file
    sh -c "duplicacy $GLOBAL_OPTIONS prune $command" | tee -a $log_file
    exitcode=$?

    if [[ $exitcode -eq 0 ]]; then
        echo "*** Delete marked chunks ***" | tee -a $log_file
        duplicacy $GLOBAL_OPTIONS prune -exhaustive | tee -a $log_file
        exitcode=$?
    fi
fi

duration=$(echo "$(date +%s.%N) - $start" | bc)
subject=""

if [ $exitcode -eq 0 ]; then
    echo Backup COMPLETED, duration $(converts $duration) | tee -a $log_file
    subject="duplicacy job id \"$SNAPSHOT_ID\" COMPLETED"
else
    echo Backup FAILED, code $exitcode, duration $(converts $duration) | tee -a $log_file
    subject="duplicacy job id \"$SNAPSHOT_ID\" FAILED"
fi

if [[ ! -z ${EMAIL_SMTP_SERVER} ]] && [[ ! -z ${EMAIL_TO} ]]; then
    boundary="_====_boundary_====_$(date +%Y%m%d%H%M%S)_====_"

    echo "To: $EMAIL_TO" >> $mail_file
    echo "Subject: $subject" >> $mail_file
    echo "Content-Type: multipart/mixed; boundary=\"$boundary\"" >> $mail_file
    echo "Mime-Version: 1.0" >> $mail_file
    echo "" >> $mail_file

    echo "--${boundary}" >> $mail_file
    echo "" >> $mail_file

    if [[ `wc -l $log_file | awk '{ print $1 }'` -gt $((2*$EMAIL_LOG_LINES_IN_BODY)) ]]; then
        head -$EMAIL_LOG_LINES_IN_BODY $log_file >> $mail_file
        echo "..." >> $mail_file
        tail -n $EMAIL_LOG_LINES_IN_BODY $log_file >> $mail_file
    else
        cat $log_file >> $mail_file
    fi

    echo "" >> $mail_file

    zip_log_file=$log_dir/backuplog.zip
    zipout=`zip -j $zip_log_file $log_file`

    if [ $exitcode -ne 0 ]; then
        echo $zipout
    fi

    echo "--${boundary}" >> $mail_file
    echo "Content-Transfer-Encoding: base64" >> $mail_file
    echo "Content-Type: application/zip; name=backuplog.zip" >> $mail_file
    echo "Content-Disposition: attachment; filename=backuplog.zip" >> $mail_file
    echo "" >> $mail_file
    base64 $zip_log_file >> $mail_file
    echo "" >> $mail_file
    echo "--${boundary}--" >> $mail_file

    cat $mail_file | ssmtp -F "$EMAIL_FROM_NAME" $EMAIL_TO

    rm -rf $log_dir
fi

exit $exitcode
