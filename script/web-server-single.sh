#!/bin/bash -e

executeScript()
{
  local serverName="${1}"
  shift
  local filePath="${1}"
  shift
  local parameters=("$@")

  echo "--- Executing script at: ${filePath} on local server: ${serverName} ---"
  "${filePath}" "${parameters[@]}"
}

executeScriptWithSSH()
{
  local serverName="${1}"
  shift
  local sshUser="${1}"
  shift
  local sshHost="${1}"
  shift
  local filePath="${1}"
  shift
  local parameters=("$@")

  copyFileToSSH "${sshUser}" "${sshHost}" "${filePath}"

  local fileName
  fileName=$(basename "${filePath}")
  local remoteFileName="/tmp/${fileName}"

  echo "--- Executing script at: ${sshUser}@${sshHost}:${remoteFileName} on remote server: ${serverName} ---"
  ssh "${sshUser}@${sshHost}" "${remoteFileName}" "${parameters[@]}"

  removeFileFromSSH "${sshUser}" "${sshHost}" "${remoteFileName}"
}

copyFileToSSH()
{
  local sshUser="${1}"
  local sshHost="${2}"
  local filePath="${3}"

  local fileName
  fileName=$(basename "${filePath}")
  local remoteFileName="/tmp/${fileName}"

  echo "Copying file from: ${filePath} to: ${sshUser}@${sshHost}:${remoteFileName}"
  scp -q "${filePath}" "${sshUser}@${sshHost}:${remoteFileName}"
}

removeFileFromSSH()
{
  local sshUser="${1}"
  local sshHost="${2}"
  local filePath="${3}"

  echo "Removing file from: ${sshUser}@${sshHost}:${filePath}"
  ssh "${sshUser}@${sshHost}" "rm -rf ${filePath}"
}

scriptPath="${1}"
shift
parameters=("$@")

for parameter in "${parameters[@]}"; do
  if [[ "${parameter}" == "-w" ]] || [[ "${parameter}" == "-u" ]] || [[ "${parameter}" == "-g" ]]; then
    echo "Restricted parameter key used: ${parameter} for script: ${scriptPath}"
    exit 1
  fi
done

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

serverList=( $(ini-parse "${currentPath}/../../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

serverName=

for server in "${serverList[@]}"; do
  webServer=$(ini-parse "${currentPath}/../../env.properties" "no" "${server}" "webServer")

  if [[ -n "${webServer}" ]]; then
    serverType=$(ini-parse "${currentPath}/../../env.properties" "yes" "${server}" "type")

    if [[ "${serverType}" != "local" ]] && [[ "${serverType}" != "ssh" ]]; then
      echo "Invalid web server server type: ${serverType} of server: ${server}"
      continue
    fi

    serverName="${server}"

    break
  fi
done

if [[ -z "${serverName}" ]]; then
  echo "No web server settings found"
  exit 1
fi

serverType=$(ini-parse "${currentPath}/../../env.properties" "yes" "${serverName}" "type")

if [[ "${serverType}" != "local" ]] && [[ "${serverType}" != "ssh" ]]; then
  echo "Invalid web server server type: ${serverType} of server: ${serverName}"
  exit 1
fi

webPath=$(ini-parse "${currentPath}/../../env.properties" "yes" "${serverName}" "webPath")
webUser=$(ini-parse "${currentPath}/../../env.properties" "no" "${serverName}" "webUser")
webGroup=$(ini-parse "${currentPath}/../../env.properties" "no" "${serverName}" "webGroup")

parameters+=( "-w \"${webPath}\"" )
if [[ -n "${webUser}" ]]; then
  parameters+=( "-u \"${webUser}\"" )
fi
if [[ -n "${webGroup}" ]]; then
  parameters+=( "-g \"${webGroup}\"" )
fi

if [[ "${serverType}" == "local" ]]; then
  executeScript "${serverName}" "${scriptPath}" "${parameters[@]}"
elif [[ "${serverType}" == "ssh" ]]; then
  sshUser=$(ini-parse "${currentPath}/../../env.properties" "yes" "${serverName}" "user")
  sshHost=$(ini-parse "${currentPath}/../../env.properties" "yes" "${serverName}" "host")
  executeScriptWithSSH "${serverName}" "${sshUser}" "${sshHost}" "${scriptPath}" "${parameters[@]}"
fi
