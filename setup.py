#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""The setup script."""
import sys

from setuptools import find_packages, setup


def get_version(filename):
    """Extract the package version"""
    with open(filename, encoding='utf8') as in_fh:
        for line in in_fh:
            if line.startswith('__version__'):
                return line.split('=')[1].strip()[1:-1]
    raise ValueError("Cannot extract version from %s" % filename)


with open('README.rst', encoding='utf8') as readme_file:
    readme = readme_file.read()

try:
    with open('HISTORY.rst', encoding='utf8') as history_file:
        history = history_file.read()
except OSError:
    history = ''

# requirements for use
requirements = []

# requirements for development (testing, generating docs)
dev_requirements = [
    'better-apidoc',
    'coverage',
    'doctr',
    'flake8',
    'gitpython',
    'isort',
    'pre-commit',
    'pylint',
    'pytest',
    'pytest-cov',
    'pytest-xdist',
    'sphinx',
    'sphinx-autobuild',
    'sphinx-autodoc-typehints',
    'sphinx_rtd_theme',
    'travis-encrypt',
    'twine',
    'wheel',
]

if sys.version_info >= (3, 6):
    dev_requirements.append('black')

version = get_version('./src/pypkg_m7rap/__init__.py')

setup(
    author="Michael Goerz",
    author_email='mail@michaelgoerz.net',
    classifiers=[
        'Development Status :: 2 - Pre-Alpha',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: MIT License',
        'Natural Language :: English',
        'Programming Language :: Python :: 3.6',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
        'Natural Language :: English',
    ],
    description=(
        "Test of Python Packaging"
    ),
    python_requires='>=3.6',
    install_requires=requirements,
    extras_require={'dev': dev_requirements},
    license="MIT license",
    long_description=readme + '\n\n' + history,
    long_description_content_type='text/x-rst',
    include_package_data=True,
    keywords='pypkg_m7rap',
    name='pypkg_m7rap',
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    url='https://github.com/goerz/pypkg_m7rap',
    version=version,
    zip_safe=False,
)
