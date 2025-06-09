output "pipeline" {
  value = aws_codepipeline.this
}

output "pipeline_role" {
  value = aws_iam_role.codepipeline_role
}
