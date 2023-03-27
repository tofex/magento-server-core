#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${currentPath}/../base.sh"

scriptPath="${1}"
shift
parameters=("$@")

for parameter in "${parameters[@]}"; do
  if [[ "${parameter}" == "-n" ]] || [[ "${parameter}" == "-o" ]] || [[ "${parameter}" == "-a" ]] || [[ "${parameter}" == "-e" ]] || [[ "${parameter}" == "-c" ]] || [[ "${parameter}" == "-l" ]] || [[ "${parameter}" == "-k" ]] || [[ "${parameter}" == "-r" ]] || [[ "${parameter}" == "-f" ]] || [[ "${parameter}" == "-i" ]] || [[ "${parameter}" == "-j" ]] || [[ "${parameter}" == "-b" ]] || [[ "${parameter}" == "-s" ]] || [[ "${parameter}" == "-w" ]] || [[ "${parameter}" == "-u" ]] || [[ "${parameter}" == "-g" ]] || [[ "${parameter}" == "-t" ]] || [[ "${parameter}" == "-v" ]] || [[ "${parameter}" == "-p" ]] || [[ "${parameter}" == "-z" ]] || [[ "${parameter}" == "-x" ]] || [[ "${parameter}" == "-y" ]]; then
    echo "Restricted parameter key used: ${parameter} for script: ${scriptPath}"
    exit 1
  fi
done

if [[ ! -f "${currentPath}/../../../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

serverList=( $(ini-parse "${currentPath}/../../../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

hostList=( $(ini-parse "${currentPath}/../../../env.properties" "yes" "system" "host") )
if [[ "${#hostList[@]}" -eq 0 ]]; then
  echo "No hosts specified!"
  exit 1
fi

for host in "${hostList[@]}"; do
  vhostList=( $(ini-parse "${currentPath}/../../../env.properties" "yes" "${host}" "vhost") )
  scope=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${host}" "scope")
  code=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${host}" "code")
  sslCertFile=$(ini-parse "${currentPath}/../../../env.properties" "no" "${host}" "sslCertFile")
  sslKeyFile=$(ini-parse "${currentPath}/../../../env.properties" "no" "${host}" "sslKeyFile")
  sslTerminated=$(ini-parse "${currentPath}/../../../env.properties" "no" "${host}" "sslTerminated")
  forceSsl=$(ini-parse "${currentPath}/../../../env.properties" "no" "${host}" "forceSsl")
  requireIpList=( $(ini-parse "${currentPath}/../../../env.properties" "no" "${host}" "requireIp") )
  allowUrlList=( $(ini-parse "${currentPath}/../../../env.properties" "no" "${host}" "allowUrl") )
  basicAuthUserName=$(ini-parse "${currentPath}/../../../env.properties" "no" "${host}" "basicAuthUserName")
  basicAuthPassword=$(ini-parse "${currentPath}/../../../env.properties" "no" "${host}" "basicAuthPassword")

  hostParameters=("${parameters[@]}")

  hostParameters+=( "-n \"${host}\"" )

  serverName="${vhostList[0]}"
  hostParameters+=( "-o \"${serverName}\"" )

  hostAliasList=( "${vhostList[@]:1}" )
  if [[ "${#hostAliasList[@]}" -gt 0 ]]; then
    serverAlias=$( IFS=$','; echo "${hostAliasList[*]}" )
    hostParameters+=( "-a \"${serverAlias}\"" )
  fi

  if [[ -n "${scope}" ]]; then
    hostParameters+=( "-e \"${scope}\"" )
  fi

  if [[ -n "${code}" ]]; then
    hostParameters+=( "-c \"${code}\"" )
  fi

  if [[ -n "${sslCertFile}" ]]; then
    hostParameters+=( "-l \"${sslCertFile}\"" )
  fi

  if [[ -n "${sslKeyFile}" ]]; then
    hostParameters+=( "-k \"${sslKeyFile}\"" )
  fi

  if [[ -n "${sslTerminated}" ]]; then
    hostParameters+=( "-r \"${sslTerminated}\"" )
  fi

  if [[ -n "${forceSsl}" ]]; then
    hostParameters+=( "-f \"${forceSsl}\"" )
  fi

  requireIp=$( IFS=$','; echo "${requireIpList[*]}" )
  hostParameters+=( "-i \"${requireIp}\"" )

  allowUrl=$( IFS=$','; echo "${allowUrlList[*]}" )
  hostParameters+=( "-j \"${allowUrl}\"" )

  if [[ -n "${basicAuthUserName}" ]]; then
    hostParameters+=( "-b \"${basicAuthUserName}\"" )
  fi
  if [[ -n "${basicAuthPassword}" ]]; then
    hostParameters+=( "-s \"${basicAuthPassword}\"" )
  fi

  webServerFound=0

  for server in "${serverList[@]}"; do
    webServer=$(ini-parse "${currentPath}/../../../env.properties" "no" "${server}" "webServer")

    if [[ -n "${webServer}" ]]; then
      serverType=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${server}" "type")

      if [[ "${serverType}" != "local" ]] && [[ "${serverType}" != "ssh" ]]; then
        echo "Invalid web server server type: ${serverType} of server: ${server}"
        continue
      fi

      webPath=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${webServer}" "path")
      webUser=$(ini-parse "${currentPath}/../../../env.properties" "no" "${webServer}" "user")
      webGroup=$(ini-parse "${currentPath}/../../../env.properties" "no" "${webServer}" "group")
      webServerType=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${webServer}" "type")
      webServerVersion=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${webServer}" "version")
      httpPort=$(ini-parse "${currentPath}/../../../env.properties" "no" "${webServer}" "httpPort")
      sslPort=$(ini-parse "${currentPath}/../../../env.properties" "no" "${webServer}" "sslPort")
      proxyHost=$(ini-parse "${currentPath}/../../../env.properties" "no" "${webServer}" "proxyHost")
      proxyPort=$(ini-parse "${currentPath}/../../../env.properties" "no" "${webServer}" "proxyPort")

      hostServerParameters=("${hostParameters[@]}")

      hostServerParameters+=( "-w \"${webPath}\"" )
      if [[ -n "${webUser}" ]]; then
        hostServerParameters+=( "-u \"${webUser}\"" )
      fi
      if [[ -n "${webGroup}" ]]; then
        hostServerParameters+=( "-g \"${webGroup}\"" )
      fi
      hostServerParameters+=( "-t \"${webServerType}\"" )
      hostServerParameters+=( "-v \"${webServerVersion}\"" )
      if [[ -n "${httpPort}" ]]; then
        hostServerParameters+=( "-p \"${httpPort}\"" )
      fi
      if [[ -n "${sslPort}" ]]; then
        hostServerParameters+=( "-z \"${sslPort}\"" )
      fi
      if [[ -n "${proxyHost}" ]]; then
        hostServerParameters+=( "-x \"${proxyHost}\"" )
      fi
      if [[ -n "${proxyPort}" ]]; then
        hostServerParameters+=( "-y \"${proxyPort}\"" )
      fi

      if [[ "${serverType}" == "local" ]]; then
        executeScript "${server}" "${scriptPath}" "${hostServerParameters[@]}"
      elif [[ "${serverType}" == "ssh" ]]; then
        sshUser=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${server}" "user")
        sshHost=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${server}" "host")
        executeScriptWithSSH "${server}" "${sshUser}" "${sshHost}" "${scriptPath}" "${hostServerParameters[@]}"
      fi

      webServerFound=1
    fi
  done

  if [[ "${webServerFound}" == 0 ]]; then
    echo "No web server settings found"
    exit 1
  fi
done
