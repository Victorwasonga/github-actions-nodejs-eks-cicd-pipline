Here’s a detailed `README.md` for your project, which outlines the steps involved and the tools used, as well as how to set it up and run it:

```markdown
# CI/CD Pipeline for Node.js Application with EKS, Docker, and GitHub Actions

## Project Overview

This project demonstrates a fully automated CI/CD pipeline to build, scan, and deploy a containerized Node.js application to **Amazon Elastic Kubernetes Service (EKS)** using **GitHub Actions**. We use **Docker** to containerize the application, **Trivy** to scan the Docker image for vulnerabilities, and **Amazon ECR** to store the images. The application is deployed on EKS, and a **LoadBalancer service** is created to expose it to the public.

## Architecture

The pipeline consists of the following main components:

1. **GitHub Actions**: The CI/CD pipeline is triggered by changes to the repository, automating the process of building, scanning, and deploying the application.
2. **Docker**: Containerizes the Node.js application into an image.
3. **Trivy**: Scans the Docker image for vulnerabilities before it is pushed to the container registries.
4. **Amazon ECR (Elastic Container Registry)**: Stores the Docker images.
5. **Amazon EKS (Elastic Kubernetes Service)**: Manages the Kubernetes cluster for deploying and scaling the application.
6. **Kubernetes Deployment**: Manages the application pods in the EKS cluster.
7. **Kubernetes LoadBalancer Service**: Exposes the application externally via a LoadBalancer.

## Tools & Technologies Used

- **Node.js**: Application runtime environment.
- **Docker**: To build containerized applications.
- **GitHub Actions**: CI/CD pipeline automation.
- **Trivy**: Container image scanning tool.
- **Amazon ECR**: Managed Docker container registry by AWS.
- **Amazon EKS**: Managed Kubernetes service by AWS.
- **Kubernetes**: Container orchestration.
- **kubectl**: Kubernetes CLI for deploying and managing resources.

## Features

- **Automated Docker Build and Scan**: Every time code is pushed to the repository, the Docker image is built and scanned for vulnerabilities using Trivy.
- **Continuous Deployment**: After the image is successfully built and scanned, it is pushed to both Amazon ECR and Docker Hub.
- **Kubernetes Deployment**: The latest Docker image is automatically deployed to an EKS cluster.
- **Load Balancer Exposure**: The Node.js app is exposed to the public using an AWS LoadBalancer service.

## Prerequisites

Before you begin, ensure you have the following:

- **AWS CLI** installed and configured.
- **eksctl** installed for creating and managing EKS clusters.
- **kubectl** installed for interacting with Kubernetes.
- **Docker** installed on your local machine.
- **GitHub account** with access to GitHub Actions.
- **AWS IAM User** with proper permissions for EKS, ECR, and EC2.
- **Docker Hub account** for storing images.

## Setup Instructions

### 1. Clone the Repository

Start by cloning the repository to your local machine:

```bash
git clone https://github.com/yourusername/your-repository.git
cd your-repository
```

### 2. Set Up AWS EKS Cluster

If you haven’t already created an EKS cluster, you can use the following `eksctl` command to create it:

```bash
eksctl create cluster --name actions-eks-cluster --region us-east-1 --nodegroup-name actions-eks-ng --node-type t3.medium --nodes 1 --managed
```

### 3. Configure AWS Credentials

Set your AWS credentials as secrets in GitHub:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`

### 4. Configure Docker Hub Credentials

Set up the following secrets in GitHub for Docker Hub login:

- `DOCKER_USERNAME`
- `DOCKER_PASSWORD`

### 5. Create Kubernetes Manifests

Create the necessary Kubernetes manifest files for deployment and service:

- `deployment.yaml`: Kubernetes deployment for the Node.js app.
- `service.yaml`: LoadBalancer service to expose the app externally.

Example `deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nodejs-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nodejs-app
  template:
    metadata:
      labels:
        app: nodejs-app
    spec:
      containers:
        - name: nodejs-app
          image: 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-node-app:latest
          ports:
            - containerPort: 3000
```

Example `service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nodejs-service
spec:
  selector:
    app: nodejs-app
  type: LoadBalancer
  ports:
    - protocol: TCP
      port: 80
      targetPort: 3000
```

### 6. Set Up GitHub Actions Workflow

The main steps of the GitHub Actions workflow (`.github/workflows/ci-cd.yml`) are as follows:

- **Build Docker Image**: Build the Docker image from the Node.js application.
- **Scan Docker Image with Trivy**: Scan the image for vulnerabilities.
- **Push Docker Image to ECR**: Push the image to Amazon ECR.
- **Push Docker Image to Docker Hub**: Optionally push the image to Docker Hub.
- **Deploy to EKS**: Apply Kubernetes manifests to deploy the application to EKS.
- **Verify Deployment**: Wait for the pods to roll out and verify that the deployment is successful.

### 7. Workflow Example

Here’s an example of the GitHub Actions workflow:

```yaml
# .github/workflows/main.yml
name: CI/CD Pipeline

on:
  push:
    branches:
      - main

jobs:
  # 1. Checkout the repository
  checkout:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v3
      
  # 2. Set up Node.js and Install Dependencies
  install_dependencies:
    runs-on: ubuntu-latest
    needs: checkout
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v3

      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: 16

      - name: Install Dependencies
        run: |
          echo "Installing dependencies..."
          npm install

# Build, Scan, Tag, and Push Image to Amazon ECR
  build_and_scan:
    runs-on: ubuntu-latest
    needs: install_dependencies
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Build Docker Image
        run: |
          echo "Building Docker image..."
          docker build -t my-node-app:latest .

      - name: Scan Docker Image with Trivy
        run: |
          echo "Scanning Docker image with Trivy..."
          docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image my-node-app:latest

      # Set up AWS Credentials
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRETE_ACCESS_KEY }}  # Fixed Typo
          aws-region: ${{ secrets.AWS_REGION }}

    

      # ✅ Login to Amazon ECR
      - name: Log in to Amazon ECR
        run: |
          aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${{ secrets.ECR_REPOSITORY_URI }}
          echo "✅ ECR Login successful!"

      # 🏷️ Tag Docker Image for Amazon ECR
      - name: Tag Docker Image for Amazon ECR
        run: |
          ECR_REPO="${{ secrets.ECR_REPOSITORY_URI }}/actions-cicd"
          echo "🏷️ Tagging Docker image for Amazon ECR..."
          docker tag my-node-app:latest $ECR_REPO:latest

      # 📌 Verify Local Docker Images
      - name: Verify Local Docker Images
        run: docker images

      # 📤 Push Image to Amazon ECR
      - name: Push Image to Amazon ECR
        run: |
          ECR_REPO="${{ secrets.ECR_REPOSITORY_URI }}/actions-cicd"
          echo "📤 Pushing Docker image to Amazon ECR..."
          docker push $ECR_REPO:latest

      # ✅ Login to Docker Hub
      - name: Log in to Docker Hub
        run: |
          echo "${{ secrets.DOCKER_PASSWORD }}" | docker login -u "${{ secrets.DOCKER_USERNAME }}" --password-stdin
          echo "✅ Docker Hub login successful!"

      #  Tag Docker Image for Docker Hub
      - name: Tag Docker Image for Docker Hub
        run: |
          DOCKER_REPO="${{ secrets.DOCKER_USERNAME }}/my-node-app"
          echo "🏷️ Tagging Docker image for Docker Hub..."
          docker tag my-node-app:latest $DOCKER_REPO:latest

      #  Push Image to Docker Hub
      - name: Push Image to Docker Hub
        run: |
          DOCKER_REPO="${{ secrets.DOCKER_USERNAME }}/my-node-app"
          echo " Pushing Docker image to Docker Hub..."
          docker push $DOCKER_REPO:latest
      # Push Image to Amazon ECR
      - name: Push Image to Amazon ECR
        run: |
          ECR_REPO="${{ secrets.ECR_REPOSITORY_URI }}/actions-cicd"
          echo "Pushing Docker image to Amazon ECR..."
          docker push $ECR_REPO:latest

      # Update Kubeconfig 
      - name: Update kubeconfig
        run: aws eks --region ${{ secrets.AWS_REGION }} update-kubeconfig --name actions-eks-cluster

      # Install kubectl
      - name: Install kubectl
        run: |
          curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/kubectl
          chmod +x ./kubectl
          sudo mv ./kubectl /usr/local/bin/kubectl

      # Update Deployment YAML with the latest image
      - name: Update deployment image
        run: |
          ECR_REPO="${{ secrets.ECR_REPOSITORY_URI }}/actions-cicd"
          sed -i "s|image: .*|image: $ECR_REPO:latest|" manifests/deployment.yaml

      # Deploy to Amazon EKS
      - name: Deploy to EKS
        run: |
          kubectl apply -f manifests/deployment.yaml
          kubectl apply -f manifests/service.yaml

      # Verify Deployment Status
      - name: Verify Deployment
        run: |
          echo "Waiting for pods to be in a running state..."
          kubectl rollout status deployment/nodejs-app
          kubectl get pods -o wide

```

### 8. Access the Application

After the deployment is complete, your application will be exposed through an **AWS Load Balancer**. You can access it using the Load Balancer URL. To get the URL:

1. Run `kubectl get svc nodejs-service` to see the external URL.
2. Open the URL in your browser to access the Node.js application.

## Conclusion

This project demonstrates a modern, fully automated CI/CD pipeline using GitHub Actions, Docker, Trivy, ECR, and EKS for deploying a secure and scalable Node.js application. It ensures that every change is automatically built, scanned for vulnerabilities, pushed to container registries, and deployed to AWS with minimal manual intervention.
```
