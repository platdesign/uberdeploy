#!/bin/sh

# Only a litte test
#
# - Show active version
# - Create a project
# - Make some changes
# - Deploy it
# - Run it locally
# - Display logs
# - Destroy it
# - Show help

TMPDIR=`mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`;

(
	cd "${TMPDIR}";

	uberdeploydev -v

	uberdeploydev create "test";

	cd "test";

	echo "{}" > "package.json";
	echo "{}" > "bower.json";

	bower install --save jquery
	npm install --save jquery

	uberdeploydev deploy;

	uberdeploydev run

	uberdeploydev log

	uberdeploydev destroy;

	uberdeploydev --help

	rm -rf "${TMPDIR}"

) | while read line; do
	echo "$line";
done

