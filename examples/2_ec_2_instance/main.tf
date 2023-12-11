provider "aws" {
    region = "eu-central-1"
}

# Create a new VPC
resource "aws_vpc" "example_vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
        Name = "example-vpc"
    }
}

# Create a subnet within the VPC
resource "aws_subnet" "example_subnet" {
    vpc_id     = aws_vpc.example_vpc.id
    cidr_block = "10.0.1.0/24"
    tags = {
        Name = "example-subnet"
    }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "example_igw" {
    vpc_id = aws_vpc.example_vpc.id
    tags = {
        Name = "example-igw"
    }
}

# Create a route table and a public route
resource "aws_route_table" "example_route_table" {
    vpc_id = aws_vpc.example_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.example_igw.id
    }
    tags = {
        Name = "example-route-table"
    }
}

# Associate the route table with the subnet
resource "aws_route_table_association" "example_association" {
    subnet_id      = aws_subnet.example_subnet.id
    route_table_id = aws_route_table.example_route_table.id
}

# Create an Elastic IP
resource "aws_eip" "example_eip" {
    tags = {
        Name = "example-eip"
    }
}

# Attach the Elastic IP to your instance
resource "aws_eip_association" "eip_assoc" {
    instance_id   = aws_instance.example.id
    allocation_id = aws_eip.example_eip.id
}


resource "aws_security_group" "allow_ssh" {
    name        = "allow_ssh"
    description = "Allow SSH inbound traffic"
    vpc_id = aws_vpc.example_vpc.id

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]  // Oder beschränken Sie dies auf Ihre IP-Adresse für zusätzliche Sicherheit
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "allow_ssh"
    }
}

resource "aws_key_pair" "example_key_pair" {
  key_name   = "example_key_pair_2"
  public_key = file("${path.module}/mykey.pub")
}


# Your existing instance configuration
resource "aws_instance" "example" {
    ami = "ami-06dd92ecc74fdfb36"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.example_subnet.id
    key_name               = aws_key_pair.example_key_pair.key_name
    vpc_security_group_ids = [aws_security_group.allow_ssh.id]
    tags = {
        Name = "terraform-example"
    }
}

# Your existing instance configuration
resource "aws_instance" "example-2" {
    ami = "ami-06dd92ecc74fdfb36"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.example_subnet.id
    key_name               = aws_key_pair.example_key_pair.key_name
    vpc_security_group_ids = [aws_security_group.allow_ssh.id]
    tags = {
        Name = "terraform-example-2"
    }
}