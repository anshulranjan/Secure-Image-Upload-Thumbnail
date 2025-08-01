# Cloud-Based Image Upload and Processing System

A secure, serverless cloud application for uploading images, automatic thumbnail generation, and secure download via signed URLs, built with AWS Lambda, API Gateway, S3, and fully automated infrastructure as code (Terraform) and CI/CD (GitHub Actions).

---

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Project Structure](#project-structure)
- [Security](#security)
- [Monitoring & Logging](#monitoring--logging)
- [Development & CI/CD](#development--cicd)
- [Cost Control](#cost-control)


---

## Features

- **Easy image upload via a REST API**
- **Automatic thumbnail generation** (128x128px, serverless)
- **Secure, time-limited download links** (signed URLs)
- **Fully serverless / no servers to manage**
- **Automated cloud infrastructure with Terraform**
- **CI/CD deployment with GitHub Actions**
- **Centralized logging and monitoring**
- **IAM-based least-privilege security**

---

## Architecture

<img width="1275" height="461" alt="image" src="https://github.com/user-attachments/assets/8725903b-c610-4212-bc59-05858df5d9ad" />


**How it works:**
1. The user uploads an image with a POST request to API Gateway.
2. API Gateway calls the Lambda (upload handler), which stores the image in S3 (`uploads/`).
3. A second Lambda (thumbnail generator) is triggered automatically by a new S3 object; it creates and stores a thumbnail in `thumbnails/`.
4. The user can retrieve secure download links for the original or thumbnail using `/get-url`.
5. All code, infrastructure, and deployment is automated.

---

## Tech Stack

- **AWS Lambda** (Python, Pillow for image processing)
- **Amazon S3** (secure, scalable storage)
- **API Gateway** (REST API endpoints)
- **Terraform** (infrastructure as code)
- **GitHub Actions** (CI/CD automation)
- **CloudWatch** (logs, monitoring)
- **IAM** (security, scoped permissions)

<img width="902" height="367" alt="image" src="https://github.com/user-attachments/assets/4ca51a6a-9ca8-4b83-9b76-40975633c115" />

---

## Getting Started

### Prerequisites

- AWS account with API keys
- Python 3.x and pip
- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [GitHub](https://github.com/) account

---

### Project Structure

```plaintext
cloud-image-upload/
│
├── infra/                # Terraform code
│   └── main.tf
│   └── variables.tf
│   └── outputs.tf
│
├── lambda/               # Lambda sources & zipped packages
│   └── api_upload.py
│   └── thumbnail.py
│   └── get_url.py
│   └── api_upload.zip
│   └── thumbnail.zip
│   └── get_url.zip
│
└── .github/workflows/
    └── deploy.yml        # GitHub Actions CI/CD pipeline
```

---

## Security
- S3 buckets are private; access is only via signed URLs.
- Permissions use least privilege IAM roles.
- API access is always over HTTPS.
- Only Lambda functions can write/read S3; users never access S3 directly.

---

## Monitoring & Logging
- All Lambda logs and errors are sent to AWS CloudWatch.
- API Gateway logs and metrics available in the AWS Console.

---

## Development & CI/CD
- Terraform manages all infrastructure as code.
- GitHub Actions (.github/workflows/deploy.yml) automates checks and deployment on code pushes.

---

## Cost Control
- Uses AWS Free Tier for most development.
- To remove all resources, run:
```
terraform destroy
```

