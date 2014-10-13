#!/bin/sh



# Get the name of the project from first given argument
PROJECTNAME="${1}"

# Place to store all deployed projects
STORE="${HOME}/Uberdeploy"

# Path to project
PROJECTPATH="${STORE}/${PROJECTNAME}"

# Path to projects bare repository
BAREPATH="${PROJECTPATH}/bare.git"






#########################################################
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
#########################################################



create_hook_postReceive() {
	local BARE="${1}"
	local FILE="${BARE}/hooks/post-receive";

	cat <<--EOT > ${FILE}
	#!/bin/sh

	SCRIPTPATH=\$( cd "\$( dirname "\${BASH_SOURCE[0]}" )" && pwd )
	BARE=\${SCRIPTPATH%/*}
	PROJECTPATH=\${BARE%/*}
	WORK=\${PROJECTPATH}/work


	checkout_worktree() {
		local WORKPATH=\${1};
		mkdir -p \${WORKPATH}
		unset GIT_INDEX_FILE
		export GIT_WORK_TREE=\${WORKPATH}/
		export GIT_DIR=\${BARE}/
		git checkout -f
	}

	handle_config() {
		local CONFIG=\${1}
		source \${CONFIG}

		if [[ -n \${WORKTREE} ]]; then
			mkdir -p \${WORKTREE}

			if [ -d \${WORKTREE} ]; then
				checkout_worktree \${WORKTREE}
			fi
		fi
	}

	config_get_val() {
		local CONFIG=\${1};
		local KEY=\${2};

		local REGEX=\${KEY}'[[:space:][:space:]]*:[[:space:]]*["]?(.[^";]*)["]?[[:space:]]*[;]'

		if [[ \${CONFIG} =~ \${REGEX} ]]; then
			echo \${BASH_REMATCH[1]}
		fi
	}


	# Create default workpath if not exists and checkout
	checkout_worktree \${WORK}


	# read config
	CONFIGFILE=\${WORK}/.uberdeploy
	if [ -e \${CONFIGFILE} ]; then

		CONFIG=\$(cat \${CONFIGFILE})
		WORKTREE=\$(config_get_val "\${CONFIG}" WORKTREE)
		_CONFIG_RUN=\$(config_get_val "\${CONFIG}" RUN)

		if [[ -n \${WORKTREE} ]]; then
			checkout_worktree \${WORKTREE}
		fi

	fi



	# Change to active worktree
	if [[ -n \${WORKTREE} ]];
		then
			cd \${WORKTREE}
		else
			cd \${WORK}
	fi


	# Detect RUN
	if [[ -n \${_CONFIG_RUN} ]]; then

		sFile=\${PROJECTPATH}/service

		echo "#!/bin/sh" > \${sFile}
		echo "cd \${PWD}" >> \${sFile}
		echo "exec \${_CONFIG_RUN} 2>&1" >> \${sFile}

		# Make FILE executable
		chmod +x \${sFile}
	fi



	# Call post-receive handler from deploy-folder if exists
	if [ -e deploy/post-receive ]; then
		_PWD=\${PWD}
		cd \${PROJECTPATH}
		source \${_PWD}/deploy/post-receive
	fi

	-EOT



	# Make FILE executable
	chmod +x ${FILE}

}





if [ -d ${PROJECTPATH} ];
	then
		sshcall_error "Project already exists"
	else

		# Create bare repository
		git init --bare ${BAREPATH}

		# Create post-receive hook file in bare repository
		create_hook_postReceive ${BAREPATH}

fi


sshcall_respond


