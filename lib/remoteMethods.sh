#!/bin/bash


function createRemoteProject() {
	local NAME="${1}";
	local SSH_AUTHORITY="${2}";

	COMMAND="
		$(func2string remote_project_log)
		$(func2string remote_project_create)
		$(func2string remote_notify)
		$(func2string remote_error)
		$(func2string remote_project_callActiveWorktreeDeployHandler)
		$(func2string remote_project_readConfigFile)
		$(func2string remote_project_setEnvVars)
		$(func2string remote_project_createServiceFile)
		$(func2string remote_project_checkoutWorktree)
		$(func2string remote_project_writePostReceiveHook)
		$(func2string remote_project_createBareRepo)
		$(func2string config_get_val)
		$(func2string ifFileSetVar)
		$(func2string ifDirSetVar)


		remote_project_create ${NAME}

	";

	remote_execute "${SSH_AUTHORITY}" "${COMMAND}" BODY

	echo "$BODY"

}


function displayRemoteLog() {
	local NAME="${1}";
	local SSH_AUTHORITY="${2}";

	COMMAND="
		$(func2string remote_notify)
		$(func2string remote_error)
		$(func2string remote_project_setEnvVars)
		$(func2string remote_project_displayLog)

		remote_project_setEnvVars \${HOME}'/Uberdeploy/${NAME}'
		remote_project_displayLog
	";

	remote_execute "${SSH_AUTHORITY}" "${COMMAND}" BODY

	echo "$BODY"
}



function remote_project_displayLog() {

	remote_notify "Project-Log for '${PROJECT_NAME}'";
	cat "${PROJECT_PATH}/log" | tail -20 | while read line;
	do
		remote_notify "${line}"
	done

}



function remote_project_create() {
	local PROJECTNAME="${1}";
	remote_project_setEnvVars "${HOME}/Uberdeploy/${PROJECTNAME}"

	if [ -d ${PROJECT_PATH} ];
		then
			remote_error "Project already exists";
			error 1
		else

			# Create bare repo
			remote_project_createBareRepo "${PROJECT_BARE}"
			remote_project_log "Created"
	fi
}

function remote_project_reinitialize() {
	local PROJECTNAME="${1}";
	remote_project_setEnvVars "${HOME}/Uberdeploy/${PROJECTNAME}"

	# Create bare repo
	remote_project_createBareRepo "${PROJECT_BARE}"
}











function remote_project_createBareRepo() {

	local BARE="${1}";

	# Create bare repository
	remote_notify "$(git init --bare "${BARE}")"

	# If any errors occure while creating bare repo
	if [[ $? -ne 0 ]]; then
		remote_error "Couldn't create repository";
		error 1
	fi


	setHeader 'GIT_ORIGIN_PATH' "${BARE}";

	# Create post-receive-hook in bare-repo
	remote_project_writePostReceiveHook "${BARE}"

}




function remote_project_writePostReceiveHook() {
	local BARE="${1}"
	local FILE="${BARE}/hooks/post-receive";

	# Determine name of action for message
	ifFileSetVar "${FILE}" DONE_ACTION 'updated' 'created'


	# Write into file
	cat <<--EOT > ${FILE}
		#!/bin/sh

		# Utils
		$(func2string remote_project_log)
		$(func2string remote_notify)
		$(func2string remote_error)
		$(func2string remote_project_callActiveWorktreeDeployHandler)
		$(func2string remote_project_readConfigFile)
		$(func2string remote_project_setEnvVars)
		$(func2string remote_project_createServiceFile)
		$(func2string remote_project_checkoutWorktree)
		$(func2string config_get_val)
		$(func2string ifFileSetVar)
		$(func2string ifDirSetVar)


		SCRIPTPATH=\$( cd "\$( dirname "\${BASH_SOURCE[0]}" )" && pwd )

		# Set some project variables
		remote_project_setEnvVars "\${SCRIPTPATH%/*/*}"
		ACTIVE_WORKTREE="\${PROJECT_WORK}";


		# Create default workpath if not exists and checkout
		remote_project_checkoutWorktree "\${PROJECT_WORK}"

		# Load config
		remote_project_readConfigFile "\${PROJECT_CONFIG}" CONFIG

		# Checkout config-worktree if is given
		CONF_WORKTREE=\$(config_get_val "\${CONFIG}" 'WORKTREE')
		if [[ -n \${CONF_WORKTREE} ]]; then
			remote_project_checkoutWorktree "\${CONF_WORKTREE}"
			ACTIVE_WORKTREE="\${CONF_WORKTREE}"
		fi


		# Change to active worktree
		cd "\${ACTIVE_WORKTREE}"


		# Create Service file
		RUN=\$(config_get_val "\${CONFIG}" RUN)
		remote_project_createServiceFile "\${PROJECT_PATH}" "\${RUN}"


		# Call post-receive handler from deploy-folder if exists
		remote_project_callActiveWorktreeDeployHandler "\${PROJECT_PATH}" "\${ACTIVE_WORKTREE}" 'post-receive'

		remote_notify "Project '${PROJECT_NAME}' successfully uberdeployed =)"
		remote_project_log "Deployed"
	-EOT



	# Make FILE executable
	chmod +x ${FILE}

	# Notify about done work
	remote_notify "Post-Receive-Hook ${DONE_ACTION}";
}



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
	remote_notify "Worktree ${DONE_ACTION} at path: ${WORKPATH}";
}





function remote_project_createServiceFile() {
	local PROJECTPATH="${1}";
	local RUNCOMMAND="${2}";
	local SVCFILE="${PROJECTPATH}/service";

	if [[ -n ${RUNCOMMAND} ]];
		then
			echo "#!/bin/sh" > ${SVCFILE}
			echo "cd ${PWD}" >> ${SVCFILE}
			echo "exec ${RUNCOMMAND} 2>&1" >> ${SVCFILE}

			# Make FILE executable
			chmod +x ${SVCFILE}

			remote_notify "Servicehandler created: ${SVCFILE}"
		else
			# Remove service file if exists and no runcommand is given
			if [ -e ${SVCFILE} ]; then
				rm -f ${SVCFILE}
				remote_notify "Servicehandler removed: ${SVCFILE}"
			fi
	fi

}




function remote_project_setEnvVars() {
	PROJECT_PATH="${1}";

	PROJECT_NAME="${PROJECT_PATH##*/}";
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



function remote_project_callActiveWorktreeDeployHandler() {
	local PROJECTPATH="${1}";
	local WORKTREE="${2}";
	local HANDLER="${3}";


	local HANDLERPATH="${WORKTREE}/deploy/${HANDLER}"

	if [ -e "${HANDLERPATH}" ]; then
		cd "${PROJECTPATH}"
		remote_notify "deploy/${HANDLER}"
		source "${HANDLERPATH}"
	fi
}



function remote_notify() {
	echo -e "\033[33;36m----> ${1}\033[0m";
}
function remote_error() {
	remote_notify "\033[33;31m${1}";
}


function remote_project_log() {
	local FILE="${PROJECT_PATH}/log";
	local MESSAGE=${1};

	if [ -d ${PROJECT_PATH} ]; then

		echo -e "`date`	-  ${MESSAGE}" >> ${FILE}

	fi

}
