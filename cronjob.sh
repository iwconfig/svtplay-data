#!/bin/sh

## Add this to crontab with crontab -e
## * */6 * * * /PATH/TO/cronjob.sh
##

TMPDIR=/tmp/svtplay-data

mkdir -p $TMPDIR
cd $TMPDIR

git clone https://github.com/iwconfig/svtplay-data .

if ./gather_data.py; then
    git commit -a -m "Daily data update: $(date '+%Y-%m-%d %H:%M:%S')"
    git push -u origin master
    rm -rf $TMPDIR
fi
