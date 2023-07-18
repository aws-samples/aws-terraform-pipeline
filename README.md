<p align="center">
<h1> aws-terraform-pipeline</h1>
</p>



<p align="center">
An easy way to deploy Terraform ... with Terraform. 
</p>

## Prerequisites
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- Existing AWS CodeCommit repository

## Limitations
- This pattern requires a [remote state](https://developer.hashicorp.com/terraform/language/state/remote)

## Architecture
The module is sourced remotely using the [GitHub source type](https://developer.hashicorp.com/terraform/language/modules/sources#github). But it could be cloned and sourced locally or from your own private registry, if required. 

![image info](./img/architecture.png)

1. User commits to existing repository. 
2. The commit invokes an Amazon EventBridge rule, which runs the AWS CodePipeline pipeline.
3. The pipeline validates the code, then runs a `terraform plan`, before waiting for manual approval. Once this is issued, the resources are built with a `terraform apply`. 
4. Pipeline artifacts are sent to an Amazon S3 bucket. Pipeline activity is logged in Amazon CloudWatch logs. 

#### Pipeline Validation

| Check | Description |
|---|---|
| validate | runs `terraform validate` to make sure that the code is syntactically valid. |
| lint | runs [TFLint](https://github.com/terraform-linters/tflint) which will find errors, depreciated syntax, and check naming conventions |
| fmt | runs `terraform fmt --recursive --check` to ensure consistency. |
| SAST | runs [Checkov](https://www.checkov.io/) for security best practices. |

## Deployment

The module is deployed from a separate `deploy` directory within your existing CodeCommit repo. This segregates your existing code from the pipeline. 

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

### Module Inputs

These are the module inputs for the `main.tf` file in the `deploy` directory. It is setup for a [GitHub source type](https://developer.hashicorp.com/terraform/language/modules/sources#github) but it could be cloned and deployed locally. 

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
1. Ensure your repository has a remote state configured that [this codebuild policy](./modules/pipeline/codebuild.tf?plain=1#198) can access. An S3 backend within the same AWS account is ideal for this, but ensure you use a different key to your `deploy` directory. 
2. Commit changes to your repository. This will run the pipeline. 

### (Optional) Edit the pipeline 
If you need to edit an existing pipeline, do so from the `deploy` directory with a `terraform apply`.

### (Optional) Setup a cross-account pipeline
The pipeline can assume a cross-account role and deploy to another AWS account. Ensure there is a cross-account role that can be assumed by [this codebuild policy](./modules/pipeline/codebuild.tf?plain=1#198), then edit the terraform provider in your repository to include the `assume role` argument.

## Troubleshooting

| Issue | Fix |
|---|---|
| Failed lint, fmt, or SAST checks | Read the report or logs to discover why the code has failed, then make a new commit. |
| Failed plan or apply stage | Read the report or logs to discover error in terraform code, then make a new commit. |
| Failed SAST | Read the checkov logs (Details > Reports) and either make the correction in code or add a skip to the module inputs. |
| `Error: error creating CodeBuild Report Group: InvalidInputException: Invalid encryption key: region does not match current region` during `terraform apply` | Ensure you have defined the correct `region` in `main.tf`.  
| `Terraform initialized in an empty directory!` | Make sure you are in the `deploy` directory when running `terraform init`. |
| Pipeline fails on apply with `the action failed because no branch named main was found ...` | Either nothing has been committed to the repo or the branch is incorrect (Eg using `Master` not `Main`). Either commit to the Main branch or change the module input to fix this. |

## Best Practices

The CodeBuild execution role is highly privileged as this pattern is designed for a wide audience to deploy any resource to an AWS account. You may want to reduce the scope of the role and define specific services or actions, depending on your requirements. If you are operating at scale with multiple pipelines, you should consider a [Service Control Policy (SCP)](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html) to protect the role from being edited or assumed by other principals. You could also use a SCP to prohibit actions like `IAM:CreateUser` or `account:*`. 

Permissions to your CodeCommit repository, CodeBuild projects, and CodePipeline pipeline should be tightly controlled. Here are some ideas:
- [Specify approval permission for specific pipelines and approval actions](https://docs.aws.amazon.com/codepipeline/latest/userguide/approvals-iam-permissions.html#approvals-iam-permissions-limited).
- [Using identity-based policies for AWS CodeBuild](https://docs.aws.amazon.com/codebuild/latest/userguide/auth-and-access-control-iam-identity-based-access-control.html). 
- [Limit pushes and merges to branches in AWS CodeCommit](https://docs.aws.amazon.com/codecommit/latest/userguide/how-to-conditional-branch.html)

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