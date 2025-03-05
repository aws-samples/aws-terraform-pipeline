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
