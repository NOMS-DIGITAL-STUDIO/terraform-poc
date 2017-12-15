# Infrastructure Orchestration

**Never check passwords or other similar secrets into source control**

Each directory represents a distinct project, and is effectively a seperate terraform environment.

## Setup

### Required Software

 * [terraform 0.11.1+](http://terraform.io/)
 * [Node.JS 8+](https://nodejs.org/)
 * [Yarn](https://yarnpkg.com/en/)


Install dependencies from npm using yarn from (package.json):

```
yarn install
```

Some environments might interact with the github api, you'll need to go get an API key from the admin UI to make that work. 

```
GITHUB_TOKEN=xxxx
```

Fetch the token from Settings->Developer Settings->Personal Access Tokens->Generate new token



### Terraform initialization 

In order to authenticate with the Azure RM APIs you'll need to be able to login via the azure cli.  e.g.

```
$ az login
```

See [the terraform documentation](https://www.terraform.io/docs/providers/azurerm/authenticating_via_azure_cli.html) for full details.

Then switch the directory for the project you wish to terraform, and run the python init script:

e.g.
```~ $ cd digital-studio-infra/webops/dev/
~/digital-studio-infra/webops/dev (master) $ python3 init.py
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

### Terraform initialization (using service principal authentication)

Some folders still use SP auth in which case you'll need an azure AD app which appropriate permissions. This is a bit annoying to set up. See [the terraform documentation](https://www.terraform.io/docs/providers/azurerm/index.html#creating-credentials) for full details.

Once you have this data, set them as environment variables before running any terraform commands.

```
ARM_CLIENT_ID=xxxxx
ARM_CLIENT_SECRET=xxxxx
```
