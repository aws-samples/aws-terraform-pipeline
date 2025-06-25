resource "aws_codestarnotifications_notification_rule" "this" {
  count          = var.notifications["enabled"] == true ? 1 : 0
  name           = var.pipeline_name
  detail_type    = var.notificaitons["detail_type"]
  event_type_ids = var.notifications["events"]
  resource       = aws_codepipeline.this.arn

  target {
    address = var.notifications["sns_topic"] == null ? aws_sns_topic.this.arn : var.notifications["sns_topic"]
  }
}

resource "aws_sns_topic" "this" {
  count = var.notifications["enabled"] == true ? 1 : 0
  name  = var.pipeline_name
}

resource "aws_sns_topic_policy" "this" {
  count  = var.notifications["enabled"] == true && var.notifications["sns_topic"] == null ? 1 : 0
  arn    = aws_sns_topic.this.arn
  policy = data.aws_iam_policy_document.sns.json
}

data "aws_iam_policy_document" "sns" {
  count = var.notifications["enabled"] == true && var.notifications["sns_topic"] == null ? 1 : 0
  statement {
    actions = ["sns:Publish"]

    principals {
      type        = "Service"
      identifiers = ["codestar-notifications.amazonaws.com"]
    }

    resources = [aws_sns_topic.this.arn]
  }
}

resource "aws_sns_topic_subscription" "this" {
  count     = var.notifications["enabled"] == true && var.notifications["sns_topic"] == null ? 1 : 0
  topic_arn = aws_sns_topic.this.arn
  protocol  = var.notifications["protocol"]
  endpoint  = var.notifications["endpoint"]
}
