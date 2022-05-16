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

hosts=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "hosts")
if [[ -n "${hosts}" ]]; then
  echo "Moving hosts"
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
else
  echo "No hosts to move"
fi
