resource "aws_security_group" "final-sg-pub-bastion" {
  name        = "final-sg-pub-bastion"
  description = "final-sg-pub-bastion"
  vpc_id      = aws_vpc.final-vpc.id
  ingress {
    from_port   = 6022
    to_port     = 6022
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "final-sg-pub-bastion"
  }
}

resource "aws_security_group" "final-sg-pri-web" {
  name        = "final-sg-pri-web"
  description = "final-sg-pri-web"
  vpc_id      = aws_vpc.final-vpc.id
  ingress {
    from_port = 6022
    to_port   = 6022
    protocol  = "tcp"
    #security_groups = [aws_security_group.final-sg-pub-bastion.id]
    cidr_blocks = ["0.0.0.0/0"] # 일단 포트 다열어놓음
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "final-sg-pri-web"
  }
}

# was 
resource "aws_security_group" "final-sg-pri-was" {
  name        = "final-sg-pri-was"
  description = "final-sg-pri-was"
  vpc_id      = aws_vpc.final-vpc.id
  ingress {
    from_port = 6022
    to_port   = 6022
    protocol  = "tcp"
    #security_groups = [aws_security_group.final-sg-pub-bastion.id]
    cidr_blocks = ["0.0.0.0/0"] # 일단 포트 다열어놓음
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["10.0.10.0/24", "10.0.20.0/24"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "final-sg-pri-was"
  }
}

# db 
resource "aws_security_group" "final-sg-pri-db" {
  name        = "final-sg-pri-db"
  description = "final-sg-pri-db"
  vpc_id      = aws_vpc.final-vpc.id
  ingress {
    from_port       = 6022
    to_port         = 6022
    protocol        = "tcp"
    security_groups = [aws_security_group.final-sg-pub-bastion.id]
  }
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "final-sg-pri-db"
  }
}

# alb sg 
resource "aws_security_group" "final-sg-alb-web" {
  name        = "final-sg-alb-web"
  description = "final-sg-alb-web"
  vpc_id      = aws_vpc.final-vpc.id
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "final-sg-alb-web"
  }
}