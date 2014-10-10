#!/bin/bash

CONFIGFILENAME='.uberdeploy'
readConfigFile() {
	local CONFIGFILE="${PROJECTPATH}/${CONFIGFILENAME}"
	if [[ -e ${CONFIGFILE} ]]; then
		source ${CONFIGFILE}
	fi
}
saveConfigFile() {
	local CONFIGFILE="${PROJECTPATH}/${CONFIGFILENAME}"

	echo "#Config" > ${CONFIGFILE}
	echo "SSH_AUTHORITY='${SSH_AUTHORITY}';" >> ${CONFIGFILE}

	if [[ -n ${REMOTE_WORKPATH} ]]; then
		echo "REMOTE_WORKPATH='${REMOTE_WORKPATH}';" >> ${CONFIGFILE}
	fi

}


detectProjectVariables() {

	# Detect project name
	if [[ -n ${1} ]]
		then
			PROJECTPATH="${PWD}/${1}"
			PROJECTNAME="${1}"
		else
			PROJECTPATH="${PWD}"
			PROJECTNAME="${PWD##*/}"
	fi

	# Store variables in temp-variables to prevent that they will be overwritten by config-file
	local _PROJECTPATH=${PROJECTPATH}
	local _PROJECTNAME=${PROJECTNAME}

	# Read the config file of the project
	readConfigFile

	# Set the temporary variables to the real ones back
	PROJECTPATH=${_PROJECTPATH}
	PROJECTNAME=${_PROJECTNAME}


	# Set variables with default values
	GIT_ORIGIN_NAME=${GIT_ORIGIN_NAME:='uberspace'}

	# Ask for SSH_AUTHORITY if necessary
	if [[ ! -n ${SSH_AUTHORITY} ]];
		then input_required "SSH authority (e.g. user@server.uberspace.de) " SSH_AUTHORITY
	fi

}




input() {
	local RES;
	read -p "${1} " RES
	eval "${2}=${RES}"
}

input_required() {
	local RES;
	while [[ ! ${RES} ]]; do
		read -p "${1} [required] " RES
	done
	eval "${2}=${RES}"
}

input_default() {
	local RES;
	read -p "${1} (default: ${2}) " RES
	RES=${RES:-${2}}
	eval "${3}=${RES}"
}
