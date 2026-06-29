resource "aws_s3_bucket" "this" {
  bucket = var.global_bucket_name
  # This tells Terraform to empty the bucket (including all versions) before deleting it
  force_destroy = true
tags = {
    Project = "DriftProtection" # This is the bridge
  }
}
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}
output "bucket_name" {
  value = aws_s3_bucket.this.bucket
}
output "bucket_arn" {
  value = aws_s3_bucket.this.arn
}