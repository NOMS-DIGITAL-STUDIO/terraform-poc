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
    
    logging.info("host and zone =  %s.%s" % (host, zone))
    
    if host == "*":
        acme_challenge_name = "_acme-challenge"
    else:
        acme_challenge_name = "_acme-challenge." + host

    if host != os.getenv("CERTBOT_DOMAIN")
        continue

    create_record_set = subprocess.run(
        ["az", "network", "dns", "record-set", "txt", "create",
         "--name", acme_challenge_name,
         "--resource-group", resource_group,
         "--zone-name", zone,
         "--ttl", "60"
         ],
        stdout=subprocess.PIPE,
        check=True
    )

    if create_record_set.returncode == 0:

        logging.info("Created DNS empty txt record for %s.%s" % (host, zone))

        create_dns_record = subprocess.run(
            ["az", "network", "dns", "record-set", "txt", "add-record",
             "--record-set-name", acme_challenge_name,
             "--resource-group", resource_group,
             "--zone-name", zone,
             "--value", os.getenv("CERTBOT_VALIDATION")
             ],
            stdout=subprocess.PIPE,
            check=True
        )
        if create_dns_record.returncode == 0:
            logging.info("Added validation value to txt record for %s.%s" % (host, zone))
            logging.info("Certbot validation value: %s" % (os.getenv("CERTBOT_VALIDATION")))
        else:
            logging.warn("Error updating DNS txt record for %s.%s" % (host, zone))
    else:
        logging.warn("Error creating DNS record set for %s.%s" %
                     (host, zone))
