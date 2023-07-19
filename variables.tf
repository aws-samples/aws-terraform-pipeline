// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

variable "pipeline_name" {
  type = string
}

variable "codecommit_repo" {
  type = string
}

variable "branch" {
  type = string
}

variable "environment_variables" {
  description = "environment variables for codebuild"
  type        = map(string)
}

variable "checkov_skip" {
  description = "list of checkov checks to skip"
  type        = list(string)
  default     = [ "CKV_AWS_0" ]
}    

