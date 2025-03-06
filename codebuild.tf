// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

module "validation" {
  for_each              = local.validation_stages
  source                = "./modules/codebuild"
  codebuild_name        = "${var.pipeline_name}-${each.key}"
  codebuild_role        = aws_iam_role.codebuild_validate.arn
  environment_variables = each.value
  build_timeout         = var.build_timeout
  build_spec            = "${each.key}.yml"
  log_group             = local.log_group
  image                 = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
}

module "plan" {
  source                = "./modules/codebuild"
  codebuild_name        = "${var.pipeline_name}-plan"
  codebuild_role        = aws_iam_role.codebuild_execution.arn
  environment_variables = var.environment_variables
  build_timeout         = var.build_timeout
  build_spec            = "plan.yml"
  log_group             = local.log_group
  image                 = "hashicorp/terraform:${var.terraform_version}"
}

module "apply" {
  source                = "./modules/codebuild"
  codebuild_name        = "${var.pipeline_name}-apply"
  codebuild_role        = aws_iam_role.codebuild_execution.arn
  environment_variables = var.environment_variables
  build_timeout         = var.build_timeout
  build_spec            = "apply.yml"
  log_group             = local.log_group
  image                 = "hashicorp/terraform:${var.terraform_version}"
}

resource "aws_iam_role" "codebuild_validate" {
  name               = "${var.pipeline_name}-codebuild-validate"
  assume_role_policy = data.aws_iam_policy_document.codebuild_validate_assume.json
}

resource "aws_iam_role" "codebuild_execution" {
  name               = "${var.pipeline_name}-codebuild-execution"
  assume_role_policy = data.aws_iam_policy_document.codebuild_execution_assume.json
}

data "aws_iam_policy_document" "codebuild_validate_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "aws:SourceArn"
      values = [
        "arn:aws:codebuild:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:project/${var.pipeline_name}-*"
      ]
    }
  }
}

data "aws_iam_policy_document" "codebuild_execution_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values = [
        "arn:aws:codebuild:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:project/${var.pipeline_name}-plan",
        "arn:aws:codebuild:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:project/${var.pipeline_name}-apply"
      ]
    }
  }
}

resource "aws_iam_role_policy_attachment" "codebuild_validate" {
  role       = aws_iam_role.codebuild_validate.name
  policy_arn = aws_iam_policy.codebuild_validate.arn
}

resource "aws_iam_role_policy_attachment" "codebuild_execution" {
  role       = aws_iam_role.codebuild_execution.name
  policy_arn = var.codebuild_policy == null ? "arn:aws:iam::aws:policy/AdministratorAccess" : var.codebuild_policy
}

resource "aws_iam_policy" "codebuild_validate" {
  name   = "${var.pipeline_name}-codebuild-validate"
  policy = data.aws_iam_policy_document.codebuild.json
}

data "aws_iam_policy_document" "codebuild" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${local.log_group}",
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${local.log_group}:*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "codebuild:CreateReport",
      "codebuild:UpdateReport",
      "codebuild:BatchPutTestCases"
    ]

    resources = [
      aws_codebuild_report_group.sast.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.this.arn}/*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt"
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_codebuild_report_group" "sast" {
  name           = "sast-report-${var.pipeline_name}"
  type           = "TEST"
  delete_reports = true

  export_config {
    type = "S3"

    s3_destination {
      bucket              = aws_s3_bucket.this.id
      encryption_disabled = false
      encryption_key      = try(var.kms_key, data.aws_kms_key.s3.arn)
      packaging           = "NONE"
      path                = "/sast"
    }
  }
}
