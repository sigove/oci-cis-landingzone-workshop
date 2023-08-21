#!/bin/sh

wget https://github.com/cli/cli/releases/download/v2.32.1/gh_2.32.1_linux_386.tar.gz -O gh.tar.gz
tar -xf gh.tar.gz
export PATH="$HOME/gh_2.32.1_linux_386/bin/:$PATH"

# Authenticate to github and get also the user scope
gh auth login -s user

gh repo clone saguadob/oci-cis-landingzone-workshop-nose
cd oci-cis-landingzone-workshop-nose

git config user.name "$(gh api user -q .login)"
git config user.email "$(gh api user/public_emails -q first.email)"

git_config_ocid=$(oci resource-manager configuration-source-provider create-github-access-token-provider --compartment-id "$OCI_CMP_ID" --access-token "$(gh auth token)" --api-endpoint "https://github.com"  --display-name "gh-lz-01" --query data.id --raw-output) 

oci resource-manager stack create-from-git-provider --compartment-id "$OCI_CMP_ID" --config-source-configuration-source-provider-id "$git_config_ocid" --config-source-branch-name main --config-source-repository-url "$(gh repo view --json url -q .url)" --config-source-working-directory config --display-name "stack-gh-oci-lz-01" --terraform-version "1.2.x"