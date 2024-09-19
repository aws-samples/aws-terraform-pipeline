// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = try(var.kms_key, null)
      sse_algorithm     = can(var.kms_key) ? "aws:kms" : "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.this.json
}

data "aws_iam_policy_document" "this" {
  statement {
    effect = "Deny"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:*",
    ]

    resources = [
      "${aws_s3_bucket.this.arn}/*",
      "${aws_s3_bucket.this.arn}"
    ]

    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = var.enable_retention ? 1 : 0
  bucket = aws_s3_bucket.this.id

  rule {
    id = "retention-policy-${var.retention_in_days}-days"

    expiration {
      days = var.retention_in_days
    }

    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "this" {
  count  = var.access_logging_bucket == "" ? 0 : 1
  bucket = aws_s3_bucket.this.id

  target_bucket = var.access_logging_bucket
  target_prefix = "${var.bucket_name}/"
}
