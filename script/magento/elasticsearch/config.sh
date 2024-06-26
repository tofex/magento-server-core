#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${currentPath}/../../base.sh"

scriptPath="${1}"
shift
parameters=("$@")

for parameter in "${parameters[@]}"; do
  if [[ "${parameter}" == "-m" ]] || [[ "${parameter}" == "-e" ]] || [[ "${parameter}" == "-d" ]] || [[ "${parameter}" == "-r" ]] || [[ "${parameter}" == "-c" ]] || [[ "${parameter}" == "-n" ]] || [[ "${parameter}" == "-v" ]] || [[ "${parameter}" == "-o" ]] || [[ "${parameter}" == "-p" ]] || [[ "${parameter}" == "-u" ]] || [[ "${parameter}" == "-w" ]] || [[ "${parameter}" == "-s" ]] || [[ "${parameter}" == "-i" ]] || [[ "${parameter}" == "-j" ]]; then
    echo "Restricted parameter key used: ${parameter} for script: ${scriptPath}"
    exit 1
  fi
done

if [[ ! -f "${currentPath}/../../../../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

magentoVersion=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "install" "magentoVersion")
if [[ -z "${magentoVersion}" ]]; then
  echo "No magento version specified!"
  exit 1
fi

magentoEdition=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "install" "magentoEdition")
if [[ -z "${magentoEdition}" ]]; then
  echo "No magento edition specified!"
  exit 1
fi

magentoMode=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "install" "magentoMode")
if [[ -z "${magentoMode}" ]]; then
  echo "No magento mode specified!"
  exit 1
fi

repositoryList=( $(ini-parse "${currentPath}/../../../../env.properties" "yes" "install" "repositories") )
if [[ "${#repositoryList[@]}" -eq 0 ]]; then
  echo "No composer repositories specified!"
  exit 1
fi

repositories=$(IFS=,; printf '%s' "${repositoryList[*]}")

cryptKey=$(ini-parse "${currentPath}/../../../../env.properties" "no" "install" "cryptKey")

parameters+=( "-m \"${magentoVersion}\"" )
parameters+=( "-e \"${magentoEdition}\"" )
parameters+=( "-d \"${magentoMode}\"" )
parameters+=( "-r \"${repositories}\"" )
if [[ -n "${cryptKey}" ]]; then
  parameters+=( "-c \"${cryptKey}\"" )
fi

serverList=( $(ini-parse "${currentPath}/../../../../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

serverName=

for server in "${serverList[@]}"; do
  elasticsearch=$(ini-parse "${currentPath}/../../../../env.properties" "no" "${server}" "elasticsearch")

  if [[ -n "${elasticsearch}" ]]; then
    serverType=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${server}" "type")

    if [[ "${serverType}" != "local" ]] && [[ "${serverType}" != "ssh" ]]; then
      echo "Invalid elasticsearch server type: ${serverType} of server: ${server}"
      continue
    fi

    serverName="${server}"

    break
  fi
done

if [[ -z "${serverName}" ]]; then
  echo "No elasticsearch settings found"
  exit 1
fi

serverType=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${serverName}" "type")

if [[ "${serverType}" != "local" ]] && [[ "${serverType}" != "ssh" ]]; then
  echo "Invalid elasticsearch server type: ${serverType} of server: ${serverName}"
  exit 1
fi

elasticsearchVersion=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${elasticsearch}" "version")
if [[ "${serverType}" == "local" ]]; then
  elasticsearchHost="localhost"
else
  elasticsearchHost=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${serverName}" "host")
fi
elasticsearchPort=$(ini-parse "${currentPath}/../../../../env.properties" "no" "${elasticsearch}" "port")
elasticsearchUser=$(ini-parse "${currentPath}/../../../../env.properties" "no" "${elasticsearch}" "user")
elasticsearchPassword=$(ini-parse "${currentPath}/../../../../env.properties" "no" "${elasticsearch}" "password")

parameters+=( "-n \"${serverName}\"" )
parameters+=( "-v \"${elasticsearchVersion}\"" )
parameters+=( "-o \"${elasticsearchHost}\"" )
parameters+=( "-p \"${elasticsearchPort}\"" )
if [[ -n "${elasticsearchUser}" ]]; then
  parameters+=( "-u \"${elasticsearchUser}\"" )
fi
if [[ -n "${elasticsearchPassword}" ]]; then
  parameters+=( "-w \"${elasticsearchPassword}\"" )
fi

parameters+=( "-s \"script:${currentPath}/../../../../config/merge/web-server.sh:merge.sh\"" )
parameters+=( "-i \"script:${currentPath}/../../../../config/merge.php\"" )
parameters+=( "-j \"script:${currentPath}/../../../../config/add.php\"" )

if [[ "${serverType}" == "local" ]]; then
  executeScript "${serverName}" "${scriptPath}" "${parameters[@]}"
elif [[ "${serverType}" == "ssh" ]]; then
  sshUser=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${serverName}" "user")
  sshHost=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${serverName}" "host")
  environment=$(ini-parse "${currentPath}/../../../../env.properties" "no" "system" "environment")
  if [[ -z "${environment}" ]]; then
    environment="no"
  fi
  executeScriptWithSSH "${serverName}" "${sshUser}" "${sshHost}" "${environment}" "${scriptPath}" "${parameters[@]}"
fi
