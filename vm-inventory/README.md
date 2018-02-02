# VM inventory

The script will produce an inventory of tagged VMs in Azure.

## Setup

### Required Software

 * [Python 3.6] (https://www.python.org/)
 * [Azure CLI 2.0] (https://docs.microsoft.com/en-us/cli/azure/overview?view=azure-cli-latest)

## Running the script

In order to authenticate with the Azure RM APIs you'll need to be able to login via the azure cli.  e.g.

```
$ az login
```

You will need the Azure subscription id for the environment the data is to be collected from.

```
$ python3 vm-inventory.py -s <subscription-id>
```

The script will output the data to the screen and save to a CSV file for further processing.
