# Lab 02 - Implementing DevOps routines

Now that the Landing Zone is deployed, let's think about on how to collaborate using the landing zone

# Task 1 - Protect the main branch

Go to your repo settings

```sh
gh repo view --web
```

And go to `Code and automation > Branches` and create new branch protection rule

<!-- #TODO Add screenshots -->

# Task 2 - Setup Lightweight Static analysis

Create a new workflow file called tf.yml

<details>
<summary>tf.yml</summary>

```yaml
name: "Terraform"

permissions:
      id-token: write
      contents: read
      issues: write
      pull-requests: write

on:
  push:
    branches:
      - prepare
    paths:
      - .github/workflows/tf.yml
      - config/**
      - pre-config/**
      - modules/**
      - lz/**
  pull_request:
    branches:
      - main
    paths:
      - .github/workflows/tf.yml
      - config/**
      - pre-config/**
      - modules/**
      - lz/**

jobs:
  terraform:
    name: "Terraform"
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: lz
    permissions:
      pull-requests: write
    steps:
    - uses: actions/checkout@v3
    - uses: hashicorp/setup-terraform@v2
      with:
        terraform_version: 1.2.9

    - name: Terraform fmt
      id: fmt
      run: terraform fmt -check
      continue-on-error: true

    - name: Terraform Init
      id: init
      run: terraform init

    - name: Terraform Validate
      id: validate
      run: terraform validate -no-color
```

</details>

# Task 3 - Improving Code REsiliency using speculative runs

```sh
openssl genrsa -out ~/oci_api_key.pem 2048    
chmod go-rwx ~/oci_api_key.pem                    
openssl rsa -pubout -in ~/oci_api_key.pem -out ~/oci_api_key_public.pem
KEY_FINGERPRINT=$(oci iam user api-key upload --user-id $OCI_CS_USER_OCID --key-file ~/oci_api_key_public.pem --query data.fingerprint --raw-output)
export OCI_CLI_KEY_CONTENT="$(<~/oci_api_key.pem)"
```

We are going to use the OCI github action to generate our secrets

```sh
gh secret set OCI_CLI_USER --body "$OCI_CS_USER_OCID"
gh secret set OCI_CLI_REGION --body "$OCI_REGION"
gh secret set OCI_CLI_TENANCY --body "$OCI_TENANCY"
gh secret set OCI_CLI_FINGERPRINT --body "$KEY_FINGERPRINT"
gh secret set OCI_CLI_KEY_CONTENT < ~/oci_api_key.pem
gh variable set OCI_LZ_STACK_ID --body "$OCI_LZ_STACK_ID"
```
