cd ../Dockercompose/alfdemo261
docker compose stop

#now call zipbackupdata.sh
cd ../../tools
echo "Backing up data to zip..."
./zipbackupdata.sh