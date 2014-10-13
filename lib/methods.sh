#!/bin/bash

source ${SCRIPTPATH}/../lib/githelper.sh
source ${SCRIPTPATH}/../lib/utils.sh
source ${SCRIPTPATH}/../lib/remoteMethods.sh


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


	createRemoteProject ${PROJECTNAME} ${SSH_AUTHORITY}

	local GIT_ORIGIN_URL="ssh://${SSH_AUTHORITY}"$(config_get_val "$REMOTE_EXECUTE_HEADER" 'GIT_ORIGIN_PATH');


	cd ${PROJECTPATH}
	if ! git remote | grep ${GIT_ORIGIN_NAME} > /dev/null; then
		git remote add ${GIT_ORIGIN_NAME} ${GIT_ORIGIN_URL}
		echo_notify "Added remote '${GIT_ORIGIN_NAME}' to repository"
		echo_notify_white "URL: ${GIT_ORIGIN_URL}"
	fi

}




# Init project locally and on remote
# This should be used when starting a new empty project
create() {

	init $@
	initRemote $@

	cd ${PROJECTPATH}
	if [ ! -d "deploy" ]; then
		mkdir "deploy"
	fi

	if [ ! -e "deploy/post-receive" ]; then
		echo "#!/bin/bash" > deploy/post-receive
		echo_notify "Added hook: deploy/post-receive"
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

	if [[ ! -d .git ]]; then
		echo_error "Can't deploy. No repository found."
		exit 1
	fi

	if ! git remote | grep ${GIT_ORIGIN_NAME} > /dev/null; then
		echo_error "Missing remote '${GIT_ORIGIN_NAME}'"
		exit 1
	fi

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
	git push ${GIT_ORIGIN_NAME} master

}





# Updates the current installation of uberdeploy on your machine
update() {

	check_version ${VERSION};	STATUS=$?

	case ${STATUS} in
		0) echo "Already latest version" ;;
		2)
			local LIB_DIR=${SCRIPT%/*/*}

			if [[ -d ${LIB_DIR} ]]; then
				rm -rf ${LIB_DIR}
			fi

			echo "Downloading repository"
			mkdir -p ${LIB_DIR}

			# Get the tarball
			TMPTARFILE="${LIB_DIR}/${TOOLNAME}.tar.gz"
			curl -fsSLo TMPTARFILE ${REPOSITORY}/tarball/master

			# Extract tarball to directory
			echo "Extracting files"
			tar -zxf TMPTARFILE --strip-components 1 -C ${LIB_DIR}

			# Remove the tarball
			rm -rf TMPTARFILE

			echo "Ready!"

		;;

	esac


}



uninstall() {
	if input_confirm "Really?"; then
		echo 'Not implemented ;)'
	fi
}




help() {

	cat ${SCRIPTPATH}/../lib/help.txt

	check_version_and_hint ${VERSION}

}

function displayLog() {
	detectProjectVariables $@
	displayRemoteLog ${PROJECTNAME} ${SSH_AUTHORITY}
}

