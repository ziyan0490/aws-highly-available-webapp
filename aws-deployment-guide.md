# AWS Highly Available Web App Deployment Guide
### VPC → Subnets → NAT/IGW → Route Tables → Security Groups → ALB → Auto Scaling → S3 Logging

---

## Architecture Overview

- 1 VPC
- 2 Public Subnets (different AZs) → for ALB and NAT Gateway
- 2 Private Subnets (different AZs) → for EC2 instances (Auto Scaling Group)
- 1 Internet Gateway (IGW) → public internet access
- 1 NAT Gateway (in a public subnet) → private subnets get outbound internet
- 2 Route Tables (Public + Private)
- 2 Security Groups (ALB-SG, EC2-SG)
- 1 Target Group + 1 Application Load Balancer
- 1 Launch Template (with user data script)
- 1 Auto Scaling Group → Desired: 2, Min: 2, Max: 4
- 1 S3 Bucket → stores ALB access logs

---

## Step 1: Create the VPC

1. Go to **VPC Console** → **Your VPCs** → **Create VPC**
2. Select **VPC only**
3. Settings:
   - Name tag: fullstack
   - IPv4 CIDR: `10.0.0.0/16`
   - IPv6: No IPv6 CIDR block
   - Tenancy: Default
4. Click Create VPC

---

## Step 2: Create 4 Subnets (2 Public + 2 Private)

Go to Subnets → Create subnet → select fullstack (vpc), then add all 4 at once:

| Subnet Name | AZ | CIDR Block | Type |
|---|---|---|---|
| public-subnet-1 | us-east-1a | 10.0.1.0/24 | Public |
| public-subnet-2 | us-east-1b | 10.0.2.0/24 | Public |
| private-subnet-1 | us-east-1a | 10.0.3.0/24 | Private |
| private-subnet-2 | us-east-1b | 10.0.4.0/24 | Private |

Click Create subnet.

> ⚠️ Use two different Availability Zones — this is what makes the ALB and ASG highly available.

**Enable auto-assign public IP** for the two public subnets:
- Select public1 → Actions → Edit subnet settings → check Enable auto-assign public IPv4 address → Save
- Repeat for public2

---

## Step 3: Create and Attach the Internet Gateway

1. go to Internet Gateways → Create internet gateway
2. Name: internet
3. Click Create, then select it → Actions → Attach to VPC → choose fullstack

---

## Step 4: Create the NAT Gateway

1. go to NAT Gateways → Create NAT gateway
2. Settings:
   - Name: nat
   - Subnet: public1
   - Connectivity type: Public
   - Elastic IP: Click Allocate Elastic IP and select it
3. Click Create NAT gateway 
---

## Step 5: Create Route Tables

Public Route Table
1. Route Tables → Create route table
2. Name: public, VPC: fullstack → Create
3. Edit routes:
   - Add route: Destination 0.0.0.0/0 → Target: Internet Gateway → internet
4. Subnet associations tab → Edit subnet associations
   - ✅ Check public-subnet-1
   - ✅ Check public-subnet-2
   - Save

Private Route Table
1. Route Tables → Create route table
2. Name: private, VPC: fullstack → Create
3. Edit routes:
   - Add route: Destination 0.0.0.0/0 → Target: NAT Gateway → myapp-nat-gw
4. Subnet associations tab → Edit subnet associations
   - ✅ Check private-subnet-1
   - ✅ Check private-subnet-2
   - Save

---

Step 6: Create Security Groups

ALB Security Group
1. EC2 Console → Security Groups → Create security group
2. Name: loadbalancer , VPC: fullstack
3. Inbound rules:
   - HTTP (80) — Source: 0.0.0.0/0
4. Outbound: leave default (all traffic allowed)
5. Create.

EC2 Security Group
1. Create security group
2. Name: ec2 VPC: fullstack
3. Inbound rules:
   - HTTP (80) — Source: loadbalacncer security group
   - SSH (22) — Source: your IP 
4. Outbound: leave default
5. Create.

> This ensures only the load balancer can reach your EC2 instances on port 80 — instances are not directly exposed to the internet since they live in private subnets.

---

Step 7: Create S3 Bucket for ALB Access Logs

1. S3 Console → Create bucket
2. Bucket name: aload (must be globally unique)
3. Region: same as your VPC
4. Block Public Access: keep all blocked (default)
5. Create bucket
6. ALB will need permission to write to this bucket — AWS automatically prompts you to attach the required bucket policy when you enable access logging in Step 9 (or you can add the AWS-provided ELB log-delivery policy manually under Permissions → Bucket Policy).

---

Step 8: Create Target Group

1. EC2 Console → Target Groups → Create target group
2. Settings:
   - Target type: Instances
   - Name: alb-ec2
   - Protocol: HTTP, Port: 80
   - VPC: fullstack
   - Health check path: / (or your app's health endpoint)
3. Click Next → skip registering targets manually (ASG will do this) → Create target group

---

Step 9: Create the Application Load Balancer

1. EC2 Console → Load Balancers → Create load balancer → Application Load Balancer
2. Settings:
   - Name: myapp-alb
   - Scheme: Internet-facing
   - VPC: fullstack
   - Mappings: select both subnets public1 and public2
   - Security group: loadblancer
3. Listener: HTTP:80 → forward to alb-ec2
4. Create load balancer
5. Enable access logging:
   - Select the ALB → Attributes tab → Edit
   - Enable Monitor → toggle on Access logs
   - S3 URI: s3://aloadb
   - Save changes

---

## Step 10: Create Launch Template

1. EC2 Console → Launch Templates → Create launch template
2. Settings:
   - Name: ec2-autoscale
   - AMI: Amazon Linux 2023 (or your preferred AMI)
   - Instance type: t3.micro (or as needed)
   - Key pair: select or create one
   - Security group: ec2
   - Advanced details → User data: in here you can insert your userdata script
3. Click Create launch template

---

Step 11: Create Auto Scaling Group

1. EC2 Console → Auto Scaling Groups → Create Auto Scaling group
2. Settings:
   - Name: ec2-autoscaleee
   - Launch template: ec2-autoscale
   - VPC: fullstack
   - Subnets: select subnets private1 and private2 (instances stay private, ALB handles public traffic)
3. Load balancing:
   - Attach to an existing load balancer
   - Choose target group: myapp-tg
   - Enable ELB health checks
4. Group size:
   - Desired capacity: 2
   - Minimum capacity: 2
   - Maximum capacity: 4
5. Create Auto Scaling group

---

Step 12: Verify the Deployment

1. Wait for the ASG to launch 2 instances (Instance Management tab)
2. Check Target Group → Targets — both should show `healthy`
3. Copy the ALB's DNS name (Load Balancers → myapp-alb → Description)
4. Paste it into a browser — you should see your app respond
5. Check the S3 bucket after a few minutes — ALB access log files should start appearing




