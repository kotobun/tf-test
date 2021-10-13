variable "access_key" {}
variable "secret_key" {}

variable "region" {
  default = "croc"
}

provider "aws" {
  endpoints {
    ec2 = "https://api.cloud.croc.ru"
  }

  # NOTE: STS API is not implemented, skip validation
  skip_credentials_validation = true

  # NOTE: IAM API is not implemented, skip validation
  skip_requesting_account_id = true

  # NOTE: Region has different name, skip validation
  skip_region_validation = true

  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}

###########
### VPC ###
###########
data "aws_vpc" "tf_test" {
  id              = "vpc-20C6C696"
  cidr_block      = "172.31.0.0/16"
}

###############
### Subnets ###
###############
resource "aws_subnet" "subnet1" {
  vpc_id            = data.aws_vpc.tf_test.id
  cidr_block        = "172.31.16.0/20"
  availability_zone = "ru-msk-comp1p"
}

##########
### SG ###
##########
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound connections"
  vpc_id      = data.aws_vpc.tf_test.id

  ingress {
    description = "SSH inbound"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_ssh"
  }
}

##################
### Elastic IP ###
##################
resource "aws_eip" "test_1" {
  vpc = true
}

resource "aws_ec2_tag" "test_1_eip" {
  resource_id = resource.aws_eip.test_1.id
  key         = "Name"
  value       = "test_1"
}

resource "aws_eip_association" "test_1" {
  instance_id   = resource.aws_instance.test_1.id
  allocation_id = aws_eip.test_1.id
}

#####################
### EC2 Instances ###
#####################
resource "aws_instance" "test_1" {
  tags = {
    Name = "test_1"
  }
  ami               = "cmi-0B217391"
  instance_type     = "m5.2small"
  subnet_id         = resource.aws_subnet.subnet1.id
  monitoring        = true
  source_dest_check = true
  key_name          = "gmelnikov"
  private_ip        = "172.31.16.4"
  associate_public_ip_address = false
  root_block_device {
    volume_size = 32
    volume_type = "gp2"
  }
  security_groups = [
    aws_security_group.allow_ssh.id
  ]
}
