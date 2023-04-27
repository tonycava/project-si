resource "aws_default_vpc" "default_vpc" {
  tags = {
    Name = "Default VPC"
  }
}

data "aws_availability_zones" "available_zones" {}

resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.available_zones.names[0]

  tags = {
    Name = "Default Subnet"
  }
}

resource "aws_security_group" "default_security_group" {
  name        = "ec2 security group"
  description = "ec2 Security Group"
  vpc_id      = aws_default_vpc.default_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
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
}

resource "aws_instance" "ec2_instance" {
  ami                    = "ami-05e8e219ac7e82eba"
  instance_type          = "t2.micro"
  key_name               = "project-key"
  subnet_id              = aws_default_subnet.default_az1.id
  user_data              = file("install-website.sh")
  vpc_security_group_ids = [aws_security_group.default_security_group.id]
  tags                   = {
    Name = "terraform-example"
  }
}

output "public_ip" {
  value = aws_instance.ec2_instance.public_ip
}