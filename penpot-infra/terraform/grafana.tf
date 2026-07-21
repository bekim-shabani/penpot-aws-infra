# Lecture du listener HTTPS créé par le controller
data "aws_lb_listener" "https" {
  load_balancer_arn = data.aws_lb.controller.arn
  port              = 443
}

# Target group dédié Grafana
resource "aws_lb_target_group" "grafana" {
  name        = "${var.cluster_name}-grafana-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/api/health"
    port                = "3000"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 15
    timeout             = 5
    matcher             = "200"
  }
}

resource "aws_lb_target_group_attachment" "grafana" {
  target_group_arn = aws_lb_target_group.grafana.arn
  target_id        = aws_instance.grafana.private_ip
  port             = 3000
}

# Règle listener — priorité 100 (libre, le controller utilise 1-5)
resource "aws_lb_listener_rule" "grafana" {
  listener_arn = data.aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }

  condition {
    host_header {
      values = ["grafana.${var.domain_name}"]
    }
  }
}