#!/bin/sh


SSHCALL_SUCCESS=true

sshcall_error() {
	SSHCALL_SUCCESS=false
	SSHCALL_MESSAGE="${1}"
	sshcall_respond
	exit 1;
}


sshcall_respond() {
	echo "----END----"
	echo "SSHCALL_SUCCESS=${SSHCALL_SUCCESS};"
	echo "SSHCALL_MESSAGE='${SSHCALL_MESSAGE}';"
	echo "GIT_ORIGIN_PATH='${BAREPATH}';"
}


# Get the name of the project from first given argument
PROJECTNAME="${1}"

# Place to store all deployed projects
STORE="${HOME}/Uberdeploy"

# Path to project
PROJECTPATH="${STORE}/${PROJECTNAME}"

# Path to projects bare repository
BAREPATH="${PROJECTPATH}/bare.git"

# Path to projects work directory (from input or default)
WORKPATH=${2:-${PROJECTPATH}/work}

# Path to post-receive hook file
POST_RECEIVE="${BAREPATH}/hooks/post-receive"


if [ -d ${PROJECTPATH} ];
	then
		sshcall_error "Project already exists"
	else

		# Create bare repository
		git init --bare ${BAREPATH}

		# Create work directory
		mkdir -p ${WORKPATH}

		# Create post-receive hook file in bare repository
		cat <<EOT > ${POST_RECEIVE}
			#!/bin/sh
			#echo -e "\n-------------- POST RECEIVE -------------------"
			mkdir -p ${WORKPATH}
			unset GIT_INDEX_FILE
			export GIT_WORK_TREE=${WORKPATH}/
			export GIT_DIR=${BAREPATH}/
			git checkout -f


			# If Workpath changed
			if [ -e ${WORKPATH}/.uberdeploy ]
			then
				source ${WORKPATH}/.uberdeploy

				if [[ -n \${REMOTE_WORKPATH} ]]; then
					mkdir -p \${REMOTE_WORKPATH}
					export GIT_WORK_TREE=\${REMOTE_WORKPATH}/
					export GIT_DIR=${BAREPATH}/
					git checkout -f
					WORKPATH=\${REMOTE_WORKPATH}
				fi
			fi


			cd ${WORKPATH}
			if [ -e ${WORKPATH}/deploy/post-receive ]
			then
				sh ${WORKPATH}/deploy/post-receive
			fi
EOT

		# Make post-receive hook executable
		chmod +x ${POST_RECEIVE}

fi


sshcall_respond


