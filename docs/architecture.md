# Architecture

![image info](../img/architecture.png)

1. User commits to existing repository. 
2. The commit invokes an Amazon EventBridge rule, which runs the AWS CodePipeline pipeline.
3. The pipeline validates the code, then runs a `terraform plan`, before waiting for manual approval. Once this is issued, the resources are built with a `terraform apply` (either within the same account or another AWS account, depending on how your code is configured).  
4. Pipeline artifacts are sent to an Amazon S3 bucket. Pipeline activity is logged in Amazon CloudWatch logs. 

## Pipeline Validation

| Check | Description |
|---|---|
| validate | runs `terraform validate` to make sure that the code is syntactically valid. |
| lint | runs [tfLint](https://github.com/terraform-linters/tflint) which will find errors, depreciated syntax, and check naming conventions. |
| fmt | runs `terraform fmt --recursive --check` to ensure code is consistently formatted. |
| sast | runs [checkov](https://www.checkov.io/) for security best practices. |
| tags (optional)| runs [tag-nag](https://github.com/jakebark/tag-nag) to validate tags.|
