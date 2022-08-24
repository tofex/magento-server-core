#!/bin/bash -e

currentBasePath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

executeScript()
{
  local serverName="${1}"
  shift
  local filePath="${1}"
  shift
  local parameters=("$@")

  filePath=$(replacePlaceHolder "${filePath}" "${parameters[@]}")

  if [[ ! -f "${filePath}" ]]; then
    echo "Script at: ${filePath} does not exist"
    exit 1
  fi

  local parsedParameters=()
  for parameter in "${parameters[@]}"; do
    if [[ "${parameter}" =~ ^file:.* ]] || [[ "${parameter}" =~ ^script:.* ]] || [[ "${parameter}" =~ ^-[[:alpha:]][[:space:]]*\"script: ]] || [[ "${parameter}" =~ ^--[[:alpha:]]+[[:space:]]*\"script: ]]; then
      local parameterFilePath
      if [[ "${parameter}" =~ ^file:.* ]]; then
        parameterFilePath="${parameter:5}"
      elif [[ "${parameter}" =~ ^script:.* ]]; then
        parameterFilePath="${parameter:7}"
      else
        readarray -d " " -t parameterParts < <(printf '%s' "${parameter}")
        parsedParameters+=( "${parameterParts[0]}" )
        parameterFilePath=$(echo "${parameterParts[1]}" | tr -d '"')
        parameterFilePath="${parameterFilePath:7}"
      fi
      parameterFilePath=$(replacePlaceHolder "${parameterFilePath}" "${parameters[@]}")

      if [[ "${parameterFilePath}" =~ ":" ]]; then
        readarray -d : -t parameterFilePathParts < <(printf '%s' "${parameterFilePath}")
        parameterFilePath="${parameterFilePathParts[0]}"
      fi

      if [[ ! -f "${parameterFilePath}" ]]; then
        echo "File at: ${parameterFilePath} does not exist"
        exit 1
      fi

      parameter="${parameterFilePath}"
    fi
    parsedParameters+=( "${parameter}" )
  done

  echo "--- Executing script at: ${filePath} on local server: ${serverName} ---"
  "${filePath}" "${parsedParameters[@]}"
}

executeScriptQuiet()
{
  local serverName="${1}"
  shift
  local filePath="${1}"
  shift
  local parameters=("$@")

  filePath=$(replacePlaceHolder "${filePath}" "${parameters[@]}")

  if [[ ! -f "${filePath}" ]]; then
    exit 1
  fi

  local parsedParameters=()
  for parameter in "${parameters[@]}"; do
    if [[ "${parameter}" =~ ^file:.* ]] || [[ "${parameter}" =~ ^script:.* ]] || [[ "${parameter}" =~ ^-[[:alpha:]][[:space:]]*\"script: ]] || [[ "${parameter}" =~ ^--[[:alpha:]]+[[:space:]]*\"script: ]]; then
      local parameterFilePath
      if [[ "${parameter}" =~ ^file:.* ]]; then
        parameterFilePath="${parameter:5}"
      elif [[ "${parameter}" =~ ^script:.* ]]; then
        parameterFilePath="${parameter:7}"
      else
        readarray -d " " -t parameterParts < <(printf '%s' "${parameter}")
        parsedParameters+=( "${parameterParts[0]}" )
        parameterFilePath=$(echo "${parameterParts[1]}" | tr -d '"')
        parameterFilePath="${parameterFilePath:7}"
      fi
      parameterFilePath=$(replacePlaceHolder "${parameterFilePath}" "${parameters[@]}")

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

  "${filePath}" "${parsedParameters[@]}"
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

  filePath=$(replacePlaceHolder "${filePath}" "${parameters[@]}")

  if [[ ! -f "${filePath}" ]]; then
    echo "Script at: ${filePath} does not exist"
    exit 1
  fi

  local parsedParameters=()
  local remoteFileNames=()
  for parameter in "${parameters[@]}"; do
    if [[ "${parameter}" =~ ^file:.* ]] || [[ "${parameter}" =~ ^script:.* ]] || [[ "${parameter}" =~ ^-[[:alpha:]][[:space:]]*\"script: ]] || [[ "${parameter}" =~ ^--[[:alpha:]]+[[:space:]]*\"script: ]]; then
      local parameterFilePath
      if [[ "${parameter}" =~ ^file:.* ]]; then
        parameterFilePath="${parameter:5}"
      elif [[ "${parameter}" =~ ^script:.* ]]; then
        parameterFilePath="${parameter:7}"
      else
        readarray -d " " -t parameterParts < <(printf '%s' "${parameter}")
        parsedParameters+=( "${parameterParts[0]}" )
        parameterFilePath=$(echo "${parameterParts[1]}" | tr -d '"')
        parameterFilePath="${parameterFilePath:7}"
      fi
      parameterFilePath=$(replacePlaceHolder "${parameterFilePath}" "${parameters[@]}")

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
        echo "File at: ${parameterFilePath} does not exist"
        exit 1
      fi

      copyFileToSSH "${sshUser}" "${sshHost}" "${parameterFilePath}" "${parameterRemoteFileName}"

      parameter="${parameterRemoteFileName}"

      remoteFileNames+=( "${parameterRemoteFileName}" )
    fi
    parsedParameters+=( "${parameter}" )
  done

  local fileName
  fileName=$(basename "${filePath}")
  local remoteFileName="/tmp/${fileName}"

  copyFileToSSH "${sshUser}" "${sshHost}" "${currentBasePath}/../prepare-parameters.sh" "/tmp/prepare-parameters.sh"
  copyFileToSSH "${sshUser}" "${sshHost}" "${filePath}" "${remoteFileName}"

  echo "--- Executing script at: ${filePath} on remote server: ${serverName} [${sshUser}@${sshHost}] at: ${remoteFileName} ---"
  # shellcheck disable=SC2029
  ssh "${sshUser}@${sshHost}" "${remoteFileName}" "${parsedParameters[@]}"

  removeFileFromSSH "${sshUser}" "${sshHost}" "${remoteFileName}"
  removeFileFromSSH "${sshUser}" "${sshHost}" "/tmp/prepare-parameters.sh"

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

  filePath=$(replacePlaceHolder "${filePath}" "${parameters[@]}")

  if [[ ! -f "${filePath}" ]]; then
    exit 1
  fi

  local parsedParameters=()
  local remoteFileNames=()
  for parameter in "${parameters[@]}"; do
    if [[ "${parameter}" =~ ^file:.* ]] || [[ "${parameter}" =~ ^script:.* ]] || [[ "${parameter}" =~ ^-[[:alpha:]][[:space:]]*\"script: ]] || [[ "${parameter}" =~ ^--[[:alpha:]]+[[:space:]]*\"script: ]]; then
      local parameterFilePath
      if [[ "${parameter}" =~ ^file:.* ]]; then
        parameterFilePath="${parameter:5}"
      elif [[ "${parameter}" =~ ^script:.* ]]; then
        parameterFilePath="${parameter:7}"
      else
        readarray -d " " -t parameterParts < <(printf '%s' "${parameter}")
        parsedParameters+=( "${parameterParts[0]}" )
        parameterFilePath=$(echo "${parameterParts[1]}" | tr -d '"')
        parameterFilePath="${parameterFilePath:7}"
      fi
      parameterFilePath=$(replacePlaceHolder "${parameterFilePath}" "${parameters[@]}")

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

  local fileName
  fileName=$(basename "${filePath}")
  local remoteFileName="/tmp/${fileName}"

  copyFileToSSHQuiet "${sshUser}" "${sshHost}" "${currentBasePath}/../prepare-parameters.sh" "/tmp/prepare-parameters.sh"
  copyFileToSSHQuiet "${sshUser}" "${sshHost}" "${filePath}" "${remoteFileName}"

  # shellcheck disable=SC2029
  ssh "${sshUser}@${sshHost}" "${remoteFileName}" "${parsedParameters[@]}"

  removeFileFromSSHQuiet "${sshUser}" "${sshHost}" "${remoteFileName}"

  for remoteFileName in "${remoteFileNames[@]}"; do
    removeFileFromSSHQuiet "${sshUser}" "${sshHost}" "${remoteFileName}"
  done
}

replacePlaceHolder()
{
  local text="${1}"
  shift

  local preparedParameters
  local parameter
  local key
  local value
  local textReplace

  declare -A preparedParameters
  while [[ "$#" -gt 0 ]]; do
    parameter="${1}"
    shift
    if [[ "${parameter:0:2}" == "--" ]] || [[ "${parameter}" =~ ^-[[:alpha:]][[:space:]]* ]] || [[ "${parameter}" =~ ^-\?$ ]]; then
      if [[ "${parameter}" =~ ^--[[:alpha:]]*[[:space:]] ]]; then
        readarray -d " " -t parameterParts < <(printf '%s' "${parameter}")
        key="${parameterParts[0]:2}"
        value=$(echo "${parameterParts[1]}" | tr -d '"')
        preparedParameters["${key}"]="${value}"
        continue
      fi
      if [[ "${parameter:0:2}" == "--" ]]; then
        key="${parameter:2}"
      elif [[ "${parameter}" =~ ^-\?$ ]]; then
        key="help"
      else
        key="${parameter:1}"
      fi
      if [[ "$#" -eq 0 ]]; then
        preparedParameters["${key}"]=1
      else
        value="${1}"
        if [[ "${value:0:2}" == "--" ]]; then
          preparedParameters["${key}"]=1
          continue
        fi
        shift
        # shellcheck disable=SC2034
        preparedParameters["${key}"]="${value}"
      fi
    fi
  done

  # shellcheck disable=SC2016
  textReplace=$(echo "${text}" | sed 's/\[\([[:alpha:]]*\)\]/\${preparedParameters\["\1\"]}/g')
  if [[ "${text}" != "${textReplace}" ]]; then
    text=$(eval echo "${textReplace}")
  fi

  echo -n "${text}"
}

declare -A preparedSSHAccess
export preparedSSHAccess

prepareSSH()
{
  local sshHost="${1}"
  local verbose="${2:-1}"
  local keyCount
  local changedKey
  local oldIFS
  local keys
  local key
  local currentHostKey
  local previousHostKeys
  local foundHostKey
  local sshHostIp
  local currentHostIpKey
  local previousHostIpKeys
  local foundHostIpKey

  if ! test "${preparedSSHAccess["${sshHost}"]+isset}"; then
    if [[ $(echo 'exit' | telnet "${sshHost}" 22 2>&1 | grep -c "Connected to" | cat) -gt 0 ]]; then
      if [[ "${verbose}" == 1 ]]; then
        echo "Preparing SSH access to host: ${sshHost}"
      fi

      keyCount=$(cat ~/.ssh/known_hosts | awk '{print $1, $2}' | grep -e "^${sshHost}\s" | awk '{print $2}' | sort | uniq -c | sort -nr | awk '{print $1}' | head -n 1)
      if [[ -z "${keyCount}" ]]; then
        if [[ "${verbose}" == 1 ]]; then
          echo "No previous keys found"
        fi
        keyCount=0
      fi

      if [[ "${keyCount}" -gt 0 ]]; then
        if [[ "${keyCount}" -eq 1 ]]; then
          changedKey=0
          oldIFS="${IFS}"
          IFS=$'\n'
          keys=( $(ssh-keyscan "${sshHost}" 2>/dev/null | grep -ve "^#" ) )
          IFS="${oldIFS}"
          for key in "${keys[@]}"; do
            if [[ $(cat ~/.ssh/known_hosts | grep -c "${key}" | cat) -eq 0 ]]; then
              if [[ "${verbose}" == 1 ]]; then
                echo "Found changed keys to host"
              fi
              changedKey=1
              break
            fi
          done
        else
          changedKey=1
        fi
        if [[ "${changedKey}" == 1 ]]; then
          if [[ "${verbose}" == 1 ]]; then
            echo "Removing all previous host keys"
          fi
          ssh-keygen -R "${sshHost}" >/dev/null 2>/dev/null
          if [[ "${verbose}" == 1 ]]; then
            echo "Adding all host keys"
          fi
          ssh-keyscan "${sshHost}" 2>/dev/null | grep -ve "^#" >> ~/.ssh/known_hosts
        fi
      else
        if [[ "${verbose}" == 1 ]]; then
          echo "Adding all host keys"
        fi
        ssh-keyscan "${sshHost}" 2>/dev/null | grep -ve "^#" >> ~/.ssh/known_hosts
      fi

      # shellcheck disable=SC2046
      currentHostKey=$(ssh-keygen -lf /dev/stdin <<<$(ssh-keyscan -t rsa "${sshHost}" 2>/dev/null | grep -ve "^#") | awk '{print $2}')
      previousHostKeys=( $(ssh-keygen -l -f ~/.ssh/known_hosts -F "${sshHost}" | grep -ve "^#" | awk '{print $3}') )
      foundHostKey=$(echo "${previousHostKeys[@]}" | grep -c "${currentHostKey}" | cat)
      if [[ "${foundHostKey}" == 0 ]]; then
        if [[ "${#previousHostKeys[@]}" -gt 0 ]]; then
          if [[ "${verbose}" == 1 ]]; then
            echo "Removing all previous host keys"
          fi
          ssh-keygen -R "${sshHost}" >/dev/null 2>/dev/null
          if [[ "${verbose}" == 1 ]]; then
            echo "Adding all host keys"
          fi
          ssh-keyscan "${sshHost}" 2>/dev/null | grep -ve "^#" >> ~/.ssh/known_hosts
        fi
      fi

      preparedSSHAccess["${sshHost}"]=1
    else
      >&2 echo "Could not access SSH host: ${sshHost}"
      exit 1
    fi
  fi

  sshHostIp=$(getent hosts "${sshHost}" | awk '{print $1}')

  if ! test "${preparedSSHAccess["${sshHostIp}"]+isset}"; then
    if [[ "${verbose}" == 1 ]]; then
      echo "Preparing SSH access to IP: ${sshHostIp}"
    fi

    # shellcheck disable=SC2046
    currentHostIpKey=$(ssh-keygen -lf /dev/stdin <<<$(ssh-keyscan -t rsa "${sshHostIp}" 2>/dev/null | grep -ve "^#") | awk '{print $2}')
    previousHostIpKeys=( $(ssh-keygen -l -f ~/.ssh/known_hosts -F "${sshHostIp}" | grep -ve "^#" | awk '{print $3}') )
    foundHostIpKey=$(echo "${previousHostIpKeys[@]}" | grep -c "${currentHostIpKey}" | cat)

    if [[ "${foundHostIpKey}" == 0 ]]; then
      if [[ "${#previousHostIpKeys[@]}" -gt 0 ]]; then
        if [[ "${verbose}" == 1 ]]; then
          echo "Removing all previous host keys"
        fi
        ssh-keygen -R "${sshHostIp}" >/dev/null 2>/dev/null
        if [[ "${verbose}" == 1 ]]; then
          echo "Adding all host keys"
        fi
        ssh-keyscan "${sshHostIp}" 2>/dev/null | grep -ve "^#" >> ~/.ssh/known_hosts
      fi
    fi

    preparedSSHAccess["${sshHostIp}"]=1
  fi
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

  prepareSSH "${sshHost}"

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

  prepareSSH "${sshHost}" 0

  scp -p -q "${filePath}" "${sshUser}@${sshHost}:${remoteFileName}"
}

removeFileFromSSH()
{
  local sshUser="${1}"
  local sshHost="${2}"
  local filePath="${3}"

  prepareSSH "${sshHost}"

  echo "Removing file from: ${sshUser}@${sshHost}:${filePath}"
  # shellcheck disable=SC2029
  ssh "${sshUser}@${sshHost}" "rm -rf ${filePath}"
}

removeFileFromSSHQuiet()
{
  local sshUser="${1}"
  local sshHost="${2}"
  local filePath="${3}"

  prepareSSH "${sshHost}" 0

  # shellcheck disable=SC2029
  ssh "${sshUser}@${sshHost}" "rm -rf ${filePath}"
}
