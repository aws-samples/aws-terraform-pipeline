// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

variable "environment_variables" {
  type = map(string)
}

variable "build_timeout" {
  type    = number
  default = 10
}

variable "build_spec" {
  type = string
}

variable "codebuild_name" {
  type = string
}

variable "codebuild_role" {
  type = string
}

variable "log_group" {
  type = string
}

variable "image" {
  type = string
}

variable "vpc" {
  type = map(object({
    vpc_id             = string
    subnets            = list(string)
    security_group_ids = list(string)
  }))
  default = null
}
