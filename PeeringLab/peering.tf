terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  access_key = TF_ACCESS_KEY
  secret_key = TF_SECRET_KEY
}

#Create VPC A
resource "aws_vpc" "VPC_A" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "VPC_A"
  }
}

#Create VPC B
resource "aws_vpc" "VPC_B" {
  cidr_block       = "10.1.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "VPC_B"
  }
}

#Create Subnet A
resource "aws_subnet" "SubnetA" {
  vpc_id     = aws_vpc.VPC_A.id
  cidr_block = "10.0.0.0/16"
  availability_zone = "us-east-1a"

  tags = {
    Name = "SubnetA"
  }
}
#Create Subnet B
resource "aws_subnet" "SubnetB" {
  vpc_id     = aws_vpc.VPC_B.id
  cidr_block = "10.1.0.0/16"
  availability_zone = "us-east-1b"

  tags = {
    Name = "SubnetB"
  }
}

# #create Keypair
# resource "aws_key_pair" "KeypairPeer" {
#   key_name   = "route53_keypair"
#   public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCP8OOzhB9uIAyhjw/jCQ743PJ//cM3pNI0aCSaJlyuRII6hjSybR3uiDcsjl82id7jRWF+uy4y7y/l3toHLMhgbAce5JU2nR18APL59g2GzU+8FFdgU8VZ1VQjVKWgBRK+tHLnuVdm0PTVcm7CG8viJbozFq5WS61cbbJFHRIyncOw3ev0hUQyrJ3oZGdDd3uuD1p9E6Cg9UUjPEhxTjNNZzaUj8W7T0ngGZAuYYn5R+Q8VQCYFxjJJS4PbV4V/apsdnMVtbjNDVGPVvuY5VSy+yIsib3IQooughorZkK9Gq3N2UPzgSMTFpKrOIHBxQ4pFKnrj/9Wh4mKaVf6GFh7 route53_keypair"
# }

#Create Security Group A
resource "aws_security_group" "SecurityGroupA" {
  name        = "SG1"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.VPC_A.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]

  }
  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}
#Create Security Group B
resource "aws_security_group" "SecurityGroupB" {
  name        = "SG2"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.VPC_B.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]

  }
  ingress {
    description      = "ICMP from VPC"
    from_port        = -1
    to_port          = -1
    protocol         = "ICMP"
    cidr_blocks      = [aws_vpc.VPC_A.cidr_block]

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls2"
  }
}


#Create EC2 Instance A
resource "aws_instance" "InstanceA" {
  ami = "ami-0230bd60aa48260c6"
  instance_type = "t2.micro"
  key_name = "route53_keypair"
  associate_public_ip_address = true
  subnet_id = aws_subnet.SubnetA.id
  security_groups = [aws_security_group.SecurityGroupA.id]
  tags = {
    Name = "InstanceA"
  }
}
#Create EC2 Instance B
resource "aws_instance" "InstanceB" {
  ami = "ami-0230bd60aa48260c6"
  instance_type = "t2.micro"
  key_name = "route53_keypair"
  associate_public_ip_address = true
  subnet_id = aws_subnet.SubnetB.id
  security_groups = [aws_security_group.SecurityGroupB.id]
  tags = {
    Name = "InstanceB"
  }
}

#Create Internet gateway
resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.VPC_A.id

  tags = {
    Name = "IGW"
  }
}

# #Attach IGW to VPC_A
# resource "aws_internet_gateway_attachment" "Attachment" {
#   internet_gateway_id = aws_internet_gateway.IGW.id
#   vpc_id              = aws_vpc.VPC_A.id
# }

#Create Route Table A
resource "aws_route_table" "RTA" {
  vpc_id = aws_vpc.VPC_A.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id
  }
  route {
    cidr_block = "10.1.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.SecondPeer.id
  }

  tags = {
    Name = "RTA"
  }
}

# #Route table association A

resource "aws_route_table_association" "Association" {
  subnet_id      = aws_subnet.SubnetA.id
  route_table_id = aws_route_table.RTA.id
}
# resource "aws_route_table_association" "b" {
#   gateway_id     = aws_internet_gateway.IGW.id
#   route_table_id = aws_route_table.RTA.id
# }

# #Create Route Table B
# resource "aws_route_table" "RTB" {
#   vpc_id = aws_vpc.VPC_B.id

#   route {
#     cidr_block = "10.1.0.0/16"
#   }

#   tags = {
#     Name = "RTB"
#   }
# }

#Route table association B
resource "aws_route_table_association" "B" {
subnet_id      = aws_subnet.SubnetB.id
  route_table_id = aws_vpc.VPC_B.default_route_table_id
}  

#Create a Peering connection
resource "aws_vpc_peering_connection" "SecondPeer" {
  peer_vpc_id   = aws_vpc.VPC_B.id
  vpc_id        = aws_vpc.VPC_A.id
  auto_accept   = true

  tags = {
    Name = "VPC Peering between A and B"
  }
}

#Create Route Table X
resource "aws_default_route_table" "X" {
  default_route_table_id = aws_vpc.VPC_B.default_route_table_id
  
  route {
    cidr_block = "10.0.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.SecondPeer.id
  }

  tags = {
    Name = "X"
  }
}
