from setuptools import find_packages
from setuptools import setup


setup(
    name='pre_commit_terraform',
    description='Pre-commit hooks for Terraform modules',
    url='https://github.com/devops-workflow/pre-commit-terraform',
    version='0.0.1',

    author='Steven Nemetz',
    #author_email='',

    # TODO: implement tests for each version supported here
    classifiers=[
        'License :: OSI Approved :: MIT License',
        'Programming Language :: Python :: 2',
        'Programming Language :: Python :: 2.7',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.6',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: Implementation :: CPython',
        'Programming Language :: Python :: Implementation :: PyPy',
    ],

    packages=find_packages(exclude=('tests*', 'testing*')),
    install_requires=[
        'requests',
    #    # quickfix to prevent pycodestyle conflicts
    #    'flake8!=2.5.3',
    #    'autopep8>=1.3',
    #    'pyyaml',
    #    'six',
    ],
    entry_points={
        'console_scripts': [
            'terraform_template = hooks.terraform_template:main',
        ],
    },
)
