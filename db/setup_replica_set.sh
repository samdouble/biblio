#!/bin/bash

# Wait to be able to access to at least one of the nodes of the replica-set
mongosh --nodb --eval '
var connection;
do {
  try {
    connection = new Mongo("biblio-api-mongo0:27017");
  } catch(Error) {
    sleep(1000);
  }
} while( !connection );'

# Wait for replica-set setup to finish
mongosh --host biblio-api-mongo0:27017 --eval '
var cfg = {
"_id": "rs0",
    "version": 1,
    "members": [
        {
            "_id": 0,
            "host": "biblio-api-mongo0:27017",
            "priority": 1
        },
        {
            "_id": 1,
            "host": "biblio-api-mongo1:27017",
            "priority": 0
        },
        {
            "_id": 2,
            "host": "biblio-api-mongo2:27017",
            "priority": 0
        }
    ],
};
rs.initiate(cfg);
while( !(rs.status().ok) ) {
  sleep(1000);
}'
