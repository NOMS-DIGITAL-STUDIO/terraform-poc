#!/usr/bin/env python3
import json
import subprocess
import sys
import os.path
import shutil

gitRoot = subprocess.run(
    ["git", "rev-parse", "--show-toplevel"],
    stdout=subprocess.PIPE,
    check=True
).stdout.decode().rstrip()

# Derive the backend key name from the path
cwd = os.path.basename(os.getcwd())

appDir = os.path.split(os.path.dirname(os.getcwd()))[1]
keyName = ''.join([appDir, '-', cwd, '.terraform.tfstate'])


# Check if this is a prod or dev environment
prodEnvs = ['prod', 'preprod']

environment = 'devtest'

if cwd in prodEnvs:
    environment = 'prod'

if not os.path.isfile("./.json"):
    src = ''.join([gitRoot, "/tools/config/azure-versions.json"])
    dst = "."
    shutil.copy2(src, dst)

versions = json.load(open("./azure-versions.json"))
    
providerConfig = json.load(
    open(gitRoot + "/tools/config/azure-provider-config.json"))

if 'storage_account_name' in versions:
  providerConfig[environment]["storage_account_name"] = versions['storage_account_name']

if 'resource_group_name' in versions:
  providerConfig[environment]["resource_group_name"] = versions['resource_group_name']

print(providerConfig[environment])

exit()

configTfJson = {
    'terraform': {
        'required_version': versions["terraform_version"],
        'backend': {
            'azurerm': {
                'resource_group_name': providerConfig[environment]["resource_group_name"],
                'storage_account_name': providerConfig[environment]["storage_account_name"],
                'container_name': 'terraform',
                'key': keyName
            }
        }
    },
    'provider': {
        'azurerm': {
            'tenant_id': providerConfig[environment]["tenant_id"],
            'subscription_id': providerConfig[environment]["subscription_id"],
            'version': versions["azurerm_version"]
        }
    }
}

jsonFile = json.dumps(configTfJson, indent=2)

with open("config.tf.json", "w") as f:
    f.write(jsonFile)

config = json.load(open("./config.tf.json"))

subscription_params = ["--subscription",
                       providerConfig[environment]["subscription_id"]]

# Ensure that CLI is logged in and can access the relevant subscription
subprocess.run(
    ["az", "account", "get-access-token", *subscription_params],
    check=True, stdout=subprocess.DEVNULL
)

# Activate relevant subscription in CLI
subprocess.run(
    ["az", "account", "set", *subscription_params],
    check=True
)

# Extract storage account key for remote state
key = subprocess.run(
    ["az", "storage", "account", "keys", "list",
        "--resource-group", providerConfig[environment]["resource_group_name"],
        "--account-name", providerConfig[environment]["storage_account_name"],
        "--query", "[0].value",
        "--output", "tsv",
     ],
    stdout=subprocess.PIPE,
    check=True
).stdout.decode()

# Init terraform with acquired storage account key
subprocess.run(
    ["terraform", "init", "-backend-config", "access_key=%s" % key],
    check=True
)
