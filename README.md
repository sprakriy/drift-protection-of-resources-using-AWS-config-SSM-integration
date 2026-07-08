├── main.tf              #Root module configuration (calls compute module)
├── variables.tf         # Global variables and environment definitions
├── outputs.tf           # Infrastructure output mappings
├── backend.tf           # back end terraform
└── modules/
    └── s3/
        ├── main.tf         # bucket  declarations
        └── variables.tf    # Module-specific variables
    └── ec2/
        ├── main.tf         # EC2 instance and security group declarations
        └── variables.tf    # Module-specific variables
    └── ssm/
        ├── main.tf         # SSM module
        └── variables.tf    # Module-specific variables
    └── config/
        ├── main.tf         # IAM role,config rules, SNS  declarations
        └── variables.tf    # Module-specific variables


Project: Automated Compliance & Drift ProtectionThis project implements a fully automated, event-driven compliance monitoring system using AWS Config, EventBridge, and SNS. The entire infrastructure is defined as code via Terraform.🏗 Infrastructure OverviewThis project manages 22 AWS resources, including:IAM: Dedicated service roles for AWS Config.Config: Configuration recorder and status management.Rules: Automated compliance evaluation for resources (e.g., S3, Security Groups).Messaging: EventBridge event buses and SNS topic alerting.🚀 Getting StartedPrerequisitesTerraform installed ($>= 1.0.0$)AWS CLI configured with appropriate credentials.Deployment StepsInitialize the backend: ```terraform initValidate the configuration:terraform validate
Deploy the 22-resource stack:Bashterraform apply
🧪 TestingAfter deployment, force a re-evaluation to verify the event pipeline:Bashaws configservice start-config-rules-evaluation --config-rule-names <YOUR_RULE_NAME>
You should receive an email notification via SNS shortly after execution.🧹 Cleanup (The "Destroy" Operation)To cleanly remove all 22 resources and avoid ongoing AWS costs:terraform destroy
Note: This operation is non-reversible. It will remove the recorder, IAM roles, and all associated event triggers.
