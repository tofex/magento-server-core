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

solrHost=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "solrHost")
if [[ -n "${solrHost}" ]]; then
  echo "Moving Solr server"
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
      if [[ "${solrHost}" == "localhost" ]] || [[ "${solrHost}" == "127.0.0.1" ]]; then
        ini-set "${currentPath}/../../env.properties" "yes" "${server}" "solr" "solr"
        serverFound=1
      fi
    elif [[ "${type}" == "ssh" ]]; then
      sshHost=$(ini-parse "${currentPath}/../../env.properties" "yes" "${server}" "sshHost")
      if [[ "${sshHost}" == "${solrHost}" ]]; then
        ini-set "${currentPath}/../../env.properties" "yes" "${server}" "solr" "solr"
        serverFound=1
      fi
    fi
  done
  if [[ "${serverFound}" == 0 ]]; then
    ini-set "${currentPath}/../../env.properties" "yes" "${solrHost}" "solr" "solr"
  fi
  ini-del "${currentPath}/../../env.properties" "project" "solrHost"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "solrVersion" "solr" "version"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "solrServiceName" "solr" "serviceName"
  ini-set "${currentPath}/../../env.properties" "yes" "solr" "protocol" "http"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "solrPort" "solr" "port"
  ini-set "${currentPath}/../../env.properties" "yes" "solr" "urlPath" "solr"
else
  echo "No Solr to move"
fi
