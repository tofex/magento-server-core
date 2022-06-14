#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ ! -f "${currentPath}/../../env.properties" ]; then
  echo "No environment specified!"
  exit 1
fi

cd "${currentPath}"

elasticsearchHost=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "elasticsearchHost")
elasticsearchVersion=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "elasticsearchVersion")
if [[ -n "${elasticsearchHost}" ]] || [[ -n "${elasticsearchVersion}" ]]; then
  echo "Moving Elasticsearch server"
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
      if [[ -z "${elasticsearchHost}" ]] || [[ "${elasticsearchHost}" == "localhost" ]] || [[ "${elasticsearchHost}" == "127.0.0.1" ]]; then
        ini-set "${currentPath}/../../env.properties" "yes" "${server}" "elasticsearch" "elasticsearch"
        serverFound=1
      fi
    elif [[ "${type}" == "ssh" ]]; then
      sshHost=$(ini-parse "${currentPath}/../../env.properties" "yes" "${server}" "sshHost")
      if [[ "${sshHost}" == "${elasticsearchHost}" ]]; then
        ini-set "${currentPath}/../../env.properties" "yes" "${server}" "elasticsearch" "elasticsearch"
        serverFound=1
      fi
    fi
  done
  if [[ "${serverFound}" == 0 ]] && [[ -n "${elasticsearchHost}" ]]; then
    ini-set "${currentPath}/../../env.properties" "yes" "${elasticsearchHost}" "elasticsearch" "elasticsearch"
  fi
  ini-del "${currentPath}/../../env.properties" "project" "elasticsearchHost"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "elasticsearchVersion" "elasticsearch" "version"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "elasticsearchPort" "elasticsearch" "port"
else
  echo "No elasticsearch to move"
fi
