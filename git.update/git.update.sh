#!/bin/bash
##READ FROM GIT-LIST FILE AND PULL ALL
##STRUCTURE git.LIST
##/path/to/git/root/:branch
file="/etc/git/git.list"

if [[ ! -f "$file" ]]; then
    echo "$file don't exists. Exit"
    exit 1
fi

while IFS=: read -r f1 f2
do
  ##CHECK IF PATH OF LINE IS NOT EMPTY
  if [[  ! -z "$f1"  ]]; then
    ##CHECK IF BRANCH OF LINE IS NOT EMPTY
    if [[  ! -z "$f2"  ]]; then
      ##CHECK IF PATH OF LINE EXISTS
      if [[ -d "$f1" ]]; then
        git -C "$f1" fetch --all && git -C "$f1" checkout "$f2" && git -C "$f1" reset --hard "$f2" && git -C "$f1" pull
      else
        ##CHECK IF LINE IS NOT COMMENDET OUT
        if [[ ! "$f1" =~ ^\s*# ]]; then
        echo "directory $f1 directory does not exist"
        fi
      fi
    fi
  fi
done <"$file"
