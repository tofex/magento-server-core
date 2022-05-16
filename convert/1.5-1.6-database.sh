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

databaseHost=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "databaseHost")
if [[ -n "${databaseHost}" ]]; then
  echo "Moving database"
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
      if [[ "${databaseHost}" == "localhost" ]] || [[ "${databaseHost}" == "127.0.0.1" ]]; then
        ini-set "${currentPath}/../../env.properties" "yes" "${server}" "database" "database"
        serverFound=1
      fi
    elif [[ "${type}" == "ssh" ]]; then
      sshHost=$(ini-parse "${currentPath}/../../env.properties" "yes" "${server}" "sshHost")
      if [[ "${sshHost}" == "${databaseHost}" ]]; then
        ini-set "${currentPath}/../../env.properties" "yes" "${server}" "database" "database"
        serverFound=1
      fi
    fi
  done
  if [[ "${serverFound}" == 0 ]]; then
    ini-set "${currentPath}/../../env.properties" "yes" "${databaseHost}" "database" "database"
  fi
  ini-del "${currentPath}/../../env.properties" "project" "databaseHost"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "databaseType" "database" "type"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "databaseVersion" "database" "version"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "databasePort" "database" "port"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "databaseUser" "database" "user"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "databasePassword" "database" "password"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "databaseName" "database" "name"
else
  echo "No database to move"
fi
