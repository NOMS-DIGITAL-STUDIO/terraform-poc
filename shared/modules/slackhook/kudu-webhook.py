#!/usr/bin/env python3
from datetime import datetime
import argparse
import json
import logging
import subprocess
import sys
import base64
from urllib.parse import urlparse, urljoin, urlencode, parse_qs
from urllib.request import urlopen, Request

logging.basicConfig(level=logging.INFO)

parser = argparse.ArgumentParser(description='Create/update azure webapp kudu webhooks')
parser.add_argument('--appName', help='App Service name', required=True)
parser.add_argument('--urls', help='json array of the webhook urls, base64 encoded', required=True)
args = parser.parse_args()

newhookurls = json.loads((base64.b64decode(args.urls).decode()))

KUDU_API = "https://%s.scm.azurewebsites.net/" % args.appName

token = json.loads(subprocess.run(
    "az account get-access-token",
    shell=True, stdout=subprocess.PIPE
).stdout)
authorization = token['tokenType'] + ' ' + token['accessToken']

def req(method, path, data={}, params={}):
    headers = {'authorization': authorization}
    url = urljoin(KUDU_API, '/api/' + path)
    url = url + '?' + urlencode(params)
    data = json.dumps(data)
    data = data.encode('utf-8')
    logging.info("Requesting %s %s" % (method,url))
    if method == 'POST':
        headers.update({'Content-type': 'application/json'})
        logging.info("Data: %s" % data)
    with urlopen(Request(url, data=data, headers=headers, method=method)) as res:
        logging.info("Got response %d" % res.status)
        return res.read()

# Get the existing hooks.
existing_hooks = json.loads(req("GET", "hooks"))

# Loop round existing hooks and delete.
for hook in existing_hooks:
    req("DELETE", "hooks/%s" % hook['id'])

# Loop round provided hooks and add.
for hook in newhookurls:
    data = { "url": hook, "event": "PostDeployment","insecure_ssl": False }
    req('POST', "hooks", data)

