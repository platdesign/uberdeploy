#!/bin/bash

CONFIGFILENAME=".${TOOLNAME}"
function readConfigFile() {
	local CONFIGFILE="${PROJECTPATH}/${CONFIGFILENAME}"

	if [[ ! -n ${CONFIGFILECONTENT} && -e ${CONFIGFILE} ]]; then
		CONFIGFILECONTENT=$(cat ${CONFIGFILE})
	fi
	local CC=${CONFIGFILECONTENT}

	SSH_AUTHORITY=$(config_get_val "${CC}" SSH_AUTHORITY)
	WORKTREE=$(config_get_val "${CC}" WORKTREE)
	_CONFIG_RUN=$(config_get_val "${CC}" RUN)
}
function saveConfigFile() {
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

function detectProjectVariables() {

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




function input() {
	local RES;
	read -p "${1} " RES
	eval "${2}=${RES}"
}

function input_required() {
	local RES;
	while [[ ! ${RES} ]]; do
		read -p "${1} [required] " RES
	done
	eval "${2}=${RES}"
}

function input_default() {
	local RES;
	read -p "${1} (default: ${2}) " RES
	RES=${RES:-${2}}
	eval "${3}=${RES}"
}


function input_confirm() {

	while true; do
		read -p "${1} (y/n) " yn
		case ${yn} in
			[Yy]* ) return 0;;
			[Nn]* ) return 1;;
			* ) echo_notify "Decisions are not confusing; Doubt is... ;)";;
		esac
	done
}



function echo_notify() {
	echo ${1} | while read line; do
		echo -e "\033[33;32m${line}\033[0m";
	done
}
function echo_notify_white() {
	echo -e "\033[0m${1}\033[0m";
}

function echo_debug_note() {
	echo -e ${1} | while read line; do
		echo -e "\033[0m${line}\033[0m";
	done
}


function echo_error() {
	echo ${1} | while read line; do
		echo -e "\033[33;31m${line}\033[0m";
	done
}




function vercomp () {
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



function check_version() {
	RES=$(curl -s -H "Accept: application/json" https://api.github.com/repos/platdesign/${TOOLNAME}/tags?per_page=1);

	REGEX='"name":.*"([0-9A-Za-z]*\.[0-9A-Za-z]*\.[0-9A-Za-z]*)"'

	if [[ ${RES} =~ ${REGEX} ]]; then
		REMOTE_VERSION=${BASH_REMATCH[1]}

		vercomp ${1} ${REMOTE_VERSION}
		return $?
	fi

}

function check_version_and_hint() {

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



function func2string() {
	local FNAME=${1};
	echo -e "$(typeset -f ${FNAME})";
}



remote_execute() {

	local SEPERATOR='-------ENDOFREQUEST-------'

	local __RES;


	echo_notify "Connecting to '${1}'";
	__RES=$(
		exec 2>&1
		ssh "${1}" 'bash -s' <<--SSH-END
			#!/bin/sh

			$(func2string func2string)
			function request_response() {
				echo ${SEPERATOR}
				echo -e "\${RES_HEADER}"
			}
			function error() {
				request_response
				exit \$(( \${1} + 100 ));
			}
			function setHeader() {
				local FORMAT="\${1}:\"\${2}\";";

				RES_HEADER="\${RES_HEADER}\${FORMAT}";
			}
			# Execute given commands
			${2}

			# Send data to client
			request_response

		-SSH-END
	);
	__RESCODE=${?};


	if [ \( ${__RESCODE} -gt 0 \) -a \( ${__RESCODE} -lt 100 \) -o \( ${__RESCODE} -eq 255 \) ]; then
		echo_error "${__RES}"
		return 1;
	fi


	REMOTE_EXECUTE_BODY="${__RES%%${SEPERATOR}*}"
	REMOTE_EXECUTE_HEADER="${__RES##*${SEPERATOR}}"
	REMOTE_EXECUTE_STATUS=$?


	# Assign Body to variable if given
	if [[ -n ${3} ]]; then
		eval "${3}='${REMOTE_EXECUTE_BODY}'"
	fi

	# Assign Header to variable if given
	if [[ -n ${4} ]]; then
		eval "${4}='${REMOTE_EXECUTE_HEADER}'"
	fi

	if [[ -n ${REMOTE_EXECUTE_BODY} ]]; then
		echo -e "${REMOTE_EXECUTE_BODY}\c"
	fi

	return $__RESCODE;
}


function ifFileSetVar() {
	local FILE="${1}";
	if [ -e ${FILE} ];
		then
			eval "${2}='${3}'";
		else
			eval "${2}='${4}'";
	fi
}

function ifDirSetVar() {
	local FILE="${1}";
	if [ -d ${FILE} ];
		then
			eval "${2}='${3}'";
		else
			eval "${2}='${4}'";
	fi
}


function config_get_val() {
	local __CONF="${1}";
	local KEY=${2};

	local REGEX=${KEY}'[[:space:][:space:]]*:[[:space:]]*["]?(.[^";]*)["]?[[:space:]]*[;]'

	if [[ ${__CONF} =~ ${REGEX} ]]; then
		echo ${BASH_REMATCH[1]}
	fi
}


function dir_isEmpty() {
	if [ "$(ls -A $1)" ]; then
	     return 1;
	fi
}


function isDir() {
	[ -d $1 ];
}

function isFile() {
	[ -e ${1} ];
}







function installLatestVersionFromGithubToLibDir() {

	local LIB_DIR=${1};

	# Create temporary folder (LINUX and OSX supported)
	TMPDIR=`mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`;


	TMPTARFILE="${TMPDIR}/update.tar.gz"

	# Get the tarball
	echo_notify "Downloading..."
	if ! curl -fsSLo "${TMPTARFILE}" "${REPOSITORY}/tarball/master"; then
		echo_error "Download failed.";
		# Remove tmp-folder
		rm -rf "${TMPDIR}";
		return 1;
	fi


	# Clear content of lib dir
	if isFile "${LIB_DIR}/bin/uberdeploy.sh"; then
		rm -rf "${LIB_DIR}/*";
	fi

	# Extract tarball to directory
	echo_notify "Extracting files"
	tar -zxf "${TMPTARFILE}" --strip-components 1 -C "${LIB_DIR}"


	# Remove temporary folder
	rm -rf ${TMPDIR};
	return 0;
}





