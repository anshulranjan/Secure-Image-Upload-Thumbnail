In this Project, the included technologies are:

- A REST API endpoint to upload images (API Gateway → Lambda → S3)
- A Lambda that processes (makes thumbnails) from uploaded images (triggered directly from S3)
- All setup (S3, Lambda, API Gateway, IAM Roles, CloudWatch) automated by Terraform
- Code/deployment automation via Github Actions
- Security: minimal permissions, HTTPS, signed URLs to fetch images

### STEP 0: Set up accounts and tools
Sign up for AWS – https://aws.amazon.com/free/ <br />
Sign up for Github – https://github.com/ <br />
Install (or get ready to install): <br />
Terraform
```
$ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
$ echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
$ eval "$(/opt/homebrew/bin/brew shellenv)"
$ brew --version

Homebrew 4.5.13

$ brew tap hashicorp/tap
$ brew install hashicorp/tap/terraform
$ terraform -help
```
AWS CLI (optional, recommended for testing)
```
$ curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
$ sudo installer -pkg AWSCLIV2.pkg -target /
$ aws --version

aws-cli/2.28.0 Python/3.13.4 Darwin/24.5.0 exe/x86_64
```

Python (already comes with most computers)

### STEP 1: Make a Local Project
```
$ mkdir cloud-image-upload
$ cd cloud-image-upload

# Folders
$ mkdir infra lambda
```

### STEP 2: Set up AWS Access for Terraform
In AWS Console, go to IAM > Users > Add User
- Name: terraform-admin
- Select: Programmatic access
- Attach policy: AdministratorAccess (for this demo on your own account; in real life, use stricter policy)
- Download the .csv file with your new Access Key and Secret Access Key

On your computer, run:
```
$ aws configure
```
- Enter your keys
- Region: us-east-1
- Output: json

### STEP 3: Write Terraform to Create Basic AWS Resources
In infra/, create 3 files:

- main.tf
- variables.tf
- outputs.tf

main.tf 
```
provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "images" {
  bucket = "YOUR-UNIQUE-BUCKET-NAME-12345"
  force_destroy = true
}
```

Run the commands:
```
$ cd infra
$ terraform init
$ terraform plan
$ terraform apply
```
Check in AWS S3 console to see your bucket created!

### STEP 4: Write Your First Lambda Function (Python)
In lambda/, create api_upload.py <br />

Zip the function:
```
cd lambda
zip api_upload.zip api_upload.py
```
For the above lambda, Create the Lambda Function in Terraform <br />
Similarly do for the other lambda functions <br />

```
#This function uses Pillow (image processing library).
pip install -t ./ Pillow
cd lambda
zip -r thumbnail.zip thumbnail.py Pillow* PIL*
```

### Test Your System – Curl Commands & Sequence
a) Upload an Image
```
curl -X POST "https://abcd1234.execute-api.us-east-1.amazonaws.com/prod/upload" \
  -H "Content-Type: image/jpeg" \
  --data-binary "@image1.jpg"

{"message":"Uploaded!","image_key":"uploads/f6e6d...jpg"}

```

b) Get the image
```
curl "https://abcd1234.execute-api.us-east-1.amazonaws.com/prod/upload?key={image_key}"

{{"url": "https://bcd1234.execute-api.us-east-1.amazonaws.com/uploads/gdrgdertg"}
```






