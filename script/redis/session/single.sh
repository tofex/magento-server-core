#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${currentPath}/../base.sh"

scriptPath="${1}"
shift
parameters=("$@")

for parameter in "${parameters[@]}"; do
  if [[ "${parameter}" == "-o" ]] || [[ "${parameter}" == "-p" ]] || [[ "${parameter}" == "-s" ]] || [[ "${parameter}" == "-b" ]] || [[ "${parameter}" == "-v" ]]; then
    echo "Restricted parameter key used: ${parameter} for script: ${scriptPath}"
    exit 1
  fi
done

if [[ ! -f "${currentPath}/../../../../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

serverList=( $(ini-parse "${currentPath}/../../../../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

serverName=

for server in "${serverList[@]}"; do
  redisSession=$(ini-parse "${currentPath}/../../../../env.properties" "no" "${server}" "redisSession")

  if [[ -n "${redisSession}" ]]; then
    database=$(ini-parse "${currentPath}/../../../../env.properties" "no" "${redisSession}" "database")

    if [[ -n "${database}" ]]; then
      serverType=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${server}" "type")

      if [[ "${serverType}" != "local" ]] && [[ "${serverType}" != "ssh" ]]; then
        echo "Invalid Redis session server type: ${serverType} of server: ${server}"
        continue
      fi

      serverName="${server}"
    fi

    break
  fi
done

if [[ -z "${serverName}" ]]; then
  echo "No Redis session settings found"
  exit 1
fi

serverType=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${serverName}" "type")

if [[ "${serverType}" != "local" ]] && [[ "${serverType}" != "ssh" ]]; then
  echo "Invalid Redis session server type: ${serverType} of server: ${serverName}"
  exit 1
fi

redisSession=$(ini-parse "${currentPath}/../../../../env.properties" "no" "${serverName}" "redisSession")

if [[ "${serverType}" == "local" ]]; then
  host="localhost"
elif [[ "${serverType}" == "ssh" ]]; then
  host=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${serverName}" "host")
fi

port=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${redisSession}" "port")
password=$(ini-parse "${currentPath}/../../../../env.properties" "no" "${redisSession}" "password")
database=$(ini-parse "${currentPath}/../../../../env.properties" "no" "${redisSession}" "database")
version=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${redisSession}" "version")

if [[ -z "${host}" ]]; then
  echo "No Redis session host specified!"
  exit 1
fi

if [[ -z "${port}" ]]; then
  echo "No Redis session port specified!"
  exit 1
fi

if [[ -z "${database}" ]]; then
  echo "No Redis session database specified!"
  exit 1
fi

if [[ -z "${version}" ]]; then
  echo "No Redis session version specified!"
  exit 1
fi

parameters+=( "-o \"${host}\"" )
parameters+=( "-p \"${port}\"" )
if [[ -n "${password}" ]]; then
  parameters+=( "-s \"${password}\"" )
fi
parameters+=( "-b \"${database}\"" )
parameters+=( "-v \"${version}\"" )

if [[ "${serverType}" == "local" ]]; then
  executeScript "${serverName}" "${scriptPath}" "${parameters[@]}"
elif [[ "${serverType}" == "ssh" ]]; then
  sshUser=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${serverName}" "user")
  sshHost=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${serverName}" "host")
  executeScriptWithSSH "${serverName}" "${sshUser}" "${sshHost}" "${scriptPath}" "${parameters[@]}"
fi
