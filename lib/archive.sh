#!/bin/bash

# archive directory name
# used for loading and saving
archive_dir() {
	printf 'archive'
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

# main pubic method
archive_export() {
	adir="$(archive_dir)"
	if [ -d "$adir" ]
	then
		err "Error: archive directory $(tput bold)$adir$(tput sgr0) already exists"
		exit 1
	fi
	mkdir -p "$adir"

	archive_save_files_if_found
	archive_save_git_dirs_if_found
}

# main pubic method
archive_import() {
	archive_load_files_if_found
	archive_load_git_dirs
}
