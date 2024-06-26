#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${currentPath}/../../base.sh"

scriptPath="${1}"
shift
parameters=("$@")

for parameter in "${parameters[@]}"; do
  if [[ "${parameter}" == "-m" ]] || [[ "${parameter}" == "-e" ]] || [[ "${parameter}" == "-d" ]] || [[ "${parameter}" == "-r" ]] || [[ "${parameter}" == "-c" ]] || [[ "${parameter}" == "-o" ]] || [[ "${parameter}" == "-p" ]] || [[ "${parameter}" == "-u" ]] || [[ "${parameter}" == "-s" ]] || [[ "${parameter}" == "-b" ]] || [[ "${parameter}" == "-t" ]] || [[ "${parameter}" == "-v" ]]; then
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
  database=$(ini-parse "${currentPath}/../../../../env.properties" "no" "${server}" "database")

  if [[ -n "${database}" ]]; then
    serverType=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${server}" "type")

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

serverType=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${serverName}" "type")

if [[ "${serverType}" != "local" ]] && [[ "${serverType}" != "ssh" ]]; then
  echo "Invalid database server type: ${serverType} of server: ${serverName}"
  exit 1
fi

database=$(ini-parse "${currentPath}/../../../../env.properties" "no" "${serverName}" "database")

if [[ "${serverType}" == "local" ]]; then
  databaseHost="localhost"
elif [[ "${serverType}" == "ssh" ]]; then
  databaseHost=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${serverName}" "host")
fi

databasePort=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${database}" "port")
databaseUser=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${database}" "user")
databasePassword=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${database}" "password")
databaseName=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${database}" "name")
databaseType=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${database}" "type")
databaseVersion=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${database}" "version")

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

serverName=

for server in "${serverList[@]}"; do
  webServer=$(ini-parse "${currentPath}/../../../../env.properties" "no" "${server}" "webServer")

  if [[ -n "${webServer}" ]]; then
    serverType=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${server}" "type")

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

serverType=$(ini-parse "${currentPath}/../../../../env.properties" "yes" "${serverName}" "type")

if [[ "${serverType}" != "local" ]] && [[ "${serverType}" != "ssh" ]]; then
  echo "Invalid web server server type: ${serverType} of server: ${serverName}"
  exit 1
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

parameters+=( "-n \"${serverName}\"" )
parameters+=( "-w \"${webPath}\"" )
if [[ -n "${webUser}" ]]; then
  parameters+=( "-k \"${webUser}\"" )
fi
if [[ -n "${webGroup}" ]]; then
  parameters+=( "-g \"${webGroup}\"" )
fi
parameters+=( "-l \"${webServerType}\"" )
parameters+=( "-i \"${webServerVersion}\"" )
if [[ -n "${httpPort}" ]]; then
  parameters+=( "-j \"${httpPort}\"" )
fi
if [[ -n "${sslPort}" ]]; then
  parameters+=( "-z \"${sslPort}\"" )
fi
if [[ -n "${proxyHost}" ]]; then
  parameters+=( "-x \"${proxyHost}\"" )
fi
if [[ -n "${proxyPort}" ]]; then
  parameters+=( "-y \"${proxyPort}\"" )
fi

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
