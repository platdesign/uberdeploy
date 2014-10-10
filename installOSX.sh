#!/bin/bash

DIRNAME='uberdeploy'
LIB_DIR="/usr/local/lib/${DIRNAME}"
BIN_DIR="/usr/local/bin/${DIRNAME}"

# Uncomment for testing in development
#LIB_DIR="${HOME}/installtest/lib/${DIRNAME}"
#BIN_DIR="${HOME}/installtest/bin/${DIRNAME}"

REPOSITORY="https://github.com/platdesign/uberdeploy"



if [[ ! -d ${LIB_DIR} ]]; then

	printf "$(tput setaf 7)Downloading dotfiles...\033[m\n"
	mkdir -p ${LIB_DIR}

	# Get the tarball
	TMPTARFILE="${LIB_DIR}/${DIRNAME}.tar.gz"
	curl -fsSLo TMPTARFILE ${REPOSITORY}/tarball/master

	# Extract tarball to directory
	tar -zxf TMPTARFILE --strip-components 1 -C ${LIB_DIR}

	# Remove the tarball
	rm -rf TMPTARFILE

fi


# Linking the main file to the bin dir
ln -fs ${LIB_DIR}/bin/uberdeploy.sh ${BIN_DIR}
