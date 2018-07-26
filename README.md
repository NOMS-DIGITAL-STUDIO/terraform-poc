# Infrastructure Orchestration

**Never check passwords or other similar secrets into source control**

Each directory represents a distinct project, and is effectively a separate terraform environment.

## Setup

### Required Software

 * [terraform 0.11.1+](http://terraform.io/)
 * [Node.JS 8+](https://nodejs.org/)
 * [Yarn](https://yarnpkg.com/en/)
 * [Python 3.6] (https://www.python.org/)
 * [pip] (https://pip.pypa.io/en/stable/)
 * [Azure CLI 2.0] (https://docs.microsoft.com/en-us/cli/azure/overview?view=azure-cli-latest)

### Python MSSQL client

For Macs:
```
brew install freetds@0.91
brew link --force freetds@0.91
pip install pymssql
```

### Environment initialization

Install dependencies from npm using yarn from (package.json):

```
yarn install
```

Some environments might interact with the github api, you'll need to go get an API key from the admin UI to make that work.

```
GITHUB_TOKEN=xxxx
```

Fetch the token from Settings->Developer Settings->Personal Access Tokens->Generate new token

Run the repository setup script to include the python init script globally via a symlink to /usr/local/bin/digint.

```
python3 tools/initial-setup.py
```

### Terraform initialization

-In order to authenticate with the Azure RM APIs you'll need to be able to login via the azure cli.  e.g.

```
$ az login

-In order to authenticate with AWS CLI, there are 2 methond that you will to be able achieve this, see instruction below:

Scripted
--------
Checkout https://github.com/ministryofjustice/digital-studio-infra
source ./aws-users/get-access-token.sh [AWS profile name]
This script will ask for your MFA code and setup the required AWS environment variables containing the session token.  See manual steps, or look inside the script.

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


```

See [the terraform documentation](https://www.terraform.io/docs/providers/azurerm/authenticating_via_azure_cli.html) for full details.

Then switch the directory for the project you wish to terraform, and run the python init script:

e.g.
```~ $ cd digital-studio-infra/webops/dev/
~/digital-studio-infra/webops/dev (master) $ diginit
```

This should report:

```
Terraform has been successfully initialized!
```

You are now ready to run terraform commands:

e.g.
```
terraform plan
```

You can override the Terraform and Azure verions by copying the config file tools/config/azure-versions.json to your local Terraform directory.

### Terraform initialization (using service principal authentication)

Some folders still use SP auth in which case you'll need an azure AD app which appropriate permissions. This is a bit annoying to set up. See [the terraform documentation](https://www.terraform.io/docs/providers/azurerm/index.html#creating-credentials) for full details.

Once you have this data, set them as environment variables before running any terraform commands.

```
ARM_CLIENT_ID=xxxxx
ARM_CLIENT_SECRET=xxxxx
```
## Creating the Terraform code for a new app

If you are creating the Terraform code for a new app you can use the following instructions:

### Scripted

1\. From the root of the digital-infra-studio repo run the bootstrap.py script. The script accepts two arguments:
 - -a, --app-name
 - -e, --environments A comma separated list of environments to create

 e.g. ```python3 bootstrap.py -a test-app -e dev,stage```

2\. Change to the newly created environment directory and run ```diginit``` to test.

e.g. ```$ cd /test-app/dev
        $ diginit```

3\. Add the additional Terraform resources that the app requires.

4\. Add users to the Azure AD group created for the vault access policy. (The Group name will be "Digital Studio Dev Team - <app-name>")         


### Manual

1\. Create a new directory for your app in the root of the digital-infra-studio repo.

2\. Create sub directories for each required environment using the following names:

  **devtest environment**
  - dev
  - stage
  - mock

  **production environment**
  - preprod
  - prod

3\. Copy the main.tf file from tools/config to your environment sub folder.

  e.g. ```$ cp tools/config/main.tf test-app/dev/main.tf ```

4\. Change to the environment directory and replace the APPNAME placeholder with the name of the app directory

  e.g.

  ```
     variable "app-name" {
     type = "string"
     default = "APPNAME"
     }
  ```

  change to

  ```
     variable "app-name" {
     type = "string"
     default = "test-app-dev"
     }
```

5\. Create an Azure AD group with the name "Digital Studio Dev Team - <app-name>". Add users to the group.

6\. Add an access policy to the azurerm_key_vault resource with the object id for the group created in step 5.

7\. Run ```diginit``` to initialise and test the Terraform code. The command does not have any parameters.

  e.g. ```$ diginit```

8\. Add the additional Terraform resources that the app requires.


## diginit command

This command is installed by running inital-setup.py from the repository root.

It performs the following tasks:

1. Checks if the user has already used terraform for this app and if so backs up the Terraform state.

2. Creates a config.tf.json file containing details of:
- Terraform version
- Azure resource group
- Azure storage account
- Azure key for storing Terraform state
- Azure Tenant id
- Azure subscription id (devtest or prod)
- Azure RM version

3. Copies the azure-provider-config.json to the local directory. This file can then be edited to override defaults.

4. Checks the user is logged in to Azure

5. Sets the Azure subscription based on the value in config.tf.json.

6. Creates the required Azure resource group, storage account.

7. Performs terraform init to initialise the Terraform backend.
