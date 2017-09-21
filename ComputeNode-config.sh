until apt -y update
do
    echo "Waiting 60sec for apt to be free..."
    sleep 60
done
echo "Done waitng for apt..."

apt install -y python-pip jq

echo "Editing appsettings.json..."
cat /usr/lib64/microsoft-r/rserver/o16n/9.1.0/Microsoft.RServer.ComputeNode/appsettings.json > /usr/lib64/microsoft-r/rserver/o16n/9.1.0/Microsoft.RServer.ComputeNode/appsettingsOLD.json 
cat /usr/lib64/microsoft-r/rserver/o16n/9.1.0/Microsoft.RServer.ComputeNode/appsettingsOLD.json |
jq -r ".Pool.InitialSize = \"$1\"" |
jq -r ".Pool.MaxSize = \"$2\"" > /usr/lib64/microsoft-r/rserver/o16n/9.1.0/Microsoft.RServer.ComputeNode/appsettings.json
rm /usr/lib64/microsoft-r/rserver/o16n/9.1.0/Microsoft.RServer.ComputeNode/appsettingsOLD.json
cat /usr/lib64/microsoft-r/rserver/o16n/9.1.0/Microsoft.RServer.ComputeNode/appsettings.json

iptables --flush

#virtualenv and spacy installs
pip install virtualenv
python -m virtualenv /home/spacyenv
source /home/spacyenv/bin/activate
pip install spacy
python -m spacy download en

# Install required R packages
R --vanilla -e 'install.packages("spacyr", repos = "https://cloud.r-project.org")'
R --vanilla -e 'install.packages("stringr", repos = "https://cloud.r-project.org")'
R --vanilla -e 'install.packages("jsonlite", repos = "https://cloud.r-project.org")'
R --vanilla -e 'install.packages("stringi", repos = "https://cloud.r-project.org")'
R --vanilla -e 'install.packages("tidyverse", repos = "https://cloud.r-project.org")'

sleep10
echo "Configuring as R Server Compute Node..."
/usr/local/bin/dotnet /usr/lib64/microsoft-r/rserver/o16n/9.1.0/Microsoft.RServer.Utils.AdminUtil/Microsoft.RServer.Utils.AdminUtil.dll -silentcomputenodeinstall
