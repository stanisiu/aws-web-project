# 🚀 DHTAJO: AWS Automated Web Deployment Infrastructure

**DHTAJO** is a team infrastructure project focused on migrating a manually deployed legacy web application to an AWS-based containerized environment with automated CI/CD, rolling deployment, and improved credential management.

The project replaces manual AMI-based deployment procedures with a deployment pipeline integrating **GitHub Actions, AWS IAM OIDC, Amazon ECR, EC2 Auto Scaling, and Application Load Balancer**.

> **Project Focus:** Cloud Infrastructure · CI/CD Automation · Containerization · IAM Security · Rolling Deployment

---

## 🛠 Tech Stack

| Category | Technologies |
|---|---|
| Cloud Platform | AWS |
| Compute | Amazon EC2, EC2 Auto Scaling |
| Networking | VPC, Public/Private Subnets, NAT Gateway |
| Load Balancing | Application Load Balancer (ALB) |
| CI/CD | GitHub Actions |
| Identity & Security | AWS IAM, OIDC, AWS STS, Security Groups |
| Containerization | Docker, Amazon ECR |
| Runtime | Java 17, Tomcat 10 |

---

## 📐 System Architecture

![Architecture Diagram](./images/architecture.png)

### Architecture Design

The infrastructure was designed around network isolation, controlled traffic flow, automated deployment, and reduced reliance on long-lived credentials.

### 1. Network Isolation

Application instances are deployed inside **private subnets without public IP addresses**.

External HTTP traffic enters the infrastructure through the **Application Load Balancer**, while outbound internet access required by private instances is provided through a NAT Gateway.

```text
Internet
   │
   ▼
Application Load Balancer
   │
   ▼
Private EC2 Auto Scaling Group
   │
   ├── Docker Container
   │      └── Java / Tomcat Application
   │
   ▼
NAT Gateway
   │
   ▼
Amazon ECR / External Services
```

This design reduces direct exposure of application instances to the public internet.

### 2. Security Group Chaining

Application instances accept application traffic on port `8080` only from the ALB security group.

```text
Internet
   │
   │ HTTP/HTTPS
   ▼
ALB Security Group
   │
   │ TCP 8080
   ▼
EC2 Security Group
```

Using the ALB security group as the source restricts direct access to the application port and enforces the intended traffic path through the load balancer.

---

# ✨ Key Engineering Points

## 🔒 1. Keyless AWS Authentication with GitHub Actions OIDC

GitHub Actions was integrated with AWS IAM through **OpenID Connect (OIDC)** to avoid storing long-lived AWS access keys in the CI/CD environment.

The authentication flow is:

```text
GitHub Actions
      │
      │ OIDC Token
      ▼
AWS IAM Identity Provider
      │
      ▼
AWS STS
      │
      │ Temporary Credentials
      ▼
IAM Role
      │
      ▼
AWS Resources
```

The IAM trust relationship restricts role assumption based on the GitHub repository context.

Example repository condition:

```text
repo:stanisiu/aws-web-project:*
```

This approach:

- Avoids storing long-lived AWS access keys in GitHub
- Uses temporary AWS credentials through STS
- Restricts role assumption to the intended repository context
- Reduces credential exposure in the CI/CD workflow

---

## 🔄 2. Rolling Deployment with ASG Instance Refresh

Application deployment uses **EC2 Auto Scaling Instance Refresh** to progressively replace existing application instances with instances running the updated version.

The deployment flow is:

```text
Code Push
   │
   ▼
GitHub Actions
   │
   ▼
Docker Image Build
   │
   ▼
Amazon ECR
   │
   ▼
ASG Instance Refresh
   │
   ▼
New EC2 Instance
   │
   ▼
Application Startup
   │
   ▼
ALB Health Check
   │
   ├── Healthy ──► Receive Traffic
   │
   └── Unhealthy ► Not Added to Traffic Path
```

ALB health checks are used to validate instance availability before the instance participates in normal application traffic.

This rolling replacement strategy was implemented to **minimize service interruption during application deployment** rather than replacing all application instances simultaneously.

---

## 📦 3. Containerized Application Deployment

The application runtime was containerized using Docker and distributed through Amazon ECR.

The CI/CD pipeline builds the application image and pushes it to ECR, allowing EC2 instances to retrieve the required application image during deployment.

```text
Application Source
        │
        ▼
   Docker Build
        │
        ▼
   Amazon ECR
        │
        ▼
    EC2 Instance
        │
        ▼
 Docker Container
        │
        ▼
 Java 17 / Tomcat 10
```

Containerization provides a consistent application runtime across deployment instances and simplifies application version delivery.

---

# ⚙️ CI/CD Pipeline

The deployment workflow automates the application delivery process from source changes to infrastructure rollout.

```text
Git Push
   │
   ▼
GitHub Actions
   │
   ├── Authenticate to AWS via OIDC
   │
   ├── Build Docker Image
   │
   ├── Push Image to Amazon ECR
   │
   └── Trigger ASG Instance Refresh
   │
   ▼
New EC2 Instances
   │
   ▼
Pull Container Image
   │
   ▼
Start Application
   │
   ▼
ALB Health Check
   │
   ▼
Traffic Serving
```

This reduced the number of manual steps required during application deployment and standardized the deployment workflow.

---

# 📊 Measured Migration Results

The following results were recorded during the project environment and represent measurements from the implemented lab/test deployment.

| Metric | Before Migration | After Migration | Observed Change |
|---|---:|---:|---:|
| **Application Deployment Lead Time** | Approx. 15–20 min | **Approx. 36 sec** | Significantly reduced deployment initiation time |
| **Deployment Process** | Manual deployment steps | **Automated CI/CD workflow** | Reduced manual intervention |
| **Deployment Interruption** | Approx. 1–3 min | **No interruption observed during testing** | Improved deployment availability |
| **AWS Credentials** | Long-lived Access Key | **OIDC-based temporary credentials** | Reduced long-lived credential exposure |

> **Note:** These results were observed in the project test environment and should not be interpreted as production-scale performance benchmarks.

---

# 🛠 Troubleshooting Experience

## IAM Role Availability During Instance Bootstrap

During instance initialization, AWS API operations could fail before the instance role and required AWS access were fully available.

To improve bootstrap reliability, retry logic was added to the shell initialization process.

The script:

- Retries the required operation up to five times
- Waits five seconds between attempts
- Prevents transient initialization failures from immediately terminating the bootstrap process

This improved the reliability of automated instance initialization.

---

## Docker Daemon Initialization

Docker commands could execute before the Docker daemon was fully ready immediately after installation.

A readiness check using:

```bash
until docker info
```

was introduced before executing subsequent Docker operations.

This synchronizes the bootstrap workflow with Docker daemon availability and reduces failures caused by initialization timing.

---

# 🔐 Security Considerations

The project applies several controls to reduce infrastructure exposure and credential risk:

- EC2 application instances deployed without public IP addresses
- Application traffic routed through the ALB
- Security group references used to restrict EC2 application traffic
- GitHub Actions authenticated through AWS IAM OIDC
- Temporary AWS credentials issued through AWS STS
- Repository context restrictions applied to IAM role assumption
- Application artifacts distributed through private Amazon ECR repositories

These controls reduce unnecessary public exposure and reliance on long-lived credentials while maintaining an automated deployment workflow.

---

# 🎯 Project Outcomes

Through this project, the team implemented and validated:

- AWS VPC-based application infrastructure
- Private EC2 application deployment
- Application Load Balancer traffic routing
- EC2 Auto Scaling-based instance management
- Docker-based application packaging
- Amazon ECR image distribution
- GitHub Actions CI/CD automation
- AWS IAM OIDC authentication
- Rolling deployment using ASG Instance Refresh
- ALB-based instance health validation
- Automated EC2 bootstrap procedures
- Troubleshooting of IAM and Docker initialization timing issues

The project demonstrates practical experience in integrating **AWS infrastructure, containerization, CI/CD automation, IAM security, and rolling deployment mechanisms** into a single application delivery workflow.

---

## 📌 Project Scope

This project demonstrates an automated AWS deployment architecture implemented in a controlled project environment.

The focus is on:

**Network Isolation → Containerization → CI/CD → Keyless Authentication → Automated Deployment → Health Validation → Rolling Instance Replacement**

The architecture is intended to demonstrate practical cloud infrastructure and DevOps engineering concepts rather than represent a production-certified deployment platform.
