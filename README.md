# terraform-aws-pipeline
 
Deploy terraform with terraform. 

🐓 🥚 ?

(If you want to deploy to multiple AWS accounts use [terraform-multi-account-pipeline](https://github.com/aws-samples/terraform-multi-account-pipeline))

## Prerequisites
- An existing AWS CodeCommit repository *OR* an [AWS CodeConnection connection](https://docs.aws.amazon.com/dtconsole/latest/userguide/welcome-connections.html) to the third-party source and repo of your choice (GitHub, Gitlab, etc)
- [Remote state](https://developer.hashicorp.com/terraform/language/state/remote) that the pipeline can access (using the CodeBuild IAM role)  

## Deployment

This module must be deployed to a separate repository to the code you want to push through it.

```
your repo
   modules
   backend.tf 
   main.tf
   provider.tf
   variables.tf    

pipeline repo 
   main.tf <--module deployed here
```

Segregation enables the pipeline to run commands against the code in "your repo" without affecting the pipeline infrastructure. This could be an infrastructure or bootstrap repo for the AWS account.

## Module Inputs

AWS Codecommit:
```hcl
module "pipeline" {
  source        = "aws-samples/pipeline/aws"
  version       = "2.2.3"
  pipeline_name = "pipeline-name"
  repo          = "codecommit-repo-name"
}
```
Third-party service:
```hcl
module "pipeline" {
  source        = "aws-samples/pipeline/aws"
  version       = "2.2.x"
  pipeline_name = "pipeline-name"
  repo          = "organization/repo"
  connection    = aws_codestarconnections_connection.this.arn
}
```
`pipeline_name` is used to name the pipeline and prefix other resources created, like IAM roles. 

`repo` is the name of your existing repo that the pipeline will use as a source. If you are using a third-party service, the format is "my-organization/repo"  

`connection` is the connection arn of the [connection](https://docs.aws.amazon.com/dtconsole/latest/userguide/welcome-connections.html) to the third-party repo. 

### Optional Inputs

```hcl
module "pipeline" {
  ...
  branch                = "main"
  mode                  = "SUPERSEDED"
  detect_changes        = false
  kms_key               = aws_kms_key.this.arn
  access_logging_bucket = aws_s3_bucket.this.id
  artifact_retention    = 90
  log_retention         = 90

  codebuild_policy  = aws_iam_policy.this.arn
  build_timeout     = 10
  terraform_version = "1.5.7"
  checkov_version   = "3.2.0"
  tflint_version    = "0.48.0"

  vpc = {
    vpc_id             = "vpc-011a22334455bb66c",
    subnets            = ["subnet-011aabbcc2233d4ef"],
    security_group_ids = ["sg-001abcd2233ee4455"],
  }
  
  tags = join(",", [
    "Environment[Dev,Prod]",
    "Source"
  ])
  tagnag_version = "0.5.8"

  checkov_skip = [
    "CKV_AWS_144", #Ensure that S3 bucket has cross-region replication enabled
  ]
}
```
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

`tags` enables tag validation with [tag-nag](https://github.com/jakebark/tag-nag). Input a list of tag keys and/or tag keys and values to enforce. Input must be passed as a string, see [commands](https://github.com/jakebark/tag-nag?tab=readme-ov-file#commands). 

`tagnag_version` controls the [tag-nag](https://github.com/jakebark/tag-nag) version. It defaults to 0.5.8.

`checkov_skip` defines [Checkov](https://www.checkov.io/) skips for the pipeline. This is useful for organization-wide policies, removing the need to add individual resource skips. 


## Architecture

![image info](./img/architecture.png)

1. User commits to existing repository. 
2. The commit invokes an Amazon EventBridge rule, which runs the AWS CodePipeline pipeline.
3. The pipeline validates the code, then runs a `terraform plan`, before waiting for manual approval. Once this is issued, the resources are built with a `terraform apply` (either within the same account or another AWS account, depending on how your code is configured).  
4. Pipeline artifacts are sent to an Amazon S3 bucket. Pipeline activity is logged in Amazon CloudWatch logs. 

#### Pipeline Validation

| Check | Description |
|---|---|
| validate | runs `terraform validate` to make sure that the code is syntactically valid. |
| lint | runs [tfLint](https://github.com/terraform-linters/tflint) which will find errors, depreciated syntax, and check naming conventions. |
| fmt | runs `terraform fmt --recursive --check` to ensure code is consistently formatted. |
| sast | runs [checkov](https://www.checkov.io/) for security best practices. |
| tags (optional)| runs [tag-nag](https://github.com/jakebark/tag-nag) to validate tags.|

## Setup a cross-account pipeline
The pipeline can assume a cross-account role and deploy to another AWS account.

1. Ensure there is a [cross-account IAM role](https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_cross-account-with-roles.html) that can be assumed by the codebuild roles (validate and execute). 
2. Edit the provider in "your repo" to include the [assume role argument](https://developer.hashicorp.com/terraform/tutorials/aws/aws-assumerole).

```hcl
provider "aws" {
  region = "eu-west-2"
  assume_role {
    role_arn     = "arn:aws:iam::112233445566:role/cross-account-role"
    session_name = "pipeline"
  }
}
```
3. Commit the changes and run the pipeline.

## Troubleshooting

| Issue | Fix |
|---|---|
| Failed lint or validate | Read the report or logs to discover why the code has failed, then make a new commit. |
| Failed fmt | This means your code is not formatted. Run `terraform fmt --recursive` on your code, then make a new commit. |
| Failed SAST | Read the Checkov logs (click CodeBuild Project > Reports tab) and either make the correction in code or add a skip to the module inputs. |
| Failed plan or apply stage | Read the report or logs to discover error in terraform code, then make a new commit. |
| Pipeline fails on apply with `the action failed because no branch named main was found ...` | Either nothing has been committed to the repo or the branch is incorrect (Eg using `Master` not `Main`). Either commit to the Main branch or change the module input to fix this. |

## Best Practices

The CodeBuild execution role uses the [AWSAdministratorAccess](https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AdministratorAccess.html) IAM policy  as this pattern is designed for a wide audience to deploy any resource to an AWS account. It assumes there are strong organizational controls in place and good segregation practices at the AWS account level. If you need to better scope the policy, the `codebuild_policy` optional input can be used to replace this with an IAM policy of your choosing. 

Permissions to your CodeCommit repository, CodeBuild projects, and CodePipeline pipeline should be tightly controlled. Here are some ideas:
- [Specify approval permission for specific pipelines and approval actions](https://docs.aws.amazon.com/codepipeline/latest/userguide/approvals-iam-permissions.html#approvals-iam-permissions-limited).
- [Using identity-based policies for AWS CodeBuild](https://docs.aws.amazon.com/codebuild/latest/userguide/auth-and-access-control-iam-identity-based-access-control.html). 
- [Limit pushes and merges to branches in AWS CodeCommit](https://docs.aws.amazon.com/codecommit/latest/userguide/how-to-conditional-branch.html)

Checkov skips can be used where Checkov policies conflict with your organization's practices or design decisions. The `checkov_skip` module input allows you to set skips for all resources in your repository. For example, if your organization operates in a single region you may want to add `CKV_AWS_144` (Ensure that S3 bucket has cross-region replication enabled). For individual resource skips, you can still use [inline code comments](https://www.checkov.io/2.Basics/Suppressing%20and%20Skipping%20Policies.html).

## Related Resources

- [terraform-multi-account-pipeline](https://github.com/aws-samples/terraform-multi-account-pipeline)
- [Terraform Registry: aws-samples/pipeline/aws](https://registry.terraform.io/modules/aws-samples/pipeline/aws/latest)

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.
