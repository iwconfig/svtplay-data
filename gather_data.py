#!/usr/bin/env python3

from pathlib import Path
from datetime import datetime
import json
import svtapi
import sys

data = [] 
for d in svtapi.all_titles_and_singles(): 
    try:
        data.append(svtapi.episode_info(d['contentUrl']))
    except svtapi.ParameterNotFound:
        data.extend(svtapi.all_episodes_info_by_title(d['contentUrl'])) 

datafile = Path('./singles_and_episodes')
datafile.touch(exist_ok=True)

with datafile.open('r+') as f:
    data.extend(f.read())
    data = list({v['id']:v for v in data}.values())
    f.seek(0)
    f.write(json.dumps(data, indent=2, ensure_ascii=False))
    f.truncate()
    sys.exit(0)
