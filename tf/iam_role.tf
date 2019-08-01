# ECS task execution role data
data "aws_iam_policy_document" "ecs_task_execution_role" {
  version = "2012-10-17"
  statement {
    sid = ""
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# ECS task execution role
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecs_task_execution_role"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_task_execution_role.json}"
}

# ECS task execution role policy attachment
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = "${aws_iam_role.ecs_task_execution_role.name}"
  policy_arn = "${aws_iam_policy.ecs_task_execution_role.arn}"
}

resource "aws_iam_policy" "ecs_task_execution_role" {
  name = "ecs_task_execution_role_policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:GetBucketVersioning",
        "s3:GetObjectVersion",
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:ListBucketVersions"
      ],
      "Resource": [
        "arn:aws:s3:::int-helloworld-image",
        "arn:aws:s3:::int-helloworld-image/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# Iam policies for autoscale
data "aws_iam_policy_document" "ecs_auto_scale_role" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["application-autoscaling.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_auto_scale_role" {
  name               = "autoscale_role"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_auto_scale_role.json}"
}

resource "aws_iam_role_policy_attachment" "ecs_auto_scale_role" {
  role       = "${aws_iam_role.ecs_auto_scale_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
}
