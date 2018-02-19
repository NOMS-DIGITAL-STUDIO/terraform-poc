#!/usr/bin/env python3

# Create a Letsencrypt certificate(https: // letsencrypt.org) and store it in an azure key vault.

import json
import subprocess
import os
import sys
import argparse
import base64
import re
import logging
import secrets
import string

from time import gmtime, strftime, strptime
from datetime import datetime, timedelta

from python_modules import azure_account

logging.basicConfig(stream=sys.stdout, level=logging.INFO)

parser = argparse.ArgumentParser(
    description='Script to create LetsEncrypt SSL certificates and store in Azure Key Vault')

parser.add_argument("-z", "--zone", help="DNS Zone")
parser.add_argument("-n", "--hostname", help="Hostname")
parser.add_argument("-g", "--resource-group", help="Azure Resource Group for the DNS zone")
parser.add_argument("-s", "--subscription-id", help="Azure Subscription ID")
parser.add_argument("-c", "--certbot",
                    help="Certbot configuration directory set during 'certbot register'. User must have write permissions.")
parser.add_argument(
    "-v", "--vault", help="Azure Key Vault to store certificate in")
parser.add_argument(
    "-t", "--test-environment", help="test mode - uses Letsencrypt staging environment",action='store_true')
parser.add_argument(
    "-e", "--ignore-expiry", help="Ignore the expiry date check to perform an early renewal",action='store_true')
parser.add_argument(
    "-a", "--application-gateway", help="Create a certificate for an Application Gateway.",action='store_true')
parser.add_argument(
    "-x", "--extra-host", help="Create an additional host on the certificate.")
parser.add_argument(
        "-y", "--extra-zone", help="Add the zone or the additional host on the certificate.")

args = parser.parse_args()

hostname = args.hostname
extra_host = args.extra_host

if args.test_environment:
    hostname = "test-" + hostname
    extra_host = "test-" + extra_host

#    args.ignore_expiry = True

fqdn = hostname + '.' + args.zone


def get_zone_details(resource_group, zone):

    find_dns_records = subprocess.run(
        ["az", "network", "dns", "record-set", "soa", "show",
         "-g", resource_group, "-z", zone
         ],
        stdout=subprocess.PIPE,
        check=True
    ).stdout.decode()

    if find_dns_records:
        dns_records = json.loads(find_dns_records)

        key = "fqdn"

        for key, zone in dns_records.items():
            return True
        else:
            return False
    else:
        return False


def create_certificate(dns_names, fqdn, resource_group, certbot_location):

    path_to_hook_scripts = azure_account.get_git_root() + '/tools/letsencrypt'

    manual_auth_hook = "python3 {path_to_scripts}/authenticator.py '{dns_names}' {resource_group}".format(
        dns_names= json.dumps(dns_names), resource_group=resource_group, path_to_scripts=path_to_hook_scripts)

    manual_cleanup_hook = "python3 {path_to_scripts}/cleanup.py '{dns_names}' {resource_group}".format(
        dns_names= json.dumps(dns_names), resource_group=resource_group, path_to_scripts=path_to_hook_scripts)

    logging.info("Creating certificate")

    common_name = '.'.join(dns_names["common_name"])

    domains_to_renew = []

    for key,value in dns_names.items():
        fqdn = value[0] + "." + value[1]
        domains_to_renew.extend(["-d", fqdn])

    cmd = ["certbot", "certonly", "--manual",
           "--email", "noms-studio-webops@digital.justice.gov.uk",
           "--preferred-challenges", "dns",
           "--manual-auth-hook", manual_auth_hook,
           "--manual-cleanup-hook", manual_cleanup_hook,
           "--manual-public-ip-logging-ok",
           "--config-dir", certbot_location,
           "--work-dir", certbot_location,
           "--logs-dir", certbot_location,
           "--force-renewal",
           "--agree-tos"
           ]

    cmd.extend(domains_to_renew)

    if args.test_environment:
        cmd.append('--staging')
        logging.info("Using staging environment")

    try:
        certificate = subprocess.check_call(
            cmd
        )
    except subprocess.CalledProcessError:
        sys.exit("There was an error creating the certificate")

    path_to_cert = certbot_location + "/live/" + common_name + "/fullchain.pem"

    logging.info(path_to_cert)

    if os.path.exists(path_to_cert):
        logging.info("Certificate created")
        return True
    else:
        logging.error("There was an error creating the certificate")
        return False


def create_pkcs12(fqdn, certbot_location,vault):

    path_to_cert = certbot_location + "/live/" + fqdn + "/fullchain.pem"
    path_to_key = certbot_location + "/live/" + fqdn + "/privkey.pem"
    export_path = certbot_location + "/live/" + fqdn + "/pkcs.p12"

    set_passphrase = "pass:"

    if args.application_gateway:
        alphabet = string.ascii_letters + string.digits
        password = ''.join(secrets.choice(alphabet) for i in range(20))
        set_passphrase = "pass:" + password

        store_password(password,vault)

    subprocess.run(
        ["openssl", "pkcs12", "-export",
         "-inkey", path_to_key,
         "-in", path_to_cert,
         "-out", export_path,
         "-passout", set_passphrase
         ],
        stdout=subprocess.PIPE,
        check=True
    ).stdout.decode()

    if os.path.exists(export_path):
        return export_path
    else:
        sys.exit("There was a problem creating the certificate")


def store_certificate(vault, fqdn, certbot_location):

    name = fqdn.replace(".", "DOT")

    if args.application_gateway:
        name = "appgw-ssl-certificate"

    cert_file = create_pkcs12(fqdn, certbot_location,vault)

    cert_dates = get_local_certificate_expiry(fqdn, certbot_location)

    open_pkcs12 = open(cert_file, 'rb').read()
    cert_encoded = base64.encodestring(open_pkcs12)

    try:
        set_secret = subprocess.run(
            ["az", "keyvault", "secret", "set",
             "--file", cert_file,
             "--encoding", "base64",
             "--name", name,
             "--vault-name", vault
             ],
            stdout=subprocess.PIPE,
            check=True
        )

    except subprocess.CalledProcessError:
        sys.exit("There was an error saving to the key vault")

    if set_secret.returncode == 0:
        set_secret_attributes = subprocess.run(
            ["az", "keyvault", "secret", "set-attributes",
             "--name", name,
             "--content-type", "application/x-pkcs12",
             "--expires", cert_dates["end"],
             "--not-before", cert_dates["start"],
             "--vault-name", vault
             ],
            stdout=subprocess.PIPE,
            check=True
        )

        if set_secret_attributes.returncode == 0:
            return True
        else:
            sys.exit("Could not set secret attributes in key vault.")
    else:
        sys.exit("Could not set secret in key vault.")

def store_password(password,vault):

    name = "appgw-ssl-certificate-password"

    try:
        set_secret = subprocess.run(
            ["az", "keyvault", "secret", "set",
             "--value", password,
             "--encoding", "base64",
             "--name", name,
             "--vault-name", vault
             ],
            stdout=subprocess.PIPE,
            check=True
        )

    except subprocess.CalledProcessError:
        sys.exit("There was an error saving the passowrd to the vault")

def get_local_certificate_expiry(fqdn, certbot_location):

    cert_dates = {}

    cert_expiry_data = subprocess.run(
        ["openssl", "x509",
         "-startdate",
         "-enddate",
         "-noout",
         "-in", certbot_location + "/live/" + fqdn + "/fullchain.pem",
         "-inform", "pem"
         ],
        stdout=subprocess.PIPE,
        check=True
    ).stdout.decode()

    cert_expiry = cert_expiry_data.splitlines(True)

    return get_certificate_dates(cert_expiry)


def get_remote_certificate_expiry(fqdn):

    #    Use subprocess to run the shell command 'echo "Q" | openssl s_client -servername NAME -connect HOST:PORT 2>/dev/null | openssl x509 -noout -dates'

    echo = subprocess.run(
        ["echo", "Q"],
        stdout=subprocess.PIPE,
        check=True
    )

    try:
        openssl_sclient = subprocess.run(
            ["openssl", "s_client",
             "-servername", fqdn,
             "-connect", fqdn + ":443"
             ],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            input=echo.stdout,
            check=True
        )
    except:
        logging.info("Could not connect to host")
        return False

    try:
        openssl_dates = subprocess.run(
            ["openssl", "x509",
             "-startdate",
             "-enddate",
             "-noout"
             ],
            stdout=subprocess.PIPE,
            input=openssl_sclient.stdout,
            check=True
        ).stdout.decode()
    except:
       logging.info("Could not read certificate")
       return False

    cert_expiry = openssl_dates.splitlines(True)

    return get_certificate_dates(cert_expiry)


def get_certificate_dates(openssl_response):

    cert_dates = {}

    for certdate in openssl_response:

        if certdate.find("notBefore") != -1:
            start_end = "start"

        elif certdate.find("notAfter") != -1:
            start_end = "end"
        else:
            sys.exit("The certificate appears to have missing dates")

        certdate = certdate.rstrip()
        certdate = re.sub(r"not(After|Before)=", '', certdate)

        expiry_date_from_string = strptime(
            certdate, "%b %d %H:%M:%S %Y %Z")

        formatted_expiry_date = strftime(
            "%Y-%m-%dT%H:%M:%SZ", expiry_date_from_string)

        cert_dates[start_end] = formatted_expiry_date

    return cert_dates


def check_dns_name_exits(host, zone, resource_group):
    # az network dns record-set cname show -n notm-deva -g webops -z hmpps.dsd.io

    cmd = ["az", "network", "dns", "record-set",
     "cname", "show",
     "-n", host,
     "-z", zone,
     "-g", resource_group
     ]

    logging.info("Trying CNAME record")
    cname = subprocess.run(
        cmd,
        stdout=subprocess.PIPE,
        check=True
    ).stdout.decode()

    if cname:
        return True
    else:
        cmd[4] = "a"
        logging.info("Trying A record")
        a_record = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            check=True
        ).stdout.decode()

    if a_record:
        return True
    else:
        return False

def certificate_renewal_due(fqdn):

    remote_expiry = get_remote_certificate_expiry(fqdn)

    if remote_expiry:
        cert_end_date = datetime.strptime(
            remote_expiry['end'], "%Y-%m-%dT%H:%M:%SZ")

        # Adjust the renewal date to when the first letsencrypt email reminder is sent.
        adjusted_renewal_date = cert_end_date - timedelta(days=21)

        present_date = datetime.now()

        if adjusted_renewal_date > present_date:
            logging.info("Certificate does not need renewing until %s" %
                         (cert_end_date.strftime('%d %b %Y')))
            sys.exit()
    else:
        logging.info("Couldn't check certificate.")



azure_account.azure_set_subscription(args.subscription_id)

if not get_zone_details(args.resource_group, args.zone):
    sys.exit("Failed to find existing zone " + args.zone)

if check_dns_name_exits(args.hostname, args.zone, args.resource_group):
    if not args.ignore_expiry:
        logging.info("Check expiry date")
        certificate_renewal_due(fqdn)
else:
    logging.info("A record or CNAME doesn't exist. No expiry date to check.")

dns_names = {
   "common_name": [hostname,args.zone],
   "additional_name" : [extra_host,args.extra_zone]
   }

if create_certificate(dns_names, fqdn, args.resource_group, args.certbot):

    if store_certificate(args.vault, fqdn, args.certbot):
        logging.info("Certificate successfully created.")
