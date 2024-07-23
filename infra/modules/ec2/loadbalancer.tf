resource "aws_lb" "alb" {
  name        = "${local.project_name}-grafana-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.public_subnets.ids

  tags = {
    Name = "grafana-alb"
  } 
}

resource "aws_lb_target_group" "tg" {
  name        = "ec2-target-group-grafana"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.main.id
  target_type = "instance"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_target_group_attachment" "tg_attachment" {
  target_group_arn  = aws_lb_target_group.tg.arn
  target_id         = aws_instance.server.id
  port              = 80
}


resource "aws_lb" "application" {
  name        = "${local.project_name}-application-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.public_subnets.ids

  tags = {
    Name = "application-alb"
  } 
}

resource "aws_lb_target_group" "application" {
  name        = "ec2-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.main.id
  target_type = "instance"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-499"
  }
}

resource "aws_lb_listener" "application" {
  load_balancer_arn = aws_lb.application.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.application.arn
  }
}

resource "aws_lb_target_group_attachment" "application" {
  target_group_arn  = aws_lb_target_group.application.arn
  target_id         = aws_instance.server.id
  port              = 80
}