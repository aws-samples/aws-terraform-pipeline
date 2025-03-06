// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

locals {
  log_group = "/aws/${var.pipeline_name}"

  validation_stages = {
    validate = {
      image   = "hashicorp/terraform:${var.terraform_version}"
      env_var = null
    },
    fmt = {
      image   = "hashicorp/terraform:${var.terraform_version}"
      env_var = null
    },
    lint = {
      image = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
      env_var = {
        TFLINT_VERSION = var.tflint_version
      }
    },
    sast = {
      image = "bridgecrew/checkov:${var.checkov_version}",
      env_var = merge(tomap({
        SAST_REPORT_ARN = aws_codebuild_report_group.sast.arn
        CHECKOV_SKIPS   = join(",", "${var.checkov_skip}")
        })
      )
    }
  }

}
