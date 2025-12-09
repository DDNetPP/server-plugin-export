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
	mkdir -p "$adir"
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
	for file in "${files[@]}"
	do
		[ -f "$file" ] || continue

		log "found file $file, extracting .."
		archive_load_file "$file"
	done
}

# main pubic method
archive_export() {
	archive_save_files_if_found
}

# main pubic method
archive_import() {
	archive_load_files_if_found
}
