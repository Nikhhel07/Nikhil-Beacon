# Overview

**This Terraform configuration provisions a secure, multi-AZ AWS VPC with:**

•	Public and private subnets (across 3 Availability Zones)

•	Internet Gateway and NAT Gateway for public/private routing

•	AWS Network Firewall integration with stateless and stateful rule groups

•	Route tables for internet/NAT routing

•	Full tagging for environment tracking


 **1**. **VPC Setup**
 
created a Virtual Private Cloud (VPC) that spans 3 Availability Zones (AZs) in one region ( us-east-1). This provides high availability and fault tolerance.

CIDR Block: 10.0.0.0/16 for the VPC.

AZ Distribution: Spreads resources across 3 AZs for redundancy.

 **2**. **Subnets Configuration**
 
Each AZ contains both a public and private subnet:

3 Public Subnets (/24 blocks, one per AZ)

Used for resources needing direct internet access 

Connected to an Internet Gateway.

3 Private Subnets (/24 blocks, one per AZ)

For backend services 

Use NAT Gateway for outbound internet access.

Firewall Subnet(s): A dedicated subnet per AZ for hosting AWS Network Firewall endpoints.

 **3. Internet Gateway (IGW)**
 
A single IGW is attached to the VPC.

Public subnets route traffic through this IGW for internet access.

 **4. NAT Gateway**
 
A NAT Gateway (or 3, one per AZ for high availability) is deployed in the public subnets.

It allows instances in private subnets to access the internet securely without being exposed.

 **5. AWS Network Firewall**
 
Deployed into dedicated firewall subnets.

Acts as a centralized inspection point for traffic between private subnets and other networks.

Routes from private subnets are modified to direct egress traffic through the firewall endpoints.

## 6. Firewall Rules

 Implemented stateless and stateful rules:

### Stateless Rule Group
Allowed outbound HTTP (80) and HTTPS (443).

Stateless rules are evaluated first and don’t keep track of connections.

### Stateful Rule Group
Deny outbound access to a specific IP, 198.51.100.1.

Stateful rules inspect full sessions and can enforce more complex logic.


   ## To Run This Terraform Project

   **command:**  **terraform init**
   
   **command:**   **Terraform apply**
   

