# App Infrastructure Orchestration

**Never check passwords or other similar secrets into source control**

Each directory represents a distinct project, and is effectively a separate terraform environment.

This repository contains mainly azure app service architectures with one AWS monitoring project which may not be used.

The webops project contains shared resources used across apps e.g. dns zones or other resources not related to an app but in the subscriptions.

## Setup

Please see the relevant README for the project for any extra dependencies if needed.

### Required Software

 * [terraform 0.14+](http://terraform.io/)
 * [Azure CLI 2] (https://docs.microsoft.com/en-us/cli/azure/overview?view=azure-cli-latest)

### Azure provider initialization

You may need to be logged into the az cli with `az login`.

If there are any issues where you can't find the state file or resource you may not be in the correct azure account, use `az account set -subscription <ACC-NO>`

```
$ az login
```

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
