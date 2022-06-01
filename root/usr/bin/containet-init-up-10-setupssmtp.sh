#!/command/with-contenv bash

ssmtp_conf_file=/etc/ssmtp/ssmtp.conf
revaliases_file=/etc/ssmtp/revaliases

rm -f $ssmtp_conf_file
touch $ssmtp_conf_file

rm -f $revaliases_file
touch $revaliases_file

echo FromLineOverride=YES >> $ssmtp_conf_file

if [[ -n ${EMAIL_FROM} ]]; then
    echo "root:$EMAIL_FROM" >> $revaliases_file
fi

if [[ -n ${EMAIL_USE_TLS} ]]; then
    echo UseSTARTTLS=YES >> $ssmtp_conf_file
    echo UseSSL=YES >> $ssmtp_conf_file
fi

if [[ -n ${EMAIL_SMTP_SERVER} ]]; then
    if [[ -n ${EMAIL_SMTP_SERVER_PORT} ]]; then
        echo "mailhub=$EMAIL_SMTP_SERVER:$EMAIL_SMTP_SERVER_PORT" >> $ssmtp_conf_file
    else
        echo "mailhub=$EMAIL_SMTP_SERVER" >> $ssmtp_conf_file
    fi
fi

if [[ -n ${EMAIL_SMTP_LOGIN} ]]; then
    echo "AuthUser=$EMAIL_SMTP_LOGIN" >> $ssmtp_conf_file
fi

if [[ -n ${EMAIL_SMTP_PASSWORD} ]]; then
    echo "AuthPass=$EMAIL_SMTP_PASSWORD" >> $ssmtp_conf_file
fi

exit 0
