# 🚀 DHTAJO: AWS Automated Web Deployment Infrastructure

**DHTAJO** is a team infrastructure project focused on modernizing a manually operated AWS web application environment through containerization, automated CI/CD, rolling deployment, and improved credential management.

The project deploys a **Java 17 / Tomcat 10 web application packaged as a WAR file** using Docker and Amazon ECR, with application instances managed by EC2 Auto Scaling behind an Application Load Balancer.

Deployment automation is implemented through **GitHub Actions and AWS IAM OIDC**, reducing manual deployment steps and eliminating the need to store long-lived AWS access keys in the CI/CD workflow.

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
| Application | Java Web Application (WAR) |
| Runtime | Java 17, Tomcat 10 |

---

## 📐 System Architecture

![Architecture Diagram](./images/architecture.png)

### Architecture Design

The infrastructure was designed around network isolation, controlled traffic flow, automated application delivery, and reduced reliance on long-lived credentials.

### 1. Network Isolation

Application instances are deployed inside **private subnets without public IP addresses**.

External application traffic enters the infrastructure through the **Application Load Balancer**, while outbound internet access required by private instances is provided through a NAT Gateway.

```text
                    Internet
                       │
                       ▼
            Application Load Balancer
                       │
                       ▼
              Private Subnet
                       │
                       ▼
           EC2 Auto Scaling Group
                       │
                       ▼
               Docker Container
                       │
                       ▼
             Java / Tomcat App
                       
Private EC2 Instances
        │
        ▼
    NAT Gateway
        │
        ▼
Amazon ECR / External Services
```

This design reduces direct exposure of application instances to the public internet while maintaining controlled outbound connectivity.

### 2. Security Group Chaining

Application instances accept application traffic on port `8080` only from the ALB security group.

```text
Internet
   │
   │ HTTP/HTTPS
   ▼
Application Load Balancer
   │
   │ ALB Security Group
   ▼
TCP 8080
   │
   ▼
EC2 Security Group
   │
   ▼
Tomcat Application
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
- Uses temporary AWS credentials through AWS STS
- Restricts role assumption to the intended repository context
- Reduces credential exposure in the CI/CD workflow

---

## 📦 2. Java/Tomcat Containerization

The application is packaged as a **WAR file** and deployed using a Tomcat-based Docker image.

The container build process follows this structure:

```text
Java Web Application
        │
        ▼
     WAR File
        │
        ▼
     Dockerfile
        │
        ▼
Tomcat 10 Container Image
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
Java / Tomcat Application
```

The Docker image provides a consistent application runtime across EC2 instances and allows application versions to be distributed through Amazon ECR.

This repository therefore uses **Java/Tomcat as the application runtime**, with Docker serving as the standardized deployment unit.

---

## 🔄 3. Rolling Deployment with ASG Instance Refresh

Application deployment uses **EC2 Auto Scaling Instance Refresh** to progressively replace existing application instances with instances running the updated container image.

The deployment flow is:

```text
Code / Application Update
          │
          ▼
     GitHub Actions
          │
          ▼
   Build Docker Image
          │
          ▼
      Amazon ECR
          │
          ▼
Trigger ASG Instance Refresh
          │
          ▼
     New EC2 Instance
          │
          ▼
Pull Container Image
          │
          ▼
Start Tomcat Container
          │
          ▼
    ALB Health Check
          │
          ├── Healthy ──► Receive Traffic
          │
          └── Unhealthy ► Excluded from Traffic
```

ALB health checks validate instance availability before new instances participate in normal application traffic.

This rolling replacement strategy was implemented to **minimize service interruption during deployment** rather than replacing all application instances simultaneously.

---

# ⚙️ CI/CD Pipeline

The deployment workflow automates application delivery from a repository update to infrastructure rollout.

```text
Git Push
   │
   ▼
GitHub Actions
   │
   ├── Authenticate to AWS via OIDC
   │
   ├── Build Tomcat Docker Image
   │
   ├── Push Image to Amazon ECR
   │
   └── Trigger ASG Instance Refresh
   │
   ▼
EC2 Auto Scaling Group
   │
   ▼
New EC2 Instance
   │
   ├── Pull Image from ECR
   └── Start Docker Container
              │
              ▼
       Java / Tomcat App
              │
              ▼
       ALB Health Check
              │
              ▼
        Traffic Serving
```

This workflow reduces manual application deployment steps and standardizes the deployment process across EC2 instances.

---

# 📊 Measured Migration Results

The following results were recorded during the project environment and represent measurements from the implemented lab/test deployment.

| Metric | Before Migration | After Migration | Observed Change |
|---|---:|---:|---|
| **Application Deployment Lead Time** | Approx. 15–20 min | **Approx. 36 sec** | Significantly reduced deployment initiation time |
| **Deployment Process** | Manual deployment steps | **Automated CI/CD workflow** | Reduced manual intervention |
| **Deployment Interruption** | Approx. 1–3 min | **No interruption observed during testing** | Improved deployment availability |
| **AWS Credentials** | Long-lived Access Key | **OIDC-based temporary credentials** | Reduced long-lived credential exposure |

> **Note:** These results were observed in the project test environment and should not be interpreted as production-scale performance benchmarks.

---

# 🛠 Troubleshooting Experience

## 1. IAM Role Availability During Instance Bootstrap

During instance initialization, AWS API operations could fail before the instance role and required AWS access were fully available.

To improve bootstrap reliability, retry logic was added to the shell initialization process.

The script:

- Retries the required operation up to five times
- Waits five seconds between attempts
- Prevents transient initialization failures from immediately terminating the bootstrap process

This improved the reliability of automated instance initialization.

---

## 2. Docker Daemon Initialization

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

- EC2 application instances deployed in private subnets without public IP addresses
- External application traffic routed through the Application Load Balancer
- EC2 application port restricted to traffic originating from the ALB security group
- GitHub Actions authenticated through AWS IAM OIDC
- Temporary AWS credentials issued through AWS STS
- Repository context restrictions applied to IAM role assumption
- Application container images distributed through Amazon ECR
- Long-lived AWS access keys removed from the CI/CD authentication workflow

These controls reduce unnecessary public exposure and reliance on long-lived credentials while maintaining an automated application deployment workflow.

---

# 📂 Repository Structure

```text
aws-web-project/
├── .github/
│   └── workflows/
│       └── ...
├── deploy/
│   └── ROOT_260612.war
├── images/
│   └── architecture.png
├── Dockerfile
└── README.md
```

### Key Components

- **`.github/workflows/`** — GitHub Actions CI/CD workflow
- **`deploy/`** — Java WAR application artifact used for container deployment
- **`images/`** — Architecture documentation
- **`Dockerfile`** — Builds the Tomcat-based application container
- **`README.md`** — Project architecture and implementation documentation

> Legacy Node.js/Express test files were removed from the final repository because the deployed application runtime is Java/Tomcat.

---

# 🎯 Project Outcomes

Through this project, the team implemented and validated:

- AWS VPC-based application infrastructure
- Private EC2 application deployment
- Application Load Balancer traffic routing
- EC2 Auto Scaling-based instance management
- Java/Tomcat application containerization
- Docker-based application packaging
- Amazon ECR container image distribution
- GitHub Actions CI/CD automation
- AWS IAM OIDC authentication
- Temporary credential issuance through AWS STS
- Rolling deployment using ASG Instance Refresh
- ALB-based instance health validation
- Automated EC2 bootstrap procedures
- Troubleshooting of IAM and Docker initialization timing issues

The project demonstrates practical experience integrating **AWS infrastructure, Java/Tomcat containerization, CI/CD automation, IAM security, and rolling deployment mechanisms** into a unified application delivery workflow.

---

# 📌 Project Scope

This project demonstrates an automated AWS deployment architecture implemented in a controlled project environment.

The focus is on:

**Network Isolation → Java/Tomcat Containerization → CI/CD → OIDC Authentication → ECR Image Distribution → Automated Deployment → Health Validation → Rolling Instance Replacement**

The architecture is intended to demonstrate practical cloud infrastructure and DevOps engineering concepts rather than represent a production-certified deployment platform.
