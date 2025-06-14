// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.main
// SPDX-License-Identifier: MIT-0

resource "aws_codebuild_project" "this" {
  name          = var.codebuild_name
  build_timeout = var.build_timeout
  service_role  = var.codebuild_role

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = var.image
    type         = "LINUX_CONTAINER"

    dynamic "environment_variable" {
      for_each = var.environment_variables
      content {
        name  = environment_variable.key
        value = environment_variable.value
      }
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = var.log_group
      stream_name = var.codebuild_name
    }
  }

  source {
    type                = "CODEPIPELINE"
    buildspec           = file("${path.module}/buildspecs/${var.build_spec}")
    git_clone_depth     = 0
    insecure_ssl        = false
    report_build_status = false
  }

  dynamic "vpc_config" {
    for_each = var.vpc == null ? [] : [1]
    content {
      vpc_id             = vpc.value.vpc_id
      subnets            = vpc.value.subnets
      security_group_ids = vpc.security_group_ids
    }
  }
}

