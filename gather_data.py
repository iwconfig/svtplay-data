#!/usr/bin/env python3

from pathlib import Path
from datetime import datetime
import json
import svtapi

class StreamArray(list):
    def __init__(self, generator):
        self.generator = generator
        self._len = 1

    def __iter__(self):
        self._len = 0
        for item in self.generator:
            yield item
            self._len += 1

    def __len__(self):
        return self._len

def stream_handler(data):
    data = sorted(data, key=lambda k: k['programTitle'])
    for dct in data:
        yield dct

def json_cleanup(data):
    for x in 'message', 'messages':
        del data[x]    
    return data

singles_and_episodes = []
title_pages = []
for d in svtapi.all_titles_and_singles():
    try:
        dct = svtapi.episode_info(d['contentUrl'])
        singles_and_episodes.append(json_cleanup(dct))
    except svtapi.ParameterNotFound:
        dctlist = svtapi.all_episodes_info_by_title(d['contentUrl'])
        for dct in dctlist:
            dct = json_cleanup(dct)
        singles_and_episodes.extend(dctlist)
    try: 
        dct = svtapi.program_info_by_slug(d['contentUrl'])
        title_pages.append(json_cleanup(dct))
    except svtapi.JSONResponseEmpty: 
        pass
        
data = [
    (singles_and_episodes, Path('./singles_and_episodes')),
    (title_pages, Path('./title_pages'))
]

for data, datafile in data:
    if datafile.is_file():
        datafile.rename(datafile.with_suffix('.bak'))

        with datafile.with_suffix('.bak').open() as bakfile:
            bakdata = json.load(bakfile)

        data.extend(bakdata)
        data = list({v['id']:v for v in data}.values())

    with datafile.open('x') as outfile:
        stream_array = StreamArray(stream_handler(data))
        for dct in json.JSONEncoder(indent=2, ensure_ascii=False, sort_keys=True).iterencode(stream_array):
            outfile.write(dct)

    if datafile.with_suffix('.bak').is_file():
        datafile.with_suffix('.bak').unlink()

