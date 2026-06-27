resource "aws_instance" "this" {
  ami           = var.ami_id
  instance_type = "t3.medium"
  iam_instance_profile = var.iam_instance_profile # Dependency injected from SSM module
  
  tags = {
    BucketReference = var.s3_bucket_arn, # Dependency injected from S3 module
    Project = "DriftProtection" # This is the bridge
  }
}
#output "compute_instance_id" {
#  value = module.compute.instance_id
#}