resource "aws_ecs_service" "app" {
  name            = local.application
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.primary.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.primary.arn
    container_name   = "nginx"
    container_port   = 80
  }

  network_configuration {
    subnets          = var.public_subnet_ids
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = true
  }
}

resource "aws_ecs_task_definition" "primary" {
  family = local.application

  execution_role_arn = aws_iam_role.task_execution_role.arn

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = 256
  memory = 512

  container_definitions = jsonencode([
    {
      name  = "moin"
      image = "${aws_ecr_repository.app.repository_url}:latest"

      essential = true

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = local.log_group
          "awslogs-create-group"  = "true"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs-app"
        }
      }

      mountPoints = [
        {
          sourceVolume  = "efs-instance"
          containerPath = "/opt/moin/instance"
        },
        {
          sourceVolume  = "app-sock-dir"
          containerPath = "/tmp/moin"
        },
        {
          sourceVolume  = "static-dir"
          containerPath = "/var/moin/static"
        }
      ]
    },
    {
      name  = "nginx"
      image = "${aws_ecr_repository.nginx.repository_url}:latest"

      essential = true

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = local.log_group
          "awslogs-create-group"  = "true"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs-nginx"
        }
      }

      mountPoints = [
        {
          sourceVolume  = "app-sock-dir"
          containerPath = "/tmp/moin"
        },
        {
          sourceVolume  = "static-dir"
          containerPath = "/var/moin/static"
        }
      ]
    }
  ])

  volume {
    name = "efs-instance"

    efs_volume_configuration {
      file_system_id = aws_efs_file_system.moin_instance.id
    }
  }

  volume {
    name = "app-sock-dir"
  }

  volume {
    name = "static-dir"
  }
}