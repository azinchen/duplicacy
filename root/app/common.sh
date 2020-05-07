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

hostname=""

if [[ ! -z ${HOSTNAME} ]]; then
    hostname=$HOSTNAME
else
    hostname=`hostname`
fi
