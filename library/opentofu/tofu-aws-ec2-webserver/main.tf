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

  user_data = <<-EOF
#!/bin/bash

# install dependencies
apt-get update -y
apt-get install -y apache2 curl

# start + enable apache
systemctl start apache2
systemctl enable apache2

# create image dir
mkdir -p /var/www/html/images

# fetch a pretty graphic
curl -L "https://github.com/torerodev/showtime/blob/main/img/showtime.gif?raw=true" -o "/var/www/html/images/showtime.gif"

# html file that loops gif
cat > /var/www/html/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Torero Showcase</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            background-color: #000000
        }
        .container {
            width: 100%;
            text-align: left;
            padding-top: 20px;
            padding-left: 20px;
        }
        img {
            max-width: 100%;
            height: auto;
        }
    </style>
</head>
<body>
    <div class="container">
        <img src="images/showtime.gif" alt="Torero Showcase" loop>
    </div>
</body>
</html>
HTMLEOF

# set permissions
chmod -R 755 /var/www/html

echo "GIF webserver setup complete. Your GIF is now available at http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/"
EOF

  tags = {
    Name = format("ec2-%s-webserver", random_string.this.result)
  }

}