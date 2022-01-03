provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_vpc" "final-vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Name                 = "final-vpc"
  }
}

resource "aws_internet_gateway" "final-igw" {
  vpc_id = aws_vpc.final-vpc.id
  tags = {
    Name = "final-igw"
  }
}

resource "aws_eip" "final-nip" {
  vpc = true
  tags = {
    Name = "final-nip"
  }
}

resource "aws_nat_gateway" "final-ngw" {
  allocation_id = aws_eip.final-nip.id
  subnet_id     = aws_subnet.final-sub-pub-a.id
  tags = {
    Name = "final-ngw"
  }
}

# public 
resource "aws_subnet" "final-sub-pub-a" {
  vpc_id                  = aws_vpc.final-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "final-sub-pub-a"
  }
}

resource "aws_subnet" "final-sub-pub-c" {
  vpc_id                  = aws_vpc.final-vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true
  tags = {
    Name = "final-sub-pub-c"
  }
}

# private web 
resource "aws_subnet" "final-sub-pri-a-web" {
  vpc_id            = aws_vpc.final-vpc.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "final-sub-pri-a-web"
  }
}

resource "aws_subnet" "final-sub-pri-c-web" {
  vpc_id            = aws_vpc.final-vpc.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "ap-northeast-2c"
  tags = {
    Name = "final-sub-pri-c-web"
  }
}

#was
resource "aws_subnet" "final-sub-pri-a-was" {
  vpc_id            = aws_vpc.final-vpc.id
  cidr_block        = "10.0.30.0/24"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "final-sub-pri-a-was"
  }
}

resource "aws_subnet" "final-sub-pri-c-was" {
  vpc_id            = aws_vpc.final-vpc.id
  cidr_block        = "10.0.40.0/24"
  availability_zone = "ap-northeast-2c"
  tags = {
    Name = "final-sub-pri-c-was"
  }
}


# db
resource "aws_subnet" "final-sub-pri-a-db" {
  vpc_id            = aws_vpc.final-vpc.id
  cidr_block        = "10.0.50.0/24"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "final-sub-pri-a-db"
  }
}

resource "aws_subnet" "final-sub-pri-c-db" {
  vpc_id            = aws_vpc.final-vpc.id
  cidr_block        = "10.0.60.0/24"
  availability_zone = "ap-northeast-2c"
  tags = {
    Name = "final-sub-pri-c-db"
  }
}

# public > igw 
resource "aws_route_table" "final-rt-pub" {
  vpc_id = aws_vpc.final-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.final-igw.id
  }
  tags = {
    Name = "final-rt-pub"
  }
}

# public subnet을 public route table에 연결 
resource "aws_route_table_association" "final-rtass-pub-a" {
  subnet_id      = aws_subnet.final-sub-pub-a.id
  route_table_id = aws_route_table.final-rt-pub.id
}

resource "aws_route_table_association" "final-rtass-pub-c" {
  subnet_id      = aws_subnet.final-sub-pub-c.id
  route_table_id = aws_route_table.final-rt-pub.id
}

# private web > nat 
resource "aws_route_table" "final-rt-pri" {
  vpc_id = aws_vpc.final-vpc.id
  tags = {
    Name = "final-rt-pri-web"
  }
}

resource "aws_route" "final-r-pri-web" {
  route_table_id         = aws_route_table.final-rt-pri.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.final-ngw.id
}

# private web subnet을 pirvate route table에 연결 
resource "aws_route_table_association" "final-rtass-pri-a-web" {
  subnet_id      = aws_subnet.final-sub-pri-a-web.id
  route_table_id = aws_route_table.final-rt-pri.id
}
resource "aws_route_table_association" "final-rtass-pri-c-web" {
  subnet_id      = aws_subnet.final-sub-pri-c-web.id
  route_table_id = aws_route_table.final-rt-pri.id
}

resource "aws_route_table_association" "final-rtass-pri-a-was" {
  subnet_id      = aws_subnet.final-sub-pri-a-was.id
  route_table_id = aws_route_table.final-rt-pri.id
}
resource "aws_route_table_association" "final-rtass-pri-c-was" {
  subnet_id      = aws_subnet.final-sub-pri-c-was.id
  route_table_id = aws_route_table.final-rt-pri.id
}