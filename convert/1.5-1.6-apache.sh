#!/bin/bash -e

versionCompare() {
  if [[ "$1" == "$2" ]]; then
    echo "0"
  elif [[ "$1" = $(echo -e "$1\n$2" | sort -V | head -n1) ]]; then
    echo "1"
  else
    echo "2"
  fi
}

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ ! -f "${currentPath}/../../env.properties" ]; then
  echo "No environment specified!"
  exit 1
fi

cd "${currentPath}"

apacheHost=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "apacheHost")
if [[ -n "${apacheHost}" ]]; then
  echo "Moving Apache"
  servers=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "servers")
  if [[ -n "${servers}" ]]; then
    IFS=',' read -r -a serverList <<< "${servers}"
  else
    serverList=( $(ini-parse "${currentPath}/../../env.properties" "yes" "system" "server") )
  fi
  serverFound=0
  for server in "${serverList[@]}"; do
    type=$(ini-parse "${currentPath}/../../env.properties" "yes" "${server}" "type")
    if [[ "${type}" == "local" ]]; then
      if [[ "${apacheHost}" == "localhost" ]] || [[ "${apacheHost}" == "127.0.0.1" ]]; then
        ini-set "${currentPath}/../../env.properties" "yes" "${server}" "webServer" "web_server"
        serverFound=1
      fi
    elif [[ "${type}" == "ssh" ]]; then
      sshHost=$(ini-parse "${currentPath}/../../env.properties" "yes" "${server}" "sshHost")
      if [[ "${sshHost}" == "${apacheHost}" ]]; then
        ini-set "${currentPath}/../../env.properties" "yes" "${server}" "webServer" "web_server"
        serverFound=1
      fi
    fi
  done
  if [[ "${serverFound}" == 0 ]]; then
    ini-set "${currentPath}/../../env.properties" "yes" "${apacheHost}" "webServer" "web_server"
  fi
  ini-del "${currentPath}/../../env.properties" "project" "apacheHost"
  ini-set "${currentPath}/../../env.properties" "yes" "web_server" "type" "apache"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "apacheVersion" "web_server" "version"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "apacheHttpPort" "web_server" "httpPort"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "apacheSslPort" "web_server" "sslPort"
else
  echo "No Apache to move"
fi
