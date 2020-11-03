#!/bin/bash
##READ FROM GIT-LIST FILE AND PULL ALL
##STRUCTURE git.LIST
##/path/to/git/root/:branch
file="/root/scripts/git.list"
while IFS=: read -r f1 f2
do
        git -C $f1 fetch --all
        git -C $f1 checkout $f2
        git -C $f1 reset --hard $f2
        git -C $f1 pull
done <"$file
