// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

variable "pipeline_name" {
  description = "value"
  type        = string
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

variable "artifact_retention" {
  description = "s3 artifact bucket retention, in days"
  type        = number
  default     = 90
}

variable "build_timeout" {
  type    = number
  default = 10
}
