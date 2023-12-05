provider "aws" {
    region = "eu-central-1"
}

#### EC-2 with Security Group ####

resource "aws_key_pair" "example_key_pair" {
  key_name   = "example_key_pair"
  public_key = file("${path.module}/mykey.pub")
}


resource "aws_security_group" "allow_ssh" {
    name        = "allow_ssh"
    description = "Allow SSH inbound traffic"

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
  
  # Ubuntu 22.04
  ami                    = "ami-06dd92ecc74fdfb36"
  
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.example_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  
  user_data = <<-EOF
                #!/bin/bash
                sudo apt-get update
                sudo apt-get install -y docker.io
                sudo systemctl start docker
                sudo systemctl enable docker

                sudo docker run -d --name wordpress -p 80:80 wordpress
              EOF


  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
  timeouts = {
    create = "30m"
    delete = "5m"
  }
}

output "public_ip" {
  value = module.ec2_instance.public_ip
}


