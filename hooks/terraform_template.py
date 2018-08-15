'''
Use github api v3 with Python
https://pre-commit.com/#python
Needs setup.py to be installed via pip install .
'''
# TODO:
#   move request error handling to own function

from collections import namedtuple
from datetime import datetime
import argparse
import base64
import errno
import json
import os
import requests
import sys

version = '0.0.1'
debug   = True
# Parameter defaults
repo_owner       = 'devops-workflow'
repo_name        = 'terraform-template'
maintained_paths = ['.circleci/config.yml', '.pre-commit-config.yaml']

def get_file(url):
    '''
    Download file contents from github
    '''
    r = requests.get(url)
    if r.status_code != requests.codes.ok:
        print('ERROR: Failed to get file: {}. Return HTTP code: {}'.format(url, r.status_code))
        sys.exit()
    results = r.json()
    if 'encoding' in results and results['encoding'] == 'base64':
        return base64.b64decode(results['content'])
    else:
        return results['content']

def get_repo_objects(owner, repo):
    '''
    Get list of all objects in github repository
    '''
    # Without auth can get rate limited easily. Returns 403
    #   See current limits: https://api.github.com/rate_limit
    # Any way to use user's current access?? Or use web interface?
    github_date_format = '%a, %d %b %Y %H:%M:%S %Z'
    url = 'https://api.github.com/repos/{}/{}/git/trees/master'.format(owner, repo)
    params = { 'recursive' : '1' }
    r = requests.get(url, params=params)
    if r.status_code != requests.codes.ok:
        # TODO:
        #   403 due to rate, say so and what limit is with refresh time
        #       'X-RateLimit-Remaining': '52'
        #       'X-RateLimit-Reset': '1534365984'
        #       'X-RateLimit-Limit': '60'
        #   404 Not Found -> owner/repo doesn't exist or is not public
        print('ERROR: Failed to list github repository: {}/{}. Return HTTP code: {}\nHeader: {}'.format(owner, repo, r.status_code, r.headers))
        sys.exit()
    last_modified = datetime.strptime(r.headers['Last-Modified'], github_date_format)
    objects = r.json()['tree']
    return last_modified, objects

def mkdir(path):
    '''
    Create directory path is it doesn't exist
    '''
    if path != "":
        try:
            os.makedirs(path)
        except OSError as e:
            if e.errno != errno.EEXIST:
                raise

def write_file(contents, path):
    print('Creating/updating file {}'.format(path))
    with open(path, "w") as file:
      file.write(contents)
      file.close()

def get_args(argv=None):
    # TODO: need force options: copy maintained, copy all
    ### Handle arguments
    ARGS = namedtuple('ARGS', 'paths owner repo')
    parser = argparse.ArgumentParser(description='Terraform module templater', version=version)
    parser.add_argument('--owner',
        help='Owner name for the Github repository',
    )
    parser.add_argument('--repo',
        help='Github repository name'
    )
    parser.add_argument('--maintained_path',
        action='append', nargs='*', default=[],
        help='File paths to always make sure are current',
    )
    parser.add_argument('filenames',
        nargs='*',
        help='Filenames pre-commit believes are changed.',
    )
    args = parser.parse_args(argv)
    if debug:
        print('Args: {}'.format(args))
    if args.maintained_path == []:
        paths = maintained_paths
    elif any(isinstance(i, list) for i in args.maintained_path):
        # Flatten list of lists. All elements must be lists.
        # A string will get ripped apart
        paths = [item for sublist in args.maintained_path for item in sublist]
    else:
        paths = args.maintained_path
    if bool(args.owner) ^ bool(args.repo):
        parser.error('--owner and --repo must be given together')
    owner = args.owner if args.owner is not None else repo_owner
    repo = args.repo if args.repo is not None else repo_name
    if debug:
        print('Using paths: {}'.format(paths))
        print('Using repo: {}/{}'.format(owner, repo))
    return ARGS(paths, owner, repo)

def main(argv=None):
    retval = 0
    args = get_args(argv)
    ### Process github template repo and copy what is needed
    (last_modified, repo_objects) = get_repo_objects(owner=args.owner, repo=args.repo)
    for object in repo_objects:
        if object['type'] == 'tree':
            mkdir(object['path'])
        if object['type'] != 'blob':
            continue
        if object['path'] in args.paths:
            # Copy maintained files
            # Check repo date against file path.
            # Copy if repo updated more recently
            file_time = datetime.fromtimestamp(os.path.getmtime(object['path']))
            if file_time < last_modified:
                write_file(get_file(object['url']), object['path'])
                retval = 1
        if not os.path.exists(object['path']):
            # Copy missing files
            write_file(get_file(object['url']), object['path'])
            retval = 1
    return retval

if __name__ == '__main__':
  exit(main())
