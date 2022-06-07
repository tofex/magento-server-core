#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${currentPath}/../base.sh"

scriptPath="${1}"
shift
parameters=("$@")

for parameter in "${parameters[@]}"; do
  if [[ "${parameter}" == "-o" ]] || [[ "${parameter}" == "-p" ]] || [[ "${parameter}" == "-u" ]] || [[ "${parameter}" == "-s" ]] || [[ "${parameter}" == "-b" ]] || [[ "${parameter}" == "-t" ]] || [[ "${parameter}" == "-v" ]]; then
    echo "Restricted parameter key used: ${parameter} for script: ${scriptPath}"
    exit 1
  fi
done

if [[ ! -f "${currentPath}/../../../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

serverList=( $(ini-parse "${currentPath}/../../../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

serverName=

for server in "${serverList[@]}"; do
  varnish=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "varnish")

  if [[ -n "${varnish}" ]]; then
    serverType=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${server}" "type")

    if [[ "${serverType}" != "local" ]] && [[ "${serverType}" != "ssh" ]]; then
      echo "Invalid Varnsih server type: ${serverType} of server: ${server}"
      continue
    fi

    serverName="${server}"

    break
  fi
done

if [[ -z "${serverName}" ]]; then
  echo "No Varnish settings found"
  exit 1
fi

serverType=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${serverName}" "type")

if [[ "${serverType}" != "local" ]] && [[ "${serverType}" != "ssh" ]]; then
  echo "Invalid Varnish server type: ${serverType} of server: ${serverName}"
  exit 1
fi

varnish=$(ini-parse "${currentPath}/../env.properties" "no" "${serverName}" "varnish")

if [[ "${serverType}" == "local" ]]; then
  host="localhost"
elif [[ "${serverType}" == "ssh" ]]; then
  host=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${serverName}" "host")
fi

port=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${varnish}" "port")
adminPort=$(ini-parse "${currentPath}/../env.properties" "no" "${varnish}" "adminPort")
secretFile="/etc/varnish/secret"
version=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${varnish}" "version")

if [[ -z "${host}" ]]; then
  echo "No Varnish host specified!"
  exit 1
fi

if [[ -z "${port}" ]]; then
  echo "No Varnish port specified!"
  exit 1
fi

if [[ -z "${adminPort}" ]]; then
  echo "No Varnish admin port specified!"
  exit 1
fi

if [[ -z "${secretFile}" ]]; then
  echo "No Varnish secret file specified!"
  exit 1
fi

if [[ -z "${version}" ]]; then
  echo "No Varnish version specified!"
  exit 1
fi

parameters+=( "-o \"${host}\"" )
parameters+=( "-p \"${port}\"" )
parameters+=( "-a \"${adminPort}\"" )
parameters+=( "-s \"${secretFile}\"" )
parameters+=( "-v \"${version}\"" )

if [[ "${serverType}" == "local" ]]; then
  executeScript "${serverName}" "${scriptPath}" "${parameters[@]}"
elif [[ "${serverType}" == "ssh" ]]; then
  sshUser=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${serverName}" "user")
  sshHost=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${serverName}" "host")
  executeScriptWithSSH "${serverName}" "${sshUser}" "${sshHost}" "${scriptPath}" "${parameters[@]}"
fi
