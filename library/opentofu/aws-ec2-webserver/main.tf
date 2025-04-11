data "aws_availability_zones" "this" {}

data "aws_ami" "this" {

    most_recent = true

    filter {
        name   = "name"
        values = ["debian-12-amd64-*"]
    }

    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["136693071363"] # official debian images
}

resource "random_string" "this" {
  length  = 6
  special = false
  upper   = false
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = format("vpc-%s-webserver", random_string.this.result)
  }

}

resource "aws_subnet" "this" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.this.names[0]

  tags = {
    Name = format("subnet-%s-webserver", random_string.this.result)
  }

}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = format("igw-%s-webserver", random_string.this.result)
  }

}

resource "aws_route_table" "this" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = format("rtb-%s-webserver", random_string.this.result)
  }

}

resource "aws_route_table_association" "this" {
  subnet_id      = aws_subnet.this.id
  route_table_id = aws_route_table.this.id
}

resource "aws_security_group" "this" {
  name        = format("%s-webserver-sg", random_string.this.result)
  description = "Allow Inbound HTTP traffic"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP Inbound"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow ANY Outbound"
  }

  tags = {
    Name = format("sg-%s-webserver", random_string.this.result)
  }

}

resource "aws_instance" "this" {
  ami                    = data.aws_ami.this.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.this.id
  vpc_security_group_ids = [aws_security_group.this.id]

  # dynamically insert html
  user_data = templatefile("${path.module}/templates/webserver_user_data.sh", {
    html_content = file("${path.module}/templates/index.html")
  })

  tags = {
    Name = format("ec2-%s-webserver", random_string.this.result)
  }

}