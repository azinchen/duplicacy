#!/usr/bin/with-contenv bash
# shellcheck shell=bash disable=SC1008

log_dir=$1
subject=$2

if [[ -n ${EMAIL_SMTP_SERVER} ]] && [[ -n ${EMAIL_TO} ]]; then
    log_file="$log_dir"/backup.log
    mail_file="$log_dir"/mailbody.log

    boundary="_====_boundary_====_$(date +%Y%m%d%H%M%S)_====_"

    {
        echo "To: $EMAIL_TO"
        echo "Subject: $subject"
        echo "Content-Type: multipart/mixed; boundary=\"$boundary\""
        echo "Mime-Version: 1.0"
        echo ""
        echo "--${boundary}"
        echo ""
    } >> "$mail_file"

    if [[ $(wc -l "$log_file" | awk '{ print $1 }') -gt $((2*EMAIL_LOG_LINES_IN_BODY)) ]]; then
        {
            head -"$EMAIL_LOG_LINES_IN_BODY" "$log_file"
            echo "..."
            tail -n "$EMAIL_LOG_LINES_IN_BODY" "$log_file"
        } >> "$mail_file"
    else
        cat "$log_file" >> "$mail_file"
    fi

    echo "" >> "$mail_file"

    zip_log_file=$log_dir/backuplog.zip
    zipout=$(zip -j "$zip_log_file" "$log_file")

    if [ $? ]; then
        {
            echo "--${boundary}"
            echo "Content-Transfer-Encoding: base64"
            echo "Content-Type: application/zip; name=backuplog.zip"
            echo "Content-Disposition: attachment; filename=backuplog.zip"
            echo ""
            base64 "$zip_log_file"
            echo ""
            echo "--${boundary}--"
        } >> "$mail_file"
    else
        echo "$zipout"
    fi

    ssmtp -F "$EMAIL_FROM_NAME" "$EMAIL_TO" < "$mail_file"

    rm -rf "$log_dir"
fi

exit 0
