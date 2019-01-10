#!/usr/bin/env python3
import json
import subprocess
import sys
import os.path
import shutil
import argparse
import base64
import logging

sys.path.insert(0, './')

from tools.python_modules import azure_account

logging.basicConfig(stream=sys.stdout, level=logging.INFO)

parser = argparse.ArgumentParser(
    description='Script to update an SSL certificate on an Azure Application Gateway')

parser.add_argument("-b", "--gw-subscription-id", help="App gateway subscription id")
parser.add_argument("-g", "--resource-group", help="resource_group")
parser.add_argument("-a", "--gateway-name", help="Azure Application Gateway name")
parser.add_argument("-k", "--key-vault", help="Azure Key Vault where the certificate is stored")
parser.add_argument("-n", "--gw-cert-name", help="Azure app gw listener cert name")

args = parser.parse_args()

def update_ssl_cert(app_gateway_name, resource_group, gw_cert_name, key_vault):

    logging.info("Retrieving certificate.")

    secrets = ["appgw-ssl-certificate","appgw-ssl-certificate-password"]

    certificate = azure_account.get_secrets(secrets,key_vault)

    certificate_pfx = base64.b64decode(certificate["appgw-ssl-certificate"])

    with open("appgw.pfx", "wb") as f:
        f.write(certificate_pfx)

    logging.info("Updating Application Gateway with new certificate.")

    cmd = ["az", "network", "application-gateway", "ssl-cert", "update",
             "--gateway-name", app_gateway_name,
             "--resource-group", resource_group,
             "--name", gw_cert_name,
             "--cert-file", "appgw.pfx",
             "--cert-password", certificate["appgw-ssl-certificate-password"]
    ]
    logging.info("Running: %s" % (" ".join(cmd)))
    try:
        set_secret = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            check=True
        )
        logging.info(set_secret)

    except subprocess.CalledProcessError:
        sys.exit("There was an error updating the application gateway SSL certificate.")

    logging.info("Performing cleanup.")
    os.remove("appgw.pfx")

azure_account.azure_set_subscription(args.gw_subscription_id)

update_ssl_cert(args.gateway_name,args.resource_group,args.gw_cert_name,args.key_vault)
