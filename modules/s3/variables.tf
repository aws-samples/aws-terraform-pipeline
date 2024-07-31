// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

variable "bucket_name" {
  description = "Name of s3 bucket"
  type        = string
}

variable "retention_in_days" {
  type    = string
  default = "30"
}

variable "enable_retention" {
  description = "if true, a retention policy is enabled"
  type        = bool
}

variable "kms_key" {
  description = "kms key to be used"
  type        = string
}

variable "access_logging_bucket" {
  description = "s3 server access logging bucket"
  type        = string
}
