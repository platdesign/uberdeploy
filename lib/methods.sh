#!/bin/bash

source ${SCRIPTPATH}/../lib/githelper.sh
source ${SCRIPTPATH}/../lib/utils.sh



# Initialize a repository only locally
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



# Initialize a repository only on remote
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




# Init project locally and on remote
# This should be used when starting a new empty project
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


# Clone an existing repository to your local machine
join() {

	input_required "Projectname" PROJECTNAME
	input_required "SSH authority (e.g. user@server.uberspace.de)" SSH_AUTHORITY
	input_default "Location" "./${PROJECTNAME}" PROJCTPATH

	GIT_ORIGIN_URL="ssh://${SSH_AUTHORITY}/home/plati/Uberdeploy/${PROJECTNAME}/bare.git"

	git clone ${GIT_ORIGIN_URL} ${PROJCTPATH}

	cd ${PROJCTPATH}

	detectProjectVariables

	if ! git remote | grep ${GIT_ORIGIN_NAME} > /dev/null; then
		git remote add ${GIT_ORIGIN_NAME} ${GIT_ORIGIN_URL}
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


	local LIB_DIR=${SCRIPT%/*/*}

	local REPOSITORY="https://github.com/platdesign/uberdeploy"

	if [[ -d ${LIB_DIR} ]]; then
		rm -rf ${LIB_DIR}
	fi

	echo "Downloading repository"
	mkdir -p ${LIB_DIR}

	# Get the tarball
	TMPTARFILE="${LIB_DIR}/uberdeploy.tar.gz"
	curl -fsSLo TMPTARFILE ${REPOSITORY}/tarball/master

	# Extract tarball to directory
	echo "Extracting files"
	tar -zxf TMPTARFILE --strip-components 1 -C ${LIB_DIR}

	# Remove the tarball
	rm -rf TMPTARFILE

	echo "Ready!"

}



uninstall() {
	if input_confirm "Really?"; then
		echo 'Not implemented ;)'
	fi
}
