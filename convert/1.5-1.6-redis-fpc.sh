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

redisFullPageCacheHost=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "redisFullPageCacheHost")
if [[ -n "${redisFullPageCacheHost}" ]]; then
  echo "Moving Redis FPC server"
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
      if [[ "${redisFullPageCacheHost}" == "localhost" ]] || [[ "${redisFullPageCacheHost}" == "127.0.0.1" ]]; then
        ini-set "${currentPath}/../../env.properties" "yes" "${server}" "redisFPC" "redis_fpc"
        serverFound=1
      fi
    elif [[ "${type}" == "ssh" ]]; then
      sshHost=$(ini-parse "${currentPath}/../../env.properties" "yes" "${server}" "sshHost")
      if [[ "${sshHost}" == "${redisFullPageCacheHost}" ]]; then
        ini-set "${currentPath}/../../env.properties" "yes" "${server}" "redisFPC" "redis_fpc"
        serverFound=1
      fi
    fi
  done
  if [[ "${serverFound}" == 0 ]]; then
    ini-set "${currentPath}/../../env.properties" "yes" "${redisFullPageCacheHost}" "redisFPC" "redis_fpc"
  fi
  ini-del "${currentPath}/../../env.properties" "project" "redisFullPageCacheHost"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "redisFullPageCacheVersion" "redis_fpc" "version"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "redisFullPageCachePort" "redis_fpc" "port"
  redisFullPageCachePassword=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "redisFullPageCachePassword")
  if [[ -n "${redisFullPageCachePassword}" ]]; then
    ini-move "${currentPath}/../../env.properties" "yes" "project" "redisFullPageCachePassword" "redis_fpc" "password"
  fi
  ini-move "${currentPath}/../../env.properties" "yes" "project" "redisFullPageCacheDatabase" "redis_fpc" "database"
fi
