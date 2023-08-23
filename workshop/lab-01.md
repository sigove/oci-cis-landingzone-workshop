# Lab 01 - Deploy with a Landing Zone

## Task 1 - Setup a Ephemeral Environment

Go to the OCI Cloud shell using this [link](https://cloud.oracle.com/?&bdcstate=maximized&cloudshell=true)

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/saguadob/oci-cis-landingzone-workshop-nose/prepare/configure-oci-shell.sh)"
```

The following command downloads and runs this 📃 [script file](../configure-oci-shell.sh)

## Task 2 - Analize Folder structure

## Task 3 - TF Plan

``` sh
 oci resource-manager job create-plan-job --stack-id $stack_id
```

## Task 4 - Apply Configuration

oci resource-manager job create-apply-job --execution-plan-strategy $execution_plan_strategy --stack-id $stack_id

