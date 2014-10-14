#!/bin/sh

function project_exists() {
	[ \( -e "${1}/.uberdeploy" \) -a \( -e "${1}/.git" \) ];
}

function calledFromProjectPath() {
	project_exists ${PWD};
}







function project_setProjectVars() {

	PROJECT_PATH="${1}";
	PROJECT_NAME="${PROJECT_PATH##*/}";
	PROJECT_CONFIG="${PROJECT_PATH}/.uberdeploy";

}

function project_collectProjectVars() {

	if isFile ${PROJECT_CONFIG}; then
		# load config file-content
		PROJECT_CONFIG_CONTENT=`cat ${PROJECT_CONFIG}`;

		# Assign PROJECT_GIT_REMOTE_NAME
		project_loadConfigVar GIT_REMOTE_NAME
	fi

	# Try to find SSH_AUTHORITY
	RES="$(cd ${PROJECT_PATH} && git config --get "remote.${PROJECT_GIT_REMOTE_NAME}.url")";
	if [[ -n ${RES} ]]; then

		PROJECT_GIT_REMOTE_URL="${RES}";

		PROJECT_SSH_AUTHORITY="$(echo ${RES} | sed 's/.*:\/\/\([@0-9A-Za-z\-\_\.]*\)\/.*/\1/')";
	fi
}


function project_ensureVars() {
	for varname in $@; do
		V="PROJECT_${varname}"

		if [[ ! -n ${!V} ]]; then
			return 1;
		fi
	done
	return 0;
}




function project_loadConfigVar() {
	local _VAL=$(config_get_val "${PROJECT_CONFIG_CONTENT}" "${1}")
	local _NAME="PROJECT_${1}";

	if [[ -n "${2}" ]]; then
		local _NAME=${2};
	fi

	if [[ -n ${_VAL} ]]; then
		eval "${_NAME}='${_VAL}'";
		return 0;
	else
		return 1;
	fi
}
