#!/bin/sh

curl https://github.com/cli/cli/releases/download/v2.32.1/gh_2.32.1_linux_386.tar.gz --output gh.tar.gz
tar -xf gh_2.32.1_linux_386.tar.gz
export PATH="$HOME/gh/bin/:$PATH"

# Authenticate to github and get also the user scope
gh auth login -s user

gh repo clone oci-cis-landingzone-workshop-nose
cd oci-cis-landingzone-workshop-nose

git config user.name "$(gh api user -q .login)"
git config user.email "$(gh api user/public_emails -q first.email)"
