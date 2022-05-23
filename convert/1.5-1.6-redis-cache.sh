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

redisCacheHost=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "redisCacheHost")
if [[ -n "${redisCacheHost}" ]]; then
  echo "Moving Redis cache server"
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
      if [[ "${redisCacheHost}" == "localhost" ]] || [[ "${redisCacheHost}" == "127.0.0.1" ]]; then
        ini-set "${currentPath}/../../env.properties" "yes" "${server}" "redisCache" "redis_cache"
        serverFound=1
      fi
    elif [[ "${type}" == "ssh" ]]; then
      sshHost=$(ini-parse "${currentPath}/../../env.properties" "yes" "${server}" "sshHost")
      if [[ "${sshHost}" == "${redisCacheHost}" ]]; then
        ini-set "${currentPath}/../../env.properties" "yes" "${server}" "redisCache" "redis_cache"
        serverFound=1
      fi
    fi
  done
  if [[ "${serverFound}" == 0 ]]; then
    ini-set "${currentPath}/../../env.properties" "yes" "${redisCacheHost}" "redisCache" "redis_cache"
  fi
  ini-del "${currentPath}/../../env.properties" "project" "redisCacheHost"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "redisCacheVersion" "redis_cache" "version"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "redisCachePort" "redis_cache" "port"
  redisCachePassword=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "redisCachePassword")
  if [[ -n "${redisCachePassword}" ]]; then
    ini-move "${currentPath}/../../env.properties" "yes" "project" "redisCachePassword" "redis_cache" "password"
  else
    ini-del "${currentPath}/../../env.properties" "project" "redisCachePassword"
  fi
  redisCacheClassName=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "redisCacheClassName")
  if [[ -n "${redisCacheClassName}" ]]; then
    ini-move "${currentPath}/../../env.properties" "yes" "project" "redisCacheClassName" "redis_cache" "className"
  else
    ini-del "${currentPath}/../../env.properties" "project" "redisCacheClassName"
  fi
  redisCachePrefix=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "cachePrefix")
  if [[ -n "${redisCachePrefix}" ]]; then
    ini-move "${currentPath}/../../env.properties" "yes" "project" "cachePrefix" "redis_cache" "prefix"
  else
    ini-del "${currentPath}/../../env.properties" "project" "cachePrefix"
  fi
  ini-move "${currentPath}/../../env.properties" "yes" "project" "redisCacheDatabase" "redis_cache" "database"
else
  echo "No Redis cache to move"
fi
