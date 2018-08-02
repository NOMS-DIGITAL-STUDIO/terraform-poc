#!/usr/bin/env python3

# Manage the list of users used to created AWS accounts. For most actions a complete list of users is required.

import json
import subprocess
import sys
import os.path
import logging
import argparse
import secrets
import string

logging.basicConfig(stream=sys.stdout, level=logging.INFO)

parser = argparse.ArgumentParser(
    description='Script to create the config for AWS user accounts')

parser.add_argument("-e", "--environment", help="Prod or Devtest environment", choices=["devtest", "prod"], required=True)
parser.add_argument("-u", "--users", help="Users to add/del to AWS")
parser.add_argument("-a", "--user-action", help="Add or delete Users (add/del)", choices=["add", "del", "list"], required=True)
parser.add_argument("-g", "--group", help="user type to update e.g. webops, developers etc.")

args = parser.parse_args()

def manage_users(environment, user_action,group):

    user_types = ['webops','newnomis-developers']

    vault_name = "aws-users-" + environment

    logging.info("Creating user list")

    for user_type in user_types:
        logging.info("Checking " + user_type )

        user_list = []

        try:
            user_list = subprocess.run(
                ["az", "keyvault", "secret", "show",
                 "--vault-name", vault_name,
                 "--name", user_type
                 ],
                stdout=subprocess.PIPE,
                check=True
            ).stdout.decode()

            user_list = json.loads(user_list)

            user_list = user_list["value"].split(",")

            user_list = list(filter(None, user_list))

        except subprocess.CalledProcessError:
            logging.info("Key vault secret for " + user_type + " doesn't exist. It will be created if required.")

        if user_action == "list":
            print(user_list)
            continue

        users = args.users.split(",")

        for user in users:
            if user_action == "add" and user_type == group :
                if user not in user_list:
                    user_list.append(user)

                    aws_user_create(user)

                    logging.info("User " + user + " created" )
                else:
                    logging.warn("User " + user + " already exists" )
            elif user_action == "del" and user_type == group:
                if user in user_list:
                    user_list.remove(user)
                    logging.info("User " + user + " deleted" )
                else:
                    logging.warn("User " + user + " does not exist" )

        if not user_list:
            store_user_list = ","
        else:
            store_user_list = ",".join(user_list)

        user_list_update_cmd = ["az", "keyvault", "secret", "set",
        "--vault-name", vault_name,
         "--name", user_type,
         "--value", store_user_list]

        try:
            user_list = subprocess.run(
               user_list_update_cmd,
               stdout=subprocess.PIPE,
               check=True
            ).stdout.decode()
        except subprocess.CalledProcessError:
            sys.exit("There was an error storing the user list to the vault")

def aws_user_create(user):
  logging.info("Creating AWS user " + user)

  try:
      aws_user = subprocess.run(
          ["aws", "iam", "create-user",
           "--user-name", user
           ],
          stdout=subprocess.PIPE,
          check=True
      ).stdout.decode()

  except subprocess.CalledProcessError:
      logging.info("Couldn't create AWS user " + user)

  if (aws_user):

      alphabet = string.ascii_letters + string.digits
      password = ''.join(secrets.choice(alphabet) for i in range(20))

      try:
          user_list = subprocess.run(
                ["aws", "iam", "create-login-profile",
                 "--user-name", user,
                 "--password", password
                 ],
                stdout=subprocess.PIPE,
                check=True
            ).stdout.decode()
          logging.info("Password for " + user + ": " + password)
      except subprocess.CalledProcessError:
          logging.info("Couldn't set password for AWS user " + user)

manage_users(args.environment, args.user_action, args.group)
