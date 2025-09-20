provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "nomad_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "nomad-vpc"
  }
}

resource "aws_subnet" "nomad_subnet" {
  count = length(var.availability_zones)
  vpc_id            = aws_vpc.nomad_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.nomad_vpc.cidr_block, 8, count.index)
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "nomad-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "nomad_igw" {
  vpc_id = aws_vpc.nomad_vpc.id

  tags = {
    Name = "nomad-igw"
  }
}

resource "aws_route_table" "nomad_route_table" {
  vpc_id = aws_vpc.nomad_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nomad_igw.id
  }

  tags = {
    Name = "nomad-route-table"
  }
}

resource "aws_route_table_association" "nomad_route_table_association" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.nomad_subnet[count.index].id
  route_table_id = aws_route_table.nomad_route_table.id
}

resource "aws_security_group" "nomad_sg" {
  vpc_id = aws_vpc.nomad_vpc.id
  name   = "nomad-security-group"
  description = "Allow SSH, Nomad, and HTTP traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 4646
    to_port     = 4648
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

  tags = {
    Name = "nomad-sg"
  }
}

resource "aws_instance" "nomad_server" {
  count                  = var.nomad_server_count
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.nomad_subnet[count.index].id
  vpc_security_group_ids = [aws_security_group.nomad_sg.id]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/scripts/user_data.sh", {
    USER_DATA_INSTANCE_TYPE = "server",
    NOMAD_SERVER_IP         = "" # Not used for servers
  })

  tags = {
    Name = "nomad-server-${count.index}"
  }
}

resource "aws_instance" "nomad_client" {
  count                  = var.nomad_client_count
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.nomad_subnet[count.index].id
  vpc_security_group_ids = [aws_security_group.nomad_sg.id]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/scripts/user_data.sh", {
    USER_DATA_INSTANCE_TYPE = "client",
    NOMAD_SERVER_IP         = aws_instance.nomad_server[0].private_ip # Assuming a single server for simplicity
  })

  tags = {
    Name = "nomad-client-${count.index}"
  }
}
