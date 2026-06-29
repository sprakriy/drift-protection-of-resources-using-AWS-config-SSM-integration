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
# 1. The EventBridge Rule (The "Filter")
resource "aws_cloudwatch_event_rule" "compliance_change" {
  name        = "config-compliance-change-rule"
  description = "Trigger SNS for ANY Config compliance change"
  event_bus_name = "default"

  event_pattern = jsonencode({
    "source": ["aws.config"]
  })
}
/*
resource "aws_cloudwatch_event_rule" "compliance_change" {
  name        = "config-compliance-change-rule"
  description = "Trigger SNS when a config rule is non-compliant"

  event_pattern = jsonencode({
    "source": ["aws.config"],
    "detail-type": ["Config Rules Compliance Change"],
    "detail": {
      "newEvaluationResult": {
        "complianceType": ["NON_COMPLIANT"]
      }
    }
  })
}
*/
# 2. Link the Rule to your SNS Topic
resource "aws_cloudwatch_event_target" "sns_target" {
  rule      = aws_cloudwatch_event_rule.compliance_change.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.drift_alerts.arn
  event_bus_name = "default"
}

# 3. Grant EventBridge permission to publish to your SNS Topic
resource "aws_sns_topic_policy" "config_to_sns" {
  arn = aws_sns_topic.drift_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridgeToPublish"
        Effect = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.drift_alerts.arn
      }
    ]
  })
}
# 1. THE AUDITOR: Define the role the Config service needs
resource "aws_iam_role" "config_role" {
  name = "aws-config-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = { Service = "config.amazonaws.com" }
      }
    ]
  })
}

# 2. THE PERMISSION: Give it the "key-card" to audit the account
resource "aws_iam_role_policy_attachment" "config_managed_policy" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

# 3. THE RECORDER: Use the role you just created
resource "aws_config_configuration_recorder" "recorder" {
  name     = "default"
  role_arn = aws_iam_role.config_role.arn # Now it's explicitly tied to the role above

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

# 4. THE ACTIVATOR: Start it
resource "aws_config_configuration_recorder_status" "recorder_status" {
  name       = aws_config_configuration_recorder.recorder.name
  is_enabled = true
  depends_on = [aws_config_configuration_recorder.recorder]
}