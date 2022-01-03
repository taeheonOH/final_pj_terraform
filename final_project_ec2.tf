data "aws_ami" "amzn" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

/*data "aws_ami_ids" "ubuntu"
  owners = ["400669595853"]
  filter {
    name   = "name"
    values = ["ubuntu/images/ubuntu-*-*-amd64-server-*"]
  }
*/

resource "aws_instance" "final-ec2-pub-a-bastion" {
  ami                    = data.aws_ami.amzn.id
  instance_type          = "t3.micro"
  iam_instance_profile = "admin_role"
  availability_zone      = "ap-northeast-2a"
  subnet_id              = aws_subnet.final-sub-pub-a.id
  key_name               = "final-key"
  vpc_security_group_ids = [aws_security_group.final-sg-pub-bastion.id]
  user_data              = <<EOF
  #!/bin/bash
sudo -i
sed -i "s/#Port 22/Port 6022/g" /etc/ssh/sshd_config
systemctl restart sshd
EOF
  tags = {
    Name = "final-ec2-pub-a-bastion"
  }
}

resource "aws_instance" "final-ec2-pub-c-control" {
  ami                    = data.aws_ami.amzn.id
  instance_type          = "t3.micro"
  iam_instance_profile = "admin_role"
  availability_zone      = "ap-northeast-2c"
  subnet_id              = aws_subnet.final-sub-pub-c.id
  key_name               = "final-key"
  vpc_security_group_ids = [aws_security_group.final-sg-pub-bastion.id]
  user_data              = <<EOF
  #!/bin/bash
sudo -i
sed -i "s/#Port 22/Port 6022/g" /etc/ssh/sshd_config
systemctl restart sshd
cd /home/ec2-user/
amazon-linux-extras enable ansible2
yum clean metadata
yum install ansible -y
yum install git -y
git clone https://github.com/taeheonOH/ansible
cat >> /home/ec2-user/boto3_install.yml << A
---
- hosts: localhost
  become: yes

  tasks:
    - name: install pip
      yum:
        name:
          - python-pip
          - python3-pip
        state: latest

    - name: install boto
      pip:
        name:
          - boto
          - boto3
A
ansible-playbook boto3_install.yml
EOF
  tags = {
    Name = "final-ec2-pub-c-control"
  }
}

# web 이중화 구성 # a 대역에 ec2 생성 
/*resource "aws_instance" "final-ec2-pri-a-web" {
  ami                    = data.aws_ami.amzn.id
  instance_type          = "t2.micro"
  availability_zone      = "ap-northeast-2a"
  subnet_id              = aws_subnet.final-sub-pri-a-web.id
  key_name               = "final-key"
  user_data              = file("./web.sh")
  vpc_security_group_ids = [aws_security_group.final-sg-pri-web.id]
  tags = {
    Name = "final-ec2-pri-a-web"
  }
}

# c 대역에 ec2 생성 
resource "aws_instance" "final-ec2-pri-c-web2" {
  ami                    = data.aws_ami.amzn.id
  instance_type          = "t2.micro"
  availability_zone      = "ap-northeast-2c"
  subnet_id              = aws_subnet.final-sub-pri-c-web.id
  key_name               = "final-key"
  vpc_security_group_ids = [aws_security_group.final-sg-pri-web.id]
  user_data              = file("./web_source.sh")
  tags = {
    Name = "final-ec2-pri-c-web2"
  }
}


# was 역시 이중화 구성이지만 ebs를 추가적으로 붙여준다.

# was
resource "aws_instance" "final-ec2-pri-a-was" {
  ami               = data.aws_ami.amzn.id
  instance_type     = "t3.medium"
  availability_zone = "ap-northeast-2a"
  subnet_id         = aws_subnet.final-sub-pri-a-was.id
  key_name          = "final-key"
  user_data         = file("./was.sh")    # 다시 해야함
  ebs_block_device {
    device_name = "/dev/sdb"
    volume_size = "8"
  }
  vpc_security_group_ids = [aws_security_group.final-sg-pri-was.id]
  tags = {
    Name = "final-ec2-pri-a-was"
  }
}


resource "aws_instance" "final-ec2-pri-c-was2" {
  ami               = data.aws_ami.amzn.id
  instance_type     = "t2.micro"
  availability_zone = "ap-northeast-2c"
  subnet_id = aws_subnet.final-sub-pri-c-was.id
  key_name  = "final-key"
  ebs_block_device {
    device_name = "/dev/sdb"
    volume_size = "8"
  }
  vpc_security_group_ids = [aws_security_group.final-sg-pri-was.id]
  tags = {
    Name = "final-ec2-pri-c-was2"
  }
}
*/