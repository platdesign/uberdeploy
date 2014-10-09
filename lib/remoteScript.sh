#!/bin/sh


bareDir=$uberBaseDir/bare
workingDir=$uberBaseDir/work

echo `mkdir -p $bareDir`
echo `mkdir -p $workingDir`

repoPath=$bareDir/$projectName.git
workingPath=$workingDir/$projectName

echo `mkdir $workingPath`

echo `git init --bare $repoPath`


postHookFile=$repoPath/hooks/post-receive

cat <<EOT >> $postHookFile
#!/bin/sh
unset GIT_INDEX_FILE
export GIT_WORK_TREE=$workingPath
export GIT_DIR=$repoPath
git checkout -f
echo post-receive-hook fired!

if [ -e $workingPath/deploy/post-receive ]
then
	sh $workingPath/deploy/post-receive
fi
EOT

chmod +x $postHookFile
