// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

variable "pipeline_name" {
  type = string
}

variable "repo" {
  type = string
}

variable "branch" {
  type    = string
  default = "main"
}

variable "environment_variables" {
  description = "environment variables for codebuild"
  type        = map(string)
  default = {
    TF_VERSION     = "1.5.7"
    TFLINT_VERSION = "0.33.0"
  }
}

variable "checkov_skip" {
  description = "list of checkov checks to skip"
  type        = list(string)
  default     = [""]
}

variable "kms_key" {
  description = "kms key to be used"
  type        = string
  default     = null
}

variable "access_logging_bucket" {
  description = "s3 server access logging bucket"
  type        = string
  default     = null
}

variable "connection" {
  type    = string
  default = null
}

variable "detect_changes" {
  type    = string
  default = false
}

variable "codebuild_policy" {
  type    = string
  default = null
}

variable "terraform_version" {
  type    = string
  default = "latest"
}
