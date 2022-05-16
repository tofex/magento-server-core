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

hostName=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "hostName")
if [[ -n "${hostName}" ]]; then
  echo "Moving name"
  sed -i "1s/^/[system]\n/" "${currentPath}/../../env.properties"
  sed -i "2s/^/name=${hostName}\n/" "${currentPath}/../../env.properties"
  ini-del "${currentPath}/../../env.properties" "project" "hostName"
  ini-del "${currentPath}/../../env.properties" "project" "serverName"
else
  echo "No name to move"
fi
