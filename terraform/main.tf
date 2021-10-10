locals {
  account_id = data.aws_caller_identity.current.account_id
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = var.vpc_dns_support
  enable_dns_hostnames = true
  tags = {
    Name = "terraform"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public_1" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = var.availability_zone[0]
  map_public_ip_on_launch = false
}

resource "aws_subnet" "public_2" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = var.availability_zone[1]
  map_public_ip_on_launch = false
}

resource "aws_subnet" "private_1" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
  availability_zone = var.availability_zone[0]
}

resource "aws_subnet" "private_2" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.4.0/24"
  availability_zone = var.availability_zone[1]
}

resource "aws_eip" "nat_1" {
  vpc = true
}

resource "aws_eip" "nat_2" {
  vpc = true
}

resource "aws_nat_gateway" "ngw_1" {
  subnet_id = aws_subnet.public_1.id
  allocation_id = aws_eip.nat_1.id
  depends_on = [
    aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "ngw_2" {
  subnet_id = aws_subnet.public_2.id
  allocation_id = aws_eip.nat_2.id
  depends_on = [
    aws_internet_gateway.igw]
}

resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "private_2" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "private_1" {
  route_table_id = aws_route_table.private_1.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.ngw_1.id
}

resource "aws_route" "private_2" {
  route_table_id = aws_route_table.private_2.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.ngw_2.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_1.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_2.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "public" {
  route_table_id = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_1" {
  subnet_id = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.main.id
}

resource "aws_network_acl_rule" "public_ingress" {
  network_acl_id = aws_network_acl.public.id
  rule_number = 100
  protocol = "-1"
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "public_egress" {
  network_acl_id = aws_network_acl.public.id
  rule_number = 100
  egress = true
  protocol = "-1"
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"

}

resource "aws_network_acl" "private" {
  vpc_id = aws_vpc.main.id
}


resource "aws_network_acl_rule" "private_ingress" {
  network_acl_id = aws_network_acl.private.id
  rule_number = 100
  protocol = "-1"
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "private_egress" {
  network_acl_id = aws_network_acl.private.id
  rule_number = 100
  egress = true
  protocol = "-1"
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"

}

resource "aws_security_group" "ecs_lb_sg" {
  name = "ecs_lb_sg"
  description = "ECS security group for the load balancer"
  vpc_id = aws_vpc.main.id

  ingress {
    protocol = "tcp"
    from_port = 80
    to_port = 80
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  ingress {
    protocol = "tcp"
    from_port = 8080
    to_port = 8080
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  ingress {
    protocol = "tcp"
    from_port = 31000
    to_port = 61000
    self = true
  }

  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_service_sg" {
  name = "ecs-service_sg"
  description = "ECS security group for the ECS Service"
  vpc_id = aws_vpc.main.id

  ingress {
    protocol = "tcp"
    from_port = 80
    to_port = 80
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  ingress {
    protocol = "tcp"
    from_port = 8001
    to_port = 8001
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  ingress {
    protocol = "tcp"
    from_port = 31000
    to_port = 61000
    self = true
  }

  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}


resource "aws_ecs_cluster" "main" {
  name = "ecs_cluster"
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "ecs-logs"
  retention_in_days = 14
}

resource "aws_ecs_task_definition" "main" {
  family = "cake-app-service-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  container_definitions = <<DEFINITION
[
  {
    "name": "cake-app",
    "cpu": 10,
    "image": "${var.ecs_image_url}",
    "essential": true,
    "memory": 300,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "ecs-logs",
        "awslogs-region": "eu-west-2",
        "awslogs-stream-prefix": "ecs-cake-app"
      }
    },
    "portMappings": [
      {
        "containerPort": 8001
      }
    ]
  }
]
DEFINITION
}

resource "aws_iam_role" "ecs_task_role" {
  name = "cake-app-ecs-task-role"

  inline_policy {
    name = "dynamodb-access"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "dynamodb:Query",
            "dynamodb:Scan",
            "dynamodb:GetItem",
            "dynamodb:PutItem",
            "dynamodb:UpdateItem",
            "dynamodb:DeleteItem"
          ]
          Effect = "Allow"
          Resource = [
            "arn:aws:logs:eu-west-2:${local.account_id}:*/*",
            "arn:aws:dynamodb:eu-west-2:${local.account_id}:*/*"
          ]
        }
      ]
    })
  }

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "cake-app-ecs-task-execution-role"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_service" "main" {
 name                               = "cake-app-service"
 cluster                            = aws_ecs_cluster.main.id
 task_definition                    = aws_ecs_task_definition.main.arn
 desired_count                      = 2
 deployment_minimum_healthy_percent = 50
 deployment_maximum_percent         = 200
 launch_type                        = "FARGATE"
 scheduling_strategy                = "REPLICA"

 network_configuration {
   security_groups  = [aws_security_group.ecs_service_sg.id]
   subnets          = [aws_subnet.public_1.id, aws_subnet.public_2.id]
   assign_public_ip = true
 }

 load_balancer {
   target_group_arn = aws_alb_target_group.main.arn
   container_name   = "cake-app"
   container_port   = 8001
 }

 lifecycle {
   ignore_changes = [task_definition, desired_count]
 }
}

resource "aws_lb" "main" {
  name               = "cake-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.ecs_lb_sg.id]
  subnets = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  enable_deletion_protection = false
}

resource "aws_alb_target_group" "main" {
  name        = "cake-app-target-group"
  port        = 8001
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id   = aws_vpc.main.id

  health_check {
    port = "8001"
    path                = "/"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 10
    matcher             = "200"
  }
}

resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_lb.main.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.main.id
    type             = "forward"
  }
}

resource "aws_dynamodb_table" "cake_table" {
  name = "cake"
  billing_mode = "PROVISIONED"
  read_capacity = 5
  write_capacity = 5
  hash_key = "id"

  attribute {
    name = "id"
    type = "N"
  }
}
