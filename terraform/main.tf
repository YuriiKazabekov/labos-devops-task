##############################
# VPC and Networking Resources
##############################

# Create the VPC
resource "aws_vpc" "vpc01" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "vpc-01"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "igw01" {
  vpc_id = aws_vpc.vpc01.id
  tags = {
    Name = "igw-01"
  }
}

# Create a public subnet (AZ: us-east-1a)
resource "aws_subnet" "subnet01" {
  vpc_id                  = aws_vpc.vpc01.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-01"
  }
}

# Create the first private subnet (AZ: us-east-1a)
resource "aws_subnet" "subnet02" {
  vpc_id            = aws_vpc.vpc01.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "${var.aws_region}a"
  tags = {
    Name = "private-subnet-02"
  }
}

# Create the second private subnet (AZ: us-east-1b) for multi-AZ coverage
resource "aws_subnet" "subnet03" {
  vpc_id            = aws_vpc.vpc01.id
  cidr_block        = var.private_subnet_cidr2
  availability_zone = "${var.aws_region}b"
  tags = {
    Name = "private-subnet-03"
  }
}

# Create a public route table
resource "aws_route_table" "rt_public01" {
  vpc_id = aws_vpc.vpc01.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw01.id
  }

  tags = {
    Name = "rt-public-01"
  }
}

# Associate the public subnet with the public route table
resource "aws_route_table_association" "rt_public_assoc01" {
  subnet_id      = aws_subnet.subnet01.id
  route_table_id = aws_route_table.rt_public01.id
}

# Allocate an Elastic IP for the NAT Gateway
resource "aws_eip" "eip_nat01" {
  vpc = true
}

# Create a NAT Gateway in the public subnet
resource "aws_nat_gateway" "nat01" {
  allocation_id = aws_eip.eip_nat01.id
  subnet_id     = aws_subnet.subnet01.id
  tags = {
    Name = "nat-01"
  }
}

# Create a private route table
resource "aws_route_table" "rt_private01" {
  vpc_id = aws_vpc.vpc01.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat01.id
  }

  tags = {
    Name = "rt-private-01"
  }
}

# Associate the first private subnet with the private route table
resource "aws_route_table_association" "rt_private_assoc01" {
  subnet_id      = aws_subnet.subnet02.id
  route_table_id = aws_route_table.rt_private01.id
}

# Associate the second private subnet with the private route table
resource "aws_route_table_association" "rt_private_assoc02" {
  subnet_id      = aws_subnet.subnet03.id
  route_table_id = aws_route_table.rt_private01.id
}

##############################
# Data Source: Dynamically Lookup the Most Recent Ubuntu 20.04 AMI
##############################

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]   # Canonical's owner ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

##############################
# Resources for EC2, RDS, Redis, and HashiCorp Services
##############################

# Create a security group for the backend EC2 instances
resource "aws_security_group" "sg_backend01" {
  name        = "backend-sg-01"
  description = "Security group for the backend API instance"
  vpc_id      = aws_vpc.vpc01.id

  # Allow SSH access from jump host
  ingress {
    description = "SSH access from jump host"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${aws_instance.jumphost.private_ip}/32"]
  }

  # Allow internal communication for Nomad, Consul, and Vault
  ingress {
    description = "Internal communication for Nomad"
    from_port   = 4647
    to_port     = 4648
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Internal communication for Vault"
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Internal communication Consul"
    from_port   = 8300
    to_port     = 8302
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow internal communication for backend-api
  ingress {
    description = "Communication with back-end api"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow internal communication for node exporter
  ingress {
    description = "Communication with back-end api"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow access to Grafana
  ingress {
    description = "Communication with back-end api"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "backend-sg-01"
  }
}

# Create an EC2 instance for the backend API using the dynamically looked-up Ubuntu AMI
resource "aws_instance" "api_instance01" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.subnet03.id  # Placing the instance in one of the private subnets
  vpc_security_group_ids = [aws_security_group.sg_backend01.id]
  key_name               = var.key_pair_name

  tags = {
    Name = "api-instance-01"
  }
}

# Create a DB subnet group for RDS that covers two AZs
resource "aws_db_subnet_group" "db_subnet_group01" {
  name       = "db-subnet-group-01"
  subnet_ids = [aws_subnet.subnet02.id, aws_subnet.subnet03.id]

  tags = {
    Name = "db-subnet-group-01"
  }
}

## The following RDS instance block is disabled because my IAM user does not have sufficient permissions.
## Also, the assignment instructions are contradictory: one part specifies that the RDBMS should be on-prem,
## while another suggests AWS deployment. Since permissions are insufficient, I will deploy the RDBMS on-prem.
#
# resource "aws_db_instance" "db_instance01" {
#   allocated_storage      = var.db_allocated_storage
#   engine                 = "postgres"
#   engine_version         = var.db_engine_version
#   instance_class         = var.db_instance_class
#   db_name                = var.db_name
#   username               = var.db_username
#   password               = var.db_password
#   db_subnet_group_name   = aws_db_subnet_group.db_subnet_group01.name
#   vpc_security_group_ids = [aws_security_group.sg_backend01.id]
#   skip_final_snapshot    = true
#   publicly_accessible    = false
#
#   tags = {
#     Name = "db-instance-01"
#   }
# }

# Create a self-managed Redis instance on EC2 (Replacement for Elasticache)
resource "aws_instance" "redis_instance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"    # Choose an appropriate size for Redis
  subnet_id              = aws_subnet.subnet03.id
  vpc_security_group_ids = [aws_security_group.sg_backend01.id]
  key_name               = var.key_pair_name

  # User data installs and starts Redis on the instance
  user_data = <<EOF
#!/bin/bash
apt-get update -y
apt-get install -y redis-server
systemctl start redis-server
systemctl enable redis-server
EOF

  tags = {
    Name = "redis-instance"
  }
}

# Create an EC2 instance for Consul, Nomad, and Vault
resource "aws_instance" "hashicorp_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"    # Adjust instance type as needed
  subnet_id              = aws_subnet.subnet03.id
  vpc_security_group_ids = [aws_security_group.sg_backend01.id]
  key_name               = var.key_pair_name

  # User data installs and configures Nomad, Consul, and Vault
  user_data = <<EOF
#!/bin/bash
apt-get update -y

# Install Nomad
curl -O https://releases.hashicorp.com/nomad/1.2.0/nomad_1.2.0_linux_amd64.zip
apt-get install -y unzip
unzip nomad_1.2.0_linux_amd64.zip -d /usr/local/bin/
chmod +x /usr/local/bin/nomad

# Create Nomad configuration and data directories
mkdir -p /etc/nomad
mkdir -p /opt/nomad
cat <<EOT > /etc/nomad/nomad.hcl
data_dir = "/opt/nomad"
bind_addr = "0.0.0.0"
server {
  enabled = true
  bootstrap_expect = 1
}
client {
  enabled = true
}
EOT

# Create Nomad systemd service file
cat <<EOT > /etc/systemd/system/nomad.service
[Unit]
Description=Nomad Agent
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/local/bin/nomad agent -config=/etc/nomad
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT

# Install Consul
curl -O https://releases.hashicorp.com/consul/1.9.0/consul_1.9.0_linux_amd64.zip
unzip consul_1.9.0_linux_amd64.zip -d /usr/local/bin/
chmod +x /usr/local/bin/consul

# Create Consul configuration and data directories
mkdir -p /etc/consul
mkdir -p /opt/consul
cat <<EOT > /etc/consul/consul.hcl
data_dir = "/opt/consul"
bind_addr = "0.0.0.0"
server = true
bootstrap_expect = 1
EOT

# Create Consul systemd service file
cat <<EOT > /etc/systemd/system/consul.service
[Unit]
Description=Consul Agent
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/local/bin/consul agent -config-file=/etc/consul/consul.hcl
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT

# Install Vault
curl -O https://releases.hashicorp.com/vault/1.7.0/vault_1.7.0_linux_amd64.zip
unzip vault_1.7.0_linux_amd64.zip -d /usr/local/bin/
chmod +x /usr/local/bin/vault

# Create Vault configuration and data directories
mkdir -p /etc/vault
mkdir -p /opt/vault
cat <<EOT > /etc/vault/vault.hcl
storage "file" {
  path = "/opt/vault/data"
}
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}
ui = true
EOT

# Create Vault systemd service file
cat <<EOT > /etc/systemd/system/vault.service
[Unit]
Description=Vault Server
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/local/bin/vault server -config=/etc/vault/vault.hcl
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOT

# Reload systemd daemon and start services
systemctl daemon-reload
systemctl start nomad
systemctl enable nomad
systemctl start consul
systemctl enable consul
systemctl start vault
systemctl enable vault
EOF

  tags = {
    Name = "hashicorp-server"
  }
}

# Create a security group for the Jump Host
resource "aws_security_group" "sg_jumphost" {
  name        = "jumphost-sg"
  description = "Security group for the jump host"
  vpc_id      = aws_vpc.vpc01.id

  # Allow SSH access from on-premises (update the IP as needed)
  ingress {
    description = "Allow SSH from on-premises"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["185.102.185.75/32"]
  }

  # Allow access to Grafana
  ingress {
    description = "Communication with back-end api"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["185.102.185.75/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jumphost-sg"
  }
}

# Create an EC2 instance for the Jump Host in the public subnet
resource "aws_instance" "jumphost" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.subnet01.id
  vpc_security_group_ids = [aws_security_group.sg_jumphost.id]
  key_name               = var.key_pair_name

  tags = {
    Name = "jumphost"
  }
}

## The following Elasticache resources are disabled because my IAM user does not have sufficient permissions.
#
# resource "aws_elasticache_subnet_group" "cache_subnet_group01" {
#   name       = "cache-subnet-group-01"
#   subnet_ids = [aws_subnet.subnet02.id, aws_subnet.subnet03.id]
#
#   tags = {
#     Name = "cache-subnet-group-01"
#   }
# }
#
# resource "aws_elasticache_cluster" "cache_cluster01" {
#   cluster_id           = "cache-cluster-01"
#   engine               = "redis"
#   engine_version       = var.redis_engine_version
#   node_type            = var.redis_node_type
#   num_cache_nodes      = 1
#   parameter_group_name = "default.redis6.x"
#   subnet_group_name    = aws_elasticache_subnet_group.cache_subnet_group01.name
#   security_group_ids   = [aws_security_group.sg_backend01.id]
#
#   tags = {
#     Name = "cache-cluster-01"
#   }
# }
