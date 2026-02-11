# Deployment Guide

This guide provides step-by-step instructions for deploying WordPress on AWS ECS with Cloudflare.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [AWS Setup](#aws-setup)
3. [Cloudflare Setup](#cloudflare-setup)
4. [Terraform Configuration](#terraform-configuration)
5. [Deployment](#deployment)
6. [WordPress Setup](#wordpress-setup)
7. [Post-Deployment](#post-deployment)

## Prerequisites

Before starting, ensure you have:

- An AWS account with billing enabled
- A domain name registered and managed by Cloudflare
- Terraform installed on your local machine
- AWS CLI installed and configured
- Basic knowledge of command line operations

## AWS Setup

### 1. Create an IAM User for Deployment

1. Log in to AWS Console
2. Navigate to IAM → Users → Add User
3. Create a user with programmatic access
4. Attach the following policies:
   - `AmazonEC2FullAccess`
   - `AmazonECS_FullAccess`
   - `AmazonRDSFullAccess`
   - `AmazonVPCFullAccess`
   - `IAMFullAccess`
   - `CloudWatchLogsFullAccess`
   - `AmazonElasticFileSystemFullAccess`
5. Save the Access Key ID and Secret Access Key

### 2. Configure AWS CLI

```bash
aws configure
```

Enter your:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (e.g., `us-east-1`)
- Default output format (e.g., `json`)

Verify configuration:
```bash
aws sts get-caller-identity
```

## Cloudflare Setup

### 1. Add Your Domain to Cloudflare

If you haven't already:

1. Sign up at [Cloudflare](https://www.cloudflare.com)
2. Add your domain
3. Update your domain's nameservers to Cloudflare's nameservers
4. Wait for DNS propagation (usually a few hours)

### 2. Get Your Zone ID

1. Log in to Cloudflare Dashboard
2. Select your domain
3. Scroll down on the Overview page
4. Find "Zone ID" in the API section (right sidebar)
5. Copy this value

### 3. Create an API Token

1. Go to [API Tokens](https://dash.cloudflare.com/profile/api-tokens)
2. Click "Create Token"
3. Use the "Edit zone DNS" template
4. Under "Zone Resources":
   - Select "Include" → "Specific zone" → Your domain
5. Click "Continue to summary"
6. Click "Create Token"
7. **IMPORTANT**: Copy the token immediately (you won't see it again)

### 4. Configure SSL/TLS Settings

1. In Cloudflare Dashboard, select your domain
2. Go to SSL/TLS
3. Set encryption mode to "Full" (or "Full (strict)" if using ACM certificate)

## Terraform Configuration

### 1. Clone the Repository

```bash
git clone <repository-url>
cd poc/terraform
```

### 2. Create Configuration File

Copy the example configuration:

```bash
cp terraform.tfvars.example terraform.tfvars
```

### 3. Edit Configuration

Open `terraform.tfvars` in your favorite editor:

```bash
nano terraform.tfvars
# or
vim terraform.tfvars
```

Update the following values:

```hcl
# AWS Configuration
aws_region         = "us-east-1"  # Change to your preferred region
project_name       = "wordpress-ecs"
environment        = "prod"

# Database Configuration
db_password = "CHANGE_THIS_TO_A_STRONG_PASSWORD"  # Use a strong password!

# Cloudflare Configuration
cloudflare_zone_id  = "your-zone-id-from-cloudflare"
cloudflare_api_token = "your-api-token-from-cloudflare"
domain_name         = "example.com"  # Your domain
subdomain           = "www"          # Or "blog", etc.

# Optional: Adjust resources for your needs
wordpress_desired_count = 2  # Number of WordPress containers
```

### 4. Secure Your Configuration

```bash
chmod 600 terraform.tfvars
```

This ensures only you can read the file containing sensitive values.

## Deployment

### Option 1: Using the Deployment Script

The easiest way to deploy:

```bash
cd ..  # Go back to project root
./scripts/deploy.sh
```

The script will:
1. Check prerequisites
2. Initialize Terraform
3. Show you the deployment plan
4. Ask for confirmation
5. Deploy the infrastructure
6. Display outputs

### Option 2: Manual Deployment

If you prefer manual control:

```bash
cd terraform

# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Apply the configuration
terraform apply
```

Type `yes` when prompted to confirm.

## Deployment Timeline

The deployment typically takes **10-15 minutes**:

- VPC and networking: ~2 minutes
- RDS database: ~5-7 minutes
- ECS cluster and tasks: ~2-3 minutes
- Load balancer: ~1-2 minutes
- EFS: ~1 minute
- Cloudflare DNS propagation: ~1-2 minutes

## WordPress Setup

### 1. Wait for Services to Start

After Terraform completes, wait an additional 2-3 minutes for:
- RDS to be fully available
- ECS tasks to start and pass health checks
- Load balancer to route traffic

### 2. Access WordPress

Get your WordPress URL from Terraform output:

```bash
terraform output wordpress_url
```

Visit this URL in your browser (e.g., `https://www.example.com`)

### 3. Complete WordPress Installation

You'll see the WordPress installation wizard:

1. **Select Language**: Choose your language
2. **Site Information**:
   - Site Title: Your site name
   - Username: Admin username (don't use "admin")
   - Password: Strong password
   - Email: Your email address
3. Click "Install WordPress"
4. Log in with your credentials

### 4. Configure WordPress Settings

After installation:

1. Go to **Settings → General**
   - Verify "WordPress Address (URL)" and "Site Address (URL)" are correct
   - They should both be `https://www.example.com`
2. Go to **Settings → Permalinks**
   - Choose your preferred URL structure
3. Install security plugins (recommended):
   - Wordfence Security
   - Updraft Plus (for backups)

## Post-Deployment

### Verify Everything Works

1. **Check ECS Service**:
   ```bash
   aws ecs describe-services \
     --cluster wordpress-ecs-cluster \
     --services wordpress-ecs-service \
     --region us-east-1
   ```

2. **Check Running Tasks**:
   ```bash
   aws ecs list-tasks \
     --cluster wordpress-ecs-cluster \
     --region us-east-1
   ```

3. **Check Target Health**:
   - Go to AWS Console → EC2 → Target Groups
   - Select your target group
   - Verify targets are "healthy"

4. **Check CloudWatch Logs**:
   ```bash
   aws logs tail /ecs/wordpress-ecs --follow --region us-east-1
   ```

### Configure Backups

#### Database Backups

RDS automatic backups are already enabled (7-day retention). To create a manual snapshot:

```bash
aws rds create-db-snapshot \
  --db-instance-identifier wordpress-ecs-db \
  --db-snapshot-identifier wordpress-manual-backup-$(date +%Y%m%d) \
  --region us-east-1
```

#### WordPress Files Backup

EFS data is persistent, but for extra safety:

1. Install "UpdraftPlus WordPress Backup Plugin"
2. Configure it to backup to S3, Google Drive, or Dropbox
3. Schedule automatic backups

### Monitoring Setup

1. **CloudWatch Alarms**: Set up alarms for:
   - ECS CPU/Memory usage
   - RDS storage space
   - ALB response times

2. **Cloudflare Analytics**: Monitor traffic in Cloudflare Dashboard

### Security Hardening

1. **Change Database Password**: 
   - Update in AWS RDS Console
   - Update in ECS Task Definition

2. **Enable WAF** (Optional):
   - Use AWS WAF on the ALB
   - Or use Cloudflare's WAF (Pro plan)

3. **WordPress Security**:
   - Keep WordPress, themes, and plugins updated
   - Use strong passwords
   - Limit login attempts
   - Install security plugins

### Performance Optimization

1. **Enable Cloudflare Caching**:
   - Already configured via page rules
   - Monitor cache hit ratio in Cloudflare

2. **Install Caching Plugin**:
   - W3 Total Cache or WP Super Cache
   - Configure to work with EFS

3. **CDN for Media**:
   - Consider using S3 + CloudFront for media files
   - Or use a WordPress media CDN plugin

## Troubleshooting Common Issues

### Issue: Can't Access WordPress

**Symptoms**: Browser shows "Unable to connect" or timeout

**Solutions**:
1. Check ECS tasks are running:
   ```bash
   aws ecs describe-services --cluster wordpress-ecs-cluster --services wordpress-ecs-service
   ```
2. Verify DNS has propagated:
   ```bash
   dig www.example.com
   ```
3. Check CloudWatch logs for errors

### Issue: 502 Bad Gateway

**Symptoms**: Cloudflare or ALB returns 502 error

**Solutions**:
1. Check target group health in AWS Console
2. Verify security groups allow traffic
3. Check ECS task logs:
   ```bash
   aws logs tail /ecs/wordpress-ecs --follow
   ```

### Issue: Database Connection Error

**Symptoms**: WordPress shows "Error establishing database connection"

**Solutions**:
1. Verify RDS is running
2. Check security group rules allow ECS → RDS traffic
3. Verify database credentials in task definition
4. Check RDS endpoint:
   ```bash
   terraform output rds_endpoint
   ```

### Issue: WordPress Asks for FTP Credentials

**Symptoms**: WordPress prompts for FTP credentials when installing plugins

**Solutions**:
1. Add to WordPress config (via ECS task definition environment):
   ```
   FS_METHOD=direct
   ```
2. Or add to `wp-config.php` via ECS task startup script

## Updating and Maintenance

### Update WordPress Version

```bash
./scripts/update-wordpress.sh
```

Or manually:
```bash
aws ecs update-service \
  --cluster wordpress-ecs-cluster \
  --service wordpress-ecs-service \
  --force-new-deployment \
  --region us-east-1
```

### Scale Up/Down

Edit `terraform.tfvars`:
```hcl
wordpress_desired_count = 3  # Increase from 2 to 3
```

Apply changes:
```bash
cd terraform
terraform apply
```

### Update Infrastructure

After modifying Terraform files:
```bash
cd terraform
terraform plan  # Review changes
terraform apply  # Apply changes
```

## Cleanup

### Destroy All Resources

When you no longer need the infrastructure:

```bash
./scripts/destroy.sh
```

Or manually:
```bash
cd terraform
terraform destroy
```

**WARNING**: This will delete:
- All ECS tasks and services
- RDS database (all WordPress data)
- EFS file system (all WordPress files)
- Load balancer, VPC, and all other resources

**IMPORTANT**: Backup your data before destroying!

## Cost Monitoring

Monitor your AWS costs:

1. Go to AWS Console → Billing Dashboard
2. Check "Bills" for current month
3. Set up billing alerts:
   - CloudWatch → Alarms → Billing
   - Create alarm for estimated charges

Expected monthly cost: ~$130-150 USD

## Support

If you encounter issues:

1. Check CloudWatch logs
2. Review this guide's troubleshooting section
3. Consult AWS documentation
4. Open an issue in the repository

## Next Steps

After successful deployment:

1. ✅ Complete WordPress installation
2. ✅ Install essential plugins
3. ✅ Configure backups
4. ✅ Set up monitoring
5. ✅ Harden security
6. ✅ Create your first post!

Enjoy your WordPress site on AWS ECS with Cloudflare! 🚀
