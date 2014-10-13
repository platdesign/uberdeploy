#!/bin/sh

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
