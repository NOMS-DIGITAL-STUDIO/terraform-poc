# App Infrastructure Orchestration

**Never check passwords or other similar secrets into source control**

Each directory represents a distinct project, and is effectively a separate terraform environment.

This repository contains mainly azure app service architectures with one AWS monitoring project which may not be used.

The webops project contains shared resources used across apps e.g. dns zones or other resources not related to an app but in the subscriptions.

## Setup

Please see the relevant README for the project for any extra dependencies if needed.

### Required Software

 * [terraform 0.14+](http://terraform.io/)
 * [Azure CLI 2.0] (https://docs.microsoft.com/en-us/cli/azure/overview?view=azure-cli-latest)
 * [AWS CLI]

### Azure provider initialization

You may need to be logged into the az cli with `az login`.

If there are any issues where you can't find the state file or resource you may not be in the correct azure account, use `az account set -subscription <ACC-NO>`

```
$ az login
```

### AWS provider initialization

Due to a design decision terraform doesn't support dynamic prompting from providers as they expect terraform to be non-interactive.
see https://github.com/hashicorp/terraform-provider-aws/issues/2420

This affects the following projects which use the AWS provider:

```
monitoring
```

-In order to authenticate with AWS CLI, there are 2 methods that you will to be able achieve this, see instruction below:


Scripted
--------
Checkout https://github.com/ministryofjustice/digital-studio-infra

For AWS provider and AWS resources you will need to auth against the mgmt account. See https://github.com/ministryofjustice/dso-infra-aws-mgmt for more details.  Run this to authenticate against mgmt:

```
source ./aws-users/get-access-token.sh mgmt
```

This script will ask for your MFA code and setup the required AWS environment variables containing the session token.  See manual steps, or look inside the script.

If this returns an error 'Invalid

The provider config in `aws-devtest.tf` and `aws-prod.tf` now contains the role which will be assumed in either dev or prod AWS accounts.


Manual Steps
------------
retreive the ARN for your MFA device from the IAM service above: "arn:aws:iam::409876543212:mfa/BobSmith"
run following with aws cli, using token code from your device:
"aws sts get-session-token --serial-number 'arn:aws:iam::409876543212:mfa/BobSmith' --token-code 123456 --duration-seconds 129600"
aws will return temporary credentials (expire after "duration-seconds" above):
AccessKeyId
SecretAccessKey
SessionToken
Re-export the temp credentials respecively as:
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_SESSION_TOKEN
Test your access with something like aws s3 ls or aws describe-instances
These credentials will be used and indeed required going forward - note that they expire after a max of 36 hours (129600 seconds from above).


### Github provider initialization

Some environments might interact with the github api, you'll need to go get an API key from the admin UI to make that work.

```
GITHUB_TOKEN=xxxx
```

Fetch the token from Settings->Developer Settings->Personal Access Tokens->Generate new token


### Terraform initialization (using service principal authentication)

Some folders still use SP auth in which case you'll need an azure AD app which appropriate permissions. This is a bit annoying to set up. See [the terraform documentation](https://www.terraform.io/docs/providers/azurerm/index.html#creating-credentials) for full details.

Once you have this data, set them as environment variables before running any terraform commands.

```
ARM_CLIENT_ID=xxxxx
ARM_CLIENT_SECRET=xxxxx
```


### Python MSSQL client
If you are planning to setup or interact with the SQL databases the dependencies are below.

For Macs:
```
brew install freetds@0.91
brew link --force freetds@0.91
pip install pymssql
```
