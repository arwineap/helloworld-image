resource "aws_security_group" "alb_main" {
  name        = "alb-helloworld-image"
  description = "Allow inbound traffic to helloworld-image ALB"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "TCP"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "TCP"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["${var.cidr}"]
  }

  tags {
    Name        = "alb-helloworld-image"
  }
}


resource "aws_alb" "main" {
  name            = "helloworld-image"
  subnets         = ["${aws_subnet.external.*.id}"]
  security_groups = ["${aws_security_group.alb_main.id}"]
}

resource "aws_alb_target_group" "app" {
  name        = "tg-helloworld-image"
  port        = "${var.app_port}"
  protocol    = "HTTP"
  vpc_id      = "${aws_vpc.vpc.id}"
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/healthcheck"
    unhealthy_threshold = "2"
  }
}

resource "aws_alb_listener" "fe" {
  load_balancer_arn = "${aws_alb.main.id}"
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.app.id}"
    type             = "forward"
  }
}


output "dns_name" {
  value = "${aws_alb.main.dns_name}"
}
