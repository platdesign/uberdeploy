#!/bin/bash

function git_anyUntrackedFiles() {
	[ `git status --porcelain 2>/dev/null| grep "^??" | wc -l` -gt 0 ]
}

function git_anyChanges() {
	[[ -n $(git status --porcelain) ]]
}

#function isGitRepo() {
#	[ -d "${1}/.git" ];
#}

function git_push() {
	local REMOTENAME=${1};

	echo_notify "Pushing to ${REMOTENAME}...";

	git push "${REMOTENAME}" master --progress --porcelain 2>&1 | while read line; do
		echo $line | grep '^remote:' | sed -n -e 's/^remote: //p' | echo_remote_notify;
		echo $line | grep -Ev "remote:|ssh:|refs|^Done"
	done | echo_notify

	return ${PIPESTATUS[0]};
}

function isGitRepo() {
	isDir "${1}/.git"
}
