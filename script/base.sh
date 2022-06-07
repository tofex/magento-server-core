#!/bin/bash -e

executeScript()
{
  local serverName="${1}"
  shift
  local filePath="${1}"
  shift
  local parameters=("$@")

  filePath=$(replacePlaceHolder "${filePath}")

  if [[ ! -f "${filePath}" ]]; then
    echo "Script at: ${filePath} does not exist"
    exit 1
  fi

  local parsedParameters=()
  for parameter in "${parameters[@]}"; do
    if [[ "${parameter}" =~ ^script:.* ]]; then
      local parameterFilePath="${parameter:7}"
      parameterFilePath=$(replacePlaceHolder "${parameterFilePath}")

      if [[ ! -f "${parameterFilePath}" ]]; then
        echo "Script at: ${parameterFilePath} does not exist"
        exit 1
      fi

      parameter="${parameterFilePath}"
    fi
    parsedParameters+=( "${parameter}" )
  done

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

  filePath=$(replacePlaceHolder "${filePath}")

  if [[ ! -f "${filePath}" ]]; then
    echo "Script at: ${filePath} does not exist"
    exit 1
  fi

  local parsedParameters=()
  local remoteFileNames=()
  for parameter in "${parameters[@]}"; do
    if [[ "${parameter}" =~ ^script:.* ]]; then
      local parameterFilePath="${parameter:7}"
      parameterFilePath=$(replacePlaceHolder "${parameterFilePath}")

      if [[ ! -f "${parameterFilePath}" ]]; then
        echo "Script at: ${parameterFilePath} does not exist"
        exit 1
      fi

      copyFileToSSH "${sshUser}" "${sshHost}" "${parameterFilePath}"

      local parameterFilePathName
      parameterFilePathName=$(basename "${parameterFilePath}")
      local parameterRemoteFileName="/tmp/${parameterFilePathName}"

      parameter="${parameterRemoteFileName}"

      remoteFileNames+=( "${parameterRemoteFileName}" )
    fi
    parsedParameters+=( "${parameter}" )
  done

  copyFileToSSH "${sshUser}" "${sshHost}" "${filePath}"

  local fileName
  fileName=$(basename "${filePath}")
  local remoteFileName="/tmp/${fileName}"

  echo "--- Executing script at: ${filePath} on remote server: ${serverName} [${sshUser}@${sshHost}] at: ${remoteFileName} ---"
  ssh "${sshUser}@${sshHost}" "${remoteFileName}" "${parsedParameters[@]}"

  removeFileFromSSH "${sshUser}" "${sshHost}" "${remoteFileName}"

  for remoteFileName in "${remoteFileNames[@]}"; do
    removeFileFromSSH "${sshUser}" "${sshHost}" "${remoteFileName}"
  done
}

replacePlaceHolder()
{
  local text="${1}"

  local textReplace
  textReplace=$(echo "${text}" | sed 's/\[\([[:alpha:]]*\)\]/\${\1}/g')
  if [[ "${text}" != "${textReplace}" ]]; then
    text=$(eval echo "${textReplace}")
  fi

  echo -n "${text}"
}

copyFileToSSH()
{
  local sshUser="${1}"
  local sshHost="${2}"
  local filePath="${3}"

  if [[ ! -f "${filePath}" ]]; then
    echo "File at: ${filePath} does not exist"
    exit 1
  fi

  local fileName
  fileName=$(basename "${filePath}")
  local remoteFileName="/tmp/${fileName}"

  echo "Getting server fingerprint"
  ssh-keyscan "${sshHost}" >> ~/.ssh/known_hosts 2>/dev/null

  echo "Copying file from: ${filePath} to: ${sshUser}@${sshHost}:${remoteFileName}"
  scp -q "${filePath}" "${sshUser}@${sshHost}:${remoteFileName}"
}

removeFileFromSSH()
{
  local sshUser="${1}"
  local sshHost="${2}"
  local filePath="${3}"

  echo "Getting server fingerprint"
  ssh-keyscan "${sshHost}" >> ~/.ssh/known_hosts 2>/dev/null

  echo "Removing file from: ${sshUser}@${sshHost}:${filePath}"
  ssh "${sshUser}@${sshHost}" "rm -rf ${filePath}"
}
