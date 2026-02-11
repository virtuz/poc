output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "rds_endpoint" {
  description = "RDS database endpoint"
  value       = aws_db_instance.wordpress.endpoint
  sensitive   = true
}

output "rds_address" {
  description = "RDS database address"
  value       = aws_db_instance.wordpress.address
}

output "efs_id" {
  description = "EFS file system ID"
  value       = aws_efs_file_system.wordpress.id
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.wordpress.name
}

output "cloudflare_record" {
  description = "Cloudflare DNS record hostname"
  value       = "${var.subdomain}.${var.domain_name}"
}

output "wordpress_url" {
  description = "WordPress site URL"
  value       = "https://${var.subdomain}.${var.domain_name}"
}
