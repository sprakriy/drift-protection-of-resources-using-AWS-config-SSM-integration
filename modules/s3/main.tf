resource "aws_s3_bucket" "this" {
  bucket = var.global_bucket_name

tags = {
    Project = "DriftProtection" # This is the bridge
  }
}
output "bucket_name" {
  value = aws_s3_bucket.this.bucket
}
output "bucket_arn" {
  value = aws_s3_bucket.this.arn
}