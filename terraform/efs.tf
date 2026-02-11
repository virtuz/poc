# EFS File System
resource "aws_efs_file_system" "wordpress" {
  creation_token = "${var.project_name}-efs"
  encrypted      = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name        = "${var.project_name}-efs"
    Environment = var.environment
  }
}

# EFS Mount Targets
resource "aws_efs_mount_target" "wordpress" {
  count           = length(var.availability_zones)
  file_system_id  = aws_efs_file_system.wordpress.id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.efs.id]
}
