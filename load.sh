#!/bin/bash

# Book
edition=3
bookurl="http://uhunt.felix-halim.net/api/cpbook/${edition}"

function create() {
    tmpfile=$(mktemp /tmp/uhunt.XXXXXX)
}

function clear() {
    if [ -f "${tmpfile}" ]; then
        rm -rf "${tmpfile}" 1>/dev/null 2>&1;
    fi
}

function die() {
    clear;

    [ -z "$@" ] || echo "$@";

    exit 1;
}

create;

wget -O "${tmpfile}" "${bookurl}" 1>/dev/null 2>&1 \
  || die "Unable to download problems";

(
OLDIFS=${IFS};
IFS=$'\n';

chapters=0;

echo -n "CHAPTERS=("
for chapter in $(cat ${tmpfile} | jq ".[].title"); do
    echo -n " ${chapter}";
    ((chapters++));
done
echo " )";

echo;

for c in $(jot - 1 "${chapters}"); do
    echo -n "PROBLEMS_${c}=(";
    for p in $(cat "${tmpfile}" | jq ".[$((c-1))].arr[].arr[][]" | \
               grep -v "\"" | sed "s/^-//"); do
        echo -n " $p"
    done
    echo " )";

    echo;
done

IFS=${OLDIFS};
) > problems.rc

clear;
