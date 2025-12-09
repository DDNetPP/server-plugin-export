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

sample_dep
log "TODO: implement"
