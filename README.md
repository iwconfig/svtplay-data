# svtplay-data

Every 6th hour a list of data of all content from SVTPlay is backed up in [./singles_and_episodes.tar.xz](singles_and_episodes.tar.xz) file. All available title page data is also stored in [./title_pages.tar.xz](title_pages.tar.xz). I made this mostly just for fun but it can be useful for retrieving information that is no longer available on SVTPlay.

Extract archives using the tar command:

    tar xf singles_and_episodes.tar.xz
    tar xf title_pages.tar.xz

The code used to acquire this data is located in [./src](src).
