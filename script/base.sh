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
    if [[ "${parameter}" =~ ^script:.* ]] || [[ "${parameter}" =~ ^-[[:alpha:]][[:space:]]*\"script: ]]; then
      local parameterFilePath
      if [[ "${parameter}" =~ ^script:.* ]]; then
        parameterFilePath="${parameter:7}"
      else
        readarray -d " " -t parameterParts < <(printf '%s' "${parameter}")
        parsedParameters+=( "${parameterParts[0]}" )
        parameterFilePath=$(echo "${parameterParts[1]}" | tr -d '"')
        parameterFilePath="${parameterFilePath:7}"
      fi
      parameterFilePath=$(replacePlaceHolder "${parameterFilePath}")

      if [[ "${parameterFilePath}" =~ ":" ]]; then
        readarray -d : -t parameterFilePathParts < <(printf '%s' "${parameterFilePath}")
        parameterFilePath="${parameterFilePathParts[0]}"
      fi

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

executeScriptQuiet()
{
  local serverName="${1}"
  shift
  local filePath="${1}"
  shift
  local parameters=("$@")

  filePath=$(replacePlaceHolder "${filePath}")

  if [[ ! -f "${filePath}" ]]; then
    exit 1
  fi

  local parsedParameters=()
  for parameter in "${parameters[@]}"; do
    if [[ "${parameter}" =~ ^script:.* ]] || [[ "${parameter}" =~ ^-[[:alpha:]][[:space:]]*\"script: ]]; then
      local parameterFilePath
      if [[ "${parameter}" =~ ^script:.* ]]; then
        parameterFilePath="${parameter:7}"
      else
        readarray -d " " -t parameterParts < <(printf '%s' "${parameter}")
        parsedParameters+=( "${parameterParts[0]}" )
        parameterFilePath=$(echo "${parameterParts[1]}" | tr -d '"')
        parameterFilePath="${parameterFilePath:7}"
      fi
      parameterFilePath=$(replacePlaceHolder "${parameterFilePath}")

      if [[ "${parameterFilePath}" =~ ":" ]]; then
        readarray -d : -t parameterFilePathParts < <(printf '%s' "${parameterFilePath}")
        parameterFilePath="${parameterFilePathParts[0]}"
      fi

      if [[ ! -f "${parameterFilePath}" ]]; then
        exit 1
      fi

      parameter="${parameterFilePath}"
    fi
    parsedParameters+=( "${parameter}" )
  done

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
    if [[ "${parameter}" =~ ^script:.* ]] || [[ "${parameter}" =~ ^-[[:alpha:]][[:space:]]*\"script: ]]; then
      local parameterFilePath
      if [[ "${parameter}" =~ ^script:.* ]]; then
        parameterFilePath="${parameter:7}"
      else
        readarray -d " " -t parameterParts < <(printf '%s' "${parameter}")
        parsedParameters+=( "${parameterParts[0]}" )
        parameterFilePath=$(echo "${parameterParts[1]}" | tr -d '"')
        parameterFilePath="${parameterFilePath:7}"
      fi
      parameterFilePath=$(replacePlaceHolder "${parameterFilePath}")

      local parameterRemoteFileName
      if [[ "${parameterFilePath}" =~ ":" ]]; then
        readarray -d : -t parameterFilePathParts < <(printf '%s' "${parameterFilePath}")
        parameterFilePath="${parameterFilePathParts[0]}"
        parameterRemoteFileName="/tmp/${parameterFilePathParts[1]}"
      else
        local parameterFilePathName
        parameterFilePathName=$(basename "${parameterFilePath}")
        parameterRemoteFileName="/tmp/${parameterFilePathName}"
      fi

      if [[ ! -f "${parameterFilePath}" ]]; then
        echo "Script at: ${parameterFilePath} does not exist"
        exit 1
      fi

      copyFileToSSH "${sshUser}" "${sshHost}" "${parameterFilePath}" "${parameterRemoteFileName}"

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

executeScriptWithSSHQuiet()
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
    exit 1
  fi

  local parsedParameters=()
  local remoteFileNames=()
  for parameter in "${parameters[@]}"; do
    if [[ "${parameter}" =~ ^script:.* ]] || [[ "${parameter}" =~ ^-[[:alpha:]][[:space:]]*\"script: ]]; then
      local parameterFilePath
      if [[ "${parameter}" =~ ^script:.* ]]; then
        parameterFilePath="${parameter:7}"
      else
        readarray -d " " -t parameterParts < <(printf '%s' "${parameter}")
        parsedParameters+=( "${parameterParts[0]}" )
        parameterFilePath=$(echo "${parameterParts[1]}" | tr -d '"')
        parameterFilePath="${parameterFilePath:7}"
      fi
      parameterFilePath=$(replacePlaceHolder "${parameterFilePath}")

      local parameterRemoteFileName
      if [[ "${parameterFilePath}" =~ ":" ]]; then
        readarray -d : -t parameterFilePathParts < <(printf '%s' "${parameterFilePath}")
        parameterFilePath="${parameterFilePathParts[0]}"
        parameterRemoteFileName="/tmp/${parameterFilePathParts[1]}"
      else
        local parameterFilePathName
        parameterFilePathName=$(basename "${parameterFilePath}")
        parameterRemoteFileName="/tmp/${parameterFilePathName}"
      fi

      if [[ ! -f "${parameterFilePath}" ]]; then
        exit 1
      fi

      copyFileToSSHQuiet "${sshUser}" "${sshHost}" "${parameterFilePath}" "${parameterRemoteFileName}"

      parameter="${parameterRemoteFileName}"

      remoteFileNames+=( "${parameterRemoteFileName}" )
    fi
    parsedParameters+=( "${parameter}" )
  done

  copyFileToSSHQuiet "${sshUser}" "${sshHost}" "${filePath}"

  local fileName
  fileName=$(basename "${filePath}")
  local remoteFileName="/tmp/${fileName}"

  ssh "${sshUser}@${sshHost}" "${remoteFileName}" "${parsedParameters[@]}"

  removeFileFromSSHQuiet "${sshUser}" "${sshHost}" "${remoteFileName}"

  for remoteFileName in "${remoteFileNames[@]}"; do
    removeFileFromSSHQuiet "${sshUser}" "${sshHost}" "${remoteFileName}"
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
  local remoteFileName="${4}"

  if [[ ! -f "${filePath}" ]]; then
    echo "File at: ${filePath} does not exist"
    exit 1
  fi

  local remoteFileName
  if [[ -z "${remoteFileName}" ]]; then
    local fileName
    fileName=$(basename "${filePath}")
    remoteFileName="/tmp/${fileName}"
  fi

  ssh-keyscan "${sshHost}" >> ~/.ssh/known_hosts 2>/dev/null

  echo "Copying file from: ${filePath} to: ${sshUser}@${sshHost}:${remoteFileName}"
  scp -p -q "${filePath}" "${sshUser}@${sshHost}:${remoteFileName}"
}

copyFileToSSHQuiet()
{
  local sshUser="${1}"
  local sshHost="${2}"
  local filePath="${3}"
  local remoteFileName="${4}"

  if [[ ! -f "${filePath}" ]]; then
    exit 1
  fi

  local remoteFileName
  if [[ -z "${remoteFileName}" ]]; then
    local fileName
    fileName=$(basename "${filePath}")
    remoteFileName="/tmp/${fileName}"
  fi

  ssh-keyscan "${sshHost}" >> ~/.ssh/known_hosts 2>/dev/null

  scp -p -q "${filePath}" "${sshUser}@${sshHost}:${remoteFileName}"
}

removeFileFromSSH()
{
  local sshUser="${1}"
  local sshHost="${2}"
  local filePath="${3}"

  ssh-keyscan "${sshHost}" >> ~/.ssh/known_hosts 2>/dev/null

  echo "Removing file from: ${sshUser}@${sshHost}:${filePath}"
  ssh "${sshUser}@${sshHost}" "rm -rf ${filePath}"
}

removeFileFromSSHQuiet()
{
  local sshUser="${1}"
  local sshHost="${2}"
  local filePath="${3}"

  ssh-keyscan "${sshHost}" >> ~/.ssh/known_hosts 2>/dev/null

  ssh "${sshUser}@${sshHost}" "rm -rf ${filePath}"
}
