#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ -f "${currentPath}/../../env.properties" ]]; then
  serverList=( $(ini-parse "${currentPath}/../../env.properties" "no" "system" "server") )
  if [[ "${#serverList[@]}" -gt 0 ]]; then
    for server in "${serverList[@]}"; do
      webServer=$(ini-parse "${currentPath}/../../env.properties" "no" "${server}" "webServer")
      if [[ -n "${webServer}" ]]; then
        webPath=$(ini-parse "${currentPath}/../../env.properties" "no" "${server}" "webPath")
        if [[ -n "${webPath}" ]]; then
          ini-move "${currentPath}/../../env.properties" "yes" "${server}" "webPath" "${webServer}" "path"
        fi
        webUser=$(ini-parse "${currentPath}/../../env.properties" "no" "${server}" "webUser")
        if [[ -n "${webUser}" ]]; then
          ini-move "${currentPath}/../../env.properties" "yes" "${server}" "webUser" "${webServer}" "user"
        fi
        webGroup=$(ini-parse "${currentPath}/../../env.properties" "no" "${server}" "webGroup")
        if [[ -n "${webGroup}" ]]; then
          ini-move "${currentPath}/../../env.properties" "yes" "${server}" "webGroup" "${webServer}" "group"
        fi
      fi
    done
  fi
fi

"${currentPath}/../script/run.sh" "webServer:ignore" "${currentPath}/1.7-apache/web-server.sh"
