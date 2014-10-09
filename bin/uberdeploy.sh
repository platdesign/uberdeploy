#!/bin/sh


read -p "Project-Name: " projectName
read -p "Uberspace Username: " uberUsername
read -p "Uberspace Server: " uberServer

uberBaseDir="/home/$uberUsername/uberdeploy"

uberSSH="$uberUsername@$uberServer.uberspace.de"

ssh $uberSSH uberBaseDir=$uberBaseDir projectName=$projectName 'bash -s' < ../lib/remoteScript.sh

repoUrl="ssh://$uberSSH/home/$uberUsername/uberdeploy/bare/$projectName.git/"

git clone $repoUrl $projectName

cd $projectName






mkdir -p deploy

serviceName=$projectName"Service"

cat <<EOT >> deploy/post-receive
#!/bin/sh
if [ ! -e /home/$uberUsername/service/$serviceName ]
then
	# Creating Service
	uberspace-setup-service $serviceName node $uberBaseDir/work/$projectName/index.js
else
	echo 'Restarting service...'
	svc -h ~/service/$serviceName
fi
EOT

echo "//Put your Server-Script here" >> index.js

git add --all
git commit -m "Added deploy hook scripts"
