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

Then we will add the following job

<details>
<summary>tf.yml</summary>

```yaml
speculative-run:
    runs-on: ubuntu-latest
    name: List the display name and shape of the instances in my compartment
    env:
      OCI_CLI_USER: ${{ secrets.OCI_CLI_USER }}
      OCI_CLI_TENANCY: ${{ secrets.OCI_CLI_TENANCY }}
      OCI_CLI_FINGERPRINT: ${{ secrets.OCI_CLI_FINGERPRINT }}
      OCI_CLI_KEY_CONTENT: ${{ secrets.OCI_CLI_KEY_CONTENT }}
      OCI_CLI_REGION: ${{ secrets.OCI_CLI_REGION }}
      OCI_LZ_STACK_ID: ${{ secrets.OCI_LZ_STACK_ID }}
    steps:
      - uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.2.9

      - name: Retrieve latest state file
        uses: oracle-actions/run-oci-cli-command@v1
        id: find-compartment-id
        with:
          command: 'resource-manager stack get-stack-tf-state --file oci-tf.tfstate --stack-id "$OCI_LZ_STACK_ID"'
          query: "data[?name=='testing'].id"

      - name: Create PR git connection
        uses: oracle-actions/run-oci-cli-command@v1
        id: create-gh-pr-git-config
        with:
          command: 'resource-manager configuration-source-provider create-github-access-token-provider --compartment-id "$OCI_CLI_TENANCY" --access-token "${{ secrets.GITHUB_TOKEN }}" --api-endpoint "https://github.com" --display-name "gh-lz-pr-${{ github.event.number }}-action-${{ github.run_id }}"'
          query: "data.id"
      
      - name: Create PR Stack
        uses: oracle-actions/run-oci-cli-command@v1
        id: create-gh-pr-stack
        with:
          command: 'resource-manager stack create-from-git-provider --compartment-id "$OCI_CLI_TENANCY" --config-source-configuration-source-provider-id "${{ steps.create-gh-pr-git-config.outputs.raw_output }}" --config-source-branch-name "pull/${{ github.event.number }}/head" --config-source-repository-url "https://github.com/${{ github.repository }}" --config-source-working-directory lz --display-name "stack-gh-pr-${{ github.event.number }}-action-${{ github.run_id }}" --terraform-version "1.2.x" --variables "{\"tenancy_ocid\":\"$OCI_CLI_TENANCY\" , \"region\":\"$OCI_CLI_REGION\"}"'
          query: "data.id"
      
      - name: Import current stack
        uses: oracle-actions/run-oci-cli-command@v1
        id: import-gh-pr-stack
        with:
          command: ' oci resource-manager job create-import-tf-state-job --stack-id "${{ steps.create-gh-pr-stack.outputs.raw_output }}" --tf-state-file oci-tf.tfstate --wait-for-state SUCCEEDED --wait-for-state FAILED --wait-for-state CANCELED --max-wait-seconds 600 --wait-interval-seconds 10'
          query: "data.id"

      - name: Run speculative plan
        uses: oracle-actions/run-oci-cli-command@v1
        id: run-tf-plan
        with:
          command: 'resource-manager job create-plan-job --stack-id "${{ steps.create-gh-pr-stack.outputs.raw_output }}" --display-name "plan-gh-pr-${{ github.event.number }}-action-${{ github.run_id }}" --wait-for-state SUCCEEDED --wait-for-state FAILED --wait-for-state CANCELED --max-wait-seconds 600 --wait-interval-seconds 10'
          query: "data.id"
      
      - name: Get speculative plan
        uses: oracle-actions/run-oci-cli-command@v1
        id: create-gh-pr-stack
        with:
          command: 'resource-manager job get-job-tf-state --file pr-plan.tfplan --job-id "${{ steps.run-tf-plan.outputs.raw_output }}"'
          query: "data.id"
      
      - name: Terraform Validate
        id: parse-tfplan
        run: terraform show -no-color pr-plan.tfplan
      
      - uses: actions/github-script@v6
        if: github.event_name == 'pull_request'
        env:
          PLAN: "terraform\n${{ steps.parse-tfplan.outputs.stdout }}"
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          script: |
            // 1. Retrieve existing bot comments for the PR
            const { data: comments } = await github.rest.issues.listComments({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.issue.number,
            })
            const botComment = comments.find(comment => {
              return comment.user.type === 'Bot' && comment.body.includes('Terraform Format and Style')
            })
  
            // 2. Prepare format of the comment
            const output = `#### Terraform Format and Style 🖌\`${{ steps.fmt.outcome }}\`
            #### Terraform Initialization ⚙️\`${{ steps.init.outcome }}\`
            #### Terraform Validation 🤖\`${{ steps.validate.outcome }}\`
            <details><summary>Validation Output</summary>
  
            \`\`\`\n
            ${{ steps.validate.outputs.stdout }}
            \`\`\`
  
            </details>
  
            #### Terraform Plan 📖\`${{ steps.plan.outcome }}\`
  
            <details><summary>Show Plan</summary>
  
            \`\`\`\n
            ${process.env.PLAN}
            \`\`\`
  
            </details>
  
            *Pusher: @${{ github.actor }}, Action: \`${{ github.event_name }}\`, Working Directory: \`${{ env.tf_actions_working_dir }}\`, Workflow: \`${{ github.workflow }}\`*`;
  
            // 3. If we have a comment, update it, otherwise create a new one
            if (botComment) {
              github.rest.issues.updateComment({
                owner: context.repo.owner,
                repo: context.repo.repo,
                comment_id: botComment.id,
                body: output
              })
            } else {
              github.rest.issues.createComment({
                issue_number: context.issue.number,
                owner: context.repo.owner,
                repo: context.repo.repo,
                body: output
              })
            }
  
      - name: Get speculative plan
        uses: oracle-actions/run-oci-cli-command@v1
        id: cleanup-gh-pr-stack
        with:
          command: 'resource-manager stack delete --stack-id "${{ steps.create-gh-pr-stack.outputs.raw_output }}" --force'
```

</details>