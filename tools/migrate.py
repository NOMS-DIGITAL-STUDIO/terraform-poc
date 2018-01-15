#!/usr/bin/env python3
import json
import subprocess
import sys
import os.path
import shutil
import time

storageAccounts = ['prod', 'preprod', 'stage', 'dev']

cwd = os.path.basename(os.getcwd())
appDir = os.path.split(os.path.dirname(os.getcwd()))[1]
resourceGroup = appDir+"-"+cwd

if cwd in storageAccounts:
  newStorageAccount = appDir + cwd + "storage"
else:
    # If we have an unknown storage account, we're going to assume it is dev
    newStorageAccount = appDir + "devstorage"

config = json.load(open("config.tf.json"))

stateKey = config['terraform']['backend']['azurerm']['key']
subscriptionId = config['provider']['azurerm']['subscription_id']
currentStorageAccount = config['terraform']['backend']['azurerm']['storage_account_name']

if newStorageAccount == currentStorageAccount:
  print("No storage account name change required")
else:
  print("Changing storage account name from " + currentStorageAccount + " to " + newStorageAccount + " based on current working directory")
  
subprocess.run(
    ["az", "account", "get-access-token"],
	stdout=subprocess.PIPE,
	check=True
).stdout.decode()

subprocess.run(
	["az", "account", "set",
	"--subscription", subscriptionId
	],
	stdout=subprocess.PIPE,
	check=True
).stdout.decode()

accounts = json.loads(subprocess.run(
    ["az", "storage", "account", "list"],
    stdout=subprocess.PIPE,
    check=True
).stdout.decode())

names = []

for name in accounts:
  names.append(name['name'])

if newStorageAccount in names: 
  subprocess.run(
      ["az", "storage", "account", "create",
      "--name", newStorageAccount,
      "--resource-group", resourceGroup,
      ],
      stdout=subprocess.PIPE,
      check=True
  ).stdout.decode()
#else:
#  print(newStorageAccount + " - account name already exists")

config['terraform']['backend']['azurerm']['storage_account_name'] = newStorageAccount

# NB, this assumes we have resource group names following the format of {product}-{env} precreated, which _does_ seem to be true
config['terraform']['backend']['azurerm']['resource_group_name'] = resourceGroup

with open('config.tf.json', 'w') as outfile:
    json.dump(config, outfile, indent=4) 

subscription_params = ["--subscription",
                       config['provider']['azurerm']["subscription_id"]]

subprocess.run(
    ["az", "account", "set", *subscription_params],
    check=True
)

# Extract storage account key for remote state
key = subprocess.run(
    ["az", "storage", "account", "keys", "list",
        "--resource-group", resourceGroup,
        "--account-name", newStorageAccount,
        "--query", "[0].value",
        "--output", "tsv",
     ],
    stdout=subprocess.PIPE,
    check=True
).stdout.decode()

# Make sure the container exists
response = json.loads(subprocess.run(
    ["az", "storage", "container", "exists",
    "--account-name", newStorageAccount,
    "--name", "terraform",
    ],
    stdout=subprocess.PIPE,
    check=True
).stdout.decode())

if response["exists"] == False:
  subprocess.run(
    ["az", "storage","container", "create",
    "--account-name", newStorageAccount,
    "--name", "terraform"
    ],
    stdout=subprocess.PIPE,
    check=True
  )
  
#state = json.dumps(subprocess.run(
#    ["terraform", "state","pull"],
#    stdout=subprocess.PIPE,
#    check=True
#).stdout.decode())

with open('.terraform.tfstate.backup', 'w') as outfile:
    json.dump(state, outfile, indent=4) 

subprocess.run(
    ["terraform", "init",
    "-backend-config", "access_key=%s" % key,
	"-force-copy"
    ],
    stdout=subprocess.PIPE,
    check=True
)
