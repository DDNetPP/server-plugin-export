#!/bin/bash

ARG_FORMAT=dir

ARCHIVE_TMP_DIR="$(mktemp -d /tmp/ddpp_server_archive_XXXXXX)"
archive_cleanup() {
	rm -rf "$ARCHIVE_TMP_DIR"
}
trap archive_cleanup EXIT

# users choice for archive name
archive_name() {
	printf 'archive'
}

# unpacked temporary archive working directory
archive_dir() {
	printf '%s/%s' "$ARCHIVE_TMP_DIR" "$(archive_name)"
}

# copy file to archive
_archive_save_cp() {
	local filepath="$1"
	local adir
	adir="$(archive_dir)"
	local dst="$adir/$filepath"
	if [ -f "$dst" ]
	then
		err "Error: file already exists $dst"
		exit 1
	fi
	# TODO: throw error if its a file path
	#       because then we need to create directories
	cp "$filepath" "$dst"
}

# copy file from archive to cwd
_archive_load_cp() {
	local filepath="$1"
	local adir
	adir="$(archive_dir)"
	local dst="$filepath"
	if [ -f "$dst" ]
	then
		err "Error: file already exists $dst"
		exit 1
	fi
	# TODO: throw error if its a file path
	#       because then we need to create directories
	cp "$adir/$filepath" "$filepath"
}

# store file to archive
archive_save_file() {
	local filepath="$1"
	_archive_save_cp "$filepath"
}

# extract file from archive
archive_load_file() {
	local filepath="$1"
	_archive_load_cp "$filepath"
}

archive_save_files_if_found() {
	local files=(
		autoexec.cfg
		server.cnf
	)
	local file
	for file in "${files[@]}"
	do
		[ -f "$file" ] || continue

		log "found file $file, archiving .."
		archive_save_file "$file"
	done
}

archive_load_files_if_found() {
	local files=(
		autoexec.cfg
		server.cnf
	)
	local file
	local adir
	adir="$(archive_dir)"
	for file in "${files[@]}"
	do
		[ -f "$adir/$file" ] || continue

		log "found file $adir/$file, extracting .."
		archive_load_file "$file"
	done
}

archive_save_git_dir() {
	local remote="$1"
	local path="$2"
	local adir
	adir="$(archive_dir)"
	printf '%s %s\n' "$path" "$remote" >> "$adir/remotes.txt"
}

archive_load_git_dirs() {
	local git_path
	local git_remote
	local adir
	adir="$(archive_dir)"
	local remotes_file="$adir/remotes.txt"
	[ -f "$remotes_file" ] || return

	while IFS=' ' read -r git_path git_remote
	do
		if [ -d "$git_path/.git" ]
		then
			err "Error: $git_path/.git already exists"
			exit 1
		fi
		local base_dir="$(dirname "$git_path")"
		pushd "$base_dir" >/dev/null
		git clone "$git_remote"
		popd >/dev/null # base_dir
	done < "$remotes_file"
}

archive_save_git_dirs_if_found() {
	local git_dir
	while read -r git_dir
	do
		[ "$git_dir" = "./.git" ] && continue

		local git_remote=""
		git_dir="$(dirname "$git_dir")"
		log "found git repo: $git_dir"

		pushd "$git_dir" >/dev/null
		if ! git_remote="$(git config --get remote.origin.url)"
		then
			wrn "WARNING: failed to get origin remote in $PWD"
		fi
		popd >/dev/null # git_dir

		if [ "$git_remote" != "" ]
		then
			log "writing $git_remote to archive .."
			archive_save_git_dir "$git_remote" "$git_dir"
		fi
	done < <(find . -name .git -type d | perl -e 'print sort { length($a) <=> length($b) } <>')
	# the perl length cmp is to sort by length
	# we need to store the git repos in that order
	# to get the proper nesting order when loading them again
	# otherwise the nested git repos are missing a base directory
	# or the parent repos can not be created because the directory already exists
}

archive_load_dir() {
	local adir
	adir="$(archive_name)"

	if [ "$ARG_FORMAT" = "stdin_base64" ]
	then
		log "paste base64 encoded archive to import"
		printf '> '
		local archive_input_b64
		read -r archive_input_b64
		pushd "$ARCHIVE_TMP_DIR"
		printf '%s' "$archive_input_b64" > archive.base64
		base64 -d archive.base64 > archive.zip
		unzip archive.zip
		popd
	elif [ "$ARG_FORMAT" = "base64" ]
	then
		if [ ! -f "$adir".base64 ]
		then
			err "Error: archive base64 $(tput bold)${adir}.base64$(tput sgr0) not found"
			exit 1
		fi
		base64 -d "$adir".base64 > "$ARCHIVE_TMP_DIR"/archive.zip
		pushd "$ARCHIVE_TMP_DIR"
		unzip archive.zip
		popd
	elif [ "$ARG_FORMAT" = "zip" ]
	then
		if [ ! -f "$adir".zip ]
		then
			err "Error: archive zip $(tput bold)${adir}.zip$(tput sgr0) not found"
			exit 1
		fi
		cp "${adir}.zip" "$ARCHIVE_TMP_DIR"
		pushd "$ARCHIVE_TMP_DIR"
		unzip "${adir}.zip"
		popd
	elif [ "$ARG_FORMAT" = "dir" ]
	then
		if [ ! -d "$adir" ]
		then
			err "Error: archive directory $(tput bold)$adir$(tput sgr0) not found"
			exit 1
		fi
		cp -r "${adir}" "$ARCHIVE_TMP_DIR"/archive
	else
		err "Error: unknown format $ARG_FORMAT"
		exit 1
	fi
}

# main pubic method
archive_export() {
	local format="$1"
	ARG_FORMAT="$format"

	# check if user chosen name and format
	# matches an existing file
	local adir
	adir="$(archive_name)"
	if [ -d "$adir" ] && [ "$ARG_FORMAT" = "dir" ]
	then
		err "Error: archive directory $(tput bold)$adir$(tput sgr0) already exists"
		exit 1
	fi
	if [ -d "$adir".zip ] && [ "$ARG_FORMAT" = "zip" ]
	then
		err "Error: archive zip $(tput bold)${adir}.zip$(tput sgr0) already exists"
		exit 1
	fi
	if [ -d "$adir".base64 ] && [ "$ARG_FORMAT" = "base64" ]
	then
		err "Error: archive base64 $(tput bold)${adir}.base64$(tput sgr0) already exists"
		exit 1
	fi
	# create temporary working directory
	mkdir -p "$(archive_dir)"

	archive_save_files_if_found
	archive_save_git_dirs_if_found

	# generate all formats at all times
	pushd "$ARCHIVE_TMP_DIR"
	zip -r archive.zip archive
	base64 -w0 archive.zip > archive.base64
	popd

	if [ "$ARG_FORMAT" = "base64" ]
	then
		cp "$(archive_dir).base64" "$(archive_name).base64"
	elif [ "$ARG_FORMAT" = "zip" ]
	then
		cp "$(archive_dir).zip" "$(archive_name).zip"
	elif [ "$ARG_FORMAT" = "dir" ]
	then
		cp -r "$(archive_dir)" "$(archive_name)"
	else
		err "Unsupported format '$ARG_FORMAT'"
		exit 1
	fi

	local size
	size="$(du "$(archive_dir).zip" | awk '{ print $1}')"
	if [ "$size" -lt 20 ]
	then
		log "small archive detected creating base64 that can be copy pasted ..."
		echo ""
		cat "$(archive_dir)".base64
		echo ""
		echo ""
		log "copy the output above into a archive.base64 file to import"
	fi

	local out_name
	out_name="$(archive_name)"
	if [ "$ARG_FORMAT" != "dir" ]
	then
		out_name="$out_name.$ARG_FORMAT"
	fi
	log "finished export written to $(tput bold)$out_name$(tput sgr0)"
}

# main pubic method
archive_import() {
	local format="$1"
	ARG_FORMAT="$format"
	archive_load_dir

	archive_load_files_if_found
	archive_load_git_dirs
}
