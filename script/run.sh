#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

addInstallParameters()
{
  local magentoVersion
  local magentoEdition
  local magentoMode
  local repositoryList
  local repositories
  local cryptKey

  magentoVersion=$(ini-parse "${currentPath}/../../env.properties" "yes" "install" "magentoVersion")
  if [[ -z "${magentoVersion}" ]]; then
    echo "No magento version specified!"
    exit 1
  fi

  magentoEdition=$(ini-parse "${currentPath}/../../env.properties" "yes" "install" "magentoEdition")
  if [[ -z "${magentoEdition}" ]]; then
    echo "No magento edition specified!"
    exit 1
  fi

  magentoMode=$(ini-parse "${currentPath}/../../env.properties" "yes" "install" "magentoMode")
  if [[ -z "${magentoMode}" ]]; then
    echo "No magento mode specified!"
    exit 1
  fi

  repositoryList=( $(ini-parse "${currentPath}/../../env.properties" "yes" "install" "repositories") )
  if [[ "${#repositoryList[@]}" -eq 0 ]]; then
    echo "No composer repositories specified!"
    exit 1
  fi
  repositories=$(IFS=,; printf '%s' "${repositoryList[*]}")

  cryptKey=$(ini-parse "${currentPath}/../../env.properties" "no" "install" "cryptKey")

  runParameters+=( "--magentoVersion \"${magentoVersion}\"" )
  runParameters+=( "--magentoEdition \"${magentoEdition}\"" )
  runParameters+=( "--magentoMode \"${magentoMode}\"" )
  runParameters+=( "--repositories \"${repositories}\"" )
  if [[ -n "${cryptKey}" ]]; then
    runParameters+=( "--cryptKey \"${cryptKey}\"" )
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
  elif [[ "${webServerServerType}" == "ssh" ]]; then
    webServerHost=$(ini-parse "${currentPath}/../../env.properties" "yes" "${webServerServerName}" "host")
  else
    echo "Unsupported web server server type: ${webServerServerType}"
    exit 1
  fi
  webServerType=$(ini-parse "${currentPath}/../../env.properties" "yes" "${webServer}" "type")
  webServerVersion=$(ini-parse "${currentPath}/../../env.properties" "yes" "${webServer}" "version")
  httpPort=$(ini-parse "${currentPath}/../../env.properties" "no" "${webServer}" "httpPort")
  sslPort=$(ini-parse "${currentPath}/../../env.properties" "no" "${webServer}" "sslPort")
  proxyHost=$(ini-parse "${currentPath}/../../env.properties" "no" "${webServer}" "proxyHost")
  proxyPort=$(ini-parse "${currentPath}/../../env.properties" "no" "${webServer}" "proxyPort")
  webPath=$(ini-parse "${currentPath}/../../env.properties" "yes" "${webServerServerName}" "webPath")
  webUser=$(ini-parse "${currentPath}/../../env.properties" "no" "${webServerServerName}" "webUser")
  webGroup=$(ini-parse "${currentPath}/../../env.properties" "no" "${webServerServerName}" "webGroup")

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
  runParameters+=( "--webPath \"${webPath}\"" )
  if [[ -n "${webUser}" ]]; then
    runParameters+=( "--webUser \"${webUser}\"" )
  fi
  if [[ -n "${webGroup}" ]]; then
    runParameters+=( "--webGroup \"${webGroup}\"" )
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
    databaseHost="localhost"
  elif [[ "${databaseServerType}" == "ssh" ]]; then
    databaseHost=$(ini-parse "${currentPath}/../../env.properties" "yes" "${databaseServerName}" "host")
  else
    echo "Unsupported Database server type: ${databaseServerType}"
    exit 1
  fi
  databasePort=$(ini-parse "${currentPath}/../../env.properties" "yes" "${database}" "port")
  databaseUser=$(ini-parse "${currentPath}/../../env.properties" "yes" "${database}" "user")
  databasePassword=$(ini-parse "${currentPath}/../../env.properties" "yes" "${database}" "password")
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

  redisCacheServerType=$(ini-parse "${currentPath}/../../env.properties" "yes" "${redisCacheServerName}" "type")

  redisCacheVersion=$(ini-parse "${currentPath}/../../env.properties" "yes" "${redisCache}" "version")
  if [[ "${redisCacheServerType}" == "local" ]]; then
    redisCacheHost="localhost"
  elif [[ "${redisCacheServerType}" == "ssh" ]]; then
    redisCacheHost=$(ini-parse "${currentPath}/../../env.properties" "yes" "${redisCacheServerName}" "host")
  else
    echo "Unsupported Redis cache server type: ${redisCacheServerType}"
    exit 1
  fi
  redisCachePort=$(ini-parse "${currentPath}/../../env.properties" "yes" "${redisCache}" "port")
  redisCachePassword=$(ini-parse "${currentPath}/../../env.properties" "no" "${redisCache}" "password")
  redisCacheDatabase=$(ini-parse "${currentPath}/../../env.properties" "yes" "${redisCache}" "database")
  redisCacheCachePrefix=$(ini-parse "${currentPath}/../../env.properties" "no" "${redisCache}" "cachePrefix")
  redisCacheClassName=$(ini-parse "${currentPath}/../../env.properties" "no" "${redisCache}" "className")

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

  redisFPCServerType=$(ini-parse "${currentPath}/../../env.properties" "yes" "${redisFPCServerName}" "type")

  redisFPCVersion=$(ini-parse "${currentPath}/../../env.properties" "yes" "${redisFPC}" "version")
  if [[ "${redisFPCServerType}" == "local" ]]; then
    redisFPCHost="localhost"
  elif [[ "${redisFPCServerType}" == "ssh" ]]; then
    redisFPCHost=$(ini-parse "${currentPath}/../../env.properties" "yes" "${redisFPCServerName}" "host")
  else
    echo "Unsupported Redis FPC server type: ${redisFPCServerType}"
    exit 1
  fi
  redisFPCPort=$(ini-parse "${currentPath}/../../env.properties" "yes" "${redisFPC}" "port")
  redisFPCPassword=$(ini-parse "${currentPath}/../../env.properties" "no" "${redisFPC}" "password")
  redisFPCDatabase=$(ini-parse "${currentPath}/../../env.properties" "yes" "${redisFPC}" "database")
  redisFPCCachePrefix=$(ini-parse "${currentPath}/../../env.properties" "no" "${redisFPC}" "cachePrefix")
  redisFPCClassName=$(ini-parse "${currentPath}/../../env.properties" "no" "${redisFPC}" "className")

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

  redisSessionServerType=$(ini-parse "${currentPath}/../../env.properties" "yes" "${redisSessionServerName}" "type")

  redisSessionVersion=$(ini-parse "${currentPath}/../../env.properties" "yes" "${redisSession}" "version")
  if [[ "${redisSessionServerType}" == "local" ]]; then
    redisSessionHost="localhost"
  elif [[ "${redisSessionServerType}" == "ssh" ]]; then
    redisSessionHost=$(ini-parse "${currentPath}/../../env.properties" "yes" "${redisSessionServerName}" "host")
  else
    echo "Unsupported Redis session server type: ${redisSessionServerType}"
    exit 1
  fi
  redisSessionPort=$(ini-parse "${currentPath}/../../env.properties" "yes" "${redisSession}" "port")
  redisSessionPassword=$(ini-parse "${currentPath}/../../env.properties" "no" "${redisSession}" "password")
  redisSessionDatabase=$(ini-parse "${currentPath}/../../env.properties" "yes" "${redisSession}" "database")

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
  local elasticsearchUser
  local elasticsearchPassword

  elasticsearchServerType=$(ini-parse "${currentPath}/../../env.properties" "yes" "${elasticsearchServerName}" "type")

  elasticsearchVersion=$(ini-parse "${currentPath}/../../env.properties" "yes" "${elasticsearch}" "version")
  if [[ "${elasticsearchServerType}" == "local" ]]; then
    elasticsearchHost="localhost"
  elif [[ "${elasticsearchServerType}" == "ssh" ]]; then
    elasticsearchHost=$(ini-parse "${currentPath}/../../env.properties" "yes" "${elasticsearchServerName}" "host")
  else
    echo "Unsupported Elasticsearch server type: ${elasticsearchServerType}"
    exit 1
  fi
  elasticsearchPort=$(ini-parse "${currentPath}/../../env.properties" "yes" "${elasticsearch}" "port")
  elasticsearchUser=$(ini-parse "${currentPath}/../../env.properties" "no" "${elasticsearch}" "user")
  elasticsearchPassword=$(ini-parse "${currentPath}/../../env.properties" "no" "${elasticsearch}" "password")

  runParameters+=( "--elasticsearchServerName \"${elasticsearchServerName}\"" )
  runParameters+=( "--elasticsearchVersion \"${elasticsearchVersion}\"" )
  runParameters+=( "--elasticsearchHost \"${elasticsearchHost}\"" )
  runParameters+=( "--elasticsearchPort \"${elasticsearchPort}\"" )
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

  vhostList=( $(ini-parse "${currentPath}/../../env.properties" "yes" "${hostName}" "vhost") )
  scope=$(ini-parse "${currentPath}/../../env.properties" "yes" "${hostName}" "scope")
  code=$(ini-parse "${currentPath}/../../env.properties" "yes" "${hostName}" "code")
  sslCertFile=$(ini-parse "${currentPath}/../../env.properties" "no" "${hostName}" "sslCertFile")
  sslKeyFile=$(ini-parse "${currentPath}/../../env.properties" "no" "${hostName}" "sslKeyFile")
  sslTerminated=$(ini-parse "${currentPath}/../../env.properties" "no" "${hostName}" "sslTerminated")
  forceSsl=$(ini-parse "${currentPath}/../../env.properties" "no" "${hostName}" "forceSsl")
  requireIpList=( $(ini-parse "${currentPath}/../../env.properties" "no" "${hostName}" "requireIp") )
  allowUrlList=( $(ini-parse "${currentPath}/../../env.properties" "no" "${hostName}" "allowUrl") )
  basicAuthUserName=$(ini-parse "${currentPath}/../../env.properties" "no" "${hostName}" "basicAuthUserName")
  basicAuthPassword=$(ini-parse "${currentPath}/../../env.properties" "no" "${hostName}" "basicAuthPassword")

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
  runParameters+=( "--mergeScript \"script:${currentPath}/../../config/merge/web-server.sh:merge.sh\"" )
  runParameters+=( "--mergeScriptPhpScript \"script:${currentPath}/../../config/merge.php\"" )
  runParameters+=( "--addScript \"script:${currentPath}/../../config/add.php\"" )
}

source "${currentPath}/base.sh"

executeServers="${1}"
shift
scriptPath="${1}"
shift
parameters=("$@")

if [[ ! -f "${currentPath}/../../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

readarray -d , -t executeServerList < <(printf '%s' "${executeServers}")

executeServer="${executeServerList[0]}"
readarray -d : -t executeServerParts < <(printf '%s' "${executeServer}")
executeServerSystem="${executeServerParts[0]}"
executeServerName="${executeServerParts[1]}"
if [[ -z "${executeServerName}" ]]; then
  executeServerName="single"
fi

if [[ "${executeServerSystem}" == "host" ]]; then
  hostList=( $(ini-parse "${currentPath}/../../env.properties" "yes" "system" "host") )
  if [[ "${#hostList[@]}" -eq 0 ]]; then
    echo "No hosts specified!"
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
  >&2 echo "Could not find any server to run: ${executeServerSystem}:${executeServerName}"
  exit 1
fi

# shellcheck disable=SC2235
if [[ "${#executeServerList[@]}" -eq 1 ]] && [[ "${executeServerSystem}" == "all" ]]; then
  executeOnAll=1
elif [[ "${#executeServerList[@]}" -eq 1 ]] && ([[ "${executeServerSystem}" == "install" ]] || [[ "${executeServerSystem}" == "config" ]]); then
  if [[ "${executeServerName}" == "local" ]]; then
    runParameters=("${parameters[@]}")
    if [[ "${executeServerSystem}" == "install" ]]; then
      addInstallParameters
    elif [[ "${executeServerSystem}" == "config" ]]; then
      addConfigParameters
    fi
    executeScript "local" "${scriptPath}" "${runParameters[@]}"
    exit 0
  else
    executeOnAll=1
  fi
elif [[ "${#executeServerList[@]}" -gt 1 ]] && ([[ "${executeServerSystem}" == "install" ]] || [[ "${executeServerSystem}" == "config" ]]); then
  runParameters=("${parameters[@]}")
  if [[ "${executeServerSystem}" == "install" ]]; then
    addInstallParameters
  elif [[ "${executeServerSystem}" == "config" ]]; then
    addConfigParameters
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

      if [[ "${executeServerSystem}" == "install" ]]; then
        addInstallParameters
      elif [[ "${executeServerSystem}" == "config" ]]; then
        addConfigParameters
      elif [[ "${executeServerSystem}" == "webServer" ]]; then
        addWebServerParameters "${serverName}" "${serverSystem}"
      elif [[ "${executeServerSystem}" == "database" ]]; then
        addDatabaseParameters "${serverName}" "${serverSystem}"
      elif [[ "${executeServerSystem}" == "redisCache" ]]; then
        addRedisCacheParameters "${serverName}" "${serverSystem}"
      elif [[ "${executeServerSystem}" == "redisFPC" ]]; then
        addRedisFPCParameters "${serverName}" "${serverSystem}"
      elif [[ "${executeServerSystem}" == "redisSession" ]]; then
        addRedisSessionParameters "${serverName}" "${serverSystem}"
      elif [[ "${executeServerSystem}" == "elasticsearch" ]]; then
        addElasticsearchParameters "${serverName}" "${serverSystem}"
      fi

      if [[ "${#executeServerList[@]}" -eq 1 ]]; then
        serverType=$(ini-parse "${currentPath}/../../env.properties" "yes" "${serverName}" "type")

        if [[ "${serverType}" == "local" ]]; then
          executeScript "${serverName}" "${scriptPath}" "${runParameters[@]}"
        elif [[ "${serverType}" == "ssh" ]]; then
          sshUser=$(ini-parse "${currentPath}/../../env.properties" "yes" "${serverName}" "user")
          sshHost=$(ini-parse "${currentPath}/../../env.properties" "yes" "${serverName}" "host")
          executeScriptWithSSH "${serverName}" "${sshUser}" "${sshHost}" "${scriptPath}" "${runParameters[@]}"
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
