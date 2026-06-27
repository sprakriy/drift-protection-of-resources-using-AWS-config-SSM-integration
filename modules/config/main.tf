# 1. Rule to detect if S3 bucket is public
resource "aws_config_config_rule" "s3_public" {
  name = "s3-bucket-public-access-prohibited"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }
}

# 2. Rule to detect if S3 bucket is encrypted
resource "aws_config_config_rule" "s3_encryption" {
  name = "s3-bucket-server-side-encryption-enabled"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }
}
# 1. Detect unauthorized instance types (e.g., ensuring only t3.medium is used)
/*
resource "aws_config_config_rule" "ec2_instance_type" {
  name = "ec2-instance-type-check"
  source {
    owner             = "AWS"
    source_identifier = "INSTANCES_IN_VPC" # Or use custom Lambda for specific instance type matching
  }
  input_parameters = jsonencode({
    instanceType = "t3.medium"
  })
}
*/
resource "aws_config_config_rule" "ec2_instance_type" {
  name = "ec2-instance-type-check"

  source {
    owner             = "AWS"
    source_identifier = "DESIRED_INSTANCE_TYPE"
  }

  # Managed rules require input_parameters as a JSON-encoded string
  input_parameters = jsonencode({
    instanceType = "t3.medium" # Note: Some rules use 'instanceTypes' (plural)
  })
}

# 2. Detect if EC2 has an IAM role attached
resource "aws_config_config_rule" "ec2_iam_role" {
  name = "ec2-instance-profile-attached"
  source {
    owner             = "AWS"
    source_identifier = "EC2_INSTANCE_PROFILE_ATTACHED"
}
}
# 3. Detect if Security Groups allow unrestricted access (common drift)
resource "aws_config_config_rule" "ec2_sg_restricted" {
  name = "restricted-common-ports"
  source {
    owner             = "AWS"
    source_identifier = "RESTRICTED_INCOMING_TRAFFIC"
  }
}
resource "aws_sns_topic" "drift_alerts" {
  name = "config-drift-alerts"
}
resource "aws_sns_topic_subscription" "drift_alerts_email" {
  topic_arn = aws_sns_topic.drift_alerts.arn
  protocol  = "email"
  endpoint  = "shankar.prakriya@gmail.com"
}
resource "aws_config_delivery_channel" "config_delivery" {
  name           = "default"
  s3_bucket_name = var.s3_bucket_name
  sns_topic_arn  = aws_sns_topic.drift_alerts.arn
}
#data "aws_s3_bucket" "existing_logs_bucket" {
#  bucket = "config-bucket-319310747432" # The literal name of your bucket
#}
locals {
  # Define these locally so they are accessible to both the policy and the delivery channel
  config_bucket_name = "config-bucket-319310747432"
  config_bucket_arn  = "arn:aws:s3:::${local.config_bucket_name}"
}
resource "aws_s3_bucket_policy" "config_bucket_policy" {
  bucket = var.s3_bucket_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSConfigBucketPermissionsCheck"
        Action = "s3:GetBucketAcl"
        Effect = "Allow"
        Resource = var.s3_bucket_arn
        Principal = { Service = "config.amazonaws.com" }
      },
      {
        Sid    = "AWSConfigBucketDelivery"
        Action = "s3:PutObject"
        Effect = "Allow"
        Resource = "${var.s3_bucket_arn}/*"
        Principal = { Service = "config.amazonaws.com" }
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      }
    ]
  })
}