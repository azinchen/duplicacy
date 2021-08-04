#!/usr/bin/with-contenv bash
# shellcheck shell=bash disable=SC1008

dup_pid=$(ps | grep "duplicacy backup" | grep -v "grep" | awk '{print $1;}')

if [[ -n "${dup_pid}" ]]; then
    echo Stop current backup process with safe resume from current uploaded progress when next backup occurs
    kill -2 "$dup_pid"
else
    echo No current backup process, nothing to stop
fi

exit 0
