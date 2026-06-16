#!/bin/bash
echo "deleting the postgres data and alf_data directories and restoring from zip backup"
rm -rf ../DockerCompose/AlfrescoEnterprise/data/services/postgres/data
rm -rf ../DockerCompose/AlfrescoEnterprise/data/services/content/alf_data