#!/bin/bash


function remote_notify() {
	if isString $1; then
		echo -e "\033[33;36m${1}\033[0m";
		return 0;
	fi

	while read -r line; do
		${FUNCNAME[0]} "$line";
	done
}
