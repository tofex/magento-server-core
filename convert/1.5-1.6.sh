#!/bin/bash -e

versionCompare() {
  if [[ "$1" == "$2" ]]; then
    echo "0"
  elif [[ "$1" = $(echo -e "$1\n$2" | sort -V | head -n1) ]]; then
    echo "1"
  else
    echo "2"
  fi
}

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ ! -f "${currentPath}/../../env.properties" ]; then
  echo "No environment specified!"
  exit 1
fi

cd "${currentPath}"

echo "Moving host name"
hostName=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "hostName")
if [[ -n "${hostName}" ]]; then
  sed -i "1s/^/[system]\n/" "${currentPath}/../../env.properties"
  sed -i "2s/^/name=${hostName}\n/" "${currentPath}/../../env.properties"
  ini-del "${currentPath}/../../env.properties" "project" "hostName"
  ini-del "${currentPath}/../../env.properties" "project" "serverName"
fi

echo "Moving project id"
ini-move "${currentPath}/../../env.properties" "yes" "project" "projectId" "system" "projectId"

echo "Moving server"
servers=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "servers")
if [[ -n "${servers}" ]]; then
  IFS=',' read -r -a serverList <<< "${servers}"
  for server in "${serverList[@]}"; do
    ini-set "${currentPath}/../../env.properties" "no" "system" "server" "${server}"
    ini-set "${currentPath}/../../env.properties" "no" "deploy" "server" "${server}"
    deployHistoryCount=$(ini-parse "${currentPath}/../../env.properties" "no" "${server}" "deployHistoryCount")
    if [[ -n "${deployHistoryCount}" ]]; then
      ini-move "${currentPath}/../../env.properties" "yes" "${server}" "deployHistoryCount" "deploy" "deployHistoryCount"
    fi
  done
  ini-del "${currentPath}/../../env.properties" "project" "servers"
fi

echo "Moving install"
magentoVersion=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "magentoVersion")
if [[ -n "${magentoVersion}" ]]; then
  composerUser=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "composerUser")
  composerPassword=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "composerPassword")
  if [[ $(versionCompare "${magentoVersion}" "1.9.4.5") == 0 ]] || [[ $(versionCompare "${magentoVersion}" "1.9.4.5") == 1 ]]; then
    composerServer="https://composer.tofex.de"
  else
    composerServer="https://repo.magento.com"
  fi
  ini-set "${currentPath}/../../env.properties" yes install repositories "composer|${composerServer}|${composerUser}|${composerPassword}"
  ini-del "${currentPath}/../../env.properties" "project" "composerUser"
  ini-del "${currentPath}/../../env.properties" "project" "composerUser"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "magentoVersion" "install" "magentoVersion"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "magentoEdition" "install" "magentoEdition"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "mageMode" "install" "magentoMode"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "cryptKey" "install" "cryptKey"
fi

echo "Moving hosts"
hosts=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "hosts")
if [[ -n "${hosts}" ]]; then
  hostList=( $(echo "${hosts}" | tr "," "\n") )
  basicAuthUser=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "basicAuthUser")
  basicAuthPassword=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "basicAuthPassword")
  sslCertFile=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "sslCertFile")
  sslKeyFile=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "sslKeyFile")
  for host in "${hostList[@]}"; do
    vhost=$(echo "${host}" | cut -d: -f1)
    magentoScope=$(echo "${host}" | cut -d: -f2)
    magentoCode=$(echo "${host}" | cut -d: -f3)
    ini-set "${currentPath}/../../env.properties" "no" "system" "host" "${vhost}"
    ini-set "${currentPath}/../../env.properties" "yes" "${vhost}" "vhost" "${vhost}"
    ini-set "${currentPath}/../../env.properties" "yes" "${vhost}" "scope" "${magentoScope}"
    ini-set "${currentPath}/../../env.properties" "yes" "${vhost}" "code" "${magentoCode}"
    if [[ -n "${basicAuthUser}" ]]; then
      ini-set "${currentPath}/../../env.properties" "yes" "${vhost}" "basicAuthUserName" "${basicAuthUser}"
    fi
    if [[ -n "${basicAuthPassword}" ]]; then
      ini-set "${currentPath}/../../env.properties" "yes" "${vhost}" "basicAuthPassword" "${basicAuthPassword}"
    fi
    if [[ -n "${sslCertFile}" ]]; then
      ini-set "${currentPath}/../../env.properties" "yes" "${vhost}" "sslCertFile" "${sslCertFile}"
    fi
    if [[ -n "${sslKeyFile}" ]]; then
      ini-set "${currentPath}/../../env.properties" "yes" "${vhost}" "sslKeyFile" "${sslKeyFile}"
    fi
  done
  ini-del "${currentPath}/../../env.properties" "project" "hosts"
  ini-del "${currentPath}/../../env.properties" "project" "basicAuthUser"
  ini-del "${currentPath}/../../env.properties" "project" "basicAuthPassword"
  ini-del "${currentPath}/../../env.properties" "project" "sslCertFile"
  ini-del "${currentPath}/../../env.properties" "project" "sslKeyFile"
fi

echo "Moving database"
databaseHost=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "databaseHost")
serverFound=0
for server in "${serverList[@]}"; do
  type=$(ini-parse "${currentPath}/../../env.properties" "yes" "${server}" "type")
  if [[ "${type}" == "local" ]]; then
    if [[ "${databaseHost}" == "localhost" ]] || [[ "${databaseHost}" == "127.0.0.1" ]]; then
      ini-set "${currentPath}/../../env.properties" "yes" "${server}" "database" "database"
      serverFound=1
    fi
  elif [[ "${type}" == "ssh" ]]; then
    sshHost=$(ini-parse "${currentPath}/../../env.properties" "yes" "${server}" "sshHost")
    if [[ "${sshHost}" == "${databaseHost}" ]]; then
      ini-set "${currentPath}/../../env.properties" "yes" "${server}" "database" "database"
      serverFound=1
    fi
  fi
done
if [[ "${serverFound}" == 0 ]]; then
  ini-set "${currentPath}/../../env.properties" "yes" "${databaseHost}" "database" "database"
fi
ini-del "${currentPath}/../../env.properties" "project" "databaseHost"
ini-move "${currentPath}/../../env.properties" "yes" "project" "databaseType" "database" "type"
ini-move "${currentPath}/../../env.properties" "yes" "project" "databaseVersion" "database" "version"
ini-move "${currentPath}/../../env.properties" "yes" "project" "databasePort" "database" "port"
ini-move "${currentPath}/../../env.properties" "yes" "project" "databaseUser" "database" "user"
ini-move "${currentPath}/../../env.properties" "yes" "project" "databasePassword" "database" "password"
ini-move "${currentPath}/../../env.properties" "yes" "project" "databaseName" "database" "name"

apacheHost=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "apacheHost")
if [[ -n "${apacheHost}" ]]; then
  echo "Moving web server"
  serverFound=0
  for server in "${serverList[@]}"; do
    type=$(ini-parse "${currentPath}/../../env.properties" "yes" "${server}" "type")
    if [[ "${type}" == "local" ]]; then
      if [[ "${apacheHost}" == "localhost" ]] || [[ "${apacheHost}" == "127.0.0.1" ]]; then
        ini-set "${currentPath}/../../env.properties" "yes" "${server}" "webServer" "web_server"
        serverFound=1
      fi
    elif [[ "${type}" == "ssh" ]]; then
      sshHost=$(ini-parse "${currentPath}/../../env.properties" "yes" "${server}" "sshHost")
      if [[ "${sshHost}" == "${apacheHost}" ]]; then
        ini-set "${currentPath}/../../env.properties" "yes" "${server}" "webServer" "web_server"
        serverFound=1
      fi
    fi
  done
  if [[ "${serverFound}" == 0 ]]; then
    ini-set "${currentPath}/../../env.properties" "yes" "${apacheHost}" "webServer" "web_server"
  fi
  ini-del "${currentPath}/../../env.properties" "project" "apacheHost"
  ini-set "${currentPath}/../../env.properties" "yes" "web_server" "type" "apache"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "apacheVersion" "web_server" "version"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "apacheHttpPort" "web_server" "httpPort"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "apacheSslPort" "web_server" "sslPort"
fi

redisCacheHost=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "redisCacheHost")
if [[ -n "${redisCacheHost}" ]]; then
  echo "Moving Redis cache server"
  serverFound=0
  for server in "${serverList[@]}"; do
    type=$(ini-parse "${currentPath}/../../env.properties" "yes" "${server}" "type")
    if [[ "${type}" == "local" ]]; then
      if [[ "${redisCacheHost}" == "localhost" ]] || [[ "${redisCacheHost}" == "127.0.0.1" ]]; then
        ini-set "${currentPath}/../../env.properties" "yes" "${server}" "redisCache" "redis_cache"
        serverFound=1
      fi
    elif [[ "${type}" == "ssh" ]]; then
      sshHost=$(ini-parse "${currentPath}/../../env.properties" "yes" "${server}" "sshHost")
      if [[ "${sshHost}" == "${redisCacheHost}" ]]; then
        ini-set "${currentPath}/../../env.properties" "yes" "${server}" "redisCache" "redis_cache"
        serverFound=1
      fi
    fi
  done
  if [[ "${serverFound}" == 0 ]]; then
    ini-set "${currentPath}/../../env.properties" "yes" "${redisCacheHost}" "redisCache" "redis_cache"
  fi
  ini-del "${currentPath}/../../env.properties" "project" "redisCacheHost"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "redisCacheVersion" "redis_cache" "version"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "redisCachePort" "redis_cache" "port"
  redisCachePassword=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "redisCachePassword")
  if [[ -n "${redisCachePassword}" ]]; then
    ini-move "${currentPath}/../../env.properties" "yes" "project" "redisCachePassword" "redis_cache" "password"
  fi
  ini-move "${currentPath}/../../env.properties" "yes" "project" "redisCacheDatabase" "redis_cache" "database"
fi

redisSessionHost=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "redisSessionHost")
if [[ -n "${redisSessionHost}" ]]; then
  echo "Moving Redis session server"
  serverFound=0
  for server in "${serverList[@]}"; do
    type=$(ini-parse "${currentPath}/../../env.properties" "yes" "${server}" "type")
    if [[ "${type}" == "local" ]]; then
      if [[ "${redisSessionHost}" == "localhost" ]] || [[ "${redisSessionHost}" == "127.0.0.1" ]]; then
        ini-set "${currentPath}/../../env.properties" "yes" "${server}" "redisSession" "redis_session"
        serverFound=1
      fi
    elif [[ "${type}" == "ssh" ]]; then
      sshHost=$(ini-parse "${currentPath}/../../env.properties" "yes" "${server}" "sshHost")
      if [[ "${sshHost}" == "${redisSessionHost}" ]]; then
        ini-set "${currentPath}/../../env.properties" "yes" "${server}" "redisSession" "redis_session"
        serverFound=1
      fi
    fi
  done
  if [[ "${serverFound}" == 0 ]]; then
    ini-set "${currentPath}/../../env.properties" "yes" "${redisSessionHost}" "redisSession" "redis_session"
  fi
  ini-del "${currentPath}/../../env.properties" "project" "redisSessionHost"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "redisSessionVersion" "redis_session" "version"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "redisSessionPort" "redis_session" "port"
  redisSessionPassword=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "redisSessionPassword")
  if [[ -n "${redisSessionPassword}" ]]; then
    ini-move "${currentPath}/../../env.properties" "yes" "project" "redisSessionPassword" "redis_session" "password"
  fi
  ini-move "${currentPath}/../../env.properties" "yes" "project" "redisSessionDatabase" "redis_session" "database"
fi

redisFullPageCacheHost=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "redisFullPageCacheHost")
if [[ -n "${redisFullPageCacheHost}" ]]; then
  echo "Moving Redis FPC server"
  serverFound=0
  for server in "${serverList[@]}"; do
    type=$(ini-parse "${currentPath}/../../env.properties" "yes" "${server}" "type")
    if [[ "${type}" == "local" ]]; then
      if [[ "${redisFullPageCacheHost}" == "localhost" ]] || [[ "${redisFullPageCacheHost}" == "127.0.0.1" ]]; then
        ini-set "${currentPath}/../../env.properties" "yes" "${server}" "redisFPC" "redis_fpc"
        serverFound=1
      fi
    elif [[ "${type}" == "ssh" ]]; then
      sshHost=$(ini-parse "${currentPath}/../../env.properties" "yes" "${server}" "sshHost")
      if [[ "${sshHost}" == "${redisFullPageCacheHost}" ]]; then
        ini-set "${currentPath}/../../env.properties" "yes" "${server}" "redisFPC" "redis_fpc"
        serverFound=1
      fi
    fi
  done
  if [[ "${serverFound}" == 0 ]]; then
    ini-set "${currentPath}/../../env.properties" "yes" "${redisFullPageCacheHost}" "redisFPC" "redis_fpc"
  fi
  ini-del "${currentPath}/../../env.properties" "project" "redisFullPageCacheHost"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "redisFullPageCacheVersion" "redis_fpc" "version"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "redisFullPageCachePort" "redis_fpc" "port"
  redisFullPageCachePassword=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "redisFullPageCachePassword")
  if [[ -n "${redisFullPageCachePassword}" ]]; then
    ini-move "${currentPath}/../../env.properties" "yes" "project" "redisFullPageCachePassword" "redis_fpc" "password"
  fi
  ini-move "${currentPath}/../../env.properties" "yes" "project" "redisFullPageCacheDatabase" "redis_fpc" "database"
fi

solrHost=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "solrHost")
if [[ -n "${solrHost}" ]]; then
  echo "Moving Solr server"
  serverFound=0
  for server in "${serverList[@]}"; do
    type=$(ini-parse "${currentPath}/../../env.properties" "yes" "${server}" "type")
    if [[ "${type}" == "local" ]]; then
      if [[ "${solrHost}" == "localhost" ]] || [[ "${solrHost}" == "127.0.0.1" ]]; then
        ini-set "${currentPath}/../../env.properties" "yes" "${server}" "solr" "solr"
        serverFound=1
      fi
    elif [[ "${type}" == "ssh" ]]; then
      sshHost=$(ini-parse "${currentPath}/../../env.properties" "yes" "${server}" "sshHost")
      if [[ "${sshHost}" == "${solrHost}" ]]; then
        ini-set "${currentPath}/../../env.properties" "yes" "${server}" "solr" "solr"
        serverFound=1
      fi
    fi
  done
  if [[ "${serverFound}" == 0 ]]; then
    ini-set "${currentPath}/../../env.properties" "yes" "${solrHost}" "solr" "solr"
  fi
  ini-del "${currentPath}/../../env.properties" "project" "solrHost"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "solrVersion" "solr" "version"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "solrServiceName" "solr" "serviceName"
  ini-set "${currentPath}/../../env.properties" "yes" "solr" "protocol" "http"
  ini-move "${currentPath}/../../env.properties" "yes" "project" "solrPort" "solr" "port"
  ini-set "${currentPath}/../../env.properties" "yes" "solr" "urlPath" "solr"
fi
