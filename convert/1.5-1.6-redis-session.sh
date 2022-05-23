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

redisSessionHost=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "redisSessionHost")
if [[ -n "${redisSessionHost}" ]]; then
  echo "Moving Redis session server"
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
      if [[ "${redisSessionHost}" == "localhost" ]] || [[ "${redisSessionHost}" == "127.0.0.1" ]]; then
        ini-set "${currentPath}/../../env.properties" "yes" "${server}" "redisSession" "redis_session"
        serverFound=1
      fi
    elif [[ "${type}" == "ssh" ]]; then
      sshHost=$(ini-parse "${currentPath}/../../env.properties" "yes" "${server}" "sshHost")
      if [[ "${sshHost}" == "${redisSessionHost}" ]]; then
        ini-set "${currentPath}/../../env.properties" "yes" "${server}" "redisSession" "redis_session"
        serverFound=1
      fi
    fi
  done
  if [[ "${serverFound}" == 0 ]]; then
    ini-set "${currentPath}/../../env.properties" "yes" "${redisSessionHost}" "redisSession" "redis_session"
  fi
  ini-del "${currentPath}/../../env.properties" "project" "redisSessionHost"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "redisSessionVersion" "redis_session" "version"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "redisSessionPort" "redis_session" "port"
  redisSessionPassword=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "redisSessionPassword")
  if [[ -n "${redisSessionPassword}" ]]; then
    ini-move "${currentPath}/../../env.properties" "yes" "project" "redisSessionPassword" "redis_session" "password"
  else
    ini-del "${currentPath}/../../env.properties" "project" "redisSessionPassword"
  fi
  ini-move "${currentPath}/../../env.properties" "yes" "project" "redisSessionDatabase" "redis_session" "database"
else
  echo "No Redis session to move"
fi
