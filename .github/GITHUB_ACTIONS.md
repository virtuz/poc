# GitHub Actions CI/CD for Terraform

This repository includes automated CI/CD pipelines for Terraform infrastructure deployment using GitHub Actions.

## Workflows

### 1. Terraform Plan (Pull Requests)

**File**: `.github/workflows/terraform-plan.yml`

**Trigger**: Automatically runs when a pull request is opened or updated against the `main` branch with changes to:
- Any files in the `terraform/` directory
- The workflow file itself

**Actions**:
1. Checks out the code
2. Sets up Terraform
3. Configures AWS credentials
4. Runs `terraform fmt -check` to validate formatting
5. Runs `terraform init` to initialize the working directory
6. Runs `terraform validate` to validate the configuration
7. Runs `terraform plan` to show proposed changes
8. Posts a comment on the PR with the plan output

**Purpose**: Allows reviewers to see exactly what infrastructure changes will be made before merging.

### 2. Terraform Apply (Main Branch)

**File**: `.github/workflows/terraform-apply.yml`

**Trigger**: Automatically runs when code is pushed/merged to the `main` branch with changes to:
- Any files in the `terraform/` directory
- The workflow file itself

**Actions**:
1. Checks out the code
2. Sets up Terraform
3. Configures AWS credentials
4. Runs `terraform init` to initialize the working directory
5. Runs `terraform plan` to create an execution plan
6. Runs `terraform apply -auto-approve` to apply the changes from the plan

**Purpose**: Automatically deploys approved infrastructure changes to AWS.

**Security Note**: By default, the workflow applies changes automatically. For production environments, it's strongly recommended to enable GitHub environment protection rules to require manual approval before deployment. See the "Advanced Configuration" section for setup instructions.

## Required Secrets

The following secrets must be configured in your GitHub repository settings (Settings → Secrets and variables → Actions):

### Secrets

1. **AWS_ACCESS_KEY_ID**
   - Description: AWS access key for Terraform to authenticate
   - How to get: Create an IAM user with programmatic access and appropriate permissions
   - Required for: Both workflows

2. **AWS_SECRET_ACCESS_KEY**
   - Description: AWS secret key for Terraform to authenticate
   - How to get: Provided when creating the IAM user
   - Required for: Both workflows

3. **DB_PASSWORD**
   - Description: Strong password for the WordPress database
   - How to get: Generate a secure random password
   - Required for: Both workflows

4. **CLOUDFLARE_ZONE_ID**
   - Description: Your Cloudflare zone ID
   - How to get: Found in your Cloudflare dashboard under the domain's overview page
   - Required for: Both workflows

5. **CLOUDFLARE_API_TOKEN**
   - Description: API token with DNS edit permissions
   - How to get: Create at https://dash.cloudflare.com/profile/api-tokens using "Edit zone DNS" template
   - Required for: Both workflows

### Variables

1. **DOMAIN_NAME** (optional if using terraform.tfvars)
   - Description: Your domain name (e.g., example.com)
   - Where to set: Settings → Secrets and variables → Actions → Variables tab
   - Required for: Both workflows

2. **AWS_REGION** (optional, defaults to us-east-1)
   - Description: AWS region for deployment
   - Where to set: Settings → Secrets and variables → Actions → Variables tab
   - Default: us-east-1

## Setting Up Secrets in GitHub

1. Navigate to your repository on GitHub
2. Click **Settings**
3. In the left sidebar, click **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. Add each secret listed above with its corresponding value
6. For variables, click on the **Variables** tab and add them similarly

## AWS IAM Permissions

The AWS IAM user/role used by GitHub Actions needs the following permissions:

- EC2 (VPC, Security Groups, Subnets)
- ECS (Clusters, Services, Task Definitions)
- RDS (Database instances)
- EFS (File systems)
- Application Load Balancer
- IAM (for role creation)
- Secrets Manager
- CloudWatch Logs

Consider using the following managed policies:
- `AmazonEC2FullAccess`
- `AmazonECSFullAccess`
- `AmazonRDSFullAccess`
- `AmazonElasticFileSystemFullAccess`
- `ElasticLoadBalancingFullAccess`
- `IAMFullAccess`
- `SecretsManagerReadWrite`
- `CloudWatchLogsFullAccess`

**Security Note**: For production, create a custom policy with least-privilege permissions instead of using full access policies.

## Backend Configuration (Recommended)

For production use, it's highly recommended to configure a remote backend for Terraform state:

1. Create an S3 bucket for state storage
2. Create a DynamoDB table for state locking
3. Add backend configuration to `terraform/main.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "wordpress-ecs/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

4. Update the IAM permissions to include S3 and DynamoDB access

## Workflow Behavior

### Pull Request Workflow

1. Developer creates a PR with infrastructure changes
2. GitHub Actions runs `terraform plan`
3. Plan output is posted as a comment on the PR
4. Reviewers can see exactly what will change
5. If the plan fails, the workflow fails and prevents merging
6. Once approved and merged, the apply workflow runs

### Main Branch Workflow

1. Code is merged to main branch
2. GitHub Actions runs `terraform apply -auto-approve`
3. Infrastructure is automatically deployed
4. Workflow logs show the apply output
5. If apply fails, the workflow fails and team is notified

## Testing the Workflows

### Test Plan Workflow

1. Make a change to a Terraform file (e.g., update a comment)
2. Create a pull request
3. Verify the workflow runs and posts a comment with the plan
4. Check that the plan output is visible and correct

### Test Apply Workflow

1. Merge a PR to main
2. Verify the workflow runs
3. Check AWS console to confirm changes are applied
4. Review workflow logs for any errors

## Troubleshooting

### Workflow Fails with "Error: Terraform initialization required"

**Solution**: Ensure `terraform init` step is running before plan/apply steps.

### Workflow Fails with "Error: No valid credential sources found"

**Solution**: Verify AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY secrets are set correctly.

### Plan Output Not Appearing in PR Comment

**Solution**: 
- Verify the workflow has `pull-requests: write` permission
- Check that `GITHUB_TOKEN` has appropriate permissions
- Review workflow logs for errors in the comment step

### Apply Fails with "Error acquiring the state lock"

**Solution**: 
- Another apply might be running
- Configure state locking with DynamoDB
- Or manually release the lock if it's stuck

### Variables Not Being Passed

**Solution**:
- Ensure all required secrets are configured
- Check variable names match exactly (case-sensitive)
- Verify terraform.tfvars has default values if needed

## Security Best Practices

1. **Never commit secrets** to the repository
2. **Use least-privilege IAM policies** for GitHub Actions
3. **Enable branch protection** on main to require PR reviews
4. **Rotate credentials regularly** (AWS keys, API tokens)
5. **Use remote state backend** with encryption and locking
6. **Review plan output** carefully before approving PRs
7. **Enable environment protection** for production deployments (see Advanced Configuration)
8. **Audit workflow runs** regularly in the Actions tab
9. **Test in development environment** before applying to production
10. **Monitor AWS CloudTrail** for unexpected infrastructure changes

## Advanced Configuration

### Adding Manual Approval for Apply (STRONGLY RECOMMENDED)

⚠️ **Important**: For production infrastructure, you should always require manual approval before terraform apply runs. This prevents unintended changes from being automatically deployed.

To require manual approval before running terraform apply:

1. Go to Settings → Environments
2. Create a new environment (e.g., "production")
3. Add required reviewers (at least 1-2 people who understand infrastructure)
4. Optionally set a wait timer (e.g., 5 minutes to allow time for review)
5. In `terraform-apply.yml`, uncomment the environment line:

```yaml
jobs:
  terraform-apply:
    name: Terraform Apply
    runs-on: ubuntu-latest
    environment: production  # Uncomment this line
```

After this configuration, every push to main will:
1. Run terraform plan
2. Pause and wait for a reviewer to approve
3. Only run terraform apply after approval is granted

This ensures no infrastructure changes are applied without human oversight.

### Running Workflows on Multiple Branches

To run workflows on development branches:

```yaml
on:
  push:
    branches:
      - main
      - develop
      - 'release/**'
```

### Using Different Variables per Environment

Create different variable sets in GitHub for different environments and reference them based on branch or environment.

## Monitoring

- **Actions Tab**: View all workflow runs
- **Pull Requests**: See plan comments
- **Email Notifications**: Configure in GitHub settings
- **Slack Integration**: Set up using GitHub Actions Slack action

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform GitHub Actions](https://github.com/hashicorp/setup-terraform)
- [AWS Credentials Action](https://github.com/aws-actions/configure-aws-credentials)
- [Terraform Best Practices](https://developer.hashicorp.com/terraform/cloud-docs/recommended-practices)
