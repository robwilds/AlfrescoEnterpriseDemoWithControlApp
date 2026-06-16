#!/bin/bash
#set variables if needed

# start the container stack
# (assumes the caller has permission to do this)
open -a docker

sleep 5

#check postgres data
cd ../DockerCompose/alfdemo261/data/services/postgres/
#now extract the postgres database
if [ ! -d "./data/" ]; then
  echo "data directory does not exist...unzipping postgres backup"
  unzip data.zip -d data
else
  echo "postgres data directory is present...skipping"
fi

#check alf_data
cd ../content/
#now extract the alf_data files
if [ ! -d "./alf_data/" ]; then
  echo " alfdata directory does not exist...unzipping alf_data backup"
  unzip alf_data.zip -d alf_data
else
  echo "alfdata directory is present...skipping"
fi

echo "changing to docker compose directory"
cd ../DockerCompose/alfdemo261/
#docker compose up  --pull missing -d
docker compose up -d --pull missing

# wait for the service to be ready
while ! curl --fail --silent --head http://localhost:8080; do
  sleep 1
done

# open the browser window
open http://localhost:8080