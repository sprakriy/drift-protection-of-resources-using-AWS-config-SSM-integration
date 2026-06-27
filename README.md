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
