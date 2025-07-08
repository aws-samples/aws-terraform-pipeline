# Optional inputs

`branch` is the branch to source. It defaults to `main`.

`mode` is [pipeline execution mode](https://docs.aws.amazon.com/codepipeline/latest/userguide/concepts-how-it-works.html#concepts-how-it-works-executions). It defaults to `SUPERSEDED`.

`detect_changes` is used with third-party services, like GitHub. It enables AWS CodeConnections to invoke the pipeline when there is a commit to the repo. It defaults to `false`.

`kms_key` is the arn of an *existing* AWS KMS key. This input will encrypt the Amazon S3 bucket with a AWS KMS key of your choice. Otherwise the bucket will be encrypted using SSE-S3. Your AWS KMS key policy will need to allow codebuild and codepipeline to `kms:GenerateDataKey*` and `kms:Decrypt`.

`access_logging_bucket` S3 server access logs bucket ARN, enables server access logging on the S3 artifact bucket.

`artifact_retention` controls the S3 artifact bucket retention period. It defaults to 90 (days). 

`log_retention` controls the CloudWatch log group retention period. It defaults to 90 (days). 

`codebuild_policy` replaces the [AWSAdministratorAccess](https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AdministratorAccess.html) IAM policy. This can be used if you want to scope the permissions of the pipeline. 

`build_timeout` is the CodeBuild project build timeout. It defaults to 10 (minutes). 

`terraform_version` controls the terraform version. It defaults to 1.5.7.

`checkov_version` controls the [Checkov](https://www.checkov.io/) version. It defaults to latest.

`tflint_version` controls the [tflint](https://github.com/terraform-linters/tflint) version. It defaults to 0.48.0.

`vpc` configures the CodeBuild projects to [run in a VPC](https://docs.aws.amazon.com/codebuild/latest/userguide/vpc-support.html).  

`notifications` creates a [CodeStar notification](https://docs.aws.amazon.com/dtconsole/latest/userguide/welcome.html) for the pipeline. `sns_topic` is the SNS topic arn. `events` are the [notification events](https://docs.aws.amazon.com/dtconsole/latest/userguide/concepts.html#events-ref-pipeline). `detail_type` is either BASIC or FULL. The SNS topic must allow [codestar-notifications.amazonaws.com to publush to the topic](https://docs.aws.amazon.com/dtconsole/latest/userguide/notification-target-create.html). 

`tags` enables tag validation with [tag-nag](https://github.com/jakebark/tag-nag). Input a list of tag keys and/or tag keys and values to enforce. Input must be passed as a string, see [commands](https://github.com/jakebark/tag-nag?tab=readme-ov-file#commands). 

`tagnag_version` controls the [tag-nag](https://github.com/jakebark/tag-nag) version. It defaults to 0.5.8.

`checkov_skip` defines [Checkov](https://www.checkov.io/) skips for the pipeline. This is useful for organization-wide policies, removing the need to add individual resource skips. 
