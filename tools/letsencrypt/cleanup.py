#!/usr/bin/env python3

import os
import subprocess
import sys
import logging
import json

logging.basicConfig(stream=sys.stdout, level=logging.INFO)

dns_names = json.loads(sys.argv[1])
resource_group = sys.argv[2]

for key,value in dns_names.items():

    host = value[0]
    zone = value[1]

    if host == "*":
        acme_challenge_name = "_acme-challenge"
    else:
        acme_challenge_name = "_acme-challenge." + host

    if host != os.getenv("CERTBOT_DOMAIN"):
        continue

    logging.info("Deleting DNS record for " + acme_challenge_name )

    delete_dns_record = subprocess.run(
        ["az", "network", "dns", "record-set", "txt", "remove-record",
         "--record-set-name", acme_challenge_name,
         "--resource-group", resource_group,
         "--zone-name", zone,
         "--value", os.getenv("CERTBOT_VALIDATION")
         ],
        stdout=subprocess.PIPE,
        check=True
    )

    if delete_dns_record.returncode == 0:
        logging.info("Deleted DNS record for %s.%s" % (host, zone))
    else:
        logging.warn("Error deleting DNS record for %s.%s" % (host, zone))
