<h1 align="center">
  svtplay-data
</h1>

<p align="center">
  <a target="_blank" rel="noopener noreferrer" href="https://www.svtplay.se"><img align="middle" src="https://img.shields.io/date/1548277200.svg?label=initial%20backup&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMjUuOTQxNDEgMTc5LjQ1MzEzIj48cGF0aCBmaWxsPSIjMDRjNTA0IiBkPSJNMCAxNzkuNDUzMTNsMTI1Ljk0MTQtOTAuNDcyNjYyTC4wNjY0MDYgMCAwIDE3OS40NTMxM3oiLz48L3N2Zz4=&logoColor=00C700&colorA=0b0c0d&colorB=00C700&style=popout"></a>
  <a href="https://github.com/iwconfig/svtplay-data/blob/master/singles_and_episodes.json.xz"><img align="middle" src="https://img.shields.io/badge/dynamic/json.svg?url=https://img.badgesize.io/iwconfig/svtplay-data/master/singles_and_episodes.json.xz.json&query=prettySize&label=singles_and_episodes.json.xz%20size&logo=json&logoColor=00C700&colorA=0b0c0d&colorB=00C700&style=popout"></a>
  <a href="https://github.com/iwconfig/svtplay-data/blob/master/title_pages.json.xz"><img align="middle" src="https://img.shields.io/badge/dynamic/json.svg?url=https://img.badgesize.io/iwconfig/svtplay-data/master/title_pages.json.xz.json&query=prettySize&label=title_pages.json.xz%20size&logo=json&logoColor=00C700&colorA=0b0c0d&colorB=00C700&style=popout"></a>
  <a href="https://github.com/iwconfig/svtplay-data"><img align="middle" src="https://img.shields.io/github/repo-size/iwconfig/svtplay-data.svg?logo=github&logoColor=00C700&colorA=0b0c0d&colorB=00C700&style=popout"></a>
</p>

Every 6th hour a list of data of all content from SVTPlay is backed up in [./singles_and_episodes.json.xz](singles_and_episodes.json.xz) file. All available title page data is also stored in [./title_pages.json.xz](title_pages.json.xz). I made this mostly just for fun but it can be useful for retrieving information that is no longer available on SVTPlay.

Extract archives using the xz command:

    xz -dk singles_and_episodes.json.xz
    xz -dk title_pages.json.xz

The code used to acquire this data is located in [./src](src).
