#!/bin/sh

## Add this to crontab with crontab -e
## * */6 * * * /PATH/TO/cronjob.sh
##

TMPDIR=/tmp/svtplay-data
USERNAME='your username'
PASSWORD='your password'
EMAIL='your email'

mkdir -p $TMPDIR
cd $TMPDIR

git clone https://github.com/iwconfig/svtplay-data .

git config user.email $EMAIL
git config user.name $USERNAME

if ./gather_data.py; then
    git add *
    git commit -m "Daily data update: $(date '+%Y-%m-%d %H:%M:%S')"
    git push -u https://$USERNAME:$PASSWORD@github.com/$USERNAME/svtplay-data master
    rm -rf $TMPDIR
fi
