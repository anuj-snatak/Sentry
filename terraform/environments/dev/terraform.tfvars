project_name = "cloudforge"
environment  = "dev"
aws_region   = "us-east-1"

owner       = "platform-team"
cost_center = "engineering"

vpc_cidr           = "10.0.0.0/16"
single_nat_gateway = true

# Left empty intentionally: no SSH ingress ships enabled by default.
# Add your corporate/VPN CIDR here (e.g. ["203.0.113.0/24"]) before
# relying on SSH-based Ansible access; SSM Session Manager (already
# wired via the interface VPC endpoints below) is the preferred path
# and needs no entry here.
admin_cidr_blocks = []

app_port                       = 8080
enable_vpc_interface_endpoints = true

instance_type        = "t3.micro"
health_check_path    = "/health"
asg_min_size         = 1
asg_max_size         = 3
asg_desired_capacity = 2

# Add a real destination here to receive CloudWatch alarm notifications,
# e.g. [{ protocol = "email", endpoint = "ops@example.com" }]
sns_subscriptions = []
