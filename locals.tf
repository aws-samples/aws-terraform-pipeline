// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

locals {
  log_group = "/aws/${var.pipeline_name}"

  validation_stages = {
    validate = "hashicorp/terraform:${var.terraform_version}"
    fmt      = "hashicorp/terraform:${var.terraform_version}"
    lint     = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    sast     = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
  }

  conditional_validation_stages = {
    tags = "jakebark/tag-nag:${var.tagnag_version}"
  }

  env_var = {
    TFLINT_VERSION  = var.tflint_version
    SAST_REPORT_ARN = aws_codebuild_report_group.sast.arn
    CHECKOV_SKIPS   = join(",", "${var.checkov_skip}")
    TAGNAG_TAGS     = var.tags
    TF_VERSION      = "1.5.7"
  }
}
