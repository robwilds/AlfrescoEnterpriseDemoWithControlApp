#!/bin/bash
#start with prepping the alf_data directory
cd ../DockerCompose/alfdemo261/data/services/content;
ECHO $PWD;
if test -f "alf_data.zip"; then
  echo "File exists...removing"
  rm alf_data.zip
  cd alf_data
  zip -r '../alf_data.zip' *
  sleep 2
else
  echo "File does not exist"
  cd alf_data
  zip -r '../alf_data.zip' *
  sleep 2
fi


#continue on to the postgres data now
cd ../../postgres/;
ECHO $PWD;
if test -f "data.zip"; then
  echo "File exists...removing"
  rm data.zip
  cd data
  zip -r '../data.zip' *
  sleep 2
else
  echo "File does not exist"
  cd data
  zip -r '../data.zip' *
  sleep 2
fi

