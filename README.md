# Setup - Provision an EKS Cluster using terraform

### For this setup you will need the following:
* an AWS account with IAM permissions listed on Eks module documentation
* AWS CLI configured
* kubectl

After installing the AWS CLI. Configure it to use your credentials.

```shell
$ aws configure
AWS Access Key ID [None]: <YOUR_AWS_ACCESS_KEY_ID>
AWS Secret Access Key [None]: <YOUR_AWS_SECRET_ACCESS_KEY>
Default region name [None]: <YOUR_AWS_REGION>
Default output format [None]: json
```

This enables Terraform access to the configuration file and performs operations on your behalf with these security credentials.

After you've done this, initalize your Terraform workspace, which will download 
the provider and initialize it with the values provided in the `terraform.tfvars` file.

```shell
$ terraform init
```

Then, provision your EKS cluster by running `terraform apply`. This will 
take approximately 10 minutes.

```shell
$ terraform apply
```


## Configure kubectl

```shell
# Use terraform output to find region and clustername. 
$ terraform output

# Configure kubectl
$ aws eks --region us-east-2 update-kubeconfig --name training-eks-sR8eLIil 

```

## Clean up terraform workspace
NB! Remember to destroy the resources you created with terraform on aws and confirm with "Yes" in your terminal.


```shell
$ terraform destroy
```