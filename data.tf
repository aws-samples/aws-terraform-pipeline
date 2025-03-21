// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_kms_key" "s3" {
  key_id = "alias/aws/s3"
}

