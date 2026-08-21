data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    sid     = "AllowEC2AssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "infra_monitor_s3_upload" {
  statement {
    sid    = "UploadSystemReport"
    effect = "Allow"

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}/${var.s3_object_key}"
    ]
  }
}

resource "aws_iam_role" "infra_monitor_ec2" {
  name               = "${var.project_name}-ec2-role"
  description        = "IAM role used by the infra-monitor EC2 workload"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name        = "${var.project_name}-ec2-role"
    Project     = var.project_name
    Environment = var.environment
    Phase       = "august-security"
  }
}

resource "aws_iam_policy" "infra_monitor_s3_upload" {
  name        = "${var.project_name}-s3-upload"
  description = "Allow infra-monitor EC2 to upload only its system report"
  policy      = data.aws_iam_policy_document.infra_monitor_s3_upload.json

  tags = {
    Name        = "${var.project_name}-s3-upload"
    Project     = var.project_name
    Environment = var.environment
    Phase       = "august-security"
  }
}

resource "aws_iam_role_policy_attachment" "infra_monitor_s3_upload" {
  role       = aws_iam_role.infra_monitor_ec2.name
  policy_arn = aws_iam_policy.infra_monitor_s3_upload.arn
}

resource "aws_iam_instance_profile" "infra_monitor" {
  name = "${var.project_name}-instance-profile"
  role = aws_iam_role.infra_monitor_ec2.name

  tags = {
    Name        = "${var.project_name}-instance-profile"
    Project     = var.project_name
    Environment = var.environment
    Phase       = "august-security"
  }
}
