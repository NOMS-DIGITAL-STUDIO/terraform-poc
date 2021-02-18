# Managing AWS users

## Required Software

 * [Terraform 0.12.28](http://terraform.io/)
 * [Python 3.6] (https://www.python.org/)
 * [Azure CLI 2.0](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
 * [AWS CLI 1.14+] (https://aws.amazon.com/cli/)
 * [jq command line JSON processor](https://stedolan.github.io/jq/)
 * pwgen [on Mac 'brew install pwgen']

## Managing users

The list of users is stored as a comma separated list in an Azure key vault. Terraform/AWS always requires a complete list of users for processing. In order to manage the users we need to:

1. Retrieve existing users for each type (admins/developers etc) from the Azure key vault.
2. Add or delete users as required.
3. Save the list back to the key vault.
4. Run terraform in the appropriate environment to update AWS.

To do this we use the ```manage-users.py``` script.

e.g. to add two users to the developers group:

```python3 manage-users.py -e prod -u JackSmith,BobJones -a add -g developers```

Parameters:

-e, --environment The environment the user is created for. Determines the Azure key vault used. (Required)
-u, --users A comma separated list of users to add or delete.
-a, --user-action Action to take i.e. add, delete or list. (Required)
-g, --group The group the user will belong to e.g. developers  

TBC: Add groups of developers in the format <dev team>_developers   



## Generating an access token to use AWS CLI with MFA enabled.

Due to a design decision terraform doesn't support dynamic prompting from providers as they expect terraform to be non-interactive.
see `https://github.com/hashicorp/terraform-provider-aws/issues/2420`

A script has been created to generate the AWS security token required for the CLI when MFA is enabled.

The script parameter is the name of the profile in your AWS credentials file (usually found at ~/.aws/credentials). If no parameter is given it will use the default profile created by the AWS configure command.

The script should be sourced when run to correctly export the necessary environment variables. The security token, along with an access key id and secret are stored as environment variables and will be valid for 12 hours.

1. Ensure your AWS CLI has been set up with ```aws configure```. Credentials are required to get the security token, they will not allow any further access.

2. Source the ```get-access-token.sh``` script to obtain an access token.

e.g. ```. ./get-access-token.sh dev```

Example profile:

```
[dev]
 aws_access_key_id = <key id value>
 aws_secret_access_key = <secret value>
```
