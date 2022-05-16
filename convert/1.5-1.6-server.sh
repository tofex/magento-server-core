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

servers=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "servers")
if [[ -n "${servers}" ]]; then
  echo "Moving server"
  IFS=',' read -r -a serverList <<< "${servers}"
  for server in "${serverList[@]}"; do
    ini-set "${currentPath}/../../env.properties" "no" "system" "server" "${server}"
    ini-set "${currentPath}/../../env.properties" "no" "deploy" "server" "${server}"
    deployHistoryCount=$(ini-parse "${currentPath}/../../env.properties" "no" "${server}" "deployHistoryCount")
    if [[ -n "${deployHistoryCount}" ]]; then
      ini-move "${currentPath}/../../env.properties" "yes" "${server}" "deployHistoryCount" "deploy" "deployHistoryCount"
    fi
  done
  ini-del "${currentPath}/../../env.properties" "project" "servers"
else
  echo "No server to move"
fi
