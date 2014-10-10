#!/bin/bash


# Help text
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
	echo 'HELP WILL COME'
	exit
fi


SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`

source ${SCRIPTPATH}/../lib/methods.sh

echo #only to start in a new line
case ${1} in
	init)
		init ${@/%${1}*} ;;
	create)
		create ${@/%${1}*} ;;
	join)
		join ${@/%${1}*} ;;
	destroy)
		destroy ${@/%${1}*} ;;
	deploy)
		deploy ${@/%${1}*} ;;
	update)
		update ${@/%${1}*} ;;
	uninstall)
		uninstall ${@/%${1}*} ;;
	-*|--*)
		echo "Warning: invalid option $opt" ;;
esac
