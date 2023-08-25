#!/bin/sh

#Download and install GH CLI
wget https://github.com/cli/cli/releases/download/v2.32.1/gh_2.32.1_linux_386.tar.gz -O gh.tar.gz
tar -xf gh.tar.gz
export PATH="$HOME/gh_2.32.1_linux_386/bin/:$PATH"
echo 'export PATH="$HOME/workshop/gh_2.32.1_linux_386/bin/:$PATH"' >> ~/.bashrc

# Authenticate to github and get also the user scope
gh auth login -s user -h github.com -p https -w

gh repo fork saguadob/oci-cis-landingzone-workshop-nose --fork-name oci-cis-landingzone-workshop --clone --remote=true --remote-name=origin
cd oci-cis-landingzone-workshop

git config user.name "$(gh api user -q .login)"
git config user.email "$(gh api user/public_emails -q first.email)"
gh repo set-default "$(gh api user -q .login)/oci-cis-landingzone-workshop"

 
