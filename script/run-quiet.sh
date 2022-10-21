#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck disable=SC2034
executeScript="executeScriptQuiet"
# shellcheck disable=SC2034
executeScriptWithSSH="executeScriptWithSSHQuiet"

source "${currentPath}/run.sh"
