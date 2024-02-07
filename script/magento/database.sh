#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${currentPath}/../base.sh"

scriptPath="${1}"
shift
parameters=("$@")

for parameter in "${parameters[@]}"; do
  if [[ "${parameter}" == "-m" ]] || [[ "${parameter}" == "-e" ]] || [[ "${parameter}" == "-d" ]] || [[ "${parameter}" == "-r" ]] || [[ "${parameter}" == "-c" ]] || [[ "${parameter}" == "-o" ]] || [[ "${parameter}" == "-p" ]] || [[ "${parameter}" == "-u" ]] || [[ "${parameter}" == "-s" ]] || [[ "${parameter}" == "-b" ]] || [[ "${parameter}" == "-t" ]] || [[ "${parameter}" == "-v" ]]; then
    echo "Restricted parameter key used: ${parameter} for script: ${scriptPath}"
    exit 1
  fi
done

if [[ ! -f "${currentPath}/../../../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

magentoVersion=$(ini-parse "${currentPath}/../../../env.properties" "yes" "install" "magentoVersion")
if [[ -z "${magentoVersion}" ]]; then
  echo "No magento version specified!"
  exit 1
fi

magentoEdition=$(ini-parse "${currentPath}/../../../env.properties" "yes" "install" "magentoEdition")
if [[ -z "${magentoEdition}" ]]; then
  echo "No magento edition specified!"
  exit 1
fi

magentoMode=$(ini-parse "${currentPath}/../../../env.properties" "yes" "install" "magentoMode")
if [[ -z "${magentoMode}" ]]; then
  echo "No magento mode specified!"
  exit 1
fi

repositoryList=( $(ini-parse "${currentPath}/../../../env.properties" "yes" "install" "repositories") )
if [[ "${#repositoryList[@]}" -eq 0 ]]; then
  echo "No composer repositories specified!"
  exit 1
fi

repositories=$(IFS=,; printf '%s' "${repositoryList[*]}")

cryptKey=$(ini-parse "${currentPath}/../../../env.properties" "no" "install" "cryptKey")

parameters+=( "-m \"${magentoVersion}\"" )
parameters+=( "-e \"${magentoEdition}\"" )
parameters+=( "-d \"${magentoMode}\"" )
parameters+=( "-r \"${repositories}\"" )
if [[ -n "${cryptKey}" ]]; then
  parameters+=( "-c \"${cryptKey}\"" )
fi

serverList=( $(ini-parse "${currentPath}/../../../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

serverName=

for server in "${serverList[@]}"; do
  database=$(ini-parse "${currentPath}/../../../env.properties" "no" "${server}" "database")

  if [[ -n "${database}" ]]; then
    serverType=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${server}" "type")

    if [[ "${serverType}" != "local" ]] && [[ "${serverType}" != "remote" ]] && [[ "${serverType}" != "ssh" ]]; then
      >&2 echo "Invalid database server type: ${serverType} of server: ${server}"
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

serverType=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${serverName}" "type")

if [[ "${serverType}" != "local" ]] && [[ "${serverType}" != "remote" ]] && [[ "${serverType}" != "ssh" ]]; then
  >&2 echo "Invalid database server type: ${serverType} of server: ${serverName}"
  exit 1
fi

database=$(ini-parse "${currentPath}/../../../env.properties" "no" "${serverName}" "database")

if [[ "${serverType}" == "local" ]]; then
  databaseHost="127.0.0.1"
elif [[ "${serverType}" == "remote" ]] || [[ "${serverType}" == "ssh" ]]; then
  databaseHost=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${serverName}" "host")
fi

databasePort=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${database}" "port")
databaseUser=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${database}" "user")
databasePassword=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${database}" "password")
databaseName=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${database}" "name")
databaseType=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${database}" "type")
databaseVersion=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${database}" "version")

if [[ -z "${databaseHost}" ]]; then
  echo "No database host specified!"
  exit 1
fi

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

if [[ -z "${databaseType}" ]]; then
  echo "No database type specified!"
  exit 1
fi

if [[ -z "${databaseVersion}" ]]; then
  echo "No database version specified!"
  exit 1
fi

parameters+=( "-o \"${databaseHost}\"" )
parameters+=( "-p \"${databasePort}\"" )
parameters+=( "-u \"${databaseUser}\"" )
parameters+=( "-s \"${databasePassword}\"" )
parameters+=( "-b \"${databaseName}\"" )
parameters+=( "-t \"${databaseType}\"" )
parameters+=( "-v \"${databaseVersion}\"" )

if [[ "${serverType}" == "local" ]] || [[ "${serverType}" == "remote" ]]; then
  executeScript "${serverName}" "${scriptPath}" "${parameters[@]}"
elif [[ "${serverType}" == "ssh" ]]; then
  sshUser=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${serverName}" "user")
  sshHost=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${serverName}" "host")
  environment=$(ini-parse "${currentPath}/../../../env.properties" "no" "system" "environment")
  if [[ -z "${environment}" ]]; then
    environment="no"
  fi
  executeScriptWithSSH "${serverName}" "${sshUser}" "${sshHost}" "${environment}" "${scriptPath}" "${parameters[@]}"
fi
