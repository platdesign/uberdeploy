#!/bin/bash

git_anyUntrackedFiles() {
	[ `git status --porcelain 2>/dev/null| grep "^??" | wc -l` -gt 0 ]
}

git_anyChanges() {
	[[ -n $(git status --porcelain) ]]
}

