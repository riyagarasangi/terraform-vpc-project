###########################################################
# LAUNCH TEMPLATE
###########################################################
resource "aws_launch_template" "web_lt" {
  name_prefix   = "${var.env}-lt"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [var.security_group_id]

  user_data = base64encode(<<EOF
#!/bin/bash
yum update -y
amazon-linux-extras install nginx1 -y
systemctl enable nginx
systemctl start nginx
echo "Welcome to nginx from ${var.env}" > /usr/share/nginx/html/index.html
EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.env}-autoscaling-instance"
    }
  }
}

###########################################################
# LOAD BALANCER
###########################################################
resource "aws_lb" "web_lb" {
  name               = "${var.env}-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [var.alb_security_group_id]

  subnets = [
    var.subnet_a_id,
    var.subnet_b_id
  ]
}

###########################################################
# TARGET GROUP
###########################################################
resource "aws_lb_target_group" "web_tg" {
  name        = "${var.env}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"
}

###########################################################
# LISTENER
###########################################################
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

###########################################################
# AUTO SCALING GROUP
###########################################################
resource "aws_autoscaling_group" "web_asg" {
  name                = "${var.env}-asg"
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity

  vpc_zone_identifier = [
    var.subnet_a_id,
    var.subnet_b_id
  ]

  target_group_arns = [aws_lb_target_group.web_tg.arn]

  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }

  health_check_type = "EC2"
}

###########################################################
# OUTPUT
###########################################################
output "load_balancer_dns" {
  value = aws_lb.web_lb.dns_name
}
