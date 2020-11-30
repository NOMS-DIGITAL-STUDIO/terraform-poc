#!/usr/bin/env python3
import json
import subprocess
import sys
import os.path
import shutil
import logging
import fnmatch


from python_modules import state_backup
from python_modules import azure_account
from python_modules import storage_creation

logging.basicConfig(stream=sys.stdout, level=logging.INFO)

def create_config_file():

    git_root = azure_account.get_git_root()

    logging.info("Creating config.tf.json")

    # Derive the names for key, resource group and storage account from the path
    cwd = os.path.basename(os.getcwd())

    appDir = os.path.split(os.path.dirname(os.getcwd()))[1]

    keyName = ''.join([appDir, '-', cwd, '.terraform.tfstate'])

    storage_account = appDir.replace('-','') + cwd + "storage"
    # make sure it's not over the 24 character limit for storage account names
    storage_account = storage_account[:24]

    resource_group = appDir + "-" + cwd

    # Check if this is a prod or dev environment
    prodEnvs = ['prod', 'preprod']

    environment = 'devtest'

    if cwd in prodEnvs:
        environment = 'prod'

    if not os.path.isfile("./azure-version-override.json"):
        logging.info("Creating fresh azure-version-override.json")
        src = ''.join([git_root, "/tools/config/azure-version-override.json"])
        dst = "."
        shutil.copy2(src, dst)

    env_versions = json.load(open("./azure-version-override.json"))

    azure_account_ids = json.load(open(git_root + "/tools/config/azure-account-config.json"))

    configTfJson = {
        'terraform': {
            'required_version': env_versions["terraform_version"],
            'backend': {
                'azurerm': {
                    'resource_group_name': resource_group,
                    'storage_account_name': storage_account,
                    'container_name': 'terraform',
                    'key': keyName
                }
            }
        },
        'provider': {
            'azurerm': {
                'tenant_id': azure_account_ids[environment]["tenant_id"],
                'subscription_id': azure_account_ids[environment]["subscription_id"],
                'version': env_versions["azurerm_version"],
                'features': {}
            }
        }
    }



    jsonFile = json.dumps(configTfJson, indent=2)

    with open("config.tf.json", "w") as f:
        f.write(jsonFile)

    logging.info("config.tf.json created")


def check_first_time_terraform_init():

    if os.path.exists("./.terraform"):

        try:
            state_exists = subprocess.run(
                ["terraform", "show",
                 ],
                stdout=subprocess.PIPE,
                check=True
            ).stdout.decode()
        except:
            logging.warning("There is a problem with .terraform")
            logging.warning("You may need to delete .terraform before running this script. Exiting.")
            sys.exit()

        if "No state" in state_exists:
            logging.info("There is no Terraform state to backup")
            return False
        else:
            logging.info("Terraform state exists")
            return True
    else:
        logging.info("There is no .terraform directory")
        return False


if len(fnmatch.filter(os.listdir('.'), '*.tf')) < 1:
    logging.warning("There are no terraform config files. Exiting.")
    sys.exit(1)

if check_first_time_terraform_init():
    logging.info("Backing up the state")
    state_backup.backup()

create_config_file()

config = json.load(open("./config.tf.json"))

subscription_id = config["provider"]["azurerm"]["subscription_id"]
tenant_id = config["provider"]["azurerm"]["tenant_id"]
resource_group = config["terraform"]["backend"]["azurerm"]["resource_group_name"]
storage_account = config["terraform"]["backend"]["azurerm"]["storage_account_name"]

logging.info("Authorizing in Azure")
azure_account.azure_access_token(subscription_id)

azure_account.azure_set_subscription(subscription_id)

storage_creation.create_storage_account(resource_group, storage_account)

if ("ARM_CLIENT_ID" in os.environ) and ("ARM_CLIENT_SECRET" in os.environ):
    logging.info("Running terraform init with a Service Principal")
    subprocess.run(
        ["terraform", "init",
            "-backend-config=arm_client_id=%s" % os.environ.get('ARM_CLIENT_ID'),
            "-backend-config=arm_client_secret=%s" % os.environ.get('ARM_CLIENT_SECRET'),
            "-backend-config=arm_tenant_id=%s" % tenant_id,
            "-backend-config=arm_subscription_id=%s" % subscription_id],
        check=True
    )
else:
    logging.info("Running terraform init with Az cli auth and storage access key")
    key = subprocess.run(
        ["az", "storage", "account", "keys", "list",
            "--resource-group", resource_group,
            "--account-name", storage_account,
            "--query", "[0].value",
            "--output", "tsv",
         ],
        stdout=subprocess.PIPE,
        check=True
    ).stdout.decode()

    subprocess.run(
        ["terraform", "init", "-backend-config", "access_key=%s" % key],
        check=True
    )
