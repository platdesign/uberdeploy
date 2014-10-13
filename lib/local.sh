#!/bin/sh



function calledFromProjectPath() {
	[ -e "${PWD}/.uberdeploy" ]
}






function project_setProjectVars() {

	PROJECT_PATH="${1}";
	PROJECT_NAME="${PROJECT_PATH##*/}";
	PROJECT_CONFIG="${PROJECT_PATH}/.uberdeploy";

	PROJECT_GIT_REMOTE_URL="$(git config --get "remote.${GIT_ORIGIN_NAME}.url")";

	if [[ -n ${PROJECT_GIT_REMOTE_URL} ]]; then
		PROJECT_SSH_AUTHORITY=$(echo $GIT_REMOTE_URL | sed 's/.*:\/\/\([0-9A-Za-z\-\_\.]*\)\/.*/\1/')
	fi

}

function project_collectProjectVars() {

	# Try to find SSH_AUTHORITY
	RES="$(git config --get "remote.${GIT_ORIGIN_NAME}.url")";
	if [[ -n ${RES} ]]; then

		PROJECT_GIT_REMOTE_URL="${RES}";

		PROJECT_SSH_AUTHORITY="$(echo ${RES} | sed 's/.*:\/\/\([0-9A-Za-z\-\_\.]*\)\/.*/\1/')";
	fi


}


function project_varsSet() {
	for varname in $@; do
		V="PROJECT_${varname}"

		if [[ ! -n ${!V} ]]; then
			return 1;
		fi
	done
	return 0;
}
