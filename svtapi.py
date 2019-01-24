from urllib.request import urlopen, Request
from urllib.parse import urlparse, quote
from http.client import RemoteDisconnected
from functools import lru_cache, wraps
from datetime import datetime, timedelta
import json, re, time


_API_URL                 = 'https://www.svtplay.se/api/'

_EPISODE_INFO            = 'episode?id={artid}'
_ALL_EPISODES_INFO_TITLE = 'title_episodes_by_article_id?articleId={artid}'
_PROGRAM_INFO_SLUG       = 'title?slug={slug}'
_ALL_TITLES_AND_SINGLES  = 'all_titles_and_singles'

class JSONResponseEmpty(Exception):
    def __init__(self):
        super(JSONResponseEmpty, self).__init__('JSON response is empty')

class ParameterNotFound(Exception):
    def __init__(self, msg):
        super(ParameterNotFound, self).__init__(msg)

class Dict(dict):  
    def get(self, key, default=None):  
        value = super(Dict, self).get(key, default) 
        if value is None:  
            if key is 'id': 
                raise ParameterNotFound('Article ID not found')
            if key is 'slug':
                raise ParameterNotFound('Slug not found')
        return value

def timed_cache(**timedelta_kwargs):                                              
    def _wrapper(f):                                                              
        update_delta = timedelta(**timedelta_kwargs)                              
        next_update = datetime.utcnow() - update_delta                            
        # Apply @lru_cache to f with no cache size limit                          
        f = lru_cache(maxsize=4)(f)                                          
                                                                                                                      
        @wraps(f)                                                       
        def _wrapped(*args, **kwargs):                                            
            nonlocal next_update                                                  
            now = datetime.utcnow()                                               
            if now >= next_update:                                                
                f.cache_clear()                                                   
                next_update = now + update_delta                                
            return f(*args, **kwargs)                                             
        return _wrapped                                                           
    return _wrapper

def url_parameters(item):
    regex = r'(?:\/video|\/genre)?\/*((?P<id>\d+)\/|(?P<slug>[\w\-]+))(?:(\/.*)?)'
    params = Dict()
    for match in re.finditer(regex, urlparse(str(item)).path):
        for key, value in match.groupdict().items():
            if value is not None:
                params.update({key: value})
    return params

def _get(url):
    print(url)
    header = {'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:64.0) Gecko/20100101 Firefox/64.0'}
    try:
        response = urlopen(Request(url, headers=header))
    except RemoteDisconnected:
        time.sleep(3)
        response = urlopen(Request(url, headers=header))
    data = response.read().decode('utf-8')
    if len(data) < 1: #or data in (None, 'null'):
        raise JSONResponseEmpty
    return json.loads(data)

get = timed_cache(minutes=2)(_get)

def episode_info(item):
    id = url_parameters(item).get('id')
    return get(_API_URL + _EPISODE_INFO.format(artid=id))

def all_episodes_info_by_title(item):
    id = program_info_by_slug(item).get('articleId')
    return get(_API_URL + _ALL_EPISODES_INFO_TITLE.format(artid=id))

def all_titles_and_singles():
    return get(_API_URL + _ALL_TITLES_AND_SINGLES)

def program_info_by_slug(item):
    slug = url_parameters(item).get('slug')
    return get(_API_URL + _PROGRAM_INFO_SLUG.format(slug=slug))
