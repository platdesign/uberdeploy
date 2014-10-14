#!/bin/bash


echo 'Preparing to install uberdeploy...';
eval "$(curl -fsSL https://raw.githubusercontent.com/platdesign/uberdeploy/master/lib/base.sh)";
eval "$(curl -fsSL https://raw.githubusercontent.com/platdesign/uberdeploy/master/lib/utils.sh)";

echo_notify "Welcome to uberdeploy =)";

DEFAULT_LIB_PATH="/usr/local/lib/${TOOLNAME}"

# Ask for INSTALL_LIB_PATH
input_default "Where would you like to install?" "${DEFAULT_LIB_PATH}" INSTALL_LIB_PATH

if ! mkdir -p "${INSTALL_LIB_PATH}"; then
	echo_error "Can't create directory (${INSTALL_LIB_PATH})";
	exit 1;
fi

if input_confirm "Create link to '${INSTALL_LIB_PATH%/*}/bin/${TOOLNAME}'?"; then
	INSTALL_BIN_PATH="${INSTALL_LIB_PATH%/*}/bin/${TOOLNAME}";
fi

if ! installLatestVersionFromGithubToLibDir "${INSTALL_LIB_PATH}"; then
	echo_error "Installation failed.";
	exit 1;
fi

if [[ -n "${INSTALL_BIN_PATH}" ]]; then

	# Linking the main file to the bin dir
	ln -fs "${INSTALL_LIB_PATH}/bin/uberdeploy.sh" "${INSTALL_BIN_PATH}"
	echo_notify "Link created (${INSTALL_BIN_PATH})";
fi

echo_notify "Installation successfully completed =)";
echo -e "\nLet's have a look at the man page (uberdeploy -h/--help)";
uberdeploy -h
