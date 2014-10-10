#!/bin/bash


input() {
	while [[ ! ${INPUT} ]]; do
		read -p ${1} INPUT
	done

	${2}=${INPUT}
}

create() {
	if [ ! ${1} ]
		then
			PROJECTNAME="${PWD##*/}"
			PROJECTPATH="${PWD}"
		else
			PROJECTNAME="${1}"
			PROJECTPATH="${PWD}/${PROJECTNAME}"
	fi


	# Ask for authority-uri
	read -p "Uberspace authority (e.g.) user@server.uberspace.de) " UBER_AUTHORITY
	if [ ! ${UBER_AUTHORITY} ]; then exit 1; fi

	# Ask for custom work directory path
	read -p "Path to work directory (empty for default) " WORKPATH

	# Execute the remoteCreate.sh on the server
	RESULT=$(ssh ${UBER_AUTHORITY} 'bash -s' < ${SCRIPTPATH}/../lib/remoteCreate.sh ${PROJECTNAME} ${WORKPATH})

	echo ${RESULT%%----END----*}

	ORIGIN_URL="ssh://${UBER_AUTHORITY}${RESULT##*----END----}"



	# Create Repository local if not exists
	if [ -d ${PROJECTPATH}/.git ]
		then
			cd ${PROJECTPATH}
			if ! git remote | grep uberspace > /dev/null; then
				git remote add uberspace ${ORIGIN_URL}
			fi

		else
			git clone ${ORIGIN_URL} ${PROJECTPATH}
			cd ${PROJECTPATH}
			if ! git remote | grep uberspace > /dev/null; then
				git remote add uberspace ${ORIGIN_URL}
			fi
	fi


	if [ ! -d "deploy" ]; then
		mkdir "deploy"
	fi

	if [ ! -e "deploy/post-receive" ]; then
		echo "#!/bin/bash" > deploy/post-receive
	fi
}



destroy() {
	echo 'Destroy...' $@
}



deploy() {
	if [ ! ${1} ]; then
		echo 'Missing commit message!'
		exit 1;
	fi

	git add --all
	git commit -m "${1}"
	git push uberspace master
}
