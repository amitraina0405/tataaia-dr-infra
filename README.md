# Automated Disaster Recovery (DR) with Infra as Code & Policy as Code

**Hybrid Cloud DR Framework for Tata AIA Life Insurance**

This repository provides an automated **Disaster Recovery (DR) solution** using **Infrastructure as Code (IaC)** and **Policy as Code (PaC)** across a **Hybrid Cloud (On-Prem + AWS)** environment.  
It leverages **Ansible, Terraform, and OPA/Conftest** to ensure **compliance-driven, reliable, and repeatable** DR operations.

---

## 🚀 Features

- **Hybrid Cloud DR Setup** – Supports both On-Premises & AWS.
- **Infrastructure as Code (IaC)** – Provisioning via Terraform + Ansible.
- **Policy as Code (PaC)** – Compliance checks using OPA/Conftest.
- **Automated DR Failover/Failback** workflows.
- **Monitoring Integration** – Prometheus, Grafana, CloudWatch.
- **Validation & Reporting** – Automated DR validation scripts.

---

## 📂 Repository Structure
 
.
├── ansible/

│   ├── roles/

│   │   └── env-setup/

│   │       ├── tasks/main.yml

│   │       ├── handlers/main.yml

│   │       ├── vars/env_setup.yml

│   │       └── templates/

│   └── playbooks/

│       └── dr_setup.yml

├── terraform/

│   └── hybrid-dr/

│       ├── main.tf

│       ├── variables.tf

│       └── outputs.tf

├── policies/

│   ├── opa/

│   │   └── dr_policies.rego

│   └── conftest/

│       └── policy_checks.rego

├── scripts/

│   └── run_dr_validation.sh

├── .gitignore

├── README.md

└── requirements.yml

---
## ⚙️ Prerequisites
- **Tools**
 - Ansible >= 2.12
 - Terraform >= 1.6
 - Open Policy Agent (OPA) / Conftest
 - Prometheus / Grafana / CloudWatch Agent
- **Credentials**
 - AWS CLI configured (`~/.aws/credentials`)
 - Vault-encrypted secrets for Ansible
---
## 🛠️ Setup & Usage
### 1. Clone Repository
```bash
git clone https://github.com/tataaia/dr-automation.git
cd dr-automation

2. Install Dependencies
ansible-galaxy install -r requirements.yml

3. Initialize Terraform
cd terraform/hybrid-dr
terraform init
terraform plan -out=plan.json

4. Apply Ansible Playbook
ansible-playbook ansible/playbooks/dr_setup.yml -i inventory/hosts.ini

5.  Run Policy Validation
conftest test terraform/hybrid-dr/plan.json

6. Run DR Validation
bash scripts/run_dr_validation.sh

Monitoring & Reporting
• Prometheus Targets: DR nodes automatically added.
• Grafana Dashboards: Prebuilt DR dashboards for SLA tracking.
• Validation Reports: Stored under dr_validation_report.txt.

Security & Compliance
• All sensitive variables are stored in Ansible Vault.
• OPA policies ensure infra follows IRDAI, RBI, and ISO 22301 compliance.
• Terraform plan must pass PaC validation before apply.

Future Enhancements
• Multi-region DR failover automation
• Chaos Engineering for resilience testing
• Integration with ServiceNow CMDB for asset tracking

Contributors
• SRE Team – Tata AIA Life Insurance
• AVP SRE (Infrastructure Automation & DR Strategy)

License
This project is licensed under the MIT License.
--- 
