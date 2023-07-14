# aws-terraform-pipeline

This Terraform module will create a pipeline to deploy Terraform. It can deploy resources to the same AWS account, or another AWS account using a cross-account role. 

It could be used to:
- validate code and resources before deployment
- ensure resources are configured securely 
- introduce a manual approval step to your deployment process

This module is designed to be deployed remotely, using the [GitHub source type](https://developer.hashicorp.com/terraform/language/modules/sources#github). But it could be deployed locally, or from your own private registry. 

## Prerequisites

- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- Existing AWS CodeCommit repository

## Limitations

- This pipeline will only validate and deploy Terraform 
- This existing CodeCOmmit repository must have a remote backend 

## Architecture
The module is sourced remotely using the [GitHub source type](https://developer.hashicorp.com/terraform/language/modules/sources#github). But it could be cloned and sourced locally, if required. 

![image info](./img/architecture.png)

1. User commits to existing repository. 
2. The commit invokes an Amazon EventBridge rule, which runs the AWS CodePipeline pipeline.
3. The pipeline validates the code, then runs a `terraform plan`, before waiting for manual approval. Once this is issued, the resources are built with a `terraform apply`, and then tested.  
4. Pipeline artifacts are sent to an Amazon S3 bucket. Pipeline activity is logged in Amazon CloudWatch logs. 

#### Pipeline Validation

| Check | Description |
|---|---|
| validate | runs `terraform validate` to make sure that the code is syntactically valid. |
| lint | runs [TFLint](https://github.com/terraform-linters/tflint) which will find errors, depreciated syntax, and check naming conventions |
| fmt | runs `terraform fmt --recursive --check` to ensure consistency. |
| SAST | runs [Checkov](https://www.checkov.io/) for security best practices. |

## Deployment

The pipeline module is deployed from a separate `deploy` directory within your existing CodeCommit repo. This segregates your existing code from the pipeline. 

```
your repo
│   README.md
│   main.tf
│   variables.tf    
│
└───deploy
    └───main.tf     
```

This means terraform commands can be run against your existing repository, by the pipeline, without affecting the pipeline infrastructure. 

### Inputs

These are the module inputs for the `main.tf` file in the `deploy` directory.

```
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  required_version = "~> 1.1"
}

provider "aws" {
  region = "eu-west-2"
}

module "pipeline" {
  source          = "github.com/aws-samples/aws-terraform-pipeline"
  pipeline_name   = "pipeline-name"
  codecommit_repo = "codecommit-repo-name"
  branch          = "main"

  environment_variables = {
    TF_VERSION     = "1.1.7"
    TFLINT_VERSION = "0.33.0"
  }

  checkov_skip = [
    "CKV_AWS_144", #Ensure that S3 bucket has cross-region replication enabled
  ]
}
```

### Deploy the pipeline 
1. Create a `deploy` directory in your existing CodeCommit repository.
2. Create a `main.tf` in this directory and add the above inputs, editing the variables as required.
3. (Recommended) add a remote backend to `main.tf`. 
4. (Optional) define Checkov skips for the pipeline. This is useful for organization-wide policies.
5. From the `deploy` directory, run `terraform init`, then `terraform apply` on your chosen AWS account. 

### Run the pipeline
1. Ensure your repository has a remote state configured that [this codebuild policy](./modules/pipeline/codebuild.tf?plain=1#198) can access. An S3 backend within the same AWS account is ideal for this.
2. Commit changes to your repository. This will run the pipeline. 

## Optional Operations

### Edit the pipeline 
If you need to edit an existing pipeline, do so from the `deploy` directory with a `terraform apply`.

### Setup a cross-account pipeline
The pipeline can assume a cross-account role and deploy to another AWS account. Ensure there is a cross-account role that can be assumed by [this codebuild policy](./modules/pipeline/codebuild.tf?plain=1#198), then edit the terraform provider in your repository to include the `assume role` argument.

## Troubleshooting

| Issue | Fix |
|---|---|
| Failed lint, fmt, or SAST checks | Read the report or logs to discover why the code has failed, then make a new commit |
| Failed plan or apply stage | Read the report or logs to discover error in terraform code, then make a new commit |
| Failed SAST for known issue | Read the checkov logs and then add an exception to `tf_sast.yml` in `buildspecs` |
| `Error: error creating CodeBuild Report Group: InvalidInputException: Invalid encryption key: region does not match current region` during `terraform apply` | Make sure you have defined the variables, including `region` in `config.auto.tfvars` 
| `Terraform initialized in an empty directory!` | Make sure you are in the `deploy` directory when running `terraform init` |
| Pipeline fails on apply with `the action failed because no branch named main was found ...` | This happens when nothing has been committed to the repo. Commit files to the main branch to initiate the pipeline. |

## Best Practice

The CodeBuild role is highly privileged as this pattern is intended for a wide audience. You may want to reduce the scope of the role and define specific services, or actions. If you are operating at scale with multiple pipelines, you should consider a [Service Control Policy (SCP)](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html) to protect the role from being edited or assumed by other principals. You could also use a SCP to prohibit actions like `IAM:CreateUser` or `account:*`. 

## Related Resources

- [AWS CodePipeline User Guide](https://docs.aws.amazon.com/codepipeline/latest/userguide/welcome.html)
- [Resource: aws_codecommit_repository](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codecommit_repository)
- [Resource: aws_codepipeline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codepipeline)
- [Resource: aws_codebuild_project](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project)
- [Federated multi-account access for AWS CodeCommit](https://aws.amazon.com/blogs/devops/federated-multi-account-access-for-aws-codecommit/)

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

