#!/usr/bin/with-contenv bash
pid=$(ps | grep "duplicacy backup" | grep -v "grep" | cut -d " " -f 1)
kill -2 $dup_pid
exit 0
