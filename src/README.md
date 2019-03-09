# svtplay-data
Every 6th hour a list of data of all content from SVTPlay is backed up in [../singles_and_episodes.json.xz](../singles_and_episodes.json.xz) file. All available title page data is also stored in [../title_pages.json.xz](../title_pages.json.xz). I made this mostly just for fun but it can be useful for retrieving information that is no longer available on SVTPlay.

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

The [.githooks/pre-commit](.githooks/pre-commit) hook verifies the json files before comitting using jq or python. Apply it by running:

    git config --local core.hooksPath "$(git rev-parse --show-toplevel)/src/.githooks/"

I also use zram in order to optimize LZMA/LZMA2 compression which consumes a lot of memory. Just use [this](https://github.com/novaspirit/rpi_zram) and you're good to go.

To get notifications when an error occur, I wrote a little daemon which listens on port 15328 for incoming error messages and forwards them to my notification daemon. This is done with netcat and the daemon script is expected to sit in the background on the receiving LAN computer.

## TODO/CONSIDER

* ~apply compression~ or
* use sqlite database (have a look at [cannadayr/git-sqlite](https://github.com/cannadayr/git-sqlite))
* use email notifications
