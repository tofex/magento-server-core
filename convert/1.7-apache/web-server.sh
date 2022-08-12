#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

webServerId=
webServerType=

if [[ -f "${currentPath}/../../prepare-parameters.sh" ]]; then
  source "${currentPath}/../../prepare-parameters.sh"
elif [[ -f /tmp/prepare-parameters.sh ]]; then
  source /tmp/prepare-parameters.sh
fi

if [[ "${webServerType}" == "apache" ]]; then
  "${currentPath}/../../env/update-web-server.sh" -i "${webServerId}" -t "apache_php"
fi
