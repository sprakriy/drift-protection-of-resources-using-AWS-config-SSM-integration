# The import block stays in your root main.tf to bind them
module "ssm_setup" {
  source = "./modules/ssm"
}

module "s3_storage" {
  source      = "./modules/s3"
  global_bucket_name = var.global_bucket_name
}

module "compute" {
  source               = "./modules/ec2"
  ami_id               = var.ami_id
  # Inject dependencies
  iam_instance_profile = module.ssm_setup.instance_profile_name
  s3_bucket_arn        = module.s3_storage.bucket_arn
}

# Add the new governance/detection module
module "governance" {
  source = "./modules/config"
  s3_bucket_name = module.s3_storage.bucket_name
  s3_bucket_arn = module.s3_storage.bucket_arn
}