#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${currentPath}/../../../base.sh"

scriptPath="${1}"
shift
parameters=("$@")

for parameter in "${parameters[@]}"; do
  if [[ "${parameter}" == "-m" ]] || [[ "${parameter}" == "-e" ]] || [[ "${parameter}" == "-d" ]] || [[ "${parameter}" == "-r" ]] || [[ "${parameter}" == "-c" ]] || [[ "${parameter}" == "-o" ]] || [[ "${parameter}" == "-p" ]] || [[ "${parameter}" == "-w" ]] || [[ "${parameter}" == "-b" ]] || [[ "${parameter}" == "-v" ]] || [[ "${parameter}" == "-l" ]] || [[ "${parameter}" == "-x" ]] || [[ "${parameter}" == "-s" ]] || [[ "${parameter}" == "-i" ]] || [[ "${parameter}" == "-j" ]]; then
    echo "Restricted parameter key used: ${parameter} for script: ${scriptPath}"
    exit 1
  fi
done

if [[ ! -f "${currentPath}/../../../../../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

magentoVersion=$(ini-parse "${currentPath}/../../../../../env.properties" "yes" "install" "magentoVersion")
if [[ -z "${magentoVersion}" ]]; then
  echo "No magento version specified!"
  exit 1
fi

magentoEdition=$(ini-parse "${currentPath}/../../../../../env.properties" "yes" "install" "magentoEdition")
if [[ -z "${magentoEdition}" ]]; then
  echo "No magento edition specified!"
  exit 1
fi

magentoMode=$(ini-parse "${currentPath}/../../../../../env.properties" "yes" "install" "magentoMode")
if [[ -z "${magentoMode}" ]]; then
  echo "No magento mode specified!"
  exit 1
fi

repositoryList=( $(ini-parse "${currentPath}/../../../../../env.properties" "yes" "install" "repositories") )
if [[ "${#repositoryList[@]}" -eq 0 ]]; then
  echo "No composer repositories specified!"
  exit 1
fi

repositories=$(IFS=,; printf '%s' "${repositoryList[*]}")

cryptKey=$(ini-parse "${currentPath}/../../../../../env.properties" "no" "install" "cryptKey")

parameters+=( "-m \"${magentoVersion}\"" )
parameters+=( "-e \"${magentoEdition}\"" )
parameters+=( "-d \"${magentoMode}\"" )
parameters+=( "-r \"${repositories}\"" )
if [[ -n "${cryptKey}" ]]; then
  parameters+=( "-c \"${cryptKey}\"" )
fi

serverList=( $(ini-parse "${currentPath}/../../../../../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

serverName=

for server in "${serverList[@]}"; do
  redisCache=$(ini-parse "${currentPath}/../../../../../env.properties" "no" "${server}" "redisCache")

  if [[ -n "${redisCache}" ]]; then
    database=$(ini-parse "${currentPath}/../../../../../env.properties" "no" "${redisCache}" "database")

    if [[ -n "${database}" ]]; then
      serverType=$(ini-parse "${currentPath}/../../../../../env.properties" "yes" "${server}" "type")

      if [[ "${serverType}" != "local" ]] && [[ "${serverType}" != "ssh" ]]; then
        echo "Invalid Redis cache server type: ${serverType} of server: ${server}"
        continue
      fi

      serverName="${server}"
    fi

    break
  fi
done

if [[ -z "${serverName}" ]]; then
  exit 0
fi

serverType=$(ini-parse "${currentPath}/../../../../../env.properties" "yes" "${serverName}" "type")

if [[ "${serverType}" != "local" ]] && [[ "${serverType}" != "ssh" ]]; then
  echo "Invalid Redis cache server type: ${serverType} of server: ${serverName}"
  exit 1
fi

redisCache=$(ini-parse "${currentPath}/../../../../../env.properties" "no" "${serverName}" "redisCache")

if [[ "${serverType}" == "local" ]]; then
  host="localhost"
elif [[ "${serverType}" == "ssh" ]]; then
  host=$(ini-parse "${currentPath}/../../../../../env.properties" "yes" "${serverName}" "host")
fi

port=$(ini-parse "${currentPath}/../../../../../env.properties" "yes" "${redisCache}" "port")
password=$(ini-parse "${currentPath}/../../../../../env.properties" "no" "${redisCache}" "password")
database=$(ini-parse "${currentPath}/../../../../../env.properties" "no" "${redisCache}" "database")
version=$(ini-parse "${currentPath}/../../../../../env.properties" "yes" "${redisCache}" "version")

if [[ -z "${host}" ]]; then
  echo "No Redis cache host specified!"
  exit 1
fi

if [[ -z "${port}" ]]; then
  echo "No Redis cache port specified!"
  exit 1
fi

if [[ -z "${database}" ]]; then
  echo "No Redis cache database specified!"
  exit 1
fi

if [[ -z "${version}" ]]; then
  echo "No Redis cache version specified!"
  exit 1
fi

parameters+=( "-o \"${host}\"" )
parameters+=( "-p \"${port}\"" )
if [[ -n "${password}" ]]; then
  parameters+=( "-w \"${password}\"" )
fi
parameters+=( "-b \"${database}\"" )
parameters+=( "-v \"${version}\"" )
parameters+=( "-l \"${className}\"" )
parameters+=( "-x \"${cachePrefix}\"" )

parameters+=( "-s \"script:${currentPath}/../../../../config/merge/web-server.sh:merge.sh\"" )
parameters+=( "-i \"script:${currentPath}/../../../../config/merge.php\"" )
parameters+=( "-j \"script:${currentPath}/../../../../config/add.php\"" )

if [[ "${serverType}" == "local" ]]; then
  executeScript "${serverName}" "${scriptPath}" "${parameters[@]}"
elif [[ "${serverType}" == "ssh" ]]; then
  sshUser=$(ini-parse "${currentPath}/../../../../../env.properties" "yes" "${serverName}" "user")
  sshHost=$(ini-parse "${currentPath}/../../../../../env.properties" "yes" "${serverName}" "host")
  environment=$(ini-parse "${currentPath}/../../../../../env.properties" "no" "system" "environment")
  if [[ -z "${environment}" ]]; then
    environment="no"
  fi
  executeScriptWithSSH "${serverName}" "${sshUser}" "${sshHost}" "${environment}" "${scriptPath}" "${parameters[@]}"
fi
