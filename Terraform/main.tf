# main.tf

# Define variables
variable "region" {
  default = "ap-south-1"
}

variable "key_name" {
  default = "my_key_pair"
}

variable "allowed_ingress_ports" {
  type        = list(number)
  description = "List of ingress ports to allow"
  default     = [22, 80, 443] # Add more ports as needed
}

# AWS provider configuration with explicit credentials
provider "aws" {
  region     = var.region
  access_key = "AKIA2UC26YX2FGFEWCG3"
  secret_key = "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"
}

# Create IAM user
resource "aws_iam_user" "terraform_user" {
  name = "terraformuser"
}

# Create VPC
resource "aws_vpc" "example" {
  cidr_block          = "10.0.0.0/16"
  enable_dns_support  = true
  enable_dns_hostnames = true

  tags = {
    Name = "MyVPC"
  }
}

# Create Subnets
resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region}a"
}

resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.region}b"
}

# Create Security Group
resource "aws_security_group" "example" {
  vpc_id = aws_vpc.example.id

  # Dynamic ingress rules
  dynamic "ingress" {
    for_each = var.allowed_ingress_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

# Generate SSH key pair
resource "tls_private_key" "key_pair" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Output public key for reference
output "public_key" {
  value = tls_private_key.key_pair.public_key_openssh
}

# Create EC2 instances
resource "aws_instance" "router" {
  ami           = "ami-06b72b3b2a773be2b"  # Replace with a valid AMI ID
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet1.id
  key_name      = var.key_name  # Use the specified key pair name
  vpc_security_group_ids = [aws_security_group.example.id]

  tags = {
    Name = "RouterInstance"
  }
}

resource "aws_instance" "switch" {
  ami           = "ami-06b72b3b2a773be2b"  # Replace with a valid AMI ID
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet2.id
  key_name      = var.key_name  # Use the specified key pair name
  vpc_security_group_ids = [aws_security_group.example.id]

  tags = {
    Name = "SwitchInstance"
  }
}


