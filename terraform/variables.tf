variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name to use for resource naming"
  type        = string
  default     = "wordpress-ecs"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "db_name" {
  description = "WordPress database name"
  type        = string
  default     = "wordpress"
}

variable "db_username" {
  description = "WordPress database username"
  type        = string
  default     = "wordpress"
  sensitive   = true
}

variable "db_password" {
  description = "WordPress database password"
  type        = string
  sensitive   = true
}

variable "wordpress_image" {
  description = "WordPress Docker image"
  type        = string
  default     = "wordpress:latest"
}

variable "wordpress_cpu" {
  description = "CPU units for WordPress task"
  type        = number
  default     = 512
}

variable "wordpress_memory" {
  description = "Memory for WordPress task"
  type        = number
  default     = 1024
}

variable "wordpress_desired_count" {
  description = "Desired number of WordPress tasks"
  type        = number
  default     = 2
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
}

variable "cloudflare_api_token" {
  description = "Cloudflare API Token"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Domain name for WordPress site"
  type        = string
}

variable "subdomain" {
  description = "Subdomain for WordPress (e.g., www or blog)"
  type        = string
  default     = "www"
}
