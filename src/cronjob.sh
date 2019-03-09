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
function echo {
    msg="$(date '+%Y-%m-%d %H:%M:%S'): $@"
    builtin echo "$msg" >> $LOGFILE
    builtin echo -e "\r$msg"
}

# log errors
function error {
    echo "ERROR: $@"
    # Send a notification also. Dependent on notify-error-daemon.sh on
    # the other LAN computer.
    builtin echo "$@" | nc debian.local 15328
    exit 1
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
git config credential.helper store
cd $DIR || error "Could not change directory to $DIR"

echo "Pulling a clean slate of remote git repository..."
git checkout master ## ensure we're on master branch
git fetch --all || error "Could not fetch the latest from remote repository!"
git reset --hard origin/master

echo "Decompressing data files..."
for file in *.json.xz; do
    xz -dfk "$file" || error "Decompression failed!"
done

echo "Running gather_data.py..."
if nice -12 ./src/gather_data.py; then
    echo "Data gathering went fine."

    function get_size { stat -c %s $1 || error "Could not get size of $1!"; }
    for file in {singles_and_episodes.json,title_pages.json}; do
	if [ $(get_size $file) -gt $(get_size ${file}.bak) ]; then
	    echo "Compressing $file"
	    xz -vvkf9eT2 $file || error "Comression failed!"
	else
	    echo "$file is unchanged. Leaving ${file}.tar.xz as is..."
	fi
	echo "Removing uncompressed files: $file and ${file}.bak..."
	rm $file ${file}.bak || error "Could not remove files!"
    done

    echo "Making commit..."
    git add singles_and_episodes.json.xz title_pages.json.xz
    git commit -m "Daily data update: $(date '+%Y-%m-%d %H:%M:%S')" -m "These archives contain all data collected since 2019-01-23 at circa 21:00 hours."

    echo "Pushing changes to remote repo"
    git push -f -u origin master || error "Could not push to remote repo!"

    echo "Now time for some cleaning..."
    if [ ! -f /tmp/bfg.jar ]; then
	echo "Downloading BFG Repo-Cleaner jar file to /tmp directory"
	curl -L -o /tmp/bfg.jar https://repo1.maven.org/maven2/com/madgag/bfg/1.13.0/bfg-1.13.0.jar || error "Could not download!"
    fi

    git fetch --all
    git reset --hard origin/master

    echo "Removing old compressed data files from earlier commits with BFG tool..."
    nice -12 java -jar /tmp/bfg.jar -D '*.json.xz' --private . || error "Java execution failed!"

    echo "Cleaning reflogs and collecting repo garbage"
    git reflog expire --expire=now --all || error "git reflog command failed! Could not cleanup reflogs."
    git gc --prune=now --aggressive || error "git gc command failed! Could not garbage collect."

    echo "Removing empty commits..."
    git filter-branch --tag-name-filter cat --commit-filter 'git_commit_non_empty_tree "$@"' -- --all || error "Could not remove empty commits!"
    git for-each-ref --format="%(refname)" refs/original/ | xargs -r -n 1 git update-ref -d || error "Could not update git references!"

    echo "Force pushing cleaned repo to remote"
    git push -f

    echo "All done, mission accomplished!"
    exit 0
else
    echo "Something went wrong, aborting..."
    exit 1
fi
