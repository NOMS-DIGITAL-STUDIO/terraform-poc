#!/usr/bin/env python3

# Terraform external data source for reading data from an azure key vault
#
# Expects the following structure as JSON via stdin:
# {
#    "vault": "<name of vault>",
#    "<secret output name 1>": "<secret vault name 1>",
#    "<secret output name 2>": "<secret vault name 2>",
#    "<secret output name 3>": "<secret vault name 3>",
#    "<secret output name 4>": "<secret vault name 4>",
#    ...
#  }
#
#  And produces the following structure as JSON via stdout:
#  {
#   "<secret output name 1>": "<secret value 1>",
#   "<secret output name 2>": "<secret value 2>",
#   "<secret output name 3>": "<secret value 3>",
#    "<secret output name 4>": "<secret value 4>",
#    ...
#  }


import json
import subprocess
import sys
import os.path
import shutil

from python_modules import azure_account

from pprint import pprint

args = json.load(sys.stdin)

vaultName = args['vault']

inputItems = args

del inputItems['vault']


def getSecrets(inputItems, vaultName):

    secrets = {}

    for key, value in inputItems.items():
        secret = subprocess.run(
            ["az", "keyvault", "secret", "show", "--vault-name",
             vaultName, "--name", value
             ],
            stdout=subprocess.PIPE,
            check=True
        ).stdout.decode()

        data = json.loads(secret)

        secrets[key] = data["value"]

    return json.dumps(secrets)


azure_account.azure_access_token()

print(getSecrets(inputItems, vaultName))
