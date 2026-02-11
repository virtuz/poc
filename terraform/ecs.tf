# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.project_name}-cluster"
    Environment = var.environment
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "wordpress" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-logs"
    Environment = var.environment
  }
}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-ecs-task-execution-role"
    Environment = var.environment
  }
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role
resource "aws_iam_role" "ecs_task" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-ecs-task-role"
    Environment = var.environment
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "wordpress" {
  family                   = "${var.project_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.wordpress_cpu
  memory                   = var.wordpress_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = "wordpress"
      image = var.wordpress_image
      
      essential = true
      
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
      
      environment = [
        {
          name  = "WORDPRESS_DB_HOST"
          value = aws_db_instance.wordpress.endpoint
        },
        {
          name  = "WORDPRESS_DB_NAME"
          value = var.db_name
        },
        {
          name  = "WORDPRESS_DB_USER"
          value = var.db_username
        },
        {
          name  = "WORDPRESS_DB_PASSWORD"
          value = var.db_password
        }
      ]
      
      mountPoints = [
        {
          sourceVolume  = "wordpress-data"
          containerPath = "/var/www/html"
          readOnly      = false
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.wordpress.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "wordpress"
        }
      }
    }
  ])

  volume {
    name = "wordpress-data"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.wordpress.id
      transit_encryption = "ENABLED"
      
      authorization_config {
        iam = "DISABLED"
      }
    }
  }

  tags = {
    Name        = "${var.project_name}-task"
    Environment = var.environment
  }
}

# ECS Service
resource "aws_ecs_service" "wordpress" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.wordpress.arn
  desired_count   = var.wordpress_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.wordpress.arn
    container_name   = "wordpress"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener.http,
    aws_efs_mount_target.wordpress
  ]

  tags = {
    Name        = "${var.project_name}-service"
    Environment = var.environment
  }
}
