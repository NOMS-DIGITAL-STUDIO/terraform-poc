import json
import subprocess
import os
import sys
import argparse
import base64
import re
import logging

from time import gmtime, strftime, strptime
from datetime import datetime, timedelta
from operator import itemgetter

logging.basicConfig(stream=sys.stdout, level=logging.INFO)

parser = argparse.ArgumentParser(
    description='Script to list VMs and their properties')

parser.add_argument(
    "-s", "--subscription-id", help="Azure Subscription ID")
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

logging.info("Getting VM size info")

vm_types = json.loads(subprocess.run(
    ["az vm list-sizes --location ukwest"],
    stdout=subprocess.PIPE,
    check=True,
    shell=True
).stdout.decode())

vm_core_lookup = {}

for vm_type in vm_types:
    vm_core_lookup[vm_type["name"]] = vm_type["numberOfCores"]

logging.info("Getting VM info")

vms = json.loads(subprocess.run(
    ["az vm list"],
    stdout=subprocess.PIPE,
    check=True,
    shell=True
).stdout.decode())

rows = 'Server type,Name,Location,Resource Group,Provisioning State,VM Size,CPU Cores\n'

vm_types = {"A": "Oracle HTTP", "W": "Weblogic", "D": "Database"}

lines = []

logging.info("Filtering VM info")

for vm in vms:

    if re.match(r'(T1|T2|T3|PP|PD|DR)(O|C|P)(A|W|D)L.*', vm['name']):

        vm_code = vm['name'][:5]

        vm_type = vm['name'][3]

        vm_size = vm['hardwareProfile']['vmSize']

        vm_cores = str(vm_core_lookup[vm_size])

        fields = [vm_types[vm_type], vm['name'], vm['location'],
                  vm['resourceGroup'], vm['provisioningState'], vm_size, vm_cores]

        lines.append(fields)

sorted_lines = sorted(lines, key=itemgetter(0))

logging.info("Sorting VM info")

for line in sorted_lines:

    rows += "".join(",".join(line)) + "\n"

print(rows)

number_of_vms = len(sorted_lines)

logging.info("Saving data to csv")

text_file = open("vm-inventory.csv", "w")
text_file.write(rows)
text_file.close()

logging.info("Complete. %s VMs found." % number_of_vms)
