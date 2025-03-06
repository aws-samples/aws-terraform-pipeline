// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

locals {
  log_group = "/aws/${var.pipeline_name}"

  validation_stages = {
    validate = "hashicorp/terraform:${var.terraform_version}"
    fmt      = "hashicorp/terraform:${var.terraform_version}"
    lint     = "ghcr.io/terraform-linters/tflint:${var.tflint_version}"
    sast     = "bridgecrew/checkov:${var.checkov_version}"
  }

  env_var = {
    SAST_REPORT_ARN = aws_codebuild_report_group.sast.arn
    CHECKOV_SKIPS   = join(",", "${var.checkov_skip}")
  }
}
