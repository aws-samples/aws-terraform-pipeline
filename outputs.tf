output "pipeline" {
  value = aws_codepipeline.this
}

output "pipeline_role" {
  value = aws_iam_role.codepipeline_role
}

output "codebuild_validate_role" {
  value = aws_iam_role.codebuild_validate
}

output "codebuild_execution_role" {
  value = aws_iam_role.codebuild_execution
}

output "cloudwatch_log_group" {
  value = aws_cloudwatch_log_group.this
}

