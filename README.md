# Highly Available Web App on AWS (VPC + ALB + Auto Scaling)

A production-style AWS infrastructure setup demonstrating a highly available, auto-scaling web application deployed across multiple Availability Zones with public/private subnet isolation.

## Architecture

```
Internet
   │
   ▼
Internet Gateway
   │
   ▼
ALB (public-subnet-1, public-subnet-2)  ──► S3 (access logs)
   │
   ▼
Target Group
   │
   ▼
Auto Scaling Group (2–4 EC2 instances)
   (private-subnet-1, private-subnet-2)
   │
   ▼
NAT Gateway (public-subnet-1) ──► Internet Gateway (outbound only)
```

**Traffic flow**
- Inbound: Internet → IGW → ALB (public subnets) → Target Group → EC2 (private subnets)
- Outbound: EC2 (private subnets) → NAT Gateway (public subnet) → IGW → Internet

## Infrastructure Components

| Component | Details |
|---|---|
| VPC | `10.0.0.0/16` |
| Public Subnets | 2, across 2 AZs |
| Private Subnets | 2, across 2 AZs |
| Internet Gateway | Attached to VPC for public subnet internet access |
| NAT Gateway | Deployed in a public subnet for private subnet outbound access |
| Route Tables | Separate public and private route tables |
| Security Groups | `alb-s` (80/443 from internet), `ec2-sg` (80 from ALB only) |
| Load Balancer | Application Load Balancer, internet-facing |
| Target Group | HTTP:80, instance target type |
| Launch Template | Amazon Linux, Apache installed via user data |
| Auto Scaling Group | Min: 2, Desired: 2, Max: 4 |
| S3 Bucket | Stores ALB access logs |

## Prerequisites

- AWS account with appropriate IAM permissions
- AWS CLI configured (if deploying via CLI/IaC)
- An EC2 key pair (if SSH access is needed)

## Deployment Steps

Full click-by-click setup instructions are in [`aws-deployment-guide.md`](./aws-deployment-guide.md).

High-level order:
1. Create VPC and 4 subnets (2 public, 2 private)
2. Create and attach Internet Gateway
3. Create NAT Gateway in a public subnet
4. Create public and private route tables, associate subnets
5. Create security groups (ALB and EC2)
6. Create S3 bucket for ALB logs
7. Create target group and Application Load Balancer
8. Enable ALB access logging to S3
9. Create launch template with user data script
10. Create Auto Scaling Group (min 2, desired 2, max 4) attached to the target group



## Verification

1. Confirm ASG instances are `InService` and healthy in the target group
2. Access the app via the ALB's DNS name
3. Confirm log files appear in the S3 bucket under the ALB logs prefix

## Cleanup

To avoid ongoing charges, delete resources in this order:
1. Auto Scaling Group (terminates instances)
2. Load Balancer and Target Group
3. NAT Gateway (and release its Elastic IP)
4. Internet Gateway (detach, then delete)
5. Subnets, Route Tables, Security Groups
6. VPC
7. S3 bucket (empty it first)


