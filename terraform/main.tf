# File: terraform/main.tf

# Step 1: Define the provider
provider "aws" {
  region = "us-west-2" # Specify your preferred region
}

# Step 2: Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "MyVPC"
  }
}

# Step 3: Create a Subnet
resource "aws_subnet" "my_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "MySubnet"
  }
}

# Step 4: Create an Internet Gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "MyInternetGateway"
  }
}

# Step 5: Create a Route Table
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "MyRouteTable"
  }
}

# Step 6: Associate the Route Table with the Subnet
resource "aws_route_table_association" "my_route_table_association" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}

# Step 7: Create a Security Group
resource "aws_security_group" "my_security_group" {
  name        = "allow_rdp"
  description = "Allow RDP traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 3389
    to_port     = 3389
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
    Name = "MySecurityGroup"
  }
}

# Step 8: Create a Key Pair
resource "tls_private_key" "my_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "my_key_pair" {
  key_name   = "my_key_pair"
  public_key = tls_private_key.my_key.public_key_openssh
}

# Step 9: Create a Windows EC2 Instance
resource "aws_instance" "my_windows_instance" {
  ami                    = "ami-0d5d9d301c853a04a" # Change to a valid Windows AMI in your region
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.my_subnet.id
  vpc_security_group_ids = [aws_security_group.my_security_group.id]
  key_name               = aws_key_pair.my_key_pair.key_name

  user_data = <<-EOF
    <powershell>
    # Any Windows user data script can be added here
    </powershell>
  EOF

  tags = {
    Name = "MyWindowsInstance"
    Environment = var.environment  # Adding the environment tag
  }
}

# Output the instance public IP and key private key
output "instance_public_ip" {
  value = aws_instance.my_windows_instance.public_ip
}

output "private_key" {
  value     = tls_private_key.my_key.private_key_pem
  sensitive = true
}

# Step 10: Create an Elastic IP and Associate it with the Instance (Optional)
resource "aws_eip" "my_eip" {
  vpc = true
  instance = aws_instance.my_windows_instance.id

  tags = {
    Name = "MyElasticIP"
  }
}