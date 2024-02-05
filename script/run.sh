#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${currentPath}/base.sh"

addSystemParameters()
{
  local systemName

  systemName=$(ini-parse "${currentPath}/../../env.properties" "yes" "system" "name")
  runParameters+=( "--systemName \"${systemName}\"" )

  environment=$(ini-parse "${currentPath}/../../env.properties" "no" "system" "environment")
  if [[ -n "${environment}" ]]; then
    runParameters+=( "--environment \"${environment}\"" )
  fi
}

addWebServerParameters()
{
  local webServerServerName="${1}"
  local webServer="${2}"

  local webServerType
  local webServerVersion
  local webServerHost
  local httpPort
  local sslPort
  local proxyHost
  local proxyPort
  local webPath
  local webUser
  local webGroup

  webServerServerType=$(ini-parse "${currentPath}/../../env.properties" "yes" "${webServerServerName}" "type")

  if [[ "${webServerServerType}" == "local" ]]; then
    webServerHost="localhost"
  elif [[ "${webServerServerType}" == "remote" ]] || [[ "${webServerServerType}" == "ssh" ]]; then
    webServerHost=$(ini-parse "${currentPath}/../../env.properties" "yes" "${webServerServerName}" "host")
  else
    >&2 echo "Unsupported web server server type: ${webServerServerType}"
    exit 1
  fi
  webServerType=$(ini-parse "${currentPath}/../../env.properties" "yes" "${webServer}" "type")
  webServerVersion=$(ini-parse "${currentPath}/../../env.properties" "yes" "${webServer}" "version")
  httpPort=$(ini-parse "${currentPath}/../../env.properties" "no" "${webServer}" "httpPort")
  sslPort=$(ini-parse "${currentPath}/../../env.properties" "no" "${webServer}" "sslPort")
  proxyHost=$(ini-parse "${currentPath}/../../env.properties" "no" "${webServer}" "proxyHost")
  proxyPort=$(ini-parse "${currentPath}/../../env.properties" "no" "${webServer}" "proxyPort")
  documentRootIsPub=$(ini-parse "${currentPath}/../../env.properties" "no" "${webServer}" "documentRootIsPub")
  webPath=$(ini-parse "${currentPath}/../../env.properties" "yes" "${webServer}" "path")
  webUser=$(ini-parse "${currentPath}/../../env.properties" "no" "${webServer}" "user")
  webGroup=$(ini-parse "${currentPath}/../../env.properties" "no" "${webServer}" "group")
  phpExecutable=$(ini-parse "${currentPath}/../../env.properties" "no" "${webServerServerName}" "php")

  runParameters+=( "--webServerServerName \"${webServerServerName}\"" )
  runParameters+=( "--webServerId \"${webServer}\"" )
  runParameters+=( "--webServerType \"${webServerType}\"" )
  runParameters+=( "--webServerVersion \"${webServerVersion}\"" )
  runParameters+=( "--webServerHost \"${webServerHost}\"" )
  if [[ -n "${httpPort}" ]]; then
    runParameters+=( "--httpPort \"${httpPort}\"" )
  fi
  if [[ -n "${sslPort}" ]]; then
    runParameters+=( "--sslPort \"${sslPort}\"" )
  fi
  if [[ -n "${proxyHost}" ]]; then
    runParameters+=( "--proxyHost \"${proxyHost}\"" )
  fi
  if [[ -n "${proxyPort}" ]]; then
    runParameters+=( "--proxyPort \"${proxyPort}\"" )
  fi
  if [[ -n "${documentRootIsPub}" ]]; then
    runParameters+=( "--documentRootIsPub \"${documentRootIsPub}\"" )
  else
    runParameters+=( "--documentRootIsPub \"yes\"" )
  fi
  runParameters+=( "--webPath \"${webPath}\"" )
  if [[ -n "${webUser}" ]]; then
    runParameters+=( "--webUser \"${webUser}\"" )
  fi
  if [[ -n "${webGroup}" ]]; then
    runParameters+=( "--webGroup \"${webGroup}\"" )
  fi

  if [[ -n "${phpExecutable}" ]]; then
    phpExecutableFound=0
    for runParameter in "${runParameters[@]}"; do
      if [[ "${runParameter}" =~ ^--phpExecutable ]]; then
        phpExecutableFound=1
      fi
    done

    if [[ "${phpExecutableFound}" == 0 ]]; then
      runParameters+=( "--phpExecutable \"${phpExecutable}\"" )
    fi
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

  databaseServerType=$(ini-parse "${currentPath}/../../env.properties" "yes" "${databaseServerName}" "type")

  if [[ "${databaseServerType}" == "local" ]]; then
    databaseHost="127.0.0.1"
  elif [[ "${databaseServerType}" == "remote" ]] || [[ "${databaseServerType}" == "ssh" ]]; then
    databaseHost=$(ini-parse "${currentPath}/../../env.properties" "yes" "${databaseServerName}" "host")
  else
    >&2 echo "Unsupported Database server type: ${databaseServerType}"
    exit 1
  fi
  databasePort=$(ini-parse "${currentPath}/../../env.properties" "yes" "${database}" "port")
  databaseUser=$(ini-parse "${currentPath}/../../env.properties" "yes" "${database}" "user")
  databasePassword=$(ini-parse "${currentPath}/../../env.properties" "yes" "${database}" "password" | sed 's/\$/\\\$/g')
  databaseName=$(ini-parse "${currentPath}/../../env.properties" "yes" "${database}" "name")
  databaseType=$(ini-parse "${currentPath}/../../env.properties" "yes" "${database}" "type")
  databaseVersion=$(ini-parse "${currentPath}/../../env.properties" "yes" "${database}" "version")

  runParameters+=( "--databaseServerName \"${databaseServerName}\"" )
  runParameters+=( "--databaseHost \"${databaseHost}\"" )
  runParameters+=( "--databasePort \"${databasePort}\"" )
  runParameters+=( "--databaseUser \"${databaseUser}\"" )
  runParameters+=( "--databasePassword \"${databasePassword}\"" )
  runParameters+=( "--databaseName \"${databaseName}\"" )
  runParameters+=( "--databaseType \"${databaseType}\"" )
  runParameters+=( "--databaseVersion \"${databaseVersion}\"" )
}

addDatabaseAnonymizeParameters()
{
  local databaseAnonymizeServerName="${1}"
  local databaseAnonymize="${2}"

  local databaseAnonymizeServerType
  local databaseAnonymizeHost
  local databaseAnonymizePort
  local databaseAnonymizeUser
  local databaseAnonymizePassword
  local databaseAnonymizeName
  local databaseAnonymizeType
  local databaseAnonymizeVersion

  databaseAnonymizeServerType=$(ini-parse "${currentPath}/../../env.properties" "yes" "${databaseAnonymizeServerName}" "type")

  if [[ "${databaseAnonymizeServerType}" == "local" ]]; then
    databaseAnonymizeHost="127.0.0.1"
  elif [[ "${databaseAnonymizeServerType}" == "remote" ]] || [[ "${databaseAnonymizeServerType}" == "ssh" ]]; then
    databaseAnonymizeHost=$(ini-parse "${currentPath}/../../env.properties" "yes" "${databaseAnonymizeServerName}" "host")
  else
    >&2 echo "Unsupported Database server type: ${databaseAnonymizeServerType}"
    exit 1
  fi
  databaseAnonymizePort=$(ini-parse "${currentPath}/../../env.properties" "yes" "${databaseAnonymize}" "port")
  databaseAnonymizeUser=$(ini-parse "${currentPath}/../../env.properties" "yes" "${databaseAnonymize}" "user")
  databaseAnonymizePassword=$(ini-parse "${currentPath}/../../env.properties" "yes" "${databaseAnonymize}" "password")
  databaseAnonymizeName=$(ini-parse "${currentPath}/../../env.properties" "yes" "${databaseAnonymize}" "name")
  databaseAnonymizeType=$(ini-parse "${currentPath}/../../env.properties" "yes" "${databaseAnonymize}" "type")
  databaseAnonymizeVersion=$(ini-parse "${currentPath}/../../env.properties" "yes" "${databaseAnonymize}" "version")

  runParameters+=( "--databaseAnonymizeServerName \"${databaseAnonymizeServerName}\"" )
  runParameters+=( "--databaseAnonymizeHost \"${databaseAnonymizeHost}\"" )
  runParameters+=( "--databaseAnonymizePort \"${databaseAnonymizePort}\"" )
  runParameters+=( "--databaseAnonymizeUser \"${databaseAnonymizeUser}\"" )
  runParameters+=( "--databaseAnonymizePassword \"${databaseAnonymizePassword}\"" )
  runParameters+=( "--databaseAnonymizeName \"${databaseAnonymizeName}\"" )
  runParameters+=( "--databaseAnonymizeType \"${databaseAnonymizeType}\"" )
  runParameters+=( "--databaseAnonymizeVersion \"${databaseAnonymizeVersion}\"" )
}

addElasticsearchParameters()
{
  local elasticsearchServerName="${1}"
  local elasticsearch="${2}"

  local elasticsearchServerType
  local elasticsearchEngine
  local elasticsearchVersion
  local elasticsearchHost
  local elasticsearchPort
  local elasticsearchPrefix
  local elasticsearchUser
  local elasticsearchPassword

  elasticsearchServerType=$(ini-parse "${currentPath}/../../env.properties" "yes" "${elasticsearchServerName}" "type")

  elasticsearchEngine=$(ini-parse "${currentPath}/../../env.properties" "no" "${elasticsearch}" "engine")
  elasticsearchVersion=$(ini-parse "${currentPath}/../../env.properties" "yes" "${elasticsearch}" "version")
  if [[ "${elasticsearchServerType}" == "local" ]]; then
    elasticsearchHost="localhost"
  elif [[ "${elasticsearchServerType}" == "ssh" ]]; then
    elasticsearchHost=$(ini-parse "${currentPath}/../../env.properties" "yes" "${elasticsearchServerName}" "host")
  else
    >&2 echo "Unsupported Elasticsearch server type: ${elasticsearchServerType}"
    exit 1
  fi
  elasticsearchPort=$(ini-parse "${currentPath}/../../env.properties" "yes" "${elasticsearch}" "port")
  elasticsearchPrefix=$(ini-parse "${currentPath}/../../env.properties" "no" "${elasticsearch}" "prefix")
  elasticsearchUser=$(ini-parse "${currentPath}/../../env.properties" "no" "${elasticsearch}" "user")
  elasticsearchPassword=$(ini-parse "${currentPath}/../../env.properties" "no" "${elasticsearch}" "password")

  if [[ -z "${elasticsearchPrefix}" ]]; then
    elasticsearchPrefix="magento"
  fi

  runParameters+=( "--elasticsearchServerName \"${elasticsearchServerName}\"" )
  if [[ -n "${elasticsearchEngine}" ]]; then
    runParameters+=( "--elasticsearchEngine \"${elasticsearchEngine}\"" )
  fi
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

addOpenSearchParameters()
{
  local openSearchServerName="${1}"
  local openSearch="${2}"

  local openSearchServerType
  local openSearchEngine
  local openSearchVersion
  local openSearchHost
  local openSearchPort
  local openSearchPrefix
  local openSearchUser
  local openSearchPassword

  openSearchServerType=$(ini-parse "${currentPath}/../../env.properties" "yes" "${openSearchServerName}" "type")

  openSearchEngine=$(ini-parse "${currentPath}/../../env.properties" "no" "${openSearch}" "engine")
  openSearchVersion=$(ini-parse "${currentPath}/../../env.properties" "yes" "${openSearch}" "version")
  if [[ "${openSearchServerType}" == "local" ]]; then
    openSearchHost="localhost"
  elif [[ "${openSearchServerType}" == "ssh" ]]; then
    openSearchHost=$(ini-parse "${currentPath}/../../env.properties" "yes" "${openSearchServerName}" "host")
  else
    >&2 echo "Unsupported OpenSearch server type: ${openSearchServerType}"
    exit 1
  fi
  openSearchPort=$(ini-parse "${currentPath}/../../env.properties" "yes" "${openSearch}" "port")
  openSearchPrefix=$(ini-parse "${currentPath}/../../env.properties" "no" "${openSearch}" "prefix")
  openSearchUser=$(ini-parse "${currentPath}/../../env.properties" "no" "${openSearch}" "user")
  openSearchPassword=$(ini-parse "${currentPath}/../../env.properties" "no" "${openSearch}" "password")

  if [[ -z "${openSearchPrefix}" ]]; then
    openSearchPrefix="magento"
  fi

  runParameters+=( "--openSearchServerName \"${openSearchServerName}\"" )
  if [[ -n "${openSearchEngine}" ]]; then
    runParameters+=( "--openSearchEngine \"${openSearchEngine}\"" )
  fi
  runParameters+=( "--openSearchVersion \"${openSearchVersion}\"" )
  runParameters+=( "--openSearchHost \"${openSearchHost}\"" )
  runParameters+=( "--openSearchPort \"${openSearchPort}\"" )
  runParameters+=( "--openSearchPrefix \"${openSearchPrefix}\"" )
  if [[ -n "${openSearchUser}" ]]; then
    runParameters+=( "--openSearchUser \"${openSearchUser}\"" )
  fi
  if [[ -n "${openSearchPassword}" ]]; then
    runParameters+=( "--openSearchPassword \"${openSearchPassword}\"" )
  fi
}

addSmtpParameters()
{
  local smtpEnabled
  local smtpHost
  local smtpPort
  local smtpProtocol
  local smtpAuthentication
  local smtpUser
  local smtpPassword

  smtpEnabled=$(ini-parse "${currentPath}/../../env.properties" "yes" "smtp" "enabled")
  if [[ -z "${smtpEnabled}" ]]; then
    >&2 echo "No SMTP enabled specified!"
    exit 1
  fi
  runParameters+=( "--smtpEnabled \"${smtpEnabled}\"" )

  if [[ "${smtpEnabled}" == "yes" ]]; then
    smtpHost=$(ini-parse "${currentPath}/../../env.properties" "yes" "smtp" "host")
    if [[ -z "${smtpHost}" ]]; then
      >&2 echo "No SMTP host specified!"
      exit 1
    fi

    smtpPort=$(ini-parse "${currentPath}/../../env.properties" "yes" "smtp" "port")
    if [[ -z "${smtpPort}" ]]; then
      >&2 echo "No SMTP port specified!"
      exit 1
    fi

    smtpProtocol=$(ini-parse "${currentPath}/../../env.properties" "yes" "smtp" "protocol")
    if [[ -z "${smtpProtocol}" ]]; then
      >&2 echo "No SMTP protocol specified!"
      exit 1
    fi

    smtpAuthentication=$(ini-parse "${currentPath}/../../env.properties" "no" "smtp" "authentication")

    runParameters+=( "--smtpHost \"${smtpHost}\"" )
    runParameters+=( "--smtpPort \"${smtpPort}\"" )
    runParameters+=( "--smtpProtocol \"${smtpProtocol}\"" )

    if [[ -n "${smtpAuthentication}" ]]; then
      runParameters+=( "--smtpAuthentication \"${smtpAuthentication}\"" )

      if [[ "${smtpAuthentication}" != "none" ]]; then
        smtpUser=$(ini-parse "${currentPath}/../../env.properties" "no" "smtp" "user")
        smtpPassword=$(ini-parse "${currentPath}/../../env.properties" "no" "smtp" "password")

        runParameters+=( "--smtpUser \"${smtpUser}\"" )
        runParameters+=( "--smtpPassword \"${smtpPassword}\"" )
      fi
    fi
  fi
}

executeServers="${1}"
shift
scriptPath="${1}"
shift
parameters=("$@")

if [[ ! -f "${currentPath}/../../env.properties" ]]; then
  >&2 echo "No environment specified!"
  exit 1
fi

if [[ -z "${executeScript}" ]]; then
  executeScript="executeScript"
fi

if [[ -z "${executeScriptWithSSH}" ]]; then
  executeScriptWithSSH="executeScriptWithSSH"
fi

#readarray -d , -t executeServerList < <(printf '%s' "${executeServers}")
IFS=, read -d "" -r -a executeServerList < <(printf '%s' "${executeServers}") || echo -n ""

executeServer="${executeServerList[0]}"
#readarray -d : -t executeServerParts < <(printf '%s' "${executeServer}")
IFS=: read -d "" -r -a executeServerParts < <(printf '%s' "${executeServer}") || echo -n ""
#readarray -d : -t executeServerParts < <(printf '%s' "${executeServer}")
IFS=: read -d "" -r -a executeServerParts < <(printf '%s' "${executeServer}") || echo -n ""
executeServerSystem="${executeServerParts[0]}"
executeServerName="${executeServerParts[1]}"
if [[ -z "${executeServerName}" ]]; then
  executeServerName="single"
fi

if [[ "${executeServerSystem}" == "host" ]]; then
  hostList=( $(ini-parse "${currentPath}/../../env.properties" "yes" "system" "host") )
  if [[ "${#hostList[@]}" -eq 0 ]]; then
    >&2 echo "No hosts specified!"
    exit 1
  fi

  for hostName in "${hostList[@]}"; do
    if [[ "${executeServerName}" == "${hostName}" ]] || [[ "${executeServerName}" == "all" ]] || [[ "${executeServerName}" == "single" ]]; then
      runParameters=("${parameters[@]}")

      addHostParameters "${hostName}"

      if [[ "${#executeServerList[@]}" -gt 1 ]]; then
        subExecuteServerList=( "${executeServerList[@]:1}" )
        subExecuteServers=$(IFS=,; printf '%s' "${subExecuteServerList[*]}")
        "${currentPath}/run.sh" "${subExecuteServers}" "${scriptPath}" "${runParameters[@]}"
      else
        "${currentPath}/run.sh" "all:all" "${scriptPath}" "${runParameters[@]}"
      fi

      if [[ "${executeServerName}" == "single" ]]; then
        exit 0
      fi
    fi
  done

  exit 0
fi

serverList=( $(ini-parse "${currentPath}/../../env.properties" "no" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  if [[ "${executeServerName}" == "skip" ]] || [[ "${executeServerName}" == "ignore" ]]; then
    exit 0
  else
    >&2 echo "Could not find any server to run: ${executeServerSystem}:${executeServerName}"
    exit 1
  fi
fi

# shellcheck disable=SC2235
if [[ "${#executeServerList[@]}" -eq 1 ]] && [[ "${executeServerSystem}" == "all" ]]; then
  executeOnAll=1
elif [[ "${#executeServerList[@]}" -eq 1 ]] && ([[ "${executeServerSystem}" == "system" ]] || [[ "${executeServerSystem}" == "install" ]] || [[ "${executeServerSystem}" == "config" ]] || [[ "${executeServerSystem}" == "smtp" ]]); then
  if [[ "${executeServerName}" == "local" ]]; then
    runParameters=("${parameters[@]}")
    if [[ "${executeServerSystem}" == "system" ]]; then
      addSystemParameters
    elif [[ "${executeServerSystem}" == "install" ]]; then
      addInstallParameters
    elif [[ "${executeServerSystem}" == "config" ]]; then
      addConfigParameters
    elif [[ "${executeServerSystem}" == "smtp" ]]; then
      addSmtpParameters
    fi
    "${executeScript}" "local" "${scriptPath}" "${runParameters[@]}"
    exit 0
  else
    executeOnAll=1
  fi
elif [[ "${#executeServerList[@]}" -gt 1 ]] && ([[ "${executeServerSystem}" == "system" ]] || [[ "${executeServerSystem}" == "install" ]] || [[ "${executeServerSystem}" == "config" ]] || [[ "${executeServerSystem}" == "smtp" ]]); then
  runParameters=("${parameters[@]}")
  if [[ "${executeServerSystem}" == "system" ]]; then
    addSystemParameters
  elif [[ "${executeServerSystem}" == "install" ]]; then
    addInstallParameters
  elif [[ "${executeServerSystem}" == "config" ]]; then
    addConfigParameters
  elif [[ "${executeServerSystem}" == "smtp" ]]; then
    addSmtpParameters
  fi
  subExecuteServerList=( "${executeServerList[@]:1}" )
  subExecuteServers=$(IFS=,; printf '%s' "${subExecuteServerList[*]}")
  "${currentPath}/run.sh" "${subExecuteServers}" "${scriptPath}" "${runParameters[@]}"
  exit 0
else
  executeOnAll=0
fi

foundAnyServer=0

for serverName in "${serverList[@]}"; do
  serverSystem=$(ini-parse "${currentPath}/../../env.properties" "no" "${serverName}" "${executeServerSystem}")

  if [[ -n "${serverSystem}" ]] || [[ "${executeOnAll}" == 1 ]]; then
    if [[ "${executeServerName}" == "${serverName}" ]] || [[ "${executeServerName}" == "single" ]] || [[ "${executeServerName}" == "skip" ]] || [[ "${executeServerName}" == "ignore" ]] || [[ "${executeServerName}" == "all" ]] || [[ "${executeOnAll}" == 1 ]]; then
      foundAnyServer=1

      runParameters=("${parameters[@]}")

      if [[ "${executeServerSystem}" == "system" ]]; then
        addSystemParameters
      elif [[ "${executeServerSystem}" == "install" ]]; then
        addInstallParameters
      elif [[ "${executeServerSystem}" == "config" ]]; then
        addConfigParameters
      elif [[ "${executeServerSystem}" == "smtp" ]]; then
        addSmtpParameters
      elif [[ "${executeServerSystem}" == "webServer" ]]; then
        addWebServerParameters "${serverName}" "${serverSystem}"
      elif [[ "${executeServerSystem}" == "database" ]]; then
        addDatabaseParameters "${serverName}" "${serverSystem}"
      elif [[ "${executeServerSystem}" == "databaseAnonymize" ]]; then
        addDatabaseAnonymizeParameters "${serverName}" "${serverSystem}"
      elif [[ "${executeServerSystem}" == "redisCache" ]]; then
        addRedisCacheParameters "${serverName}" "${serverSystem}"
      elif [[ "${executeServerSystem}" == "redisFPC" ]]; then
        addRedisFPCParameters "${serverName}" "${serverSystem}"
      elif [[ "${executeServerSystem}" == "redisSession" ]]; then
        addRedisSessionParameters "${serverName}" "${serverSystem}"
      elif [[ "${executeServerSystem}" == "elasticsearch" ]]; then
        addElasticsearchParameters "${serverName}" "${serverSystem}"
      elif [[ "${executeServerSystem}" == "openSearch" ]]; then
        addOpenSearchParameters "${serverName}" "${serverSystem}"
      fi

      if [[ "${#executeServerList[@]}" -eq 1 ]]; then
        serverType=$(ini-parse "${currentPath}/../../env.properties" "yes" "${serverName}" "type")

        if [[ "${serverType}" == "local" ]] || [[ "${serverType}" == "remote" ]]; then
          "${executeScript}" "${serverName}" "${scriptPath}" "${runParameters[@]}"
        elif [[ "${serverType}" == "ssh" ]]; then
          sshUser=$(ini-parse "${currentPath}/../../env.properties" "yes" "${serverName}" "user")
          sshHost=$(ini-parse "${currentPath}/../../env.properties" "yes" "${serverName}" "host")
          "${executeScriptWithSSH}" "${serverName}" "${sshUser}" "${sshHost}" "${scriptPath}" "${runParameters[@]}"
        fi
      else
        subExecuteServerList=( "${executeServerList[@]:1}" )
        subExecuteServers=$(IFS=,; printf '%s' "${subExecuteServerList[*]}")
        "${currentPath}/run.sh" "${subExecuteServers}" "${scriptPath}" "${runParameters[@]}"
      fi

      if [[ "${executeServerName}" == "single" ]] || [[ "${executeServerName}" == "skip" ]] || [[ "${executeServerName}" == "ignore" ]]; then
        break
      fi
    fi
  fi
done

if [[ "${foundAnyServer}" == 0 ]]; then
  if [[ "${executeServerName}" == "skip" ]]; then
    if [[ "${#executeServerList[@]}" -eq 1 ]]; then
      "${currentPath}/run.sh" "all:all" "${scriptPath}" "${parameters[@]}"
    else
      subExecuteServerList=( "${executeServerList[@]:1}" )
      subExecuteServers=$(IFS=,; printf '%s' "${subExecuteServerList[*]}")
      "${currentPath}/run.sh" "${subExecuteServers}" "${scriptPath}" "${parameters[@]}"
    fi
  elif [[ "${executeServerName}" == "ignore" ]]; then
    if [[ "${#executeServerList[@]}" -eq 1 ]]; then
      exit 0
    else
      subExecuteServerList=( "${executeServerList[@]:1}" )
      subExecuteServers=$(IFS=,; printf '%s' "${subExecuteServerList[*]}")
      "${currentPath}/run.sh" "${subExecuteServers}" "${scriptPath}" "${parameters[@]}"
    fi
  else
    >&2 echo "Could not find any server to run: ${executeServerSystem}:${executeServerName}"
    exit 1
  fi
fi
