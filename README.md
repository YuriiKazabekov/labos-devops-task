# Labos - Home Assignment for DevOps Engineer

This repository contains a solution for the DevOps Engineer home assignment. The project demonstrates the use of modern tools and practices to deploy a hybrid infrastructure (on-premises and AWS) along with a simple web application. The solution covers infrastructure provisioning, application deployment, orchestration, monitoring, and alerting.

## Table of Contents

- [Overview](#overview)
- [Solution Components](#solution-components)
  - [Infrastructure Provisioning](#infrastructure-provisioning)
  - [Application Deployment](#application-deployment)
  - [Monitoring and Alerting](#monitoring-and-alerting)
- [Getting Started](#getting-started)
- [Repository Structure](#repository-structure)
- [Jenkins Pipeline](#jenkins-pipeline)
- [Nomad Job Configuration](#nomad-job-configuration)
- [Future Enhancements](#future-enhancements)
- [License](#license)

## Overview

This project implements a hybrid infrastructure where 80% of applications run on-premises (configured via Ansible and Jenkins) and 20% run in the cloud (AWS) using Terraform to provision resources. The cloud components include networking (VPC, subnets), compute (EC2), managed databases (RDS), caching (ElastiCache), and orchestration and secrets management with HashiCorp Nomad, Consul, and Vault.

## Solution Components

### Infrastructure Provisioning

- **AWS (Cloud):**
  - **Terraform** is used to provision:
    - A VPC with both public and private subnets.
    - An EC2 instance in the private subnet for the backend API.
    - Security groups and necessary networking configurations.
    - An RDS instance for the RDBMS.
    - An ElastiCache instance for Redis.
  - The Terraform code is structured to support different environments (Dev, QA, Staging, Production) via variables and workspaces.

- **On-Premises:**
  - **Ansible** is used to configure:
    - A Jenkins server for CI/CD.
    - Servers for running Nomad, Consul, and Vault.

### Application Deployment

- **Backend API (Flask):**
  - The application is written in Python using Flask.
  - A **Dockerfile** located in the `docker/` directory builds the Docker image.
    - The image is built using the dependencies listed in `docker/requirements.txt` and the source code in `docker/app.py`.
  - The application exposes two endpoints:
    - `/health` – returns a health status (used by orchestration tools for health checks).
    - `/metrics` – exposes Prometheus metrics (using the `prometheus_client` library).

- **CI/CD:**
  - A Jenkins Pipeline builds the Docker image and tags it using a parameter (e.g., `BUILD_NUMBER=18`).
  - The image is pushed to a container registry (e.g., Docker Hub or AWS ECR).
  - The Nomad job is deployed with a command such as:
    ```bash
    nomad job run -var="BUILD_NUMBER=18" backend-api.nomad
    ```

- **Orchestration:**
  - **Nomad** is used to deploy the backend API Docker container.
  - **Consul** provides service discovery and health checks.
  - **Vault** is used for managing secrets (e.g., database credentials).

### Monitoring and Alerting

- **Prometheus:**
  - The `prometheus.yml` file is configured to scrape metrics from:
    - The backend API on port `5000` (using the `/metrics` endpoint).
    - **Node Exporter** on port `9100` for host metrics.
  - An example configuration is:
    ```yaml
    global:
      scrape_interval: 15s
      evaluation_interval: 15s

    scrape_configs:
      - job_name: 'backend-api'
        static_configs:
          - targets: ['10.0.3.91:5000']
        metrics_path: /metrics

      - job_name: 'node_exporter'
        static_configs:
          - targets: ['10.0.3.91:9100']

    rule_files:
      - "alert_rules.yml"
    ```
  - The `rule_files` directive loads alert rules from `alert_rules.yml`.

- **Grafana:**
  - Grafana is deployed (e.g., as a Docker container) and configured to use Prometheus as a data source.
  - Dashboards are created to visualize application and infrastructure metrics.

- **Alertmanager:**
  - Integrated with Prometheus to send alerts (via email, Slack, etc.) based on critical events such as high CPU usage or application downtime.
  - Alert rules are defined in the `alert_rules.yml` file.

## Getting Started

1. **Infrastructure Provisioning:**
   - Use Terraform to provision AWS resources.
   - Run Ansible playbooks to configure on-premises servers (Jenkins, Nomad, Consul, Vault).

2. **Application Deployment:**
   - Build the Docker image using the Jenkins Pipeline.
   - Deploy the Nomad job with:
     ```bash
     nomad job run -var="BUILD_NUMBER=18" backend-api.nomad
     ```

3. **Monitoring:**
   - Start Prometheus and Grafana (e.g., via Docker) to collect and visualize metrics.
   - Configure Grafana to use Prometheus as a data source and create relevant dashboards.

## Repository Structure

├── ansible
│   ├── hosts.ini
│   ├── playbook.yml
│   └── roles
│       ├── backend-api
│       │   └── tasks
│       │       └── main.yml
│       ├── hashicorp
│       │   └── tasks
│       │       └── main.yml
│       └── jenkins
│           └── tasks
│               └── main.yml
├── ansible_running_result.txt
├── aws_cli_commands.txt
├── backend-api.nomad
├── backend-api-policy.hcl
├── docker
│   ├── app.py
│   ├── Dockerfile
│   └── requirements.txt
├── Documentation.txt
├── Jenkinsfile
├── labos-keypair-01.pem
├── monitoring
│   ├── alertmanager.yml
│   ├── alert_rules.yml
│   ├── monitoring_configuration.txt
│   └── prometheus.yml
├── README.md
├── terraform
│   ├── main.tf
│   ├── outputs.tf
│   ├── provider.tf
│   └── variables.tf
└── vault&nomad_commands.txt

## Jenkins Pipeline

Jenkins Pipeline (located in the repository) builds and pushes the Docker image

## Nomad Job Configuration

To deploy the backend API, run the following command:
nomad job run -var="BUILD_NUMBER=6" backend-api.nomad

## Future Enhancements

Expand Terraform configurations to support multiple environments (Dev, QA, Staging, Production) using workspaces and templating.
Configure HTTPS for Grafana and applications via a reverse proxy (e.g., Nginx).
Enhance monitoring with additional metrics from cAdvisor for Docker containers.
Implement more advanced alerting rules and integrations with notification systems (e.g., Slack, Email).

## License

Feel free to adjust or extend this README according to your project's specifics and any additional documentation you may have.
