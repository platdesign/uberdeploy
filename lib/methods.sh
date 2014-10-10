#!/bin/bash

source ${SCRIPTPATH}/../lib/githelper.sh
source ${SCRIPTPATH}/../lib/utils.sh




init() {
	# detect project variables and ask for the ones which are not detecable or set
	detectProjectVariables $@

	# inititalize git repository if not exist
	if [ ! -d ${PROJECTPATH}/.git ]; then
		git init ${PROJECTPATH}
	fi

	# save config file
	saveConfigFile
}

initRemote() {
	if [[ ! ${PROJECTNAME} ]]; then
		detectProjectVariables $@
	fi

	local REMOTESCRIPT="${SCRIPTPATH}/../lib/remoteInit.sh"

	SSHRESULT=$(ssh ${SSH_AUTHORITY} 'bash -s' < ${SCRIPTPATH}/../lib/remoteInit.sh ${PROJECTNAME} ${REMOTE_WORKPATH})

	OUTPUT=${SSHRESULT%%----END----*}
	VARIABLES=${SSHRESULT##*----END----}
	eval ${VARIABLES}


	if [[ ${SSHCALL_SUCCESS} = true ]];
		then
			echo 'Created on remote'
		else
			echo ${SSHCALL_MESSAGE}
			exit 1;
	fi

}

create() {

	init $@
	initRemote $@

	GIT_ORIGIN_URL="ssh://${SSH_AUTHORITY}${GIT_ORIGIN_PATH}"

	cd ${PROJECTPATH}
	if ! git remote | grep ${GIT_ORIGIN_NAME} > /dev/null; then
		git remote add ${GIT_ORIGIN_NAME} ${GIT_ORIGIN_URL}
	fi

	if [ ! -d "deploy" ]; then
		mkdir "deploy"
	fi

	if [ ! -e "deploy/post-receive" ]; then
		echo "#!/bin/bash" > deploy/post-receive
	fi

}



destroy() {
	echo 'Not implemented yet'
	echo 'Destroy...' $@
}



deploy() {

	# If repository has uncomitted files
	if git_anyChanges; then
		read -p "Commit changes? (y/n) " -n 1 -r RESPONSE
		echo
		if [[ ${RESPONSE} =~ ^[Yy]$ ]]; then
			COMMIT_MESSAGE="Deploy by ${USER} from ${HOSTNAME}"
			git add --all
			git commit --allow-empty -m "${COMMIT_MESSAGE}"
		fi
	fi

	# Push to uberspace
	git push uberspace master

}






update() {
	echo 'Not implemented yet'
}

confirm() {
	read -p ${1} -n 1 -r ${2}
}


uninstall() {
	echo 'Not implemented yet...'
	read -p "Are you sure? (y/n) " -n 1 -r RE
	echo
	if [[ ${RE} =~ ^[Yy]$ ]]
		then
			echo "Uninstalling uberdeploy..."
		else
			echo "Aborting uninstalling process"
	fi
}
