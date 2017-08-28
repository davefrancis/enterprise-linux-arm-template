#!/bin/bash
until apt -y update
do
    echo "Waiting 60sec for apt to be free..."
    sleep 60
done
echo "Done waitng for apt..."

CERT_FILE=$4

SERVERCONF="server {\n\tlisten 443; \n\tssl on; \n\tserver_name $3.westus.cloudapp.azure.com; \n\tssl_certificate /etc/ssl/certs/$CERT_FILE.crt; \n\tssl_certificate_key /etc/ssl/certs/$CERT_FILE.prv; \n\troot /var/www/html; \n\tlocation /ping { return 200 \"hello\";} \n\tlocation / { \n\t\tproxy_pass http://127.0.0.1:12800; \n\t} \n}"
echo $SERVERCONF
apt install -y nginx jq

echo "Copying self-signed certs..."
cp /var/lib/waagent/$CERT_FILE.crt /etc/ssl/certs
cp /var/lib/waagent/$CERT_FILE.prv /etc/ssl/certs

touch /etc/nginx/sites-enabled/rserverconf
echo -e $SERVERCONF > /etc/nginx/sites-enabled/rserverconf
cat /etc/nginx/sites-enabled/rserverconf
sed -i 's%include /etc/nginx/sites-enabled/\*;%include /etc/nginx/sites-enabled/rserverconf;%g' /etc/nginx/nginx.conf
service nginx start

# use jq to modify appsettings.json
echo "Modifying appsettings.json..."

echo "SQL connection string:"
echo $2
cat /usr/lib64/microsoft-r/rserver/o16n/9.1.0/Microsoft.RServer.WebNode/appsettings.json > /usr/lib64/microsoft-r/rserver/o16n/9.1.0/Microsoft.RServer.WebNode/appsettingsOLD.json

# edit appsettings.json
cat /usr/lib64/microsoft-r/rserver/o16n/9.1.0/Microsoft.RServer.WebNode/appsettingsOLD.json |
jq '.ConnectionStrings.sqlserver.Enabled = true' |
jq '.ConnectionStrings.defaultDb.Enabled = false' |
jq -r ".ConnectionStrings.sqlserver.Connection = \"$2\"" |
jq '.BackEndConfiguration.Uris.Ranges = ["http://10.0.1.0-255:12805"]' |
jq '.Logging.LogLevel.Default = "Debug"' |
jq '.Logging.LogLevel.System = "Debug"' > /usr/lib64/microsoft-r/rserver/o16n/9.1.0/Microsoft.RServer.WebNode/appsettings.json

rm /usr/lib64/microsoft-r/rserver/o16n/9.1.0/Microsoft.RServer.ComputeNode/appsettingsOLD.json

#print new setting for debug
echo "New appsettings.json:"
cat /usr/lib64/microsoft-r/rserver/o16n/9.1.0/Microsoft.RServer.WebNode/appsettings.json

sleep 10
echo "Configuring as R Server Web Node..."
/usr/local/bin/dotnet /usr/lib64/microsoft-r/rserver/o16n/9.1.0/Microsoft.RServer.Utils.AdminUtil/Microsoft.RServer.Utils.AdminUtil.dll -silentwebnodeinstall "$1"

service nginx restart