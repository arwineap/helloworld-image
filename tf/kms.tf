resource "aws_kms_key" "key" {
  description             = "helloworld-image app key"
  key_usage               = "ENCRYPT_DECRYPT"
  policy                  = "${data.aws_iam_policy_document.cmk_key_policy.json}"
  is_enabled              = true
  enable_key_rotation     = false
}

resource "aws_kms_alias" "key_alias" {
  name          = "alias/helloworld_image"
  target_key_id = "${aws_kms_key.key.id}"
}


data "aws_caller_identity" "current" {}


data "aws_iam_policy_document" "cmk_key_policy" {
  statement {
    sid = "Allow root account access"

    effect = "Allow"

    principals = {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    actions = [
      "kms:*"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid = "Allow ecs task usage"

    effect = "Allow"

    principals = {
      type = "AWS"
      identifiers = [
        "${aws_iam_role.ecs_task_execution_role.arn}"
      ]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid = "Allow attachment of persistent resources"

    effect = "Allow"

    principals = {
      type = "AWS"
      identifiers = [
        "${aws_iam_role.ecs_task_execution_role.arn}"
      ]
    }

    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]

    resources = [
      "*"
    ]

    condition {
      test = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values = ["true"]
    }
  }
}
