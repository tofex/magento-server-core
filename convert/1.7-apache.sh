#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

"${currentPath}/../script/run.sh" "webServer:ignore" "${currentPath}/1.7-apache/web-server.sh"
