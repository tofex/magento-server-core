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

  echo "Executing script at: ${filePath} on local server: ${serverName}"
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

  echo "Executing script at: ${filePath} on remote server: ${serverName} [${sshUser}@${sshHost}] at: ${remoteFileName}"
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

addInstallParameters()
{
  local magentoVersion
  local magentoEdition
  local magentoMode
  local repositoryList
  local repositories
  local cryptKey

  magentoVersion=$(ini-parse "${currentBasePath}/../../env.properties" "yes" "install" "magentoVersion")
  if [[ -z "${magentoVersion}" ]]; then
    echo "No magento version specified!"
    exit 1
  fi

  magentoEdition=$(ini-parse "${currentBasePath}/../../env.properties" "yes" "install" "magentoEdition")
  if [[ -z "${magentoEdition}" ]]; then
    echo "No magento edition specified!"
    exit 1
  fi

  magentoMode=$(ini-parse "${currentBasePath}/../../env.properties" "yes" "install" "magentoMode")
  if [[ -z "${magentoMode}" ]]; then
    echo "No magento mode specified!"
    exit 1
  fi

  repositoryList=( $(ini-parse "${currentBasePath}/../../env.properties" "yes" "install" "repositories") )
  if [[ "${#repositoryList[@]}" -eq 0 ]]; then
    echo "No composer repositories specified!"
    exit 1
  fi
  repositories=$(IFS=,; printf '%s' "${repositoryList[*]}")

  cryptKey=$(ini-parse "${currentBasePath}/../../env.properties" "no" "install" "cryptKey")
  adminPath=$(ini-parse "${currentBasePath}/../../env.properties" "no" "install" "adminPath")

  runParameters+=( "--magentoVersion \"${magentoVersion}\"" )
  runParameters+=( "--magentoEdition \"${magentoEdition}\"" )
  runParameters+=( "--magentoMode \"${magentoMode}\"" )
  runParameters+=( "--repositories \"${repositories}\"" )
  if [[ -n "${cryptKey}" ]]; then
    runParameters+=( "--cryptKey \"${cryptKey}\"" )
  fi
  if [[ -n "${adminPath}" ]]; then
    runParameters+=( "--adminPath \"${adminPath}\"" )
  fi
}

addDatabaseParameters()
{
  local databaseServerName="${1}"
  local database="${2}"

  local databaseServerType
  local databaseHost
  local databasePort
  local databaseUser
  local databasePassword
  local databaseName
  local databaseType
  local databaseVersion

  databaseServerType=$(ini-parse "${currentBasePath}/../../env.properties" "yes" "${databaseServerName}" "type")

  if [[ "${databaseServerType}" == "local" ]]; then
    databaseHost="127.0.0.1"
  elif [[ "${databaseServerType}" == "ssh" ]]; then
    databaseHost=$(ini-parse "${currentBasePath}/../../env.properties" "yes" "${databaseServerName}" "host")
  else
    echo "Unsupported Database server type: ${databaseServerType}"
    exit 1
  fi
  databasePort=$(ini-parse "${currentBasePath}/../../env.properties" "yes" "${database}" "port")
  databaseUser=$(ini-parse "${currentBasePath}/../../env.properties" "yes" "${database}" "user")
  databasePassword=$(ini-parse "${currentBasePath}/../../env.properties" "yes" "${database}" "password")
  databaseName=$(ini-parse "${currentBasePath}/../../env.properties" "yes" "${database}" "name")
  databaseType=$(ini-parse "${currentBasePath}/../../env.properties" "yes" "${database}" "type")
  databaseVersion=$(ini-parse "${currentBasePath}/../../env.properties" "yes" "${database}" "version")

  runParameters+=( "--databaseServerName \"${databaseServerName}\"" )
  runParameters+=( "--databaseHost \"${databaseHost}\"" )
  runParameters+=( "--databasePort \"${databasePort}\"" )
  runParameters+=( "--databaseUser \"${databaseUser}\"" )
  runParameters+=( "--databasePassword \"${databasePassword}\"" )
  runParameters+=( "--databaseName \"${databaseName}\"" )
  runParameters+=( "--databaseType \"${databaseType}\"" )
  runParameters+=( "--databaseVersion \"${databaseVersion}\"" )
}

addRedisCacheParameters()
{
  local redisCacheServerName="${1}"
  local redisCache="${2}"

  local redisCacheServerType
  local redisCacheVersion
  local redisCacheHost
  local redisCachePort
  local redisCachePassword
  local redisCacheDatabase
  local redisCacheCachePrefix
  local redisCacheClassName

  redisCacheServerType=$(ini-parse "${currentBasePath}/../../env.properties" "yes" "${redisCacheServerName}" "type")

  redisCacheVersion=$(ini-parse "${currentBasePath}/../../env.properties" "yes" "${redisCache}" "version")
  if [[ "${redisCacheServerType}" == "local" ]]; then
    redisCacheHost="localhost"
  elif [[ "${redisCacheServerType}" == "ssh" ]]; then
    redisCacheHost=$(ini-parse "${currentBasePath}/../../env.properties" "yes" "${redisCacheServerName}" "host")
  else
    echo "Unsupported Redis cache server type: ${redisCacheServerType}"
    exit 1
  fi
  redisCachePort=$(ini-parse "${currentBasePath}/../../env.properties" "yes" "${redisCache}" "port")
  redisCachePassword=$(ini-parse "${currentBasePath}/../../env.properties" "no" "${redisCache}" "password")
  redisCacheDatabase=$(ini-parse "${currentBasePath}/../../env.properties" "yes" "${redisCache}" "database")
  redisCacheCachePrefix=$(ini-parse "${currentBasePath}/../../env.properties" "no" "${redisCache}" "cachePrefix")
  redisCacheClassName=$(ini-parse "${currentBasePath}/../../env.properties" "no" "${redisCache}" "className")

  runParameters+=( "--redisCacheServerName \"${redisCacheServerName}\"" )
  runParameters+=( "--redisCacheVersion \"${redisCacheVersion}\"" )
  runParameters+=( "--redisCacheHost \"${redisCacheHost}\"" )
  runParameters+=( "--redisCachePort \"${redisCachePort}\"" )
  if [[ -n "${redisCachePassword}" ]]; then
    runParameters+=( "--redisCachePassword \"${redisCachePassword}\"" )
  fi
  runParameters+=( "--redisCacheDatabase \"${redisCacheDatabase}\"" )
  if [[ -n "${redisCacheCachePrefix}" ]]; then
    runParameters+=( "--redisCacheCachePrefix \"${redisCacheCachePrefix}\"" )
  fi
  if [[ -n "${redisCacheClassName}" ]]; then
    runParameters+=( "--redisCacheClassName \"${redisCacheClassName}\"" )
  fi
}

addRedisFPCParameters()
{
  local redisFPCServerName="${1}"
  local redisFPC="${2}"

  local redisFPCServerType
  local redisFPCVersion
  local redisFPCHost
  local redisFPCPort
  local redisFPCPassword
  local redisFPCDatabase
  local redisFPCCachePrefix
  local redisFPCClassName

  redisFPCServerType=$(ini-parse "${currentBasePath}/../../env.properties" "yes" "${redisFPCServerName}" "type")

  redisFPCVersion=$(ini-parse "${currentBasePath}/../../env.properties" "yes" "${redisFPC}" "version")
  if [[ "${redisFPCServerType}" == "local" ]]; then
    redisFPCHost="localhost"
  elif [[ "${redisFPCServerType}" == "ssh" ]]; then
    redisFPCHost=$(ini-parse "${currentBasePath}/../../env.properties" "yes" "${redisFPCServerName}" "host")
  else
    echo "Unsupported Redis FPC server type: ${redisFPCServerType}"
    exit 1
  fi
  redisFPCPort=$(ini-parse "${currentBasePath}/../../env.properties" "yes" "${redisFPC}" "port")
  redisFPCPassword=$(ini-parse "${currentBasePath}/../../env.properties" "no" "${redisFPC}" "password")
  redisFPCDatabase=$(ini-parse "${currentBasePath}/../../env.properties" "yes" "${redisFPC}" "database")
  redisFPCCachePrefix=$(ini-parse "${currentBasePath}/../../env.properties" "no" "${redisFPC}" "cachePrefix")
  redisFPCClassName=$(ini-parse "${currentBasePath}/../../env.properties" "no" "${redisFPC}" "className")

  runParameters+=( "--redisFPCServerName \"${redisFPCServerName}\"" )
  runParameters+=( "--redisFPCVersion \"${redisFPCVersion}\"" )
  runParameters+=( "--redisFPCHost \"${redisFPCHost}\"" )
  runParameters+=( "--redisFPCPort \"${redisFPCPort}\"" )
  if [[ -n "${redisFPCPassword}" ]]; then
    runParameters+=( "--redisFPCPassword \"${redisFPCPassword}\"" )
  fi
  runParameters+=( "--redisFPCDatabase \"${redisFPCDatabase}\"" )
  if [[ -n "${redisFPCCachePrefix}" ]]; then
    runParameters+=( "--redisFPCCachePrefix \"${redisFPCCachePrefix}\"" )
  fi
  if [[ -n "${redisFPCClassName}" ]]; then
    runParameters+=( "--redisFPCClassName \"${redisFPCClassName}\"" )
  fi
}

addRedisSessionParameters()
{
  local redisSessionServerName="${1}"
  local redisSession="${2}"

  local redisSessionServerType
  local redisSessionVersion
  local redisSessionHost
  local redisSessionPort
  local redisSessionPassword
  local redisSessionDatabase

  redisSessionServerType=$(ini-parse "${currentBasePath}/../../env.properties" "yes" "${redisSessionServerName}" "type")

  redisSessionVersion=$(ini-parse "${currentBasePath}/../../env.properties" "yes" "${redisSession}" "version")
  if [[ "${redisSessionServerType}" == "local" ]]; then
    redisSessionHost="localhost"
  elif [[ "${redisSessionServerType}" == "ssh" ]]; then
    redisSessionHost=$(ini-parse "${currentBasePath}/../../env.properties" "yes" "${redisSessionServerName}" "host")
  else
    echo "Unsupported Redis session server type: ${redisSessionServerType}"
    exit 1
  fi
  redisSessionPort=$(ini-parse "${currentBasePath}/../../env.properties" "yes" "${redisSession}" "port")
  redisSessionPassword=$(ini-parse "${currentBasePath}/../../env.properties" "no" "${redisSession}" "password")
  redisSessionDatabase=$(ini-parse "${currentBasePath}/../../env.properties" "yes" "${redisSession}" "database")

  runParameters+=( "--redisSessionServerName \"${redisSessionServerName}\"" )
  runParameters+=( "--redisSessionVersion \"${redisSessionVersion}\"" )
  runParameters+=( "--redisSessionHost \"${redisSessionHost}\"" )
  runParameters+=( "--redisSessionPort \"${redisSessionPort}\"" )
  if [[ -n "${redisSessionPassword}" ]]; then
    runParameters+=( "--redisSessionPassword \"${redisSessionPassword}\"" )
  fi
  runParameters+=( "--redisSessionDatabase \"${redisSessionDatabase}\"" )
}

addElasticsearchParameters()
{
  local elasticsearchServerName="${1}"
  local elasticsearch="${2}"

  local elasticsearchServerType
  local elasticsearchVersion
  local elasticsearchHost
  local elasticsearchPort
  local elasticsearchPrefix
  local elasticsearchUser
  local elasticsearchPassword

  elasticsearchServerType=$(ini-parse "${currentBasePath}/../../env.properties" "yes" "${elasticsearchServerName}" "type")

  elasticsearchVersion=$(ini-parse "${currentBasePath}/../../env.properties" "yes" "${elasticsearch}" "version")
  if [[ "${elasticsearchServerType}" == "local" ]]; then
    elasticsearchHost="localhost"
  elif [[ "${elasticsearchServerType}" == "ssh" ]]; then
    elasticsearchHost=$(ini-parse "${currentBasePath}/../../env.properties" "yes" "${elasticsearchServerName}" "host")
  else
    echo "Unsupported Elasticsearch server type: ${elasticsearchServerType}"
    exit 1
  fi
  elasticsearchPort=$(ini-parse "${currentBasePath}/../../env.properties" "yes" "${elasticsearch}" "port")
  elasticsearchPrefix=$(ini-parse "${currentBasePath}/../../env.properties" "no" "${elasticsearch}" "prefix")
  elasticsearchUser=$(ini-parse "${currentBasePath}/../../env.properties" "no" "${elasticsearch}" "user")
  elasticsearchPassword=$(ini-parse "${currentBasePath}/../../env.properties" "no" "${elasticsearch}" "password")

  if [[ -z "${elasticsearchPrefix}" ]]; then
    elasticsearchPrefix="magento"
  fi

  runParameters+=( "--elasticsearchServerName \"${elasticsearchServerName}\"" )
  runParameters+=( "--elasticsearchVersion \"${elasticsearchVersion}\"" )
  runParameters+=( "--elasticsearchHost \"${elasticsearchHost}\"" )
  runParameters+=( "--elasticsearchPort \"${elasticsearchPort}\"" )
  runParameters+=( "--elasticsearchPrefix \"${elasticsearchPrefix}\"" )
  if [[ -n "${elasticsearchUser}" ]]; then
    runParameters+=( "--elasticsearchUser \"${elasticsearchUser}\"" )
  fi
  if [[ -n "${elasticsearchPassword}" ]]; then
    runParameters+=( "--elasticsearchPassword \"${elasticsearchPassword}\"" )
  fi
}

addHostParameters()
{
  local hostName="${1}"

  vhostList=( $(ini-parse "${currentBasePath}/../../env.properties" "yes" "${hostName}" "vhost") )
  scope=$(ini-parse "${currentBasePath}/../../env.properties" "yes" "${hostName}" "scope")
  code=$(ini-parse "${currentBasePath}/../../env.properties" "yes" "${hostName}" "code")
  sslCertFile=$(ini-parse "${currentBasePath}/../../env.properties" "no" "${hostName}" "sslCertFile")
  sslKeyFile=$(ini-parse "${currentBasePath}/../../env.properties" "no" "${hostName}" "sslKeyFile")
  sslTerminated=$(ini-parse "${currentBasePath}/../../env.properties" "no" "${hostName}" "sslTerminated")
  forceSsl=$(ini-parse "${currentBasePath}/../../env.properties" "no" "${hostName}" "forceSsl")
  requireIpList=( $(ini-parse "${currentBasePath}/../../env.properties" "no" "${hostName}" "requireIp") )
  allowUrlList=( $(ini-parse "${currentBasePath}/../../env.properties" "no" "${hostName}" "allowUrl") )
  basicAuthUserName=$(ini-parse "${currentBasePath}/../../env.properties" "no" "${hostName}" "basicAuthUserName")
  basicAuthPassword=$(ini-parse "${currentBasePath}/../../env.properties" "no" "${hostName}" "basicAuthPassword")

  runParameters+=( "--hostName \"${hostName}\"" )

  serverName="${vhostList[0]}"
  runParameters+=( "--hostServerName \"${serverName}\"" )

  hostAliasList=( "${vhostList[@]:1}" )
  if [[ "${#hostAliasList[@]}" -gt 0 ]]; then
    serverAlias=$( IFS=$','; echo "${hostAliasList[*]}" )
    runParameters+=( "--serverAlias \"${serverAlias}\"" )
  fi

  if [[ -n "${scope}" ]]; then
    runParameters+=( "--scope \"${scope}\"" )
  fi

  if [[ -n "${code}" ]]; then
    runParameters+=( "--code \"${code}\"" )
  fi

  if [[ -n "${sslCertFile}" ]]; then
    runParameters+=( "--sslCertFile \"${sslCertFile}\"" )
  fi

  if [[ -n "${sslKeyFile}" ]]; then
    runParameters+=( "--sslKeyFile \"${sslKeyFile}\"" )
  fi

  if [[ -n "${sslTerminated}" ]]; then
    runParameters+=( "--sslTerminated \"${sslTerminated}\"" )
  fi

  if [[ -n "${forceSsl}" ]]; then
    runParameters+=( "--forceSsl \"${forceSsl}\"" )
  fi

  requireIp=$( IFS=$','; echo "${requireIpList[*]}" )
  if [[ -n "${requireIp}" ]]; then
    runParameters+=( "--requireIp \"${requireIp}\"" )
  fi

  allowUrl=$( IFS=$','; echo "${allowUrlList[*]}" )
  if [[ -n "${allowUrl}" ]]; then
    runParameters+=( "--allowUrl \"${allowUrl}\"" )
  fi

  if [[ -n "${basicAuthUserName}" ]]; then
    runParameters+=( "--basicAuthUserName \"${basicAuthUserName}\"" )
  fi
  if [[ -n "${basicAuthPassword}" ]]; then
    runParameters+=( "--basicAuthPassword \"${basicAuthPassword}\"" )
  fi
}

addConfigParameters()
{
  runParameters+=( "--mergeScript \"script:${currentBasePath}/../../config/merge/web-server.sh:merge.sh\"" )
  runParameters+=( "--mergeScriptPhpScript \"script:${currentBasePath}/../../config/merge.php\"" )
  runParameters+=( "--addScript \"script:${currentBasePath}/../../config/add.php\"" )
}
