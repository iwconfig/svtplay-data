# svtplay-data
Every 6th hour a list of data of all content from SVTPlay is backed up in `singles_and_episodes` file. All available title page data is also stored in `title_pages`. I made this mostly just for fun but it can be useful for retrieving information that is no longer available on SVTPlay.

### If you for some reason want to use this in your own fork
Add the following rule to crontab with `crontab -e` (not the explanation tree)

    5 0,6,12,18 * * * /PATH/TO/cronjob.sh
    | ¯¯¯¯¯¯¯¯¯\¯¯¯¯¯\
    |           Run every day at 00:05, 06:05, 12:05 and 18:05.
     \          ¯¯¯¯¯¯¯¯¯¯¯¯¯    ¯¯¯¯¯  ¯¯¯¯¯  ¯¯¯¯¯     ¯¯¯¯¯
      Wait five minutes to let SVTPlay adjust their dataset, especially at 00:00.
      Should not be a problem but just to be safe.                         ¯¯¯¯¯

Next, run this and enter your credentials

    git config user.email "your@email.org"
    git config user.name "your name"
    git config credential.helper store
    git push

and from here on after you login automatically when pushing to repo.


## TODO/CONSIDER

* ~apply compression~ or
* use sqlite database (have a look at [cannadayr/git-sqlite](https://github.com/cannadayr/git-sqlite))
