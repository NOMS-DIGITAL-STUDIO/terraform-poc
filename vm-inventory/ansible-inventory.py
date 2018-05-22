import json
import subprocess
import os
import sys
import argparse
import logging
import yaml
from collections import defaultdict

logging.basicConfig(stream=sys.stdout, level=logging.INFO)

parser = argparse.ArgumentParser(
    description='Script to create an Ansible inventory')

parser.add_argument(
    "-s", "--subscription-id", help="Azure Subscription ID")

parser.add_argument(
    "-f", "--file-path", help="Path to store output file to")

args = parser.parse_args()

subprocess.run(
    ["az", "account", "set", "--subscription", args.subscription_id],
    check=True
)

subscription_params = ["--subscription", args.subscription_id]

subprocess.run(
    ["az", "account", "get-access-token", *subscription_params],
    check=True, stdout=subprocess.DEVNULL
)

logging.info("Getting VM info")

vms = json.loads(subprocess.run(
    ["az vm list -g NOMS-MGMT"],
    stdout=subprocess.PIPE,
    check=True,
    shell=True
).stdout.decode())


inventory = {}

for vm in vms:

  if "env" in vm["tags"]:
    env = vm["tags"]["env"]
    app = vm["tags"]["app"]
    tier = vm["tags"]["tier"]
    vmname = vm["name"]

    if env not in inventory:
        logging.info("adding env")
        inventory[env] = {}

    if app not in inventory[env]:
        logging.info("adding app")
        inventory[env][app] = {}

    if tier not in inventory[env][app]:
        logging.info("adding tier")
        inventory[env][app][tier] = {"hosts":{}}

    inventory[env][app][tier]["hosts"][vmname] = ""

if args.file_path:

    logging.info("Saving data to yaml")

    with open(args.file_path, 'w') as outfile:
        yaml.dump(inventory, outfile, default_flow_style=False)
