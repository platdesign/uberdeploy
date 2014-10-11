#!/bin/bash

CONFIGFILENAME=".${TOOLNAME}"
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


# Default variables
GIT_ORIGIN_NAME=${TOOLNAME};

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


input_confirm() {
	read -p "${1} (y/n) " -n 1 -r RES
	echo
	if [[ ${RES} =~ ^[Yy]$ ]]
		then
			return 0
		else
			return 1
	fi
}

echo_error() {
	echo "$(tput setaf 1)Error: $(tput sgr 0)${1}";
}




vercomp () {
    if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}



check_version() {
	RES=$(curl -s -H "Accept: application/json" https://api.github.com/repos/platdesign/${TOOLNAME}/tags?per_page=1);

	REGEX='"name":.*"([0-9]\.[0-9]\.[0-9])"'

	if [[ ${RES} =~ ${REGEX} ]]; then
		REMOTE_VERSION=${BASH_REMATCH[1]}

		vercomp ${1} ${REMOTE_VERSION}
		return $?
	fi

}

check_version_and_hint() {

	check_version ${1};	STATUS=$?

	case ${STATUS} in
		0) echo ;;
		1) echo "YEAH! Your version is from the future! ;)";;
		2)
			echo
			echo "------------------------------------"
			echo " $(tput setaf 6)New version available! $(tput sgr 0)(${REMOTE_VERSION})"
			echo " $(tput dim)Update with: $(tput sgr 0)${TOOLNAME} update"
			echo "------------------------------------"
		;;

	esac
}
