#!/bin/bash


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

function type_exists() {
	isString $(type -t ${1})
}








function echo_notify() {
	if isString $1; then
		echo -e "\033[33;32m${1}\033[0m";
		return 0;
	fi

	while read -r line; do
		${FUNCNAME[0]} "$line";
	done
}


function echo_error() {
	if isString $1; then
		echo -e "\033[33;31m${1}\033[0m";
		return 0;
	fi

	while read -r line; do
		${FUNCNAME[0]} "$line";
	done
}


function echo_remote_notify() {
	if isString $1; then
		echo -e "\033[33;33m───➤  ${1}\033[0m";
		return 0;
	fi

	while read -r line; do
		${FUNCNAME[0]} "$line";
	done
}

function echo_remote_error() {
	if isString $1; then
		echo -e "\033[33;31m───➤  ${1}\033[0m";
		return 0;
	fi

	while read -r line; do
		${FUNCNAME[0]} "$line";
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
	for FNAME in $@; do
		echo -e "$(typeset -f ${FNAME})";
	done
}



function remote_execute() {

	local __HEADERSFILE=$(mktemp 2>/dev/null || mktemp -t 'mytmpdir');

	( ssh "${1}" 'bash -s' <<--SSH-END
			#!/usr/bin/env bash
			exec 2>&1

			$(func2string func2string echo_error remote_notify)

			function echo_notify() {
				remote_notify "\$@";
			}

			function error() {
				exit \$(( \${1} + 100 ));
			}
			function setHeader() {
				local FORMAT="\${1}:\"\${2}\";";

				echo "[HEADER:\${RES_HEADER}\${FORMAT}]";
			}

			# Execute given commands
			${2}

		-SSH-END

	) | while read line; do

		local REGEX='\[HEADER:(.*)\]'

		if [[ ${line} =~ ${REGEX} ]]; then
			echo ${BASH_REMATCH[1]} >> "${__HEADERSFILE}";
		else
			echo $line
		fi

	done | echo_remote_notify;

	local __RESCODE=${PIPESTATUS[0]};


	REMOTE_EXECUTE_HEADER="$(cat "${__HEADERSFILE}")";
	rm $__HEADERSFILE;

	if [ \( ${__RESCODE} -gt 0 \) -a \( ${__RESCODE} -lt 100 \) -o \( ${__RESCODE} -eq 255 \) ]; then
		echo_error "${__RES}"
		return 1;
	fi

	# Assign Header to variable if given
	if [[ -n ${3} ]]; then
		eval "${3}='${REMOTE_EXECUTE_HEADER}'"
	fi

	return ${__RESCODE};
}




function ifFileSetVar() {
	if isFile "${1}"; then
		eval "${2}='${3}'";
	else
		eval "${2}='${4}'";
	fi
}

function ifDirSetVar() {
	if isDir "${1}"; then
		eval "${2}='${3}'";
	else
		eval "${2}='${4}'";
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

function isString() {
	[[ -n ${1} ]];
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





