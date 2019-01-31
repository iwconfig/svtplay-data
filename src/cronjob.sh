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

echo "Pulling a clean slate of remote git repository..."
cd $DIR || error "Could not change directory to $DIR"
nice -10 git checkout -b temp
nice -10 git branch -D master
nice -10 git checkout master
nice -10 git branch -D temp
nice -10 git clean -xffd
nice -10 git pull || error "Could not pull the latest from remote repository!"

echo "Decompressing data files..."
for file in *.tar.xz; do
    tar xf "$file" || error "Decompression failed!"
done

echo "Running gather_data.py..."
if nice -12 ./src/gather_data.py; then
    echo "Data gathering went fine."
    function get_size { stat -c %s $1 || error "Could not get size of $1!"; }
    for file in {singles_and_episodes,title_pages}; do
	if [ $(get_size $file) -gt $(get_size ${file}.bak) ]; then
	    echo "Compressing $file"
	    nice -10 tar cJf ${file}.tar.xz $file || error "Comression failed!"
	else
	    echo "$file is unchanged. Leaving ${file}.tar.xz as is..."
	fi
	echo "Removing uncompressed files: $file and ${file}.bak..."
	rm $file ${file}.bak || error "Could not remove files!"
    done

    echo "Check/compression is done. Now making commit..."
    nice -10 git add singles_and_episodes.tar.xz title_pages.tar.xz
    nice -10 git commit -m "Daily data update: $(date '+%Y-%m-%d %H:%M:%S')"

    echo "Downloading BFG Repo-Cleaner jar file to /tmp directory"
    curl -L -o /tmp/bfg.jar https://repo1.maven.org/maven2/com/madgag/bfg/1.13.0/bfg-1.13.0.jar || error "Could not download!"

    echo "Removing old compressed data files from earlier commits..."
    java -jar /tmp/bfg.jar -D '*.tar.xz' --private $DIR || error "Java execution failed!"
    git reflog expire --expire=now --all || error "git reflog command failed! Could not cleanup reflogs."
    git gc --prune=now --aggressive || error "git gc command failed! Could not garbage collect."

    echo "Removing empty commits..."
    git filter-branch --tag-name-filter cat --commit-filter 'git_commit_non_empty_tree "$@"' -- --all || error "Could not remove empty commits!"
    git for-each-ref --format="%(refname)" refs/original/ | xargs -n 1 git update-ref -d || error "Could not update git references!"

    echo "Pushing changes to remote repo"
    nice -10 git push -f -u origin master || error "Could not push to remote repo!"

    echo "Removing BFG Repo-Cleaner jar file..."
    rm /tmp/bfg.jar || error "Could not remove /tmp/bfg.jar file!"

    echo "All done, mission accomplished!"
    exit 0
else
    echo "Something went wrong, aborting..."
    exit 1
fi
