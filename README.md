# WordPress on AWS ECS with Cloudflare

This repository contains Infrastructure as Code (IaC) using Terraform to deploy a WordPress site on AWS ECS (Elastic Container Service) with Cloudflare as a CDN and DNS provider.

## 🚀 CI/CD with GitHub Actions

This repository includes automated CI/CD pipelines:
- **Pull Requests**: Automatically runs `terraform plan` and posts results as PR comments
- **Main Branch**: Automatically runs `terraform apply` when changes are merged

See [GitHub Actions Documentation](.github/GITHUB_ACTIONS.md) for setup instructions and required secrets.

## Architecture

The infrastructure includes:

- **AWS VPC**: Multi-AZ VPC with public and private subnets
- **AWS ECS Fargate**: Containerized WordPress running on Fargate
- **AWS RDS MySQL**: Managed MySQL database for WordPress
- **AWS EFS**: Elastic File System for persistent WordPress files
- **AWS ALB**: Application Load Balancer for traffic distribution
- **AWS Secrets Manager**: Secure storage for database credentials
- **Cloudflare**: CDN, DNS, and DDoS protection

## Architecture Diagram

```
┌─────────────┐
│ Cloudflare  │
│   (CDN)     │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────────┐
│              AWS Cloud                   │
│                                          │
│  ┌────────────────────────────────┐    │
│  │  Application Load Balancer     │    │
│  └───────────┬────────────────────┘    │
│              │                          │
│  ┌───────────▼───────────┐             │
│  │   ECS Fargate Tasks   │             │
│  │   (WordPress)         │             │
│  │   - Task 1            │             │
│  │   - Task 2            │             │
│  └───────┬───────┬───────┘             │
│          │       │                      │
│  ┌───────▼──┐  ┌▼────────┐            │
│  │   RDS    │  │   EFS   │            │
│  │  MySQL   │  │ (Files) │            │
│  └──────────┘  └─────────┘            │
└─────────────────────────────────────────┘
```

## Prerequisites

1. **AWS Account**: Active AWS account with appropriate permissions
2. **Terraform**: Install Terraform >= 1.0 ([Installation Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli))
3. **Cloudflare Account**: Account with a domain configured
4. **AWS CLI**: Configured with credentials ([Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html))

## Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd poc/terraform
```

### 2. Configure Variables

Copy the example variables file and edit it with your values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and update:
- `db_password`: Set a strong password for the database
- `cloudflare_zone_id`: Your Cloudflare zone ID (found in Cloudflare dashboard)
- `cloudflare_api_token`: Create an API token in Cloudflare with DNS edit permissions
- `domain_name`: Your domain name (e.g., example.com)
- `subdomain`: Subdomain for WordPress (e.g., www or blog)

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review the Plan

```bash
terraform plan
```

### 5. Deploy the Infrastructure

```bash
terraform apply
```

Type `yes` when prompted to confirm the deployment.

### 6. Access Your WordPress Site

After deployment completes (approximately 10-15 minutes), access your WordPress site at:

```
https://<subdomain>.<domain_name>
```

For example: `https://www.example.com`

Complete the WordPress installation wizard to set up your admin account.

## Configuration Details

### AWS Resources

#### VPC Configuration
- **CIDR Block**: 10.0.0.0/16 (configurable)
- **Availability Zones**: 2 (default: us-east-1a, us-east-1b)
- **Public Subnets**: For ALB
- **Private Subnets**: For ECS tasks and RDS
- **NAT Gateways**: One per AZ for outbound internet access

#### ECS Configuration
- **Launch Type**: Fargate (serverless)
- **CPU**: 512 units (0.5 vCPU)
- **Memory**: 1024 MB (1 GB)
- **Desired Count**: 2 tasks for high availability
- **Container**: Official WordPress Docker image

#### RDS Configuration
- **Engine**: MySQL 8.0
- **Instance Class**: db.t3.micro
- **Storage**: 20 GB (auto-scaling up to 100 GB)
- **Multi-AZ**: Disabled by default (can be enabled for production)
- **Backup Retention**: 7 days
- **Encryption**: Enabled

#### EFS Configuration
- **Encryption**: Enabled
- **Lifecycle Policy**: Transition to IA after 30 days
- **Purpose**: Persistent storage for WordPress files, themes, and plugins

### Cloudflare Configuration

- **DNS Record**: CNAME record pointing to ALB
- **Proxy**: Enabled (orange cloud)
- **SSL/TLS**: Recommended to use "Full" or "Full (strict)" mode
- **Page Rules**:
  - Always Use HTTPS
  - Cache static assets (wp-content)

### Security Groups

- **ALB**: Allows HTTP (80) and HTTPS (443) from anywhere
- **ECS Tasks**: Allows HTTP from ALB only
- **RDS**: Allows MySQL (3306) from ECS tasks only
- **EFS**: Allows NFS (2049) from ECS tasks only

## Cloudflare Setup

### Getting Your Cloudflare Zone ID

1. Log in to your Cloudflare dashboard
2. Select your domain
3. Scroll down on the Overview page
4. Find "Zone ID" in the right sidebar
5. Copy the value

### Creating a Cloudflare API Token

1. Go to [Cloudflare API Tokens](https://dash.cloudflare.com/profile/api-tokens)
2. Click "Create Token"
3. Use the "Edit zone DNS" template
4. Select your zone under "Zone Resources"
5. Click "Continue to summary"
6. Click "Create Token"
7. Copy the token (you won't see it again!)

### Configuring SSL/TLS Mode

For proper HTTPS configuration:

1. Go to your Cloudflare domain dashboard
2. Click on "SSL/TLS"
3. Set encryption mode to "Full" (or "Full (strict)" if you add a certificate to ALB)

## Outputs

After successful deployment, Terraform will output:

- `alb_dns_name`: Direct ALB DNS name
- `wordpress_url`: Your WordPress site URL
- `ecs_cluster_name`: ECS cluster name
- `ecs_service_name`: ECS service name
- `efs_id`: EFS file system ID

View outputs anytime with:

```bash
terraform output
```

## Maintenance

### Updating WordPress

The WordPress image is automatically pulled from Docker Hub. To update:

1. Update the task definition (it will pull the latest image on next deployment)
2. Force a new deployment:

```bash
aws ecs update-service --cluster wordpress-ecs-cluster --service wordpress-ecs-service --force-new-deployment --region us-east-1
```

### Scaling

To change the number of WordPress tasks:

1. Update `wordpress_desired_count` in `terraform.tfvars`
2. Run `terraform apply`

### Monitoring

- **CloudWatch Logs**: `/ecs/wordpress-ecs` log group
- **ECS Console**: Monitor task status and health
- **Cloudflare Analytics**: View traffic and caching statistics

## Costs

Estimated monthly costs (us-east-1):

- **ECS Fargate** (2 tasks, 0.5 vCPU, 1 GB): ~$30
- **RDS db.t3.micro**: ~$15
- **EFS**: ~$3 (for 10 GB)
- **ALB**: ~$20
- **NAT Gateways** (2): ~$65
- **Data Transfer**: Variable
- **Cloudflare**: Free tier available

**Total**: ~$133/month (excluding data transfer)

### Cost Optimization

- Reduce NAT Gateways to 1 for non-production (~$32 savings)
- Use smaller RDS instance if needed
- Reduce ECS task count to 1 for development (~$15 savings)
- Enable EFS lifecycle policy (already configured)

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

Type `yes` when prompted. This will remove all AWS resources created by Terraform.

**Note**: Ensure you've backed up any data from WordPress and the database before destroying.

## Troubleshooting

### WordPress Installation Loop

If WordPress keeps redirecting to the installation page:

1. Check that the database connection is working
2. Verify RDS is accessible from ECS tasks
3. Check CloudWatch logs for errors

### 502 Bad Gateway

If you see 502 errors:

1. Check ECS tasks are running: `aws ecs list-tasks --cluster wordpress-ecs-cluster`
2. Check target group health in AWS console
3. Verify security groups allow traffic between ALB and ECS tasks

### Database Connection Issues

1. Verify RDS instance is available
2. Check security group rules
3. Verify database credentials in task definition
4. Check CloudWatch logs for connection errors

## Security Considerations

1. **Database Password**: Use a strong, unique password - it's stored securely in AWS Secrets Manager
2. **Secrets Management**: Database credentials are stored in AWS Secrets Manager and injected securely into ECS tasks
3. **API Tokens**: Keep Cloudflare API tokens secure and never commit them to version control
4. **SSL/TLS**: Use Cloudflare's SSL/TLS encryption
5. **Updates**: Regularly update WordPress, themes, and plugins
6. **Backups**: RDS automatic backups are enabled (7 days retention)
7. **Encryption**: RDS and EFS use encryption at rest

## Advanced Configuration

### Using a Custom WordPress Image

1. Build your custom image with pre-installed themes/plugins
2. Push to Amazon ECR or Docker Hub
3. Update `wordpress_image` variable

### Multi-AZ RDS

For production, enable Multi-AZ:

In `terraform/rds.tf`, change:
```hcl
multi_az = true
```

### Custom Domain Root

To use the root domain instead of a subdomain, set:
```hcl
subdomain = "@"
```

## License

MIT

## Support

For issues and questions, please open an issue in this repository.