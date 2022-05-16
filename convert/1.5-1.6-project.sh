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

projectId=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "projectId")
if [[ -n "${projectId}" ]]; then
  echo "Moving project"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "projectId" "system" "projectId"
else
  echo "No project to move"
fi
