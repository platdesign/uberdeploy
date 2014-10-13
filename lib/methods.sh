#!/bin/bash

source ${SCRIPTPATH}/../lib/githelper.sh
source ${SCRIPTPATH}/../lib/utils.sh
source ${SCRIPTPATH}/../lib/remoteMethods.sh

source ${SCRIPTPATH}/../lib/local.sh

# Initialize a repository only locally
function init() {

	local _PROJECT_PATH="${PWD}";

	# If first parameter is set, use it as projectname
	if [[ -n ${1} ]]; then
		_PROJECT_PATH="${PWD}/${1}";
	fi

	# Set project variables
	project_setProjectVars "${_PROJECT_PATH}";


	# Project already exists
	if project_exists ${PROJECT_PATH}; then
		if ! input_confirm "Project already exists. Reinitialize?"; then
			exit 1;
		fi

	else
		# Dir exists and isn't empty
		if isDir ${PROJECT_PATH}; then
			if ! dir_isEmpty; then
				if ! input_confirm "Folder exists and isn't empty. Continue?"; then
					exit 1;
				fi
			fi
		fi
	fi


	# Check if it is an existing repo. Otherwise create it.
	if ! isGitRepo ${PROJECT_PATH}; then
		echo_notify "$(git init ${PROJECT_PATH})"
	fi

	# If config does not exist create it.
	if ! isFile ${PROJECT_CONFIG}; then
		echo "" > ${PROJECT_CONFIG};
		echo_notify "Config created."
	fi

	# Notify
	echo_notify "Project '${PROJECT_NAME}' successfully initialized."
}



# Initialize a repository only on remote
function initRemote() {
	if [[ ! ${PROJECTNAME} ]]; then
		detectProjectVariables $@
	fi


	createRemoteProject ${PROJECTNAME} ${SSH_AUTHORITY}

	if [[ $? -gt 0 ]]; then
		echo_error 'Remote repository could not be created.';
		exit 1;
	fi
}




# Init project locally and on remote
# This should be used when starting a new empty project
function create() {



	initRemote $@
	init $@


	local GIT_ORIGIN_URL="ssh://${SSH_AUTHORITY}"$(config_get_val "$REMOTE_EXECUTE_HEADER" 'GIT_ORIGIN_PATH');


	cd ${PROJECTPATH}
	if ! git remote | grep ${GIT_ORIGIN_NAME} > /dev/null; then
		git remote add ${GIT_ORIGIN_NAME} ${GIT_ORIGIN_URL}
		echo_notify "Added remote '${GIT_ORIGIN_NAME}' to repository"
		echo_notify_white "URL: ${GIT_ORIGIN_URL}"
	fi


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
function join() {

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





# Destroyes a project
# 1. on remote
# 2. on local machine
function destroy() {

	if calledFromProjectPath; then

		# Let the user confirm what he is doing ;)
		if ! input_confirm "Would you really like to destroy this app?"; then
			echo_notify "Two heads are better than one. ;)"
			exit 1;
		fi


		# Set project variables
		project_setProjectVars ${PWD};

		# Collect project variables (config,git-config)
		project_collectProjectVars ${PWD};


		# If PROJECT_SSH_AUTHORITY is set
		if project_varsSet 'NAME' 'SSH_AUTHORITY'; then

			# Let the user confirm what he is doing ;)
			if input_confirm "Remove project from remote '${PROJECT_SSH_AUTHORITY}'?"; then

				# Destroy the remote project
				if ! destroyRemoteProject "${PROJECT_NAME}" "${PROJECT_SSH_AUTHORITY}"; then
					echo_error "Remote repository couldn't be destroyed.";
				fi

			fi

		fi


		# Let the user confirm what he is doing ;)
		if input_confirm "Remove project from local machine?"; then
			if rm -rf "${PROJECT_PATH}"; then
				echo_notify "Local project successfully removed.";
			else
				echo_error "Can't remove local project.";
			fi
		fi

	else

		echo_error "Project not found. Move to projects folder.";

	fi
}






function deploy() {

	if [[ ! ${PROJECTNAME} ]]; then
		detectProjectVariables $@
	fi

	if [[ ! -d .git ]]; then
		echo_error "Can't deploy. No repository found."
		exit 1
	fi

	if ! git remote | grep ${GIT_ORIGIN_NAME} > /dev/null; then
		echo_error "Missing remote '${GIT_ORIGIN_NAME}'"
		exit 1
	fi


	COMMIT_MESSAGE="Deploy by ${USER} from ${HOSTNAME}"


	# If repository has uncomitted files
	if git_anyChanges;
		then
			input_confirm "Commit changes?"
			if [[ $? = 1 ]]; then
				git add --all
				git commit --quiet -m "${COMMIT_MESSAGE}"
				echo_notify "Committed: ${COMMIT_MESSAGE}"
			fi
		else
			input_confirm "No changes. Create empty commit?"

			if [[ $? = 1 ]]; then
				git add --all
				git commit --allow-empty -q -m "${COMMIT_MESSAGE}" 2>&1
				echo_notify "Committed: ${COMMIT_MESSAGE}"
			fi
	fi


	# Push to uberspace


	RES=$(git push --porcelain "${GIT_ORIGIN_NAME}" master 2>&1);
	RES_CODE=$?;

	echo "$RES" | while read line; do
		REMOTE=$( echo `echo $line | grep remote` | sed -n -e 's/^.*remote: //p' )
		if [[ -n ${REMOTE} ]];
			then
				echo -e "$REMOTE";
		fi
	done


	if [[ ${RES_CODE} -eq 0 ]]; then
		echo_notify "Project '${PROJECTNAME}' successfully uberdeployed =)"
	else
		case ${RES_CODE} in
			128)
				echo_error "Remote repository does not appear to exist.";
				echo_debug_note "You could create it with:\nuberdeploy create";
			;;
			*)
				echo_error "$RES" ;;

		esac

	fi
}





# Updates the current installation of uberdeploy on your machine
function update() {

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



function uninstall() {
	if input_confirm "Really?"; then
		echo 'Not implemented ;)'
	fi
}




function help() {

	cat ${SCRIPTPATH}/../lib/help.txt

	check_version_and_hint ${VERSION}
}



function displayLog() {
	detectProjectVariables $@
	displayRemoteLog ${PROJECTNAME} ${SSH_AUTHORITY}
}

