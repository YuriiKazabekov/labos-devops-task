# Explanation of Technology Choices

## Terraform (AWS Provisioning)
Terraform is used for its declarative approach and strong support for version-controlled infrastructure. It enables reproducible builds for our VPC, EC2 instances, RDS, and Elasticache resources.

## Ansible (On-Premises Configuration)
Ansible is chosen for its simplicity and ease of use in automating configuration tasks on servers. It is used to configure Jenkins, Nomad, Consul, and Vault, ensuring a consistent environment across on-prem systems.

## Jenkins (CI/CD)
Jenkins automates the build, test, and deployment processes. Our pipeline builds the Docker image for the backend API, tags it with a build number, and pushes it to a container registry.

## Docker (Containerization)
Docker packages the backend API (written in Flask) and its dependencies into a container, ensuring consistency across development and production environments.

## Nomad (Orchestration)
HashiCorp Nomad orchestrates container deployments on the AWS EC2 instance. It provides a lightweight alternative to other orchestrators and integrates seamlessly with Consul and Vault.

## Consul (Service Discovery)
Consul is used for service discovery and health checking. It helps track the status of the backend API and other services, enabling dynamic configuration and scaling.

## Vault (Secrets Management)
Vault securely stores and manages sensitive information such as database credentials, ensuring that secrets are not exposed in code or configuration files.

## Prometheus & Grafana (Monitoring & Alerting)
Prometheus scrapes metrics from the backend API and infrastructure (e.g., using Node Exporter), while Grafana visualizes these metrics in dashboards. Alertmanager is configured to send alerts for critical events like high CPU usage or application downtime.

# Steps Taken for Deployment and Configuration

## Infrastructure Provisioning (Terraform)
- Wrote Terraform modules and configuration files (`main.tf`, `provider.tf`, `variables.tf`, `outputs.tf`) to provision the VPC, subnets, EC2 instances, RDS, and Elasticache.
- Defined outputs for important resource identifiers (e.g., VPC ID, subnet IDs, instance IPs).

## On-Premises Configuration (Ansible)
- Created Ansible playbooks and roles for installing and configuring Jenkins, Docker, Nomad, Consul, and Vault.
- Configured the hosts inventory (`ansible/hosts.ini`) and created role-specific tasks (e.g., `ansible/roles/backend-api/tasks/main.yml`).

## Application Deployment
- Developed a Dockerfile in the `docker/` directory to containerize the Flask backend API.
- Wrote a Jenkins Pipeline (`Jenkinsfile`) that:
  - Checks out the repository.
  - Builds the Docker image using `--network=host` to avoid DNS issues.
  - Tags the image with the build number (e.g., using `BUILD_NUMBER`).
  - Pushes the image to a container registry.
- Created a Nomad job file (`backend-api.nomad`) that deploys the Docker container to the EC2 instance.

## Monitoring and Alerting
- Configured Prometheus (`monitoring/prometheus.yml`) to scrape metrics from the backend API (`/metrics` endpoint) and Node Exporter.
- Set up Grafana as a visualization layer.
- Defined alert rules in `monitoring/alert_rules.yml` and configured Alertmanager for critical alerts.

# Challenges Faced and How They Were Overcome

## DNS Issues During Docker Build
The Docker build process initially failed due to temporary DNS resolution errors. This was resolved by adding the `--network=host` flag in the Jenkins Pipeline's Docker build command.

## Hybrid Environment Integration
Integrating on-premises tools (Ansible, Jenkins) with cloud resources (AWS) required a careful separation of concerns. Terraform was used exclusively for cloud provisioning, while Ansible managed on-premises configuration. This separation helped maintain clarity and allowed each tool to be utilized within its area of strength.

## Sensitive Files Management
Files such as Terraform state and lock files needed to be excluded from version control. These files were added to `.gitignore` and removed from the repository history where necessary, ensuring that sensitive information and ephemeral state files are not accidentally exposed.

## Secure Communication
Ensuring secure communication between services was challenging. To address these concerns, TLS was implemented along with strict IAM roles and best practices in network configuration, securing data exchange across the infrastructure.

## RDS Deployment and Permissions Constraints
The Terraform block for the RDS instance was disabled because my IAM user did not have sufficient permissions to provision that resource in AWS. Moreover, the assignment instructions were somewhat contradictory—one part specified that the RDBMS should be on-premises, while another suggested deploying it on AWS. Given the permissions constraints and this ambiguity, I opted to deploy the RDBMS on-premises.

