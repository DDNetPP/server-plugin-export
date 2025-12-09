#!/bin/bash
# entry point is in ./bin
# this is the entry point of the lib
# the lib's current working directory should be
# the server root at all times

set -eu

PLUGIN_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1; pwd -P )"
SERVER_PATH="$(cd "$PLUGIN_PATH/../../.."; pwd - P)"
cd "$SERVER_PATH"

source "$PLUGIN_PATH/lib/dep.sh"
source "$PLUGIN_PATH/lib/archive.sh"

show_help() {
	cat <<-EOF
	usage: ${PLUGIN_PATH}/bin/archive_cli ACTION [OPTION]
	description:
	  creates an archive of the current state
	  in this server directory
	  checking a list of files that contain state
	  and copying them
	  also checking a list of known git repo locations
	  and storing these as urls
	actions:
	  export          creates a archive/ directory with all found state
	  import          extracts all files from archive/ directory into the current server dir
	options:
	  --dir       use directory as format (default)
	  --base64    use base64 file of zip archive as format
	  --zip       use zip file as format
	  --stdin     read base64 as input for import (export not supported)
	examples:
	  archive_cli export
	  archive_cli import
	EOF
}

parse_args() {
	local arg
	local action=""
	local format=dir
	while [ "$#" -gt 0 ]
	do
		arg="$1"
		shift
		if [ "${arg::2}" = "--" ]
		then
			if [ "$arg" = "--help" ]
			then
				show_help
				exit 0
			elif [ "$arg" = "--dir" ]
			then
				format=dir
			elif [ "$arg" = "--zip" ]
			then
				format=zip
			elif [ "$arg" = "--base64" ]
			then
				format=base64
			elif [ "$arg" = "--stdin" ]
			then
				format=stdin_base64
			else
				err "Unknown option '$arg'"
				exit 1
			fi
		elif [ "${arg::1}" = "-" ]
		then
			if [ "$arg" = "-h" ]
			then
				show_help
				exit 0
			else
				err "Unknown flag '$arg'"
				exit 1
			fi
		else
			if [ "$arg" = "export" ]
			then
				action=export
			elif [ "$arg" = "import" ]
			then
				action=import
			else
				err "Unknown argument '$arg'"
				exit 1
			fi
		fi
	done

	if [ "$action" = "export" ]
	then
		if [ "$format" = stdin_base64 ]
		then
			err "Error: --stdin can only be used with import not with export"
			exit 1
		fi
		archive_export "$format"
	elif [ "$action" = "import" ]
	then
		archive_import "$format"
	else
		show_help
		exit 1
	fi
}

parse_args "$@"
