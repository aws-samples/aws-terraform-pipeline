// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

module "validate" {
  source                = "./modules/codebuild"
  codebuild_name        = "${var.pipeline_name}-validate"
  codebuild_role        = aws_iam_role.codebuild_validate.arn
  environment_variables = var.environment_variables
  build_timeout         = 5
  build_spec            = "validate.yml"
  log_group             = local.log_group
}

module "fmt" {
  source                = "./modules/codebuild"
  codebuild_name        = "${var.pipeline_name}-fmt"
  codebuild_role        = aws_iam_role.codebuild_validate.arn
  environment_variables = var.environment_variables
  build_timeout         = 5
  build_spec            = "fmt.yml"
  log_group             = local.log_group
}

module "lint" {
  source                = "./modules/codebuild"
  codebuild_name        = "${var.pipeline_name}-lint"
  codebuild_role        = aws_iam_role.codebuild_validate.arn
  environment_variables = var.environment_variables
  build_timeout         = 5
  build_spec            = "lint.yml"
  log_group             = local.log_group
}

module "sast" {
  source         = "./modules/codebuild"
  codebuild_name = "${var.pipeline_name}-sast"
  codebuild_role = aws_iam_role.codebuild_validate.arn
  environment_variables = merge(tomap({
    SAST_REPORT_ARN = aws_codebuild_report_group.sast.arn
    CHECKOV_SKIPS   = var.checkov_skip
    }),
    var.environment_variables,
  )
  build_timeout = 5
  build_spec    = "sast.yml"
  log_group     = local.log_group
}

module "plan" {
  source                = "./modules/codebuild"
  codebuild_name        = "${var.pipeline_name}-plan"
  codebuild_role        = aws_iam_role.codebuild_execution.arn
  environment_variables = var.environment_variables
  build_timeout         = 10
  build_spec            = "plan.yml"
  log_group             = local.log_group
}

module "apply" {
  source                = "./modules/codebuild"
  codebuild_name        = "${var.pipeline_name}-apply"
  codebuild_role        = aws_iam_role.codebuild_execution.arn
  environment_variables = var.environment_variables
  build_timeout         = 10
  build_spec            = "apply.yml"
  log_group             = local.log_group
}

module "test" {
  source                = "./modules/codebuild"
  codebuild_name        = "${var.pipeline_name}-test"
  codebuild_role        = aws_iam_role.codebuild_execution.arn
  environment_variables = var.environment_variables
  build_timeout         = 10
  build_spec            = "test.yml"
  log_group             = local.log_group
}

resource "aws_iam_role" "codebuild_validate" {
  name               = "${var.pipeline_name}-codebuild-validate-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_validate_assume_role.json
}

resource "aws_iam_role" "codebuild_execution" {
  name               = "${var.pipeline_name}-codebuild-execution-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_execution_assume_role.json
}

data "aws_iam_policy_document" "codebuild_validate_assume_role" {
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
        "arn:aws:codebuild:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:project/${var.pipeline_name}-validate",
        "arn:aws:codebuild:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:project/${var.pipeline_name}-fmt",
        "arn:aws:codebuild:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:project/${var.pipeline_name}-lint",
        "arn:aws:codebuild:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:project/${var.pipeline_name}-sast"
      ]
    }
  }
}

data "aws_iam_policy_document" "codebuild_execution_assume_role" {
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
        "arn:aws:codebuild:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:project/${var.pipeline_name}-apply",
        "arn:aws:codebuild:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:project/${var.pipeline_name}-test"
      ]
    }
  }
}

resource "aws_iam_role_policy_attachment" "codebuild_validate" {
  role       = aws_iam_role.codebuild_validate.name
  policy_arn = aws_iam_policy.codebuild_execution.arn
}

resource "aws_iam_role_policy_attachment" "codebuild_execution" {
  role       = aws_iam_role.codebuild_execution.name
  policy_arn = aws_iam_policy.codebuild_execution.arn
}

resource "aws_iam_policy" "codebuild_validate" {
  name   = "${var.pipeline_name}-codebuild-validate-policy"
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
      "${module.artifact_s3.bucket.arn}/sast/*",
    ]
  }
}

resource "aws_iam_policy" "codebuild_execution" {
  name = "${var.pipeline_name}-codebuild-execution-policy"
  policy = data.aws_iam_policy_document.codebuild_execution_policy.json
}

data "aws_iam_policy_document" "codebuild_execution_policy" {
  statement {
    effect = "Allow"
    actions = [
      "*"
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
      bucket              = module.artifact_s3.bucket.id
      encryption_disabled = false
      encryption_key      = data.aws_kms_key.s3.arn
      packaging           = "NONE"
      path                = "/sast"
    }
  }
}