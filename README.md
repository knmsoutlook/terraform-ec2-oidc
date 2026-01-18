Sure! Here’s a clear, beginner-friendly **README.md** covering everything — from repo setup, OIDC trust, Terraform, to GitHub Actions workflow with secrets integration:

---

````markdown
# Terraform EC2 Deployment with GitHub Actions and AWS OIDC

This repository shows how to deploy an AWS EC2 instance using Terraform, triggered by GitHub Actions with AWS OIDC authentication. No long-lived AWS keys needed!

---

## Prerequisites

- AWS account with permissions to create IAM Roles, EC2, etc.
- GitHub repository under your organization (e.g., `knmsoutlook`)
- Your SSH **public key** (e.g., from `~/.ssh/id_rsa.pub`)
- Basic knowledge of Terraform and GitHub Actions

---

## Step 1: Create IAM Role for GitHub OIDC

Create an IAM Role with the following trust policy to allow GitHub Actions from any repo in your organization to assume the role:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_AWS_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:knmsoutlook/*:*"
        }
      }
    }
  ]
}
````

* Replace `YOUR_AWS_ACCOUNT_ID` with your AWS account number.
* This trust policy allows **any repo in the `knmsoutlook` org** to assume the role.
* Attach necessary IAM policies to allow Terraform to create EC2, key pairs, etc.

---

## Step 2: Store your SSH Public Key in GitHub Secrets

1. Copy the contents of your SSH public key file (`id_rsa.pub`), starting with `ssh-rsa ...`.
2. Go to your GitHub repo → **Settings** → **Secrets and variables** → **Actions**.
3. Click **New repository secret**, name it `SSH_PUBLIC_KEY`.
4. Paste your public key content and save.

---

## Step 3: Terraform files

Your Terraform files (`main.tf`, `provider.tf`, `outputs.tf`) should be at the **root of your repo** (no separate `terraform/` folder needed).

Example `main.tf` snippet for EC2 with SSH key:

```hcl
variable "ssh_public_key" {
  description = "SSH public key for EC2"
  type        = string
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_key_pair" "deployer_key" {
  key_name   = "deployer-key"
  public_key = var.ssh_public_key
}

resource "aws_instance" "example" {
  ami           = "ami-0c02fb55956c7d316" # Amazon Linux 2 AMI, update as needed
  instance_type = "t2.micro"

  key_name = aws_key_pair.deployer_key.key_name

  tags = {
    Name = "GitHubActionEC2"
  }
}

output "instance_id" {
  value = aws_instance.example.id
}
```

---

## Step 4: GitHub Actions workflow

Create `.github/workflows/deploy.yml` with:

```yaml
name: Deploy Terraform EC2

on:
  push:
    branches:
      - main

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout repository
      uses: actions/checkout@v3

    - name: Configure AWS credentials via OIDC
      uses: aws-actions/configure-aws-credentials@v2
      with:
        role-to-assume: arn:aws:iam::YOUR_AWS_ACCOUNT_ID:role/Github-actions-Kamal
        aws-region: us-east-1

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2
      with:
        terraform_version: 1.6.0

    - name: Terraform Init
      run: terraform init

    - name: Terraform Plan
      run: terraform plan -var="ssh_public_key=${{ secrets.SSH_PUBLIC_KEY }}" -out=tfplan

    - name: Terraform Apply
      run: terraform apply -auto-approve tfplan
```

* Replace `YOUR_AWS_ACCOUNT_ID` with your actual AWS account number.
* The workflow assumes your Terraform files are in the root folder.
* The `ssh_public_key` variable is passed securely from GitHub Secrets.

---

## Step 5: Push changes and deploy

```bash
git add .
git commit -m "Setup Terraform EC2 deploy workflow with OIDC"
git push origin main
```

GitHub Actions will run automatically, authenticate via OIDC, and deploy the EC2 instance using your Terraform configuration.

---

## Troubleshooting tips

* **Invalid path errors**: Make sure Terraform files are in the correct folder as expected by workflow.
* **OIDC assume role errors**: Double-check IAM trust policy matches your repo and branch naming.
* **SSH key errors**: Use GitHub Secrets and Terraform variables to pass keys securely (do not commit private keys).
* **Terraform provider versions**: Adjust Terraform and provider versions in workflow and `provider.tf` if needed.

---

## Summary

* Use IAM Role with OIDC and wildcard trust to reuse role for all org repos.
* Pass SSH public key securely via GitHub Secrets and Terraform variable.
* Run Terraform commands from GitHub Actions workflow with correct working directory.

---

Feel free to open issues or ask questions!

---

**Happy Terraforming!** 🚀

```

---

That README.md will guide you step-by-step with all fixes and best practices in place!
```
