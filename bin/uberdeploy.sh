#!/bin/bash


function get_realpath() {

    [[ ! -f "$1" ]] && return 1 # failure : file does not exist.
    [[ -n "$no_symlinks" ]] && local pwdp='pwd -P' || local pwdp='pwd' # do symlinks.
    echo "$( cd "$( echo "${1%/*}" )" 2>/dev/null; $pwdp )"/"${1##*/}" # echo result.
    return 0 # success

}




SCRIPT=$(get_realpath $0)
SCRIPTPATH=$(dirname `readlink $SCRIPT` )


if [ -e ${SCRIPTPATH}/../lib/base.sh ];
	then

		source ${SCRIPTPATH}/../lib/base.sh
		source ${SCRIPTPATH}/../lib/methods.sh

		echo #only to start in a new line
		case ${1} in
			init)
				init ${@/%${1}*} ;;
			create)
				create ${@/%${1}*} ;;
			destroy)
				destroy ${@/%${1}*} ;;
			deploy)
				deploy ${@/%${1}*} ;;
			update)
				update ${@/%${1}*} ;;
			uninstall)
				uninstall ${@/%${1}*} ;;
			log)
				displayLog ${@/%${1}*} ;;
			run)
				runProject ${@/%${1}*} ;;
			-h|--help|'')
				help ;;
			-v|--version)
				echo "uberdeploy ${VERSION}";;
			-*|--*)
				echo "Warning: invalid option $opt" ;;
		esac
	else
		echo 'Cant find real path to uberdeploy';
fi
