#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${currentPath}/../../base.sh"

scriptPath="${1}"
shift
parameters=("$@")

for parameter in "${parameters[@]}"; do
  if [[ "${parameter}" == "-n" ]] || [[ "${parameter}" == "-w" ]] || [[ "${parameter}" == "-u" ]] || [[ "${parameter}" == "-g" ]] || [[ "${parameter}" == "-t" ]] || [[ "${parameter}" == "-v" ]] || [[ "${parameter}" == "-p" ]] || [[ "${parameter}" == "-z" ]] || [[ "${parameter}" == "-x" ]] || [[ "${parameter}" == "-y" ]]; then
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

webServerFound=0

for server in "${serverList[@]}"; do
  webServer=$(ini-parse "${currentPath}/../../../../env.properties" "no" "${server}" "webServer")

  if [[ -n "${webServer}" ]]; then
    serverType=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${server}" "type")

    if [[ "${serverType}" != "local" ]] && [[ "${serverType}" != "ssh" ]]; then
      echo "Invalid web server server type: ${serverType} of server: ${server}"
      continue
    fi

    webPath=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${webServer}" "path")
    webUser=$(ini-parse "${currentPath}/../../../../env.properties" "no" "${webServer}" "user")
    webGroup=$(ini-parse "${currentPath}/../../../../env.properties" "no" "${webServer}" "group")
    webServerType=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${webServer}" "type")
    webServerVersion=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${webServer}" "version")
    httpPort=$(ini-parse "${currentPath}/../../../../env.properties" "no" "${webServer}" "httpPort")
    sslPort=$(ini-parse "${currentPath}/../../../../env.properties" "no" "${webServer}" "sslPort")
    proxyHost=$(ini-parse "${currentPath}/../../../../env.properties" "no" "${webServer}" "proxyHost")
    proxyPort=$(ini-parse "${currentPath}/../../../../env.properties" "no" "${webServer}" "proxyPort")

    serverParameters=("${parameters[@]}")

    serverParameters+=( "-n \"${server}\"" )
    serverParameters+=( "-w \"${webPath}\"" )
    if [[ -n "${webUser}" ]]; then
      serverParameters+=( "-u \"${webUser}\"" )
    fi
    if [[ -n "${webGroup}" ]]; then
      serverParameters+=( "-g \"${webGroup}\"" )
    fi
    serverParameters+=( "-t \"${webServerType}\"" )
    serverParameters+=( "-v \"${webServerVersion}\"" )
    if [[ -n "${httpPort}" ]]; then
      serverParameters+=( "-p \"${httpPort}\"" )
    fi
    if [[ -n "${sslPort}" ]]; then
      serverParameters+=( "-z \"${sslPort}\"" )
    fi
    if [[ -n "${proxyHost}" ]]; then
      serverParameters+=( "-x \"${proxyHost}\"" )
    fi
    if [[ -n "${proxyPort}" ]]; then
      serverParameters+=( "-y \"${proxyPort}\"" )
    fi

    if [[ "${serverType}" == "local" ]]; then
      executeScriptQuiet "${server}" "${scriptPath}" "${serverParameters[@]}"
    elif [[ "${serverType}" == "ssh" ]]; then
      sshUser=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${server}" "user")
      sshHost=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${server}" "host")
      executeScriptWithSSHQuiet "${server}" "${sshUser}" "${sshHost}" "${scriptPath}" "${serverParameters[@]}"
    fi

    webServerFound=1
  fi
done

if [[ "${webServerFound}" == 0 ]]; then
  echo "No web server settings found"
  exit 1
fi
