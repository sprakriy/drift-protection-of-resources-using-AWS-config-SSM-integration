terraform {
    backend "s3" {
    bucket = "sprakriya-tf-state-storage"
    key    = "automation/driftprotection/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    use_lockfile = true
    }
}