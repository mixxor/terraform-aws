provider "aws" {
    region = "eu-central-1"
}


variable "region_number" {
  # Arbitrary mapping of region name to number to use in
  # a VPC's CIDR prefix.
  default = {
    us-east-1      = 1
    us-west-1      = 2
    us-west-2      = 3
    eu-central-1   = 4
    ap-northeast-1 = 5
  }
}

variable "az_number" {
  # Assign a number to each AZ letter used in our configuration
  default = {
    a = 1
    b = 2
    c = 3
    d = 4
    e = 5
    f = 6
  }
}

# Retrieve the AZ where we want to create network resources
# This must be in the region selected on the AWS provider.
data "aws_availability_zone" "example" {
  name = "eu-central-1a"
}

data "aws_availability_zone" "example2" {
  name = "eu-central-1b"
}

data "aws_availability_zone" "example3" {
  name = "eu-central-1c"
}

resource "aws_vpc" "main_vpc" {
  cidr_block = cidrsubnet("10.0.0.0/16", 4, var.region_number[data.aws_availability_zone.example.region])
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    name = "main_vpc"
  }
}


resource "aws_internet_gateway" "internet_gateay" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main_vpc_ig"
  }
  
}

resource "aws_route_table" "aws_r_t" {
  vpc_id = aws_vpc.main_vpc.id
  

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateay.id
  }

  tags = {
    Name = "MyRouteTable"
  }
}
resource "aws_route_table_association" "cluster_rta_1" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.aws_r_t.id
}

resource "aws_route_table_association" "cluster_rta_2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.aws_r_t.id
}

resource "aws_route_table_association" "cluster_rta_3" {
  subnet_id      = aws_subnet.subnet3.id
  route_table_id = aws_route_table.aws_r_t.id

}

# Create a subnet for the AZ within the regional VPC
resource "aws_subnet" "subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = cidrsubnet(aws_vpc.main_vpc.cidr_block, 2, var.az_number[data.aws_availability_zone.example.name_suffix])
  
  tags = {
    name = "eu-central-1a"
  
  }


}

# Create a subnet for the AZ within the regional VPC
resource "aws_subnet" "subnet2" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = cidrsubnet(aws_vpc.main_vpc.cidr_block, 2, var.az_number[data.aws_availability_zone.example2.name_suffix])

  tags = {
    name = "eu-central-1b"
  
  }
}

# Create a subnet for the AZ within the regional VPC
resource "aws_subnet" "subnet3" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = cidrsubnet(aws_vpc.main_vpc.cidr_block, 2, var.az_number[data.aws_availability_zone.example3.name_suffix])

  tags = {
    name = "eu-central-1c"
  
  }
}

#### EC-2 with Security Group ####

resource "aws_key_pair" "example_key_pair" {
  key_name   = "example_key_pair"
  public_key = file("${path.module}/mykey.pub")
}


resource "aws_security_group" "allow_ssh" {
    name        = "allow_ssh"
    description = "Allow SSH inbound traffic"
    vpc_id = aws_vpc.main_vpc.id

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]  // Oder beschränken Sie dies auf Ihre IP-Adresse für zusätzliche Sicherheit
    }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]  // Oder beschränken Sie dies auf Ihre IP-Adresse für zusätzliche Sicherheit
    }

    ingress {
        from_port   = 443
        to_port     = 443
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

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "wordpress-instance"

  subnet_id     = "${aws_subnet.subnet.id}"

  # Ubuntu 22.04
  ami                    = "ami-06dd92ecc74fdfb36"
  
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.example_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  
  user_data = <<-EOT
    #!/bin/bash

    # Install Docker
    sudo apt-get update
    sudo apt-get install -y docker.io docker-compose

    # Start and enable Docker service
    sudo systemctl start docker
    sudo systemctl enable docker

    # Create directories for Docker Compose files
    mkdir compose
    # Create the Docker Compose file for MySQL
    cat > compose/docker-compose.yml << EOF
    version: "3.9"

    services:
      db:
        # We use a mariadb image which supports both amd64 & arm64 architecture
        image: mariadb:10.6.4-focal
        # If you really want to use MySQL, uncomment the following line
        #image: mysql:8.0.27
        command: '--default-authentication-plugin=mysql_native_password'
        volumes:
          - db_data:/var/lib/mysql
        restart: always
        environment:
          - MYSQL_ROOT_PASSWORD=somewordpress
          - MYSQL_DATABASE=wordpress
          - MYSQL_USER=wordpress
          - MYSQL_PASSWORD=wordpress
        expose:
          - 3306
          - 33060
      wordpress:
        image: wordpress:latest
        volumes:
          - wp_data:/var/www/html
        ports:
          - 80:80
        restart: always
        environment:
          - WORDPRESS_DB_HOST=db
          - WORDPRESS_DB_USER=wordpress
          - WORDPRESS_DB_PASSWORD=wordpress
          - WORDPRESS_DB_NAME=wordpress
    volumes:
      db_data:
      wp_data:
    EOF

    cd compose
    sudo docker-compose up -d

  EOT


  tags = {
    Terraform   = "true"
    Environment = "dev"
  }

  timeouts = {
    create = "30m"
    delete = "5m"
  }
}


# Elastic IP
resource "aws_eip" "wordpress" {

}

resource "aws_eip_association" "wordpress_ip_assoc" {
  instance_id = module.ec2_instance.id
  allocation_id = aws_eip.wordpress.allocation_id
}



output "public_ip" {
  value = aws_eip_association.wordpress_ip_assoc.public_ip
}

