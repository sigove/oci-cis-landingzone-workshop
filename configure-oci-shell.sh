#!/bin/sh

curl https://github.com/cli/cli/releases/download/v2.32.1/gh_2.32.1_linux_386.tar.gz --output gh.tar.gz
tar -xf gh_2.32.1_linux_386.tar.gz
export PATH="~/gh/bin/:$PATH"
