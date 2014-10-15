#!/bin/bash


# Displays log file of active project
function remote_project_displayLog() {
	echo_notify "Project-Log for '${PROJECT_NAME}'";
	cat "${PROJECT_PATH}/log" | tail -20 | echo_notify;
}



# Creates a new project or provisions an existing one
# $1 - provision 	// provision-remote flag from input
function remote_project_create() {
	local provision="${1}";

	if isDir "${PROJECT_PATH}";
		then
			if [[ ! $provision ]]; then
				echo_error "Project already exists";
				error 1
			else
				remote_project_provision
				remote_project_log "Provisioned"

				# Notify
				echo_notify "Project '${PROJECT_NAME}' created on remote"
			fi
		else
			# Create new repo
			remote_project_provision
			remote_project_log "Created"

			# Notify
			echo_notify "Project '${PROJECT_NAME}' created on remote"
	fi
}




# Provisions a project
function remote_project_provision() {

	mkdir -p "${PROJECT_PATH}";

	# Create tools file
	remote_project_createTools;

	# Create bare repo
	remote_project_createBareRepo "${PROJECT_BARE}"

	# Create post-receive-hook in bare-repo
	remote_project_writePostReceiveHook "${BARE}"

	# Notify
	echo_notify "Project '${PROJECT_NAME}' reinitialized on remote"
}


function remote_project_createTools() {

	local TOOLFILE="${PROJECT_PATH}/tools.sh";

	# Write into file
	cat <<--EOT > ${TOOLFILE}
		#!/bin/bash

		# Utils
		$(func2string \
			type_exists isDir isFile isString ifDirSetVar ifFileSetVar \
			remote_project_installDependencies \
			remote_project_log \
			echo_error \
			remote_notify \
			echo_notify \
			remote_project_callActiveWorktreeDeployHandler \
			remote_project_readConfigFile \
			remote_project_setEnvVars \
			remote_project_createServiceFile \
			remote_project_checkoutWorktree \
			config_get_val \
			get_realpath \
		)

		if isFile '/etc/profile'; then
			source '/etc/profile'
		fi

		if isFile "${HOME}/.bash_profile"; then
			source "${HOME}/.bash_profile"
		fi


	-EOT

	# Make FILE executable
	chmod +x ${TOOLFILE}
}


# Removes a project from remote
function remote_project_destroy() {

	if isString "${PROJECT_NAME}";
		then
			if isDir "${PROJECT_PATH}";
				then
					rm -rf "${PROJECT_PATH}";

					# Notify
					echo_notify "Project '${PROJECT_NAME}' removed";
				else
					echo_error "Project not found";
					error 1
			fi
		else
			echo_error "Project not found";
			error 1
	fi
}






# Creates the bare repo
function remote_project_createBareRepo() {

	local BARE="${1}";

	# Create bare repository
	echo_notify "$(git init --bare "${BARE}")"

	# If any errors occure while creating bare repo
	if [[ $? -ne 0 ]]; then
		echo_error "Couldn't create repository";
		error 1
	fi

	# Add GIT_ORIGIN_PATH to response headers
	setHeader 'GIT_ORIGIN_PATH' "${BARE}";
}



# Creates a post-receive hook file in a given project
function remote_project_writePostReceiveHook() {

	local FILE="${PROJECT_BARE}/hooks/post-receive";

	# Determine name of action for message
	ifFileSetVar "${FILE}" DONE_ACTION 'updated' 'created'


	# Write into file
	cat <<--EOT > ${FILE}
		#!/bin/bash

		SCRIPTPATH="\${PWD}/\${0%/*}";
		PROJECT_PATH="\${SCRIPTPATH%/*/*}";

		# Load tools
		if [ -e "\${PROJECT_PATH}/tools.sh" ]; then
			source "\${PROJECT_PATH}/tools.sh";
		else
			echo "Can't find tolls. Please --provision-remote to fix it.";
			error 1;
		fi

		# Set some project variables
		remote_project_setEnvVars "\${PROJECT_PATH##*/}";
		ACTIVE_WORKTREE="\${PROJECT_WORK}";

		# Create default workpath if not exists and checkout
		remote_project_checkoutWorktree "\${PROJECT_WORK}"

		# Load config
		remote_project_readConfigFile "\${PROJECT_CONFIG}" CONFIG

		# Checkout config-worktree if is given
		CONF_WORKTREE="\$(config_get_val "\${CONFIG}" 'WORKTREE')";
		if [[ -n \${CONF_WORKTREE} ]]; then
			remote_project_checkoutWorktree "\${CONF_WORKTREE}"
			ACTIVE_WORKTREE="\${CONF_WORKTREE}"
		fi


		# Change to active worktree
		cd "\${ACTIVE_WORKTREE}"


		# Create Service file
		RUN=\$(config_get_val "\${CONFIG}" RUN)
		remote_project_createServiceFile "\${PROJECT_PATH}" "\${RUN}"


		# Install dependencies
		remote_project_installDependencies "\${ACTIVE_WORKTREE}"


		# Call post-receive handler from deploy-folder if exists
		remote_project_callActiveWorktreeDeployHandler "\${PROJECT_PATH}" "\${ACTIVE_WORKTREE}" 'post-receive'


		echo_notify "Post Hook successfully fired"
		remote_project_log "Deployed"
	-EOT



	# Make FILE executable
	chmod +x ${FILE}

	# Notify about done work
	echo_notify "Post-Receive-Hook ${DONE_ACTION}";
}


# Checksout a given worktree
# $1 - WORKPATH 	// Path to folder where the worktree should be located
function remote_project_checkoutWorktree() {
	local WORKPATH="${1}";

	# Determine name of action for message
	ifDirSetVar "${WORKPATH}" DONE_ACTION 'updated' 'created'

	mkdir -p "${WORKPATH}"
	# unset GIT_INDEX_FILE
	export GIT_WORK_TREE="${WORKPATH}/"
	# export GIT_DIR="${BARE}/"
	git checkout -f

	# Notify about done work
	echo_notify "Worktree ${DONE_ACTION} at path: ${WORKPATH}";
}




# Creates Service file as a helper for system-daemon-services
# $1 - PROJECTPATH 	// Path to project
# $2 - RUNCOMMAND 	// Command wich starts the daemon
function remote_project_createServiceFile() {
	local PROJECTPATH="${1}";
	local RUNCOMMAND="${2}";
	local SVCFILE="${PROJECTPATH}/service"; # Change this to global projectEnvDefinition of service-file-path

	if [[ -n ${RUNCOMMAND} ]];
		then
			echo "#!/bin/sh" > ${SVCFILE}
			echo "cd ${PWD}" >> ${SVCFILE}
			echo "exec ${RUNCOMMAND} 2>&1" >> ${SVCFILE}

			# Make FILE executable
			chmod +x ${SVCFILE}

			echo_notify "Servicehandler created: ${SVCFILE}"
		else
			# Remove service file if exists and no runcommand is given
			if [ -e ${SVCFILE} ]; then
				rm -f ${SVCFILE}
				echo_notify "Servicehandler removed: ${SVCFILE}"
			fi
	fi
}







function remote_project_setEnvVars() {
	PROJECT_NAME="${1}";
	PROJECT_PATH="${HOME}/Uberdeploy/${1}";
	PROJECT_BARE="${PROJECT_PATH}/bare.git";
	PROJECT_WORK="${PROJECT_PATH}/work";
	PROJECT_SERVICE="${PROJECT_PATH}/service";
	PROJECT_CONFIG="${PROJECT_WORK}/.uberdeploy";
}







function remote_project_readConfigFile() {
	local FILE=${1};
	local _CONFIG;

	if [ -e ${FILE} ]; then

		# Read config string from file
		_CONFIG="$(cat ${FILE})";

		# Attach config string to second parameter
		eval "${2}='${_CONFIG}'";

	fi
}



# Executes a deploy hook file from projects worktree
# $1 - PROJECTPATH		// Path to project
# $2 - WORKTREE 		// Path to active worktree
# $3 - HANDLER 			// Name of the handler (e.g. post-receive)
function remote_project_callActiveWorktreeDeployHandler() {
	local PROJECTPATH="${1}";
	local WORKTREE="${2}";
	local HANDLER="${3}";


	local HANDLERFILE="${WORKTREE}/deploy/${HANDLER}"

	if isFile "${HANDLERFILE}"; then
		(
			cd "${WORKTREE}/deploy";
			echo_notify "Executing 'deploy/${HANDLER}'"
			source "${HANDLERFILE}"
		) | echo_notify
	fi

}







# Install dependencies of a project
# $1 - WORKPATH   // path to active worktree where to install dependecies
function remote_project_installDependencies() {
	local WORKPATH="${1}";

	(
		cd "${WORKPATH}";

		# NPM
		if isFile "${WORKPATH}/package.json"; then
			if type_exists 'npm'; then

				# Notify what i'm doing
				echo_notify "Installing nodejs dependecies...";

				# remove existing node_modules folder
				if isDir "${WORKPATH}/node_modules"; then
					rm -rf "${WORKPATH}/node_modules";
				fi

				# Install dependencies
				npm install --production | while read line; do
					echo "\033[0m$line";
				done | echo_notify;

				# Notify about status
				if [ ${PIPESTATUS[0]} -eq 0 ]; then
					echo_notify "Dependencies (nodejs) installed.";
				else
					echo_error "Error while installing nodejs dependencies";
				fi
			fi
		fi


		# Bower
		if isFile "${WORKPATH}/bower.json"; then
			if type_exists 'bower'; then

				# Notify what i'm doing
				echo_notify "Installing bower dependecies...";

				local BOWER_DIRECTORY='bower_components';

				if isFile "${WORKPATH}/.bowerrc"; then
					local _BOWER_DIRECTORY=$(cat "${WORKPATH}/.bowerrc" | grep directory | sed 's/\"directory\".*:.*\"\(.*\)\"/\1/' | tr -d ' ');

					if isString "${_BOWER_DIRECTORY}"; then
						BOWER_DIRECTORY="${_BOWER_DIRECTORY}";
					fi
				fi

				# remove existing bower modules
				if isDir "${WORKPATH}/${BOWER_DIRECTORY}"; then
					rm -rf "${WORKPATH}/${BOWER_DIRECTORY}";
				fi


				# Install dependencies
				bower install --production | while read line; do
					echo "\033[0m$line";
				done | echo_notify;


				# Notify about status
				if [ ${PIPESTATUS[0]} -eq 0 ]; then
					echo_notify "Dependencies (bower) installed.";
				else
					echo_error "Error while installing bower dependencies";
				fi
			fi
		fi
	)
}




# Adds a log entry to a projects remote log
# $1 - PROJECT_PATH		// Path to project
function remote_project_log() {
	local FILE="${PROJECT_PATH}/log";
	local MESSAGE=${1};

	if [ -d ${PROJECT_PATH} ]; then

		echo -e "`date`	-  ${MESSAGE}" >> ${FILE}

	fi
}
