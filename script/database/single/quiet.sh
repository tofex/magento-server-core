#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${currentPath}/../../base.sh"

scriptPath="${1}"
shift
parameters=("$@")

for parameter in "${parameters[@]}"; do
  if [[ "${parameter}" == "-o" ]] || [[ "${parameter}" == "-p" ]] || [[ "${parameter}" == "-u" ]] || [[ "${parameter}" == "-s" ]] || [[ "${parameter}" == "-b" ]] || [[ "${parameter}" == "-t" ]] || [[ "${parameter}" == "-v" ]]; then
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
  database=$(ini-parse "${currentPath}/../../../../env.properties" "no" "${server}" "database")

  if [[ -n "${database}" ]]; then
    serverType=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${server}" "type")

    if [[ "${serverType}" != "local" ]] && [[ "${serverType}" != "ssh" ]]; then
      echo "Invalid database server type: ${serverType} of server: ${server}"
      continue
    fi

    serverName="${server}"

    break
  fi
done

if [[ -z "${serverName}" ]]; then
  echo "No database settings found"
  exit 1
fi

serverType=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${serverName}" "type")

if [[ "${serverType}" != "local" ]] && [[ "${serverType}" != "ssh" ]]; then
  echo "Invalid database server type: ${serverType} of server: ${serverName}"
  exit 1
fi

database=$(ini-parse "${currentPath}/../../../../env.properties" "no" "${serverName}" "database")

if [[ "${serverType}" == "local" ]]; then
  host="localhost"
elif [[ "${serverType}" == "ssh" ]]; then
  host=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${serverName}" "host")
fi

port=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${database}" "port")
user=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${database}" "user")
password=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${database}" "password")
name=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${database}" "name")
type=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${database}" "type")
version=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${database}" "version")

if [[ -z "${host}" ]]; then
  echo "No database host specified!"
  exit 1
fi

if [[ -z "${port}" ]]; then
  echo "No database port specified!"
  exit 1
fi

if [[ -z "${user}" ]]; then
  echo "No database user specified!"
  exit 1
fi

if [[ -z "${password}" ]]; then
  echo "No database password specified!"
  exit 1
fi

if [[ -z "${name}" ]]; then
  echo "No database name specified!"
  exit 1
fi

if [[ -z "${type}" ]]; then
  echo "No database type specified!"
  exit 1
fi

if [[ -z "${version}" ]]; then
  echo "No database version specified!"
  exit 1
fi

parameters+=( "-o \"${host}\"" )
parameters+=( "-p \"${port}\"" )
parameters+=( "-u \"${user}\"" )
parameters+=( "-s \"${password}\"" )
parameters+=( "-b \"${name}\"" )
parameters+=( "-t \"${type}\"" )
parameters+=( "-v \"${version}\"" )

if [[ "${serverType}" == "local" ]]; then
  executeScriptQuiet "${serverName}" "${scriptPath}" "${parameters[@]}"
elif [[ "${serverType}" == "ssh" ]]; then
  sshUser=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${serverName}" "user")
  sshHost=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${serverName}" "host")
  environment=$(ini-parse "${currentPath}/../../../../env.properties" "no" "system" "environment")
  if [[ -z "${environment}" ]]; then
    environment="no"
  fi
  executeScriptWithSSHQuiet "${serverName}" "${sshUser}" "${sshHost}" "${environment}" "${scriptPath}" "${parameters[@]}"
fi
