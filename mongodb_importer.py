
import os
import json
from pymongo import MongoClient
import datetime
import requests
#import urllib3
#http = urllib3.PoolManager()

MONGODB_ADMINUSERNAME =  os.environ.get('MONGODB_ADMINUSERNAME', "root")
MONGODB_ADMINPASSWORD =  os.environ.get('MONGODB_ADMINPASSWORD', "example")
MONGODB_SERVER =  os.environ.get('MONGODB_SERVER', "mongodb.service.consul")
MONGODB_PORT =  os.environ.get('MONGODB_PORT', 27017)
MONGODB_DATABASENAME  =  os.environ.get('MONGODB_DATABASENAME', "contacts")
 
response = requests.get("https://jsonplaceholder.typicode.com/users")
contacts = json.loads(response.text)
myrecord2 = []
for person in contacts:
    myrecord2.append(person)
client = MongoClient('mongodb://{MONGODB_ADMINUSERNAME}:{MONGODB_ADMINPASSWORD}@{MONGODB_SERVER}:{MONGODB_PORT}/'.format(MONGODB_ADMINUSERNAME=MONGODB_ADMINUSERNAME,MONGODB_ADMINPASSWORD=MONGODB_ADMINPASSWORD,MONGODB_SERVER=MONGODB_SERVER,MONGODB_PORT=MONGODB_PORT))
mydb = client['{MONGODB_DATABASENAME}'.format(MONGODB_DATABASENAME=MONGODB_DATABASENAME)]
result = mydb.contacts.insert_many(myrecord2)
print (result.inserted_ids)
print (mydb.collection_names())
