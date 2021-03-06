#!/bin/bash
# Copyright (C) 2019 The Raphielscape Company LLC.
#
# Licensed under the Raphielscape Public License, Version 1.c (the "License");
# you may not use this file except in compliance with the License.
#
# CI Runner Script for baalajimaestro's userbot

# We need this directive
# shellcheck disable=1090

. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"/telegram

PARSE_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
PARSE_ORIGIN="$(git config --get remote.origin.url)"
COMMIT_POINT="$(git log --pretty=format:'%h : %s' -1)"
TELEGRAM_TOKEN=${BOT_API_KEY}
export BOT_API_KEY PARSE_BRANCH PARSE_ORIGIN COMMIT_POINT TELEGRAM_TOKEN
kickstart_pub

req_install() {
    pip3 install --upgrade setuptools pip
    pip3 install yapf
}

get_session() {
    curl -sLo userbot.session "$PULL_LINK"
}

test_run() {
    python3 -m userbot
    STATUS=${?}
    export STATUS
}

tg_senderror() {
    if [ -n "$PULL_REQUEST_NUMBER" ]; then
        tg_sendinfo "<code>This PR is having build issues and won't be merged until its fixed<code>"
        exit 1
    fi
    tg_sendinfo "<code>Build Throwing Error(s)</code>"

    [ -n "${STATUS}" ] &&
    exit "${STATUS}" ||
    exit 1
}

tg_yay() {
  if [ -n "$PULL_REQUEST_NUMBER" ]; then
    tg_sendinfo "<code>Compilation Success! Checking for Lint Issues before it can be merged!</code>"
    RESULT=$(yapf -d -r -p userbot)
      if ! $RESULT; then
        tg_sendinfo "<code>PR has Lint Problems, review it before merging</code>"
        exit 1
      else
        tg_sendinfo "<code>PR didn't have any Lint Problems</code>"
        exit 0
      fi
    fi
    tg_sendinfo "<code>Compilation Success!</code>"
}

# Fin Prober
fin() {
    echo "Yay! My works took $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds.~"
    tg_yay
}

finerr() {
    echo "My works took $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds but it's error..."
    tg_senderror

    [ -n "${STATUS}" ] &&
    exit "${STATUS}" ||
    exit 1
}

execute() {
    BUILD_START=$(date +"%s")
        req_install
        test_run
    BUILD_END=$(date +"%s")
    DIFF=$((BUILD_END - BUILD_START))
    if [ $STATUS -eq 0 ];
    then
    fin
    else
    finerr
    fi
}

get_session
execute
