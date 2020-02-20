#!/usr/bin/env python3
import subprocess
import sys
import os.path
import argparse
import logging

sys.path.insert(0, './')

parser = argparse.ArgumentParser(
    description='Script to update an SSL certificate on an Azure Application Gateway')

parser.add_argument('-g', '--resource-group', help='resource_group')
parser.add_argument('-b', '--gw-subscription-id', help='App gateway subscription id')
parser.add_argument('-n', '--gw-cert-name', help='Azure app gw listener cert name')
parser.add_argument('-a', '--gateway-name', help='Azure Application Gateway name')
parser.add_argument('-k', '--key-vault', help='Azure Key Vault where the certificate is stored')
parser.add_argument('-s', '--key-vault-subscription-id', help='Azure KeyVault subscription id')
parser.add_argument('-c', '--key-vault-cert-name', help='Name of the certificate in KeyVault')
parser.add_argument('-debug', '--debug', help='Change logging level to debug.', action='store_true')

args = parser.parse_args()

if args.debug:
    print('Setting logging level to debug')
    logging.basicConfig(stream=sys.stdout, level=logging.DEBUG)
    logging.getLogger().setLevel(10)
else:
    print('Setting logging level to info')
    logging.basicConfig(stream=sys.stdout, level=logging.INFO)
    logging.getLogger().setLevel(20)


def update_ssl_cert(app_gateway_name, resource_group, gw_cert_name, key_vault, cert_file, gw_subscription, passphrase):

    logging.info('function: update_ssl_cert.')
    logging.debug("Value of 'cert_file' is: %s", cert_file)

    try:
        subprocess.run(
            ['az', 'account', 'set',
             '-s', gw_subscription
             ],
            stdout=subprocess.PIPE,
            check=True
        ).stdout.decode()

    except subprocess.CalledProcessError:
        sys.exit('There was an error setting the subscription')

    logging.info('Updating Application Gateway with new certificate.')

    if args.debug:
        try:
            app_gw_info = subprocess.run(
                ['az', 'network', 'application-gateway', 'ssl-cert', 'list',
                 '--gateway-name', app_gateway_name,
                 '--resource-group', resource_group
                 ],
                stdout=subprocess.PIPE,
                check=True
            ).stdout.decode()

        except subprocess.CalledProcessError:
            sys.exit('There was an error reading app gw config')

        logging.debug("Initial value of 'app_gw_info' is: %s", app_gw_info)

    cmd = ['az', 'network', 'application-gateway', 'ssl-cert', 'update',
           '--gateway-name', app_gateway_name,
           '--resource-group', resource_group,
           '--name', gw_cert_name,
           '--cert-file', cert_file,
           '--cert-password', passphrase
           ]
    logging.info('Running: %s' % (' '.join(cmd)))

    try:
        set_secret = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            check=True
        )
        logging.info(set_secret)

    except subprocess.CalledProcessError:
        sys.exit('There was an error updating the application gateway SSL certificate.')

    if args.debug:
        try:
            app_gw_info = subprocess.run(
                ['az', 'network', 'application-gateway', 'ssl-cert', 'list',
                 '--gateway-name', app_gateway_name,
                 '--resource-group', resource_group
                 ],
                stdout=subprocess.PIPE,
                check=True
            ).stdout.decode()

        except subprocess.CalledProcessError:
            sys.exit('There was an error reading app gw config')

        logging.debug("Updated value of 'app_gw_info' is: %s", app_gw_info)


def get_cert_from_keyvault(vault_name, cert_name, vault_subscription):

    logging.debug('function: get_cert_from_keyvault')
    logging.debug('vault_subscription is: %s', vault_subscription)

    try:
        subprocess.run(
            ['az', 'account', 'set',
             '-s', vault_subscription
             ],
            stdout=subprocess.PIPE,
            check=True
        ).stdout.decode()

    except subprocess.CalledProcessError:
        sys.exit('There was an error setting the subscription')

    savecert = cert_name + '.pfx'

    try:
        vault = subprocess.run(
            ['az', 'keyvault', 'show',
             '--name', vault_name
             ],
            stdout=subprocess.PIPE,
            check=True
        ).stdout.decode()

        if vault:
            logging.debug('vault exists!')
        else:
            sys.exit('Cannot access vault!')

    except subprocess.CalledProcessError:
        sys.exit('There was an error accessing the key vault')

    try:
        cmd = ['az', 'keyvault', 'secret', 'download',
               '--name', cert_name,
               '--vault-name', vault_name,
               '--file', savecert,
               '--encoding', 'base64'
               ]

        cert = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            check=True
        ).stdout.decode()

        return cert

    except subprocess.CalledProcessError:
        sys.exit('There was an error retrieving cert from the key vault')


def add_password_to_pfx(cert_name, passphase):
    logging.debug('function: add_password_to_pfx')

    path_to_cert = (os.path.abspath(cert_name))
    logging.debug('The certificate is saved at '' + path_to_cert +''')
    certs_folder = (os.path.dirname(path_to_cert))
    basename = (os.path.basename(path_to_cert))
    logging.debug('basename is: '' + basename +''')
    filename = os.path.splitext(basename)[0]
    logging.debug('filename is: '' + filename +''')

    path_to_cert_no_pass = certs_folder + '/' + cert_name
    path_to_key = certs_folder + '/privkey.key'
    path_to_cert = certs_folder + '/public.pem'
    export_path = certs_folder + '/' + filename + '_cert_with_pass.pfx'

    set_passphrase = 'pass:' + passphase

    logging.debug('create key')
    subprocess.run(
        ['openssl', 'pkcs12',
         '-in', path_to_cert_no_pass,
         '-out', path_to_key,
         '-nocerts',
         '-password', 'pass:',
         '-passout', set_passphrase
         ],
        stdout=subprocess.PIPE,
        check=True
    ).stdout.decode()

    logging.debug('create cert')
    subprocess.run(
        ['openssl', 'pkcs12',
         '-in', path_to_cert_no_pass,
         '-out', path_to_cert,
         '-password', 'pass:',
         '-nokeys'
         ],
        stdout=subprocess.PIPE,
        check=True
    ).stdout.decode()

    logging.debug('create final cert')
    subprocess.run(
        ['openssl', 'pkcs12', '-export',
         '-out', export_path,
         '-inkey', path_to_key,
         '-in', path_to_cert,
         '-passin', set_passphrase,
         '-passout', set_passphrase
         ],
        stdout=subprocess.PIPE,
        check=True
    ).stdout.decode()

    if os.path.exists(export_path):
        logging.debug('export_path is: %s', export_path)
        return export_path
    else:
        sys.exit('There was a problem creating the certificate')


cert_file = args.key_vault_cert_name + '.pfx'
passphrase = 'temp_password'

certificate = get_cert_from_keyvault(args.key_vault, args.key_vault_cert_name, args.key_vault_subscription_id)

pfx_with_pass = add_password_to_pfx(cert_file, passphrase)
logging.debug('The value of \'pfx_with_pass\' is: %s', pfx_with_pass)

update_ssl_cert(args.gateway_name, args.resource_group, args.gw_cert_name, args.key_vault, pfx_with_pass, args.gw_subscription_id, passphrase)
