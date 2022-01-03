resource "aws_lb" "final-alb-web" {
  name               = "final-alb-web"
  internal           = false # 외부 
  load_balancer_type = "application"
  security_groups    = [aws_security_group.final-sg-alb-web.id]                       # alb는 sg 필요 
  subnets            = [aws_subnet.final-sub-pub-a.id, aws_subnet.final-sub-pub-c.id] # public subnet에서 web 통신
  access_logs {
    bucket  = "final001-bucket"
    prefix  = "test-lb"
    enabled = true
  }
  tags = {
    Name = "final-alb-web"
  }
}

output "alb-dns_name" {
  value = aws_lb.final-alb-web.dns_name
}

# 타겟그룹 생성 
resource "aws_lb_target_group" "final-atg-web" {
  name        = "final-atg-web"
  port        = "80"
  protocol    = "HTTP"
  vpc_id      = aws_vpc.final-vpc.id
  target_type = "instance"
  tags = {
    Name = "final-atg-web"
  }
  health_check {
    enabled             = true
    healthy_threshold   = 3
    interval            = 5
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 2
    unhealthy_threshold = 2
  }
  
}

# 리스너 생성 
resource "aws_lb_listener" "final-alt-web" {
  load_balancer_arn = aws_lb.final-alb-web.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.final-atg-web.arn
  }
}

# web attachement 
/*resource "aws_lb_target_group_attachment" "final-att-web" {
  target_group_arn = aws_lb_target_group.final-atg-web.arn
  target_id        = aws_instance.final-ec2-pri-a-web.id
  port             = 80
}
*/
/*
resource "aws_lb_target_group_attachment" "final-att-web2" {
  target_group_arn = aws_lb_target_group.final-atg-web.arn
  target_id        = aws_instance.final-ec2-pri-c-web2.id
  port             = 80
}
*/

# nlb 생성 
resource "aws_lb" "final-nlb-was" {
  name               = "final-nlb-was"
  internal           = true # 내부 접근 
  load_balancer_type = "network"
  subnets            = [aws_subnet.final-sub-pri-a-web.id, aws_subnet.final-sub-pri-c-web.id] # web subnet에서 was를 바라봄 
  tags = {
    Name = "final-nlb-was"
  }
}

output "nlb-dns_name" {
  value = aws_lb.final-nlb-was.dns_name
}

# 타겟그룹 
# was에서 진행 될 tomcat의 경우, 8080 port로 통신된다. 
resource "aws_lb_target_group" "final-ntg-was" {
  name        = "final-ntg-was"
  port        = "8080"
  protocol    = "TCP"
  vpc_id      = aws_vpc.final-vpc.id
  target_type = "instance"
  tags = {
    Name = "final-ntg-was"
  }
}

resource "aws_lb_listener" "final-nlt-was" {
  load_balancer_arn = aws_lb.final-nlb-was.arn
  port              = "8080"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.final-ntg-was.arn
  }
}
/*resource "aws_lb_target_group_attachment" "final-ntt-was" {
  target_group_arn = aws_lb_target_group.final-ntg-was.arn
  target_id        = aws_instance.final-ec2-pri-a-was.id
  port             = 8080
}
*/
/*
resource "aws_lb_target_group_attachment" "final-ntt-was2" {
  target_group_arn = aws_lb_target_group.final-ntg-was.arn
  target_id        = aws_instance.final-ec2-pri-c-was2.id
  port             = 8080
}
*/
