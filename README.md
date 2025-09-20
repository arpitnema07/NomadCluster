# HashiCorp Nomad Cluster Deployment on AWS

This project deploys a secure, scalable, and resilient HashiCorp Nomad cluster on AWS using Terraform. It demonstrates provisioning distributed systems, managing secure networking, and applying infrastructure best practices.

## Architecture and Design Choices

The architecture consists of:

-   **AWS VPC**: A dedicated Virtual Private Cloud for network isolation.
-   **Subnets**: Multiple subnets across different availability zones for high availability.
-   **Internet Gateway & Route Table**: For internet connectivity.
-   **Security Group**: Configured to allow SSH (port 22), Nomad RPC/Serf/HTTP (ports 4646-4648), and HTTP (port 80) traffic.
-   **Nomad Server(s)**: EC2 instance(s) running Nomad in server mode. Responsible for cluster management.
-   **Nomad Client(s)**: EC2 instance(s) running Nomad in client mode with Docker driver enabled. These nodes execute workloads.
-   **User Data Script (`user_data.sh`)**: Automates the installation and configuration of Docker and Nomad on EC2 instances. It dynamically configures instances as either Nomad servers or clients.
-   **"Hello-World" Application**: A simple containerized web application (`hashicorp/http-echo`) deployed as a Nomad job to verify cluster functionality.

**Scalability**: The Terraform code is structured to easily scale the number of client nodes by changing the `nomad_client_count` variable.

**Secure UI Access**: The Nomad UI is exposed on port 4646 on the Nomad server. For secure access, an SSH tunnel is recommended.

## Prerequisites

1.  **AWS Account**: With appropriate permissions to create EC2 instances, VPC, etc.
2.  **Terraform**: Installed locally (version 1.0+ recommended).
3.  **AWS CLI**: Configured with your AWS credentials.
4.  **SSH Key Pair**: An existing AWS EC2 Key Pair in the region you are deploying to. The name of this key pair will be provided to Terraform via the `key_name` variable.

## Deployment Instructions

1.  **Clone the repository**:
    ```bash
    git clone <your-repo-link>
    cd <your-repo-name>/terraform
    ```
2.  **Initialize Terraform**:
    ```bash
    terraform init
    ```
3.  **Review the plan**:
    ```bash
    terraform plan -var "key_name=nomad-key"
    ```
    Replace `nomad-key` with the name of your AWS EC2 Key Pair.
4.  **Apply the Terraform configuration**:
    ```bash
    terraform apply -var "key_name=nomad-key"
    ```
    Type `yes` when prompted to confirm the deployment.

    This will provision the AWS infrastructure and deploy the Nomad cluster. The `user_data.sh` script will automatically install Docker and Nomad on the instances.

5.  **Deploy the "hello-world" application**:
    Once the Terraform apply is complete and the Nomad cluster is up and running (this might take a few minutes for the instances to fully boot and Nomad to start), you can deploy the sample application.

    First, get the public IP of your Nomad server:
    ```bash
    terraform output nomad_server_public_ips
    ```
    Then, SSH into the Nomad server (replace `<server-public-ip>` and `<path-to-your-private-key>`):
    ```bash
    ssh -i <path-to-your-private-key> ubuntu@<server-public-ip>
    ```
    Inside the server, submit the Nomad job:
    ```bash
    nomad job run /home/ubuntu/jobs/hello-world.nomad
    ```
    *Note: The `hello-world.nomad` file is not automatically copied to the server by Terraform in this setup. You would typically use a provisioner or a configuration management tool for this. For this exercise, you can manually copy it or create it on the server.*
    To simplify, we will assume the `hello-world.nomad` is available on the server.

## Accessing the Nomad UI

The Nomad UI is accessible on port `4646` of the Nomad server. To access it securely, you should use an SSH tunnel:

1.  Get the public IP of your Nomad server:
    ```bash
    terraform output nomad_server_public_ips
    ```
2.  Open an SSH tunnel from your local machine (replace `<server-public-ip>` and `<path-to-your-private-key>`):
    ```bash
    ssh -i <path-to-your-private-key> -N -L 4646:localhost:4646 ubuntu@<server-public-ip>
    ```
    Keep this terminal window open.
3.  Open your web browser and navigate to: `http://localhost:4646`

## Accessing the Sample Application

The "hello-world" application is deployed on port `80` of the Nomad client(s).

1.  Get the public IP of your Nomad client(s):
    ```bash
    terraform output nomad_client_public_ips
    ```
2.  Open your web browser and navigate to: `http://<client-public-ip>`

## CI/CD with GitHub Actions

This project includes a GitHub Actions workflow (`.github/workflows/terraform.yml`) to automate the deployment of the Nomad cluster and the "hello-world" application.

### Setup GitHub Secrets

For the CI/CD pipeline to work, you need to configure the following secrets in your GitHub repository:

1.  **AWS_ACCESS_KEY_ID**: Your AWS Access Key ID.
2.  **AWS_SECRET_ACCESS_KEY**: Your AWS Secret Access Key.
3.  **SSH_KEY_NAME**: The name of your AWS EC2 Key Pair (e.g., `nomad-key`).
4.  **SSH_PRIVATE_KEY**: The *content* of your SSH private key (`.pem` file). When adding this secret, paste the entire content of your `.pem` file, including `-----BEGIN RSA PRIVATE KEY-----` and `-----END RSA PRIVATE KEY-----` lines.

**Steps to add secrets:**
-   Go to your GitHub repository.
-   Click on "Settings" > "Secrets and variables" > "Actions".
-   Click "New repository secret" for each secret listed above.

### Triggering the Pipeline

The pipeline is configured to run automatically on `push` to the `main` branch. **Note that each run of the pipeline will first destroy any existing infrastructure managed by this Terraform configuration and then create new resources.** You can also manually trigger it:

1.  Go to your GitHub repository.
2.  Click on "Actions".
3.  Select the "Terraform CI/CD for Nomad Cluster" workflow from the left sidebar.
4.  Click "Run workflow" on the right side.

## Cleanup

To destroy all the resources created by Terraform:

```bash
cd terraform
terraform destroy -var "key_name=nomad-key"
```
Type `yes` when prompted to confirm the destruction.
