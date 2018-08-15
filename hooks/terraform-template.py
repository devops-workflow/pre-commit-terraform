'''
Use github api v3 with Python
https://pre-commit.com/#python
Needs setup.py to be installed via pip install .
'''

from datetime import datetime
from pprint import pprint
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
        print('ERROR: Failed to list github repository: {}/{}. Return HTTP code: {}\nHeader: {}'.format(owner, repo, r.status_code, r.headers))
        sys.exit()
    # TODO: check for Last-Modified header. if older than maintained files, don't need to copy?
    #       Not 100% but will help with rate limit
    # Date         : Wed, 15 Aug 2018 02:22:24 GMT
	# Last-Modified: Sat, 28 Jul 2018 16:41:24 GMT
    last_modified = datetime.strptime(r.headers['Last-Modified'], github_date_format)
    date = datetime.strptime(r.headers['Date'], github_date_format)
    # Date is time of request
    print("\tNew Date: {}\n\tModified: {}".format(date.strftime('%c'), last_modified.strftime('%c')))
    objects = r.json()['tree']
    return objects
    #return last_modified, objects

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
    with open(path, "w") as file:
      file.write(contents)
      file.close()


def main(argv=None):
    # TODO: need force options: maintained, all
    parser = argparse.ArgumentParser(description='Terraform module templater', version=version)
    parser.add_argument('--owner',
        help='Owner name for the repository',
    )
    parser.add_argument('--repo',
        help='Repository name'
    )
    parser.add_argument('--maintained_path',
        action='append', nargs='*', default=[],
        help='File paths to always make sure are current',
    )
    args = parser.parse_args(argv)
    if debug:
        print('Args: {}'.format(args))
        print('Owner: {}'.format(args.owner))
        print('Repo: {}'.format(args.repo))
        print('maintained_path: {}'.format(args.maintained_path))
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


    repo_objects = get_repo_objects(owner=owner, repo=repo)
    # last_modified, repo_objects = get_repo_objects(owner=owner, repo=repo)
    '''
    for object in repo_objects:
        if object['type'] == 'tree':
            mkdir(object['path'])
        if object['type'] != 'blob':
            continue
        if object['path'] in paths:
            # Copy maintained files
            # Check repo date against file path
            # t = os.path.getmtime(object['path'])
            # file_time = datetime.fromtimestamp(t)
            # t = os.stat(object['path']).st_mtime
            # if file_time < last_modified:
            write_file(get_file(object['url']), object['path'])
        if not os.path.exists(object['path']):
            # Copy missing files
            write_file(get_file(object['url']), object['path'])
    '''
if __name__ == '__main__':
  exit(main())
