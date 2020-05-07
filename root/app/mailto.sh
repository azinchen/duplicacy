#!/usr/bin/with-contenv bash

log_dir=$1
subject=$2

if [[ ! -z ${EMAIL_SMTP_SERVER} ]] && [[ ! -z ${EMAIL_TO} ]]; then
    log_file=$log_dir/backup.log
    mail_file=$log_dir/mailbody.log

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

    if [ $? -ne 0 ]; then
        echo $zipout
    else
        echo "--${boundary}" >> $mail_file
        echo "Content-Transfer-Encoding: base64" >> $mail_file
        echo "Content-Type: application/zip; name=backuplog.zip" >> $mail_file
        echo "Content-Disposition: attachment; filename=backuplog.zip" >> $mail_file
        echo "" >> $mail_file
        base64 $zip_log_file >> $mail_file
        echo "" >> $mail_file
        echo "--${boundary}--" >> $mail_file
    fi

    cat $mail_file | ssmtp -F "$EMAIL_FROM_NAME" $EMAIL_TO

    rm -rf $log_dir
fi

exit 0
