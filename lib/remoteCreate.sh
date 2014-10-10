#!/bin/sh

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

	if [ -e ${WORKPATH}/deploy/post-receive ]
	then
		sh ${WORKPATH}/deploy/post-receive
	fi
EOT

# Make post-receive hook executable
chmod +x ${POST_RECEIVE}






echo '----END----'${BAREPATH}
