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
  if [[ "${parameter}" == "-o" ]] || [[ "${parameter}" == "-p" ]] || [[ "${parameter}" == "-u" ]] || [[ "${parameter}" == "-s" ]] || [[ "${parameter}" == "-b" ]]; then
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
  database=$(ini-parse "${currentPath}/../../env.properties" "no" "${server}" "database")

  if [[ -n "${database}" ]]; then
    serverType=$(ini-parse "${currentPath}/../../env.properties" "yes" "${server}" "type")

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

serverType=$(ini-parse "${currentPath}/../../env.properties" "yes" "${serverName}" "type")

if [[ "${serverType}" != "local" ]] && [[ "${serverType}" != "ssh" ]]; then
  echo "Invalid database server type: ${serverType} of server: ${serverName}"
  exit 1
fi

database=$(ini-parse "${currentPath}/../../env.properties" "no" "${serverName}" "database")

if [[ "${serverType}" == "local" ]]; then
  databaseHost="localhost"
elif [[ "${serverType}" == "ssh" ]]; then
  databaseHost=$(ini-parse "${currentPath}/../../env.properties" "yes" "${serverName}" "host")
fi

databasePort=$(ini-parse "${currentPath}/../../env.properties" "yes" "${database}" "port")
databaseUser=$(ini-parse "${currentPath}/../../env.properties" "yes" "${database}" "user")
databasePassword=$(ini-parse "${currentPath}/../../env.properties" "yes" "${database}" "password")
databaseName=$(ini-parse "${currentPath}/../../env.properties" "yes" "${database}" "name")

if [[ -z "${databasePort}" ]]; then
  echo "No database port specified!"
  exit 1
fi

if [[ -z "${databaseUser}" ]]; then
  echo "No database user specified!"
  exit 1
fi

if [[ -z "${databasePassword}" ]]; then
  echo "No database password specified!"
  exit 1
fi

if [[ -z "${databaseName}" ]]; then
  echo "No database name specified!"
  exit 1
fi

parameters+=( "-o \"${databaseHost}\"" )
parameters+=( "-p \"${databasePort}\"" )
parameters+=( "-u \"${databaseUser}\"" )
parameters+=( "-s \"${databasePassword}\"" )
parameters+=( "-b \"${databaseName}\"" )

if [[ "${serverType}" == "local" ]]; then
  executeScript "${serverName}" "${scriptPath}" "${parameters[@]}"
elif [[ "${serverType}" == "ssh" ]]; then
  sshUser=$(ini-parse "${currentPath}/../../env.properties" "yes" "${serverName}" "user")
  sshHost=$(ini-parse "${currentPath}/../../env.properties" "yes" "${serverName}" "host")
  executeScriptWithSSH "${serverName}" "${sshUser}" "${sshHost}" "${scriptPath}" "${parameters[@]}"
fi
