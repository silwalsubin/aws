
provider "aws" {
  region = "us-east-1" # Specify your preferred region
}

# Step 1: Check for Existing VPC and Create if it Doesn't Exist
data "aws_vpcs" "all_vpcs" {
  tags = {
    Name = "MyVPC"  # Replace with your VPC name
  }
}

resource "aws_vpc" "my_vpc" {
  count                = length(data.aws_vpcs.all_vpcs.ids) == 0 ? 1 : 0
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "MyVPC"
  }

  lifecycle {
    prevent_destroy = false
  }
}

# Step 2: Check for Existing Subnet and Create if it Doesn't Exist
data "aws_subnets" "all_subnets" {
  filter {
    name   = "tag:Name"
    values = ["MySubnet"]  # Replace with your Subnet name
  }
}

resource "aws_subnet" "my_subnet" {
  count                  = length(data.aws_subnets.all_subnets.ids) == 0 ? 1 : 0
  vpc_id                 = length(data.aws_vpcs.all_vpcs.ids) > 0 ? data.aws_vpcs.all_vpcs.ids[0] : aws_vpc.my_vpc[0].id
  cidr_block             = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "MySubnet"
  }

  lifecycle {
    prevent_destroy = false
  }
}

# Step 3: Check for Existing Internet Gateway and Create if it Doesn't Exist
data "aws_internet_gateway" "all_igws" {
  filter {
    name   = "tag:Name"
    values = ["MyInternetGateway"]  # Replace with your Internet Gateway name
  }
}

resource "aws_internet_gateway" "my_igw" {
  count  = length(data.aws_internet_gateway.all_igws.id) == 0 ? 1 : 0
  vpc_id = length(data.aws_vpcs.all_vpcs.ids) > 0 ? data.aws_vpcs.all_vpcs.ids[0] : aws_vpc.my_vpc[0].id

  tags = {
    Name = "MyInternetGateway"
  }

  lifecycle {
    prevent_destroy = false
  }
}

# Step 4: Check for Existing Route Table and Create if it Doesn't Exist
data "aws_route_tables" "all_route_tables" {
  filter {
    name   = "tag:Name"
    values = ["MyRouteTable"]  # Replace with your Route Table name
  }
}

resource "aws_route_table" "my_route_table" {
  count  = length(data.aws_route_tables.all_route_tables.ids) == 0 ? 1 : 0
  vpc_id = length(data.aws_vpcs.all_vpcs.ids) > 0 ? data.aws_vpcs.all_vpcs.ids[0] : aws_vpc.my_vpc[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = length(data.aws_internet_gateways.all_igws.ids) > 0 ? data.aws_internet_gateways.all_igws.ids[0] : aws_internet_gateway.my_igw[0].id
  }

  tags = {
    Name = "MyRouteTable"
  }

  lifecycle {
    prevent_destroy = false
  }
}

# Step 5: Associate the Route Table with the Subnet if Necessary
resource "aws_route_table_association" "my_route_table_association" {
  count          = length(data.aws_route_tables.all_route_tables.ids) == 0 ? 1 : 0
  subnet_id      = length(data.aws_subnets.all_subnets.ids) > 0 ? data.aws_subnets.all_subnets.ids[0] : aws_subnet.my_subnet[0].id
  route_table_id = length(data.aws_route_tables.all_route_tables.ids) > 0 ? data.aws_route_tables.all_route_tables.ids[0] : aws_route_table.my_route_table[0].id
}

# Step 6: Check for Existing Security Group and Create if it Doesn't Exist
data "aws_security_groups" "all_sgs" {
  filter {
    name   = "tag:Name"
    values = ["MySecurityGroup"]  # Replace with your Security Group name
  }
}

resource "aws_security_group" "my_security_group" {
  count  = length(data.aws_security_groups.all_sgs.ids) == 0 ? 1 : 0
  name        = "allow_rdp"
  description = "Allow RDP traffic"
  vpc_id      = length(data.aws_vpcs.all_vpcs.ids) > 0 ? data.aws_vpcs.all_vpcs.ids[0] : aws_vpc.my_vpc[0].id

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

  lifecycle {
    prevent_destroy = false
  }
}

# Step 7: Create a Key Pair
resource "tls_private_key" "my_key" {
  algorithm = "RSA"
  rsa_bits  = 2048

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_key_pair" "my_key_pair" {
  key_name   = "my_key_pair"
  public_key = tls_private_key.my_key.public_key_openssh

  lifecycle {
    prevent_destroy = false
  }
}

# Step 8: Create a Windows EC2 Instance
resource "aws_instance" "my_windows_instance" {
  ami                    = "ami-0069eac59d05ae12b" # Change to a valid Windows AMI in your region
  instance_type          = "t2.micro"
  subnet_id              = length(data.aws_subnets.all_subnets.ids) > 0 ? data.aws_subnets.all_subnets.ids[0] : aws_subnet.my_subnet[0].id
  vpc_security_group_ids = [length(data.aws_security_groups.all_sgs.ids) > 0 ? data.aws_security_groups.all_sgs.ids[0] : aws_security_group.my_security_group[0].id]
  key_name               = aws_key_pair.my_key_pair.key_name

  user_data = <<-EOF
    <powershell>
    # Any Windows user data script can be added here
    </powershell>
  EOF

  tags = {
    Name        = "DevNibus"
    Environment = var.environment  # Adding the environment tag
  }

  lifecycle {
    prevent_destroy = false
  }
}

# Step 9: Create an Elastic IP and Associate it with the Instance (Optional)
resource "aws_eip" "my_eip" {
  vpc      = true
  instance = aws_instance.my_windows_instance.id

  tags = {
    Name = "MyElasticIP"
  }

  lifecycle {
    prevent_destroy = false
  }
}

# Outputs
output "instance_public_ip" {
  value = aws_instance.my_windows_instance.public_ip
}

output "private_key" {
  value     = tls_private_key.my_key.private_key_pem
  sensitive = true
}
