#!/usr/bin/env bash

## Add this cron rule with crontab -e (not the explanation tree)
## 5 0,6,12,18 * * * /PATH/TO/cronjob.sh
## | ¯¯¯¯¯¯¯¯¯\¯¯¯¯¯\
## |           Run every day at 00:05, 06:05, 12:05 and 18:05.
##  \          ¯¯¯¯¯¯¯¯¯¯¯¯¯    ¯¯¯¯¯  ¯¯¯¯¯  ¯¯¯¯¯     ¯¯¯¯¯
##   Wait five minutes to let SVTPlay adjust their dataset, especially at 00:00.
##   Should not be a problem but just to be safe.     
##
## and run:
##   $ git config credential.helper store
##   $ git push
## Enter your credentials to login automatically
## from here on after.

LOCKDIR=/tmp/svtplay-data.lock
PIDFILE=$LOCKDIR/pid
LOGFILE=/tmp/svtplay-data.log
DIR=$HOME/scripts/svtplay-data

# make echo act as a logger
function echo() {
    msg="$(date '+%Y-%m-%d %H:%M:%S'): $@"
    builtin echo "$msg" >> $LOGFILE
    builtin echo -e "\r$msg"
}

# trap cleanup
function cleanup {
    echo "Removing pid file '$PIDFILE'"
    if ! rm $LOCKDIR/pid 2>/dev/null; then
	echo "Failed to remove pid file '$PIDFILE'"
        exit 1
    fi
    echo "Removing lock directory '$LOCKDIR'"
    if ! rmdir $LOCKDIR; then
        echo "Failed to remove lock directory '$LOCKDIR'"
        exit 1
    fi
    exit 0
}

# check locker
if mkdir $LOCKDIR 2>/dev/null; then
    cat <<< $$ > $PIDFILE
    echo PID: $(cat $PIDFILE)
    trap "cleanup" EXIT
    echo "Acquired lock, running"
else
    echo "Could not create lock directory '$LOCKDIR'."
    if [ -f $PIDFILE ] && kill -0 $(cat $PIDFILE) 2>/dev/null; then	
	echo "Process is running with PID $(cat $PIDFILE)."
    else
	if [ -w $LOCKDIR ]; then
	    echo "The lock already exists, but no process is running..."
	    echo "Trying to remove and restart. If no success, then try to remove it manually."
	    trap "cleanup; $0" EXIT	    
	else
	    echo "No write access!"
	fi
    fi
    exit 1
fi

# main
cd $DIR
nice -10 git checkout -b 'temp'
nice -10 git branch -D master
nice -10 git checkout master
nice -10 git branch -D temp
nice -10 git clean -xffd
nice -10 git pull

nice -10 tar xf singles_and_episodes.tar.xz title_pages.tar.xz

if nice -12 ./gather_data.py; then
    echo "Data gathering went fine. Now compressing file..."
    nice -10 tar cJf singles_and_episodes.tar.xz singles_and_episodes
    nice -10 tar cJf title_pages.tar.xz title_pages
    
    echo "Compression is done. Now making commit and pushing to github..."
    nice -10 git add singles_and_episodes.tar.xz title_pages.tar.xz
    nice -10 git commit -m "Daily data update: $(date '+%Y-%m-%d %H:%M:%S')"
    nice -10 git push -u origin master

    echo "Done. Now removing uncompressed files and then mission accomplished."
    rm singles_and_episodes title_pages
    exit 0
else
    echo "Something went wrong, aborting..."
    exit 1
fi
