#!/bin/bash

CONFIGFILENAME=".${TOOLNAME}"
readConfigFile() {
	local CONFIGFILE="${PROJECTPATH}/${CONFIGFILENAME}"

	if [[ ! -n ${CONFIGFILECONTENT} ]]; then
		CONFIGFILECONTENT=$(cat ${CONFIGFILE})
	fi
	local CC=${CONFIGFILECONTENT}

	SSH_AUTHORITY=$(config_get_val "${CC}" SSH_AUTHORITY)
	WORKTREE=$(config_get_val "${CC}" WORKTREE)
	_CONFIG_RUN=$(config_get_val "${CC}" RUN)
}
saveConfigFile() {
	local CONFIGFILE="${PROJECTPATH}/${CONFIGFILENAME}"

	echo "SSH_AUTHORITY: ${SSH_AUTHORITY};" > ${CONFIGFILE}

	if [[ -n ${WORKTREE} ]]; then
		echo "WORKTREE: ${WORKTREE};" >> ${CONFIGFILE}
	fi

	if [[ -n ${_CONFIG_RUN} ]]; then
		echo "RUN: ${_CONFIG_RUN};" >> ${CONFIGFILE}
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



function config_get_val() {
	local CONFIG=${1};
	local KEY=${2};

	local REGEX='(?:'${KEY}'\[\s]*:\[\s]*)(.*);'
	local REGEX=${KEY}'[[:space:][:space:]]*:[[:space:]]*["]?(.[^";]*)["]?[[:space:]]*[;]'
	#echo $REGEX
	if [[ ${CONFIG} =~ ${REGEX} ]]; then
		echo ${BASH_REMATCH[1]}
	fi
}
