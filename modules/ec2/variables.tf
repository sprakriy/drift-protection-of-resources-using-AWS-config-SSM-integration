variable "s3_bucket_arn" {
  description = "The ARN of the S3 bucket for compute access"
  type        = string
}
variable "iam_instance_profile" {
  description = "The IAM instance profile to attach to the EC2 instance"
  type        = string
}
variable "ami_id" {
  type        = string
  description = "description"
}