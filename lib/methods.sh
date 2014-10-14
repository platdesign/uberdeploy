#!/bin/bash

source ${SCRIPTPATH}/../lib/githelper.sh
source ${SCRIPTPATH}/../lib/utils.sh
source ${SCRIPTPATH}/../lib/remoteMethods.sh

source ${SCRIPTPATH}/../lib/local.sh

# Initialize a project locally only
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


	# Create config-file if not exists
	if ! isFile ${PROJECT_CONFIG}; then
		echo "" > ${PROJECT_CONFIG};
		echo_notify "Config created."
	fi


	# Create deploy folder if not exists
	if ! isDir "${PROJECT_PATH}/deploy"; then
		mkdir -p "${PROJECT_PATH}/deploy";
		echo_notify "Deploy folder created."
	fi


	# Create post-receive hook if not exists
	if ! isFile "${PROJECT_PATH}/deploy/post-receive"; then
		echo "#!/bin/bash" > "${PROJECT_PATH}/deploy/post-receive"
		echo_notify "Added hook: deploy/post-receive"
	fi


	# Notify
	echo_notify "Project '${PROJECT_NAME}' successfully initialized.";
}



# Initialize a project locally and on remote
# This should be used when starting a new empty project
function create() {

	# Call init with same paramters
	init $@

	# Collect project variables (config,git-config)
	project_collectProjectVars ${PROJECT_PATH};


	# Ask for PROJECT_SSH_AUTHORITY if necessary
	if ! project_ensureVars 'SSH_AUTHORITY'; then
		input_required "SSH authority (e.g. user@server.uberspace.de) " PROJECT_SSH_AUTHORITY
	fi

	# Create remote repository
	if ! createRemoteProject ${PROJECT_NAME} ${PROJECT_SSH_AUTHORITY}; then
		echo_error 'Remote repository could not be created. Maybe you can join it.';
		exit 1;
	fi

	local GIT_ORIGIN_URL="ssh://${PROJECT_SSH_AUTHORITY}"$(config_get_val "$REMOTE_EXECUTE_HEADER" 'GIT_ORIGIN_PATH');

	# Change PWD to PROJECT_PATH
	cd ${PROJECT_PATH}

	# Add remote to git repository
	if ! git remote | grep ${GIT_ORIGIN_NAME} > /dev/null; then
		git remote add ${GIT_ORIGIN_NAME} ${GIT_ORIGIN_URL}
		echo_notify "Added remote '${GIT_ORIGIN_NAME}' to repository"
		echo_notify_white "URL: ${GIT_ORIGIN_URL}"
	fi

	# Notify
	echo_notify "Project '${PROJECT_NAME}' successfully created.";
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
		project_collectProjectVars ${PROJECT_PATH};


		# If PROJECT_SSH_AUTHORITY is set
		if project_ensureVars 'NAME' 'SSH_AUTHORITY'; then

			# Let the user confirm what he is doing ;)
			if input_confirm "Remove project from remote '${PROJECT_GIT_REMOTE_NAME}'?"; then

				# Destroy the remote project
				if ! destroyRemoteProject "${PROJECT_NAME}" "${PROJECT_SSH_AUTHORITY}"; then
					echo_error "Remote repository couldn't be destroyed.";
				else
					# Remove remote from git repository
					git remote rm "${PROJECT_GIT_REMOTE_NAME}";
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

		echo_error "Project not found. Move to a projects folder.";

	fi
}


# Deploy from a projects folder
function deploy() {

	if calledFromProjectPath; then

		# Set project variables
		project_setProjectVars ${PWD};

		# Collect project variables (config,git-config)
		project_collectProjectVars ${PROJECT_PATH};

		local _COMMIT_MESSAGE="Deploy by ${USER} from ${HOSTNAME}"

		# If repository has uncomitted files
		if git_anyChanges; then
			if input_confirm "Commit changes?"; then
				git add --all
				git commit --quiet -m "${_COMMIT_MESSAGE}"
				echo_notify "Committed: ${_COMMIT_MESSAGE}"
			fi
		else
			if input_confirm "No changes. Create empty commit?"; then
				git add --all
				git commit --allow-empty -q -m "${_COMMIT_MESSAGE}" 2>&1
				echo_notify "Committed: ${_COMMIT_MESSAGE}"
			fi
		fi

		echo_notify "Pushing to ${PROJECT_GIT_REMOTE_NAME}"

		# Push to remote
		RES=$(git push --porcelain "${PROJECT_GIT_REMOTE_NAME}" master 2>&1);
		RES_CODE=$?;

		echo "$RES" | while read line; do
			REMOTE=$( echo `echo $line | grep remote` | sed -n -e 's/^.*remote: //p' )
			if [[ -n ${REMOTE} ]]; then
				echo -e "$REMOTE";
			fi
		done


		if [[ ${RES_CODE} -eq 0 ]]; then
			echo_notify "Project '${PROJECT_NAME}' successfully uberdeployed =)"
		else
			case ${RES_CODE} in
				128)
					echo_error "Remote repository does not appear to exist.";
					echo_debug_note "You could create it with:\nuberdeploy create";
				;;
				*) echo_error "$RES" ;;
			esac

		fi

	else
		echo_error "Project not found. Move to a projects folder.";
	fi
}


# Display remote log of project
function displayLog() {
	if calledFromProjectPath; then

		# Set project variables
		project_setProjectVars ${PWD};

		# Collect project variables (config,git-config)
		project_collectProjectVars ${PROJECT_PATH};

		if project_ensureVars 'NAME' 'SSH_AUTHORITY'; then
			displayRemoteLog "${PROJECT_NAME}" "${PROJECT_SSH_AUTHORITY}";
		fi

	else
		echo_error "Project not found. Move to a projects folder.";
	fi
}


# Display help/man page
function help() {
	echo_notify "${TOOLNAME}";
	cat ${SCRIPTPATH}/../lib/help.txt
	check_version_and_hint ${VERSION}
}










# Updates the current installation of uberdeploy on your machine
function update() {

	check_version ${VERSION};	STATUS=$?

	case ${STATUS} in
		0) echo_notify "Already latest version" ;;
		2)
			local LIB_DIR="${SCRIPTPATH%/*}"

			if [ -e "${LIB_DIR}/bin/uberdeploy.sh" ]; then

				if ! installLatestVersionFromGithubToLibDir ${LIB_DIR}; then
					echo_error "Update failed.";
					exit 1;
				fi

				echo_notify "Successfully updated =)";
			fi

		;;

	esac
}



function uninstall() {
	if input_confirm "Really?"; then
		echo 'Not implemented ;)'
	fi
}


# Clone an existing repository to your local machine
function join() {
	echo_error "Not implemented yet =)"
}








