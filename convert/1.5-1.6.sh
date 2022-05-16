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

"${currentPath}/1.5-1.6-name.sh"
"${currentPath}/1.5-1.6-project.sh"
"${currentPath}/1.5-1.6-server.sh"
"${currentPath}/1.5-1.6-install.sh"
"${currentPath}/1.5-1.6-hosts.sh"
"${currentPath}/1.5-1.6-database.sh"
"${currentPath}/1.5-1.6-apache.sh"
"${currentPath}/1.5-1.6-redis-cache.sh"
"${currentPath}/1.5-1.6-redis-session.sh"
"${currentPath}/1.5-1.6-redis-fpc.sh"
"${currentPath}/1.5-1.6-solr.sh"
