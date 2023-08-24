# Lab 01 - Deploy with a Landing Zone

## Task 1 - Setup a Ephemeral Environment

Go to the OCI Cloud shell using this [link](https://cloud.oracle.com/?&bdcstate=maximized&cloudshell=true)

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/saguadob/oci-cis-landingzone-workshop-nose/main/configure-oci-shell.sh)"
```

```sh
# Authenticate to github and get also the user scope
gh auth login -s user -h github.com -p https -w

gh repo fork saguadob/oci-cis-landingzone-workshop-nose --fork-name oci-cis-landingzone-workshop --clone --remote=true --remote-name=origin
cd oci-cis-landingzone-workshop

git config user.name "$(gh api user -q .login)"
git config user.email "$(gh api user/public_emails -q first.email)"
gh repo set-default "$(gh api user -q .login)/oci-cis-landingzone-workshop"
```

The following command downloads and runs this 📃 [script file](../configure-oci-shell.sh)

## Task 2 - Analize Folder structure

## Task 3 - TF Plan

``` sh
 oci resource-manager job create-plan-job --stack-id $stack_id
```

## Task 4 - Apply Configuration

oci resource-manager job create-apply-job --execution-plan-strategy $execution_plan_strategy --stack-id $stack_id

