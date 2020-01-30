#!/usr/bin/env python3

# Create a Letsencrypt certificate(https: // letsencrypt.org) and store it in an azure key vault.

import json
import subprocess
import os
import sys
import argparse
import re
import logging

from time import strftime, strptime
from datetime import datetime, timedelta, timezone

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
    '-v', '--vault', help='Azure Key Vault to store certificate in')
parser.add_argument(
    '-t', '--test-environment', help='test mode - uses Letsencrypt staging environment', action='store_true')
parser.add_argument(
    '-e', '--ignore-expiry', help='Ignore the expiry date check to perform an early renewal', action='store_true')
parser.add_argument(
    '-a', '--application-gateway', help='Create a certificate for an Application Gateway.', action='store_true')
parser.add_argument(
    '-w', '--wildcard', help='Create a wildcard cert', action='store_true')
parser.add_argument(
    '-o', '--certificate-only', help="Create a certificate but don't store in vault.", action='store_true')
parser.add_argument(
    '-x', '--extra-host', help='Create an additional host on the certificate.')
parser.add_argument(
    '-y', '--extra-zone', help='Add the zone or the additional host on the certificate.')
parser.add_argument(
    '-internal', '--internal', help='Cert may be used internally only (record may not exist in external DNS)', action='store_true')
parser.add_argument(
    '-debug', '--debug', help='Change logging level to debug.', action='store_true')

args = parser.parse_args()

if args.debug:
    print('Setting logging level to debug')
    logging.basicConfig(stream=sys.stdout, level=logging.debug)
    logging.getLogger().setLevel(10)
else:
    print('Setting logging level to info')
    logging.basicConfig(stream=sys.stdout, level=logging.INFO)
    logging.getLogger().setLevel(20)

# added this as otherwise cert is being saved to vault with hostname value (if it supplied)
if args.wildcard:
    hostname = 'wildcard'
else:
    hostname = args.hostname

extra_host = args.extra_host

if args.test_environment:
    hostname = 'test-' + hostname
    if extra_host:
        extra_host = 'test-' + extra_host

#    args.ignore_expiry = True

fqdn = hostname + '.' + args.zone


def get_zone_details(resource_group, zone):

    find_dns_records = subprocess.run(
        ['az', 'network', 'dns', 'record-set', 'soa', 'show',
         '-g', resource_group, '-z', zone
         ],
        stdout=subprocess.PIPE,
        check=True
    ).stdout.decode()

    logging.debug('Function \'get_zone_details\'')
    logging.debug('Value of zone is: %s', zone)

    if find_dns_records:
        dns_records = json.loads(find_dns_records)

        for key, value in dns_records.items():
            if key == 'fqdn' and value.startswith(zone):
                zone_found = True
        if zone_found:
            return True
        else:
            return False
    else:
        return False


def create_certificate(dns_names, resource_group, certbot_location):

    path_to_hook_scripts = azure_account.get_git_root() + '/tools/letsencrypt'

    manual_auth_hook = 'python3 {path_to_scripts}/authenticator-v2.py {dns_names} {resource_group}'.format(
        dns_names=json.dumps(dns_names), resource_group=resource_group, path_to_scripts=path_to_hook_scripts)

    manual_cleanup_hook = 'python3 {path_to_scripts}/cleanup-v2.py {dns_names} {resource_group}'.format(
        dns_names=json.dumps(dns_names), resource_group=resource_group, path_to_scripts=path_to_hook_scripts)

    logging.info('Creating certificate')

    common_name = '.'.join(dns_names['common_name'])

    domains_to_renew = []

    domains_to_renew.extend(['-d', common_name])

    if 'additional_name' in dns_names:
        logging.debug('additional_name in dns_names found!')

        if not dns_names['additional_name'][0]:
            logging.debug('must be adding basename!')
            additional_name = dns_names['additional_name'][1]
        else:
            additional_name = '.'.join(dns_names['additional_name'])

        domains_to_renew.extend(['-d', additional_name])

    cmd = ['certbot', 'certonly', '--manual',
           '--email', 'noms-studio-webops@digital.justice.gov.uk',
           '--preferred-challenges', 'dns',
           '--manual-auth-hook', manual_auth_hook,
           '--manual-cleanup-hook', manual_cleanup_hook,
           '--manual-public-ip-logging-ok',
           '--config-dir', certbot_location,
           '--work-dir', certbot_location,
           '--logs-dir', certbot_location,
           '--server', 'https://acme-v02.api.letsencrypt.org/directory',
           '--force-renewal',
           '--agree-tos',
           '--non-interactive'
           ]

    cmd.extend(domains_to_renew)

    if args.test_environment:
        cmd.append('--staging')
        logging.info('Using staging environment')

    logging.debug('Value of certbot cmd is: %s', cmd)

    try:
        certificate = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            check=True
        ).stdout.decode()

    except subprocess.CalledProcessError:
        sys.exit('There was an error creating the certificate')

    saved_cert = re.search(r'saved at:\n(.+?)/fullchain\.pem', certificate)

    path_to_cert = saved_cert.group(1).strip()

    logging.info('The certificate is saved at ' + path_to_cert)

    if os.path.exists(path_to_cert):
        logging.info('Certificate created')
        return path_to_cert
    else:
        logging.error('There was an error creating the certificate')
        return False


def create_pkcs12(saved_cert, vault):

    path_to_cert = saved_cert + '/fullchain.pem'
    path_to_key = saved_cert + '/privkey.pem'
    export_path = saved_cert + '/pkcs.p12'

    set_passphrase = 'pass:'

    subprocess.run(
        ['openssl', 'pkcs12', '-export',
         '-inkey', path_to_key,
         '-in', path_to_cert,
         '-out', export_path,
         '-passout', set_passphrase
         ],
        stdout=subprocess.PIPE,
        check=True
    ).stdout.decode()

    if os.path.exists(export_path):
        return export_path
    else:
        sys.exit('There was a problem creating the certificate')


def store_certificate(vault, fqdn, certbot_location, saved_cert, keyvault_subscription_id):

    logging.debug('running function: store_certificate')

    name = fqdn.replace('.', 'DOT')

    cert_file = create_pkcs12(saved_cert, vault)
    logging.debug('value of certfile is %s', cert_file)

    get_local_certificate_expiry(saved_cert)

    try:
        subprocess.run(
            ['az', 'keyvault', 'certificate', 'import',
                '--file', cert_file,
                '--name', name,
                '--vault-name', vault,
                '--subscription', keyvault_subscription_id,
                '--disabled', 'false'],
            stdout=subprocess.PIPE,
            check=True
        ).stdout.decode()
    except subprocess.CalledProcessError:
        sys.exit('There was an error saving to the key vault')

    return True


def get_local_certificate_expiry(saved_cert):

    cert_expiry_data = subprocess.run(
        ['openssl', 'x509',
         '-startdate',
         '-enddate',
         '-noout',
         '-in', saved_cert + '/fullchain.pem',
         '-inform', 'pem'
         ],
        stdout=subprocess.PIPE,
        check=True
    ).stdout.decode()

    cert_expiry = cert_expiry_data.splitlines(True)

    return get_certificate_dates(cert_expiry)


def get_remote_certificate_expiry(fqdn):

    #    Use subprocess to run the shell command 'echo 'Q' | openssl s_client -servername NAME -connect HOST:PORT 2>/dev/null | openssl x509 -noout -dates'

    echo = subprocess.run(
        ['echo', 'Q'],
        stdout=subprocess.PIPE,
        check=True
    )

    try:
        logging.info('Connecting with openssl to check expiry on existing cert.')
        openssl_sclient = subprocess.run(
            ['openssl', 's_client',
             '-servername', fqdn,
             '-connect', fqdn + ':443'
             ],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            input=echo.stdout,
            check=True
        )
    except Exception:
        logging.info('Could not connect to host with openssl')
        return False

    try:
        logging.info('Checking expiry on existing cert.')
        openssl_dates = subprocess.run(
            ['openssl', 'x509',
             '-startdate',
             '-enddate',
             '-noout'
             ],
            stdout=subprocess.PIPE,
            input=openssl_sclient.stdout,
            check=True
        ).stdout.decode()
    except Exception:
        logging.info('Could not read certificate')
        return False

    cert_expiry = openssl_dates.splitlines(True)

    return get_certificate_dates(cert_expiry)


def get_certificate_dates(openssl_response):

    cert_dates = {}

    for certdate in openssl_response:

        if certdate.find('notBefore') != -1:
            start_end = 'start'

        elif certdate.find('notAfter') != -1:
            start_end = 'end'
        else:
            sys.exit('The certificate appears to have missing dates')

        certdate = certdate.rstrip()
        certdate = re.sub(r'not(After|Before)=', '', certdate)

        expiry_date_from_string = strptime(
            certdate, '%b %d %H:%M:%S %Y %Z')

        formatted_expiry_date = strftime(
            '%Y-%m-%dT%H:%M:%SZ', expiry_date_from_string)

        cert_dates[start_end] = formatted_expiry_date

    return cert_dates


def check_dns_name_exits(host, zone, resource_group):
    # az network dns record-set cname show -n notm-deva -g webops -z hmpps.dsd.io

    cmd = ['az', 'network', 'dns', 'record-set', 'cname', 'show',
           '-n', host,
           '-z', zone,
           '-g', resource_group
           ]

    logging.info('Trying CNAME record')
    cname = subprocess.run(
        cmd,
        stdout=subprocess.PIPE,
        check=True
    ).stdout.decode()

    if cname:
        return True
    else:
        cmd[4] = 'a'
        logging.info('Trying A record')
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
            remote_expiry['end'], '%Y-%m-%dT%H:%M:%SZ')

        # Adjust the renewal date to when the first letsencrypt email reminder is sent.
        adjusted_renewal_date = cert_end_date - timedelta(days=21)

        present_date = datetime.now()

        if adjusted_renewal_date > present_date:
            logging.info('Certificate does not need renewing until %s' %
                         (cert_end_date.strftime('%d %b %Y')))
            sys.exit()
    else:
        logging.info("Couldn't check certificate.")
        sys.exit(1)


    logging.debug("function: get_cert_expiry_from_keyvault")

    name = fqdn.replace('.', 'DOT')

    # adding this extra try block as it catches issues with the vault being inaccessable
    try:
        vault = subprocess.run(
            ["az", "keyvault", "show",
             "--name", vault_name        
             ],
            stdout=subprocess.PIPE,
        ).stdout.decode()

        if vault:
            logging.debug('vault exists!')
        else:
            sys.exit('Cannot access vault!')

    except subprocess.CalledProcessError:
        sys.exit('There was an error accessing the key vault')

    try:
        cmd = ["az", "keyvault", "certificate", "show",
        "--name", name,
        "--vault-name", vault_name       
        ]
    
        cert = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
        ).stdout.decode()

        if cert:
            cert_info = json.loads(cert)

            return cert_info['attributes']['expires']

    except subprocess.CalledProcessError:
        sys.exit('There was an error retrieving cert from the key vault')


def check_if_cert_renewal_due(current_cert_expiry):

    logging.debug('function: check_if_cert_renewal_due')

    logging.debug('current_cert_expiry is %s', current_cert_expiry)

    # removing colon from timezone as it causes issues with format function
    if ':' == current_cert_expiry[-3:-2]:
        current_cert_expiry = current_cert_expiry[:-3]+current_cert_expiry[-2:]

    logging.debug('formatted current_cert_expiry is %s', current_cert_expiry)

    present_date = datetime.now(timezone.utc)

    cert_end_date = datetime.strptime(
            current_cert_expiry, '%Y-%m-%dT%H:%M:%S%z')

    # Adjust the renewal date
    adjusted_renewal_date = cert_end_date - timedelta(days=21)

    logging.debug('present_date is %s', present_date)
    logging.debug('current_cert_expiry is %s', current_cert_expiry)
    logging.debug('adjusted_renewal_date is %s', adjusted_renewal_date)

    logging.info('Current Certificate expires on %s' %
                 (cert_end_date.strftime('%d %b %Y')))

    if adjusted_renewal_date > present_date:
            logging.debug('Certificate does not need renewing until %s' %
                          (adjusted_renewal_date.strftime('%d %b %Y')))

            logging.info('Exiting as certificate doesnt need renewing!')
            sys.exit(0)

    return True

azure_account.azure_set_subscription(args.subscription_id)

if not get_zone_details(args.resource_group, args.zone):
    sys.exit('Failed to find existing zone ' + args.zone)

if not args.internal:
    logging.debug('args.internal is false!')
    if check_dns_name_exits(args.hostname, args.zone, args.resource_group):
        logging.debug('DNS record found!')
    else:
        logging.info("A record or CNAME doesn't exist. No expiry date to check.")

if args.ignore_expiry:
    logging.debug('args.ignore_expiry is true, proceeding to create cert.')
else:
    logging.debug('args.ignore_expiry is false, checking cert expiry.')
    if not args.internal:
        logging.debug('args.internal is false, endpoint should be accessible.')
        logging.debug('Calling "certificate_renewal_due"')
        certificate_renewal_due(fqdn)
    else:
        logging.debug("args.internal is true, check expiry via date from vault.")
        current_cert_expiry = get_cert_expiry_from_keyvault(args.vault, fqdn)
        if current_cert_expiry:
            check_if_cert_renewal_due(current_cert_expiry)
        else:
            logging.info('Cert not found. Assume its a new request.')

if args.wildcard:
    hostname = '*'

dns_names = {
   'common_name': [hostname, args.zone]
   }
if args.extra_zone:
    logging.debug('args.extra_zone is true')
    dns_names.update({
     'additional_name': [extra_host, args.extra_zone]
    })
else:
    logging.debug('args.extra_zone is false!')

saved_cert = create_certificate(dns_names, args.resource_group, args.certbot)

if not args.certificate_only:

    store_certificate(args.vault, fqdn, args.certbot, saved_cert)


logging.info('Certificate update complete.')
