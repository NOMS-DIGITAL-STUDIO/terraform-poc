#!/usr/bin/env python3
from datetime import datetime
import argparse
import json
import logging
import subprocess
import sys
from base64 import b64decode 
import pymssql  

parser = argparse.ArgumentParser(description='Helper script to augment terraform mssql setup, manage db users, execute SQL')
parser.add_argument('--server', help='MSSQL server hostname.', required=True)
parser.add_argument('--username', help='DB user to connect.', required=True)
parser.add_argument('--password', help='DB pass for user.', required=True)
parser.add_argument('--database', help='DB to connect to.', required=True)
parser.add_argument('--users', help='json map of username/password, base64 encoded')
parser.add_argument('--queries', help='json array of queries, base64 encoded')
parser.add_argument('--rollback', action="store_true", help='true/false. Test transactions and rollback any changes')
parser.add_argument('--debug', action="store_true", help='true/false. Test transactions and rollback any changes')
args = parser.parse_args()

# Setup logging
if args.debug:
    log_level=logging.DEBUG
else:
    log_level=logging.INFO

logging.basicConfig(level=log_level)

# Connect to sql db
logging.info("Connecting to %s:%s" % (args.server, args.database))
conn = pymssql.connect(server=args.server, user="%s@%s" % (args.username,args.database), password=args.password, database=args.database)
cursor = conn.cursor()

# function iterates over users/passwords and creates
def setup_users(users_dict):
    for user,password in users_dict.items():
        sql = """
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = '{username}')
    ALTER USER {username} WITH PASSWORD = '{password}';
ELSE
    CREATE USER {username} WITH PASSWORD = '{password}';
        """.format(username=user,password=password)
        logging.info("Creating user: %s" % user)
        execute_sql(sql)

# function iterates over provided SQL
def sql_setup(queries):
    for query in queries:
        logging.info("Executing: %s" % query)
        execute_sql(query)


def execute_sql(sql):
    cursor.execute("BEGIN TRANSACTION")
    logging.debug("SQL: %s" % sql)
    cursor.execute(sql)
    if args.rollback:
        logging.info("Rolling back transaction.")
        conn.rollback()
    else:
        logging.info("Commiting transaction.")
        conn.commit()

if args.users != None:
    #decode base64 and load json into dict
    users = json.loads((b64decode(args.users).decode()))
    setup_users(users)

if args.queries != None:
    queries = json.loads((b64decode(args.queries).decode()))
    sql_setup(queries)

logging.info("Closing connection.")
conn.close()
