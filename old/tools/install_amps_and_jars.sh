#!/bin/bash
#the 2 lines below are commented out as the support tools should already be mounted in the volume ready to install
#docker cp ../../supportTools/support-tools-repo-1.2.2.0-amp.amp alfdemo2341-alfresco-1:/usr/local/tomcat/amps

#Docker cp ../../supportTools/support-tools-share-1.2.2.0-amp.amp alfdemo2341-share-1:/usr/local/tomcat/amps_share

#install the amps
docker exec -it --user root alfdemo261-alfresco-1 bash -c "java -jar /usr/local/tomcat/alfresco-mmt/alfresco-mmt-26.1.0.61.jar install /usr/local/tomcat/amps /usr/local/tomcat/webapps/alfresco -directory -force -verbose"
docker exec -it --user root alfdemo261-share-1 bash -c "java -jar /usr/local/tomcat/alfresco-mmt/alfresco-mmt-26.1.0.61.jar install /usr/local/tomcat/amps_share /usr/local/tomcat/webapps/share -directory -force -verbose"

#Install jars that are placed in the amp folder
docker exec -it --user root alfdemo261-alfresco-1 bash -c "cp /usr/local/tomcat/amps/*.jar /usr/local/tomcat/webapps/alfresco/WEB-INF/lib"
docker exec -it --user root alfdemo261-share-1 bash -c "cp /usr/local/tomcat/amps_share/*.jar /usr/local/tomcat/webapps/share/WEB-INF/lib"

echo "changing directory"
cd ../DockerCompose/alfdemo261
echo "restart alfresco and share"
docker compose restart alfresco share