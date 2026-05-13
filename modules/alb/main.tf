resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.subnet_ids

  enable_deletion_protection = var.enable_deletion_protection
  enable_http2                     = true
  enable_cross_zone_load_balancing = true

  tags = merge(var.tags, { Name = "${var.project_name}-alb" })
}

resource "aws_lb_target_group" "services" {
  for_each = var.services

  name        = "${var.project_name}-${each.key}-tg"
  port        = each.value.port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = each.value.health_check_path
    matcher             = "200-299"
    protocol            = "HTTP"
  }

  deregistration_delay = 30

  tags = merge(var.tags, {
    Name    = "${var.project_name}-${each.key}-tg"
    Service = each.key
  })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Service not found"
      status_code  = "404"
    }
  }

  tags = var.tags
}

resource "aws_lb_listener_rule" "services" {
  for_each = var.services

  listener_arn = aws_lb_listener.http.arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.services[each.key].arn
  }

  condition {
    path_pattern {
      values = ["/${each.key}/*", "/${each.key}"]
    }
  }

  tags = merge(var.tags, { Service = each.key })
}
