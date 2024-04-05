# Terraform pipeline module
 
Deploy Terraform ... with terraform. 

(🐓 🥚 ?)

## Prerequisites
- An existing AWS CodeCommit repository ("your repo") with a [remote state](https://developer.hashicorp.com/terraform/language/state/remote) that the codebuild role can access. 

## Deployment

This module must be deployed to a separate repository.


```
your repo
   README.md
   backend.tf 
   main.tf
   variables.tf    

pipeline repo 
   main.tf <--module deployed here
```

Segregation enables the pipeline to run commands against the code in "your repo" without affecting the pipeline infrastructure. A single pipeline, or bootstrap, repo could be used in an account to provision multiple pipelines for your codecommit repositories. 


## Module Inputs

```hcl
module "pipeline" {
  source          = "github.com/aws-samples/aws-terraform-pipeline"
  pipeline_name   = "pipeline-name"
  codecommit_repo = "codecommit-repo-name"
}
```
`pipeline_name` is used to name the pipeline and prefix other resources created, like IAM roles. 

`codecommit_repo` is the name of your existing repo that the pipeline will use as a source. 

### Optional Inputs

```hcl
module "pipeline" {
  ...
  branch = "main"

  environment_variables = {
    TF_VERSION     = "5.0"
    TFLINT_VERSION = "0.33.0"
  }

  checkov_skip = [
    "CKV_AWS_144", #Ensure that S3 bucket has cross-region replication enabled
  ]

}
```
`branch` is the CodeCommit branch. It defaults to "main" and may need to be altered if you are using pre-commit hooks that default to "master". 

`environment_variables` can be used to define terraform and [tf_lint](https://github.com/terraform-linters/tflint) versions. 

`checkov_skip` defines [Checkov](https://www.checkov.io/) skips for the pipeline. This is useful for organization-wide policies, removing the need to add individual resource skips. 



## Architecture

![image info](./img/architecture.png)

1. User commits to existing repository. 
2. The commit invokes an Amazon EventBridge rule, which runs the AWS CodePipeline pipeline.
3. The pipeline validates the code, then runs a `terraform plan`, before waiting for manual approval. Once this is issued, the resources are built with a `terraform apply`. 
4. Pipeline artifacts are sent to an Amazon S3 bucket. Pipeline activity is logged in Amazon CloudWatch logs. 

#### Pipeline Validation

| Check | Description |
|---|---|
| validate | runs `terraform validate` to make sure that the code is syntactically valid. |
| lint | runs [TFLint](https://github.com/terraform-linters/tflint) which will find errors, depreciated syntax, and check naming conventions. |
| fmt | runs `terraform fmt --recursive --check` to ensure code is consistently formatted. |
| SAST | runs [Checkov](https://www.checkov.io/) for security best practices. |


## Setup a cross-account pipeline
The pipeline can assume a cross-account role and deploy to another AWS account.

1. Ensure there is a [cross-account IAM role](https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_cross-account-with-roles.html) that can be assumed by the codebuild role, 
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

## Troubleshooting

| Issue | Fix |
|---|---|
| Failed lint or validate | Read the report or logs to discover why the code has failed, then make a new commit. |
| Failed fmt | This means your code is not formatted. Run `terraform fmt --recursive` on your code, then make a new commit. |
| Failed SAST | Read the Checkov logs (Details > Reports) and either make the correction in code or add a skip to the module inputs. |
| Failed plan or apply stage | Read the report or logs to discover error in terraform code, then make a new commit. |
| Pipeline fails on apply with `the action failed because no branch named main was found ...` | Either nothing has been committed to the repo or the branch is incorrect (Eg using `Master` not `Main`). Either commit to the Main branch or change the module input to fix this. |

## Best Practices

The CodeBuild execution role is highly privileged as this pattern is designed for a wide audience to deploy any resource to an AWS account. You may want to reduce the scope of the role and define specific services or actions, depending on your requirements.

Permissions to your CodeCommit repository, CodeBuild projects, and CodePipeline pipeline should be tightly controlled. Here are some ideas:
- [Specify approval permission for specific pipelines and approval actions](https://docs.aws.amazon.com/codepipeline/latest/userguide/approvals-iam-permissions.html#approvals-iam-permissions-limited).
- [Using identity-based policies for AWS CodeBuild](https://docs.aws.amazon.com/codebuild/latest/userguide/auth-and-access-control-iam-identity-based-access-control.html). 
- [Limit pushes and merges to branches in AWS CodeCommit](https://docs.aws.amazon.com/codecommit/latest/userguide/how-to-conditional-branch.html)

Checkov skips can be used where Checkov policies conflict with your organization's practices or design decisions. The `checkov_skip` module input allows you to set skips for all resources in your repository. For example, if your organization operates in a single region you may want to add `CKV_AWS_144` (Ensure that S3 bucket has cross-region replication enabled). For individual resource skips, you can still use [inline code comments](https://www.checkov.io/2.Basics/Suppressing%20and%20Skipping%20Policies.html).

## Related Resources

- [AWS CodePipeline User Guide](https://docs.aws.amazon.com/codepipeline/latest/userguide/welcome.html)
- [Resource: aws_codecommit_repository](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codecommit_repository)
- [Resource: aws_codebuild_project](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project)
- [Resource: aws_codepipeline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codepipeline)


## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.
