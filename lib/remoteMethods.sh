#!/bin/bash

source "${SCRIPTPATH}/../lib/remote/utils.sh";
source "${SCRIPTPATH}/../lib/remote/project.sh";

# Creates a project on remote server
# $1 - NAME 			// Name of project
# $2 - SSH_AUTHORITY 	// Authority to connect to remote via ssh
function createRemoteProject() {
	local NAME="${1}";
	local SSH_AUTHORITY="${2}";
	local flag__provision_remote="${3}";

	COMMAND="
		$(func2string \
			remote_project_installDependencies \
			remote_project_log \
			remote_project_create \
			remote_project_callActiveWorktreeDeployHandler \
			remote_project_readConfigFile \
			remote_project_setEnvVars \
			remote_project_createServiceFile \
			remote_project_checkoutWorktree \
			remote_project_writePostReceiveHook \
			remote_project_provision \
			remote_project_createBareRepo \
			remote_project_createTools \
			config_get_val \
			get_realpath \
			type_exists isDir isFile isString ifDirSetVar ifFileSetVar \
		)

		remote_project_setEnvVars '${NAME}'
		remote_project_create ${flag__provision_remote}

	";

	remote_execute "${SSH_AUTHORITY}" "${COMMAND}"
	return $?;

}






# Destroyes a project on remote server
# $1 - NAME 			// Name of project
# $2 - SSH_AUTHORITY 	// Authority to connect to remote via ssh
function destroyRemoteProject() {
	local NAME="${1}";
	local SSH_AUTHORITY="${2}";

	COMMAND="
		$(func2string \
			type_exists isDir isFile isString ifDirSetVar ifFileSetVar \
			remote_project_setEnvVars \
			remote_project_destroy \
		)
		remote_project_setEnvVars '${NAME}'
		remote_project_destroy
	";

	remote_execute "${SSH_AUTHORITY}" "${COMMAND}"
	return $?;
}









# Displays server log of given project
# $1 - NAME 			// Name of project
# $2 - SSH_AUTHORITY 	// Authority to connect to remote via ssh
function displayRemoteLog() {
	local NAME="${1}";
	local SSH_AUTHORITY="${2}";

	COMMAND="
		$(func2string \
			remote_project_setEnvVars \
			remote_project_displayLog \
			isFile \
			isString \
		)

		remote_project_setEnvVars \${HOME}'/Uberdeploy/${NAME}'
		remote_project_displayLog
	";

	remote_execute "${SSH_AUTHORITY}" "${COMMAND}"
	return $?;
}








