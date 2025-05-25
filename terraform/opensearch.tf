locals {
  region                   = "ap-southeast-1"  # Specify your region
  opensearch_domain_name    = "kg-lab-camunda-opensearch"  # OpenSearch domain name
}

# VPC Creation
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Public Subnet Creation (for internet access)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"  # Public subnet CIDR block
  map_public_ip_on_launch = true  # Enable automatic public IP assignment
  availability_zone       = "ap-southeast-1a"  # Modify availability zone as needed
}

# Private Subnet Creation
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "ap-southeast-1a"  # Modify availability zone as needed
}

# Internet Gateway for Public Subnet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

# Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
}

# Route to allow traffic to the Internet Gateway
resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Route Table Association for Public Subnet
resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security group for OpenSearch domain (allow public internet access)
resource "aws_security_group" "opensearch_sg" {
  name        = "opensearch-sg"
  description = "Allow OpenSearch traffic from anywhere"
  vpc_id      = aws_vpc.main.id

  # Allow inbound traffic from anywhere on port 9200 (OpenSearch default port)
  ingress {
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow access from the entire internet
  }

  # Allow outbound traffic (necessary for the service)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Allow all traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# OpenSearch Domain Creation
resource "aws_opensearch_domain" "example" {
  domain_name    = local.opensearch_domain_name
  engine_version = "OpenSearch_2.3"

  cluster_config {
    instance_type  = "t3.small.search"
    instance_count = 1
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10  # 10 GB EBS volume
  }

  # Use the public subnet for OpenSearch to allow internet access
  vpc_options {
    subnet_ids         = [aws_subnet.public.id]  # Change to public subnet
    security_group_ids = [aws_security_group.opensearch_sg.id]
  }

  access_policies = <<CONFIG
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "es:*",
      "Resource": "arn:aws:es:${local.region}:${data.aws_caller_identity.current.account_id}:domain/${local.opensearch_domain_name}/*"
    }
  ]
}
CONFIG
}

# Output the OpenSearch domain endpoint
output "opensearch_endpoint" {
  value       = aws_opensearch_domain.example.endpoint
  description = "The OpenSearch domain endpoint URL"
}

# Current region and account information
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}
