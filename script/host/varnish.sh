#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${currentPath}/../base.sh"

scriptPath="${1}"
shift
parameters=("$@")

for parameter in "${parameters[@]}"; do
  if [[ "${parameter}" == "-n" ]] || [[ "${parameter}" == "-o" ]] || [[ "${parameter}" == "-a" ]] || [[ "${parameter}" == "-e" ]] || [[ "${parameter}" == "-c" ]] || [[ "${parameter}" == "-l" ]] || [[ "${parameter}" == "-k" ]] || [[ "${parameter}" == "-r" ]] || [[ "${parameter}" == "-f" ]] || [[ "${parameter}" == "-i" ]] || [[ "${parameter}" == "-b" ]] || [[ "${parameter}" == "-s" ]] || [[ "${parameter}" == "-t" ]] || [[ "${parameter}" == "-p" ]] || [[ "${parameter}" == "-d" ]] || [[ "${parameter}" == "-w" ]] || [[ "${parameter}" == "-v" ]]; then
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

  if [[ -n "${basicAuthUserName}" ]]; then
    hostParameters+=( "-b \"${basicAuthUserName}\"" )
  fi
  if [[ -n "${basicAuthPassword}" ]]; then
    hostParameters+=( "-s \"${basicAuthPassword}\"" )
  fi

  serverName=

  for server in "${serverList[@]}"; do
    varnish=$(ini-parse "${currentPath}/../../../env.properties" "no" "${server}" "varnish")

    if [[ -n "${varnish}" ]]; then
      serverType=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${server}" "type")

      if [[ "${serverType}" != "local" ]] && [[ "${serverType}" != "ssh" ]]; then
        echo "Invalid Varnish server type: ${serverType} of server: ${server}"
        continue
      fi

      serverName="${server}"

      break
    fi
  done

  if [[ -z "${serverName}" ]]; then
    echo "No Varnish settings found"
    exit 1
  fi

  serverType=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${serverName}" "type")

  if [[ "${serverType}" != "local" ]] && [[ "${serverType}" != "ssh" ]]; then
    echo "Invalid Varnish server type: ${serverType} of server: ${serverName}"
    exit 1
  fi

  varnish=$(ini-parse "${currentPath}/../../../env.properties" "no" "${serverName}" "varnish")

  if [[ "${serverType}" == "local" ]]; then
    host="localhost"
  elif [[ "${serverType}" == "ssh" ]]; then
    host=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${serverName}" "host")
  fi

  port=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${varnish}" "port")
  adminPort=$(ini-parse "${currentPath}/../../../env.properties" "no" "${varnish}" "adminPort")
  secretFile="/etc/varnish/secret"
  version=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${varnish}" "version")

  if [[ -z "${host}" ]]; then
    echo "No Varnish host specified!"
    exit 1
  fi

  if [[ -z "${port}" ]]; then
    echo "No Varnish port specified!"
    exit 1
  fi

  if [[ -z "${adminPort}" ]]; then
    echo "No Varnish admin port specified!"
    exit 1
  fi

  if [[ -z "${secretFile}" ]]; then
    echo "No Varnish secret file specified!"
    exit 1
  fi

  if [[ -z "${version}" ]]; then
    echo "No Varnish version specified!"
    exit 1
  fi

  hostParameters+=( "-t \"${host}\"" )
  hostParameters+=( "-p \"${port}\"" )
  hostParameters+=( "-d \"${adminPort}\"" )
  hostParameters+=( "-w \"${secretFile}\"" )
  hostParameters+=( "-v \"${version}\"" )

  if [[ "${serverType}" == "local" ]]; then
    executeScript "${serverName}" "${scriptPath}" "${hostParameters[@]}"
  elif [[ "${serverType}" == "ssh" ]]; then
    sshUser=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${serverName}" "user")
    sshHost=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${serverName}" "host")
    environment=$(ini-parse "${currentPath}/../../../env.properties" "no" "system" "environment")
    if [[ -z "${environment}" ]]; then
      environment="no"
    fi
    executeScriptWithSSH "${serverName}" "${sshUser}" "${sshHost}" "${environment}" "${scriptPath}" "${hostParameters[@]}"
  fi
done
