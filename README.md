# svtplay-data
Every 6th hour a list of data of all content from SVTPlay is backed up in `singles_and_episodes` file. All available title page data is also stored in `title_pages`. I made this mostly just for fun but it can be useful for retrieving information that is no longer available on SVTPlay.

### If you for some reason want to use this in your own fork
Add the following to crontab with `crontab -e`

    * */6 * * * /PATH/TO/cronjob.sh

Next, run this and enter your credentials

    git config credential.helper store
    git push

and from here on after you login automatically when pushing to repo.
