#!/bin/bash -e

executeScript()
{
  local serverName="${1}"
  shift
  local filePath="${1}"
  shift
  local parameters=("$@")

  filePath=$(replacePlaceHolder "${filePath}")

  if [[ ! -f "${filePath}" ]]; then
    echo "Script at: ${filePath} does not exist"
    exit 1
  fi

  echo "--- Executing script at: ${filePath} on local server: ${serverName} ---"
  "${filePath}" "${parameters[@]}"
}

executeScriptWithSSH()
{
  local serverName="${1}"
  shift
  local sshUser="${1}"
  shift
  local sshHost="${1}"
  shift
  local filePath="${1}"
  shift
  local parameters=("$@")

  filePath=$(replacePlaceHolder "${filePath}")

  if [[ ! -f "${filePath}" ]]; then
    echo "Script at: ${filePath} does not exist"
    exit 1
  fi

  copyFileToSSH "${sshUser}" "${sshHost}" "${filePath}"

  local fileName
  fileName=$(basename "${filePath}")
  local remoteFileName="/tmp/${fileName}"

  echo "--- Executing script at: ${filePath} on remote server: ${serverName} [${sshUser}@${sshHost}] at: ${remoteFileName} ---"
  ssh "${sshUser}@${sshHost}" "${remoteFileName}" "${parameters[@]}"

  removeFileFromSSH "${sshUser}" "${sshHost}" "${remoteFileName}"
}

replacePlaceHolder()
{
  local text="${1}"

  local textReplace
  textReplace=$(echo "${text}" | sed 's/\[\([[:alpha:]]*\)\]/\${\1}/g')
  if [[ "${text}" != "${textReplace}" ]]; then
    text=$(eval echo "${textReplace}")
  fi

  echo -n "${text}"
}

copyFileToSSH()
{
  local sshUser="${1}"
  local sshHost="${2}"
  local filePath="${3}"

  local fileName
  fileName=$(basename "${filePath}")
  local remoteFileName="/tmp/${fileName}"

  echo "Getting server fingerprint"
  ssh-keyscan "${sshHost}" >> ~/.ssh/known_hosts 2>/dev/null

  echo "Copying file from: ${filePath} to: ${sshUser}@${sshHost}:${remoteFileName}"
  scp -q "${filePath}" "${sshUser}@${sshHost}:${remoteFileName}"
}

removeFileFromSSH()
{
  local sshUser="${1}"
  local sshHost="${2}"
  local filePath="${3}"

  echo "Getting server fingerprint"
  ssh-keyscan "${sshHost}" >> ~/.ssh/known_hosts 2>/dev/null

  echo "Removing file from: ${sshUser}@${sshHost}:${filePath}"
  ssh "${sshUser}@${sshHost}" "rm -rf ${filePath}"
}

scriptPath="${1}"
shift
parameters=("$@")

for parameter in "${parameters[@]}"; do
  if [[ "${parameter}" == "-w" ]] || [[ "${parameter}" == "-u" ]] || [[ "${parameter}" == "-g" ]] || [[ "${parameter}" == "-t" ]] || [[ "${parameter}" == "-v" ]] || [[ "${parameter}" == "-p" ]] || [[ "${parameter}" == "-z" ]] || [[ "${parameter}" == "-x" ]] || [[ "${parameter}" == "-y" ]] || [[ "${parameter}" == "-n" ]] || [[ "${parameter}" == "-o" ]] || [[ "${parameter}" == "-a" ]] || [[ "${parameter}" == "-e" ]] || [[ "${parameter}" == "-c" ]] || [[ "${parameter}" == "-l" ]] || [[ "${parameter}" == "-k" ]] || [[ "${parameter}" == "-r" ]] || [[ "${parameter}" == "-f" ]] || [[ "${parameter}" == "-i" ]] || [[ "${parameter}" == "-b" ]] || [[ "${parameter}" == "-s" ]]; then
    echo "Restricted parameter key used: ${parameter} for script: ${scriptPath}"
    exit 1
  fi
done

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

serverList=( $(ini-parse "${currentPath}/../../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

hostList=( $(ini-parse "${currentPath}/../../env.properties" "yes" "system" "host") )
if [[ "${#hostList[@]}" -eq 0 ]]; then
  echo "No hosts specified!"
  exit 1
fi

webServerFound=0

for server in "${serverList[@]}"; do
  webServer=$(ini-parse "${currentPath}/../../env.properties" "no" "${server}" "webServer")

  if [[ -n "${webServer}" ]]; then
    serverType=$(ini-parse "${currentPath}/../../env.properties" "yes" "${server}" "type")

    if [[ "${serverType}" != "local" ]] && [[ "${serverType}" != "ssh" ]]; then
      echo "Invalid web server server type: ${serverType} of server: ${server}"
      continue
    fi

    webPath=$(ini-parse "${currentPath}/../../env.properties" "yes" "${server}" "webPath")
    webUser=$(ini-parse "${currentPath}/../../env.properties" "no" "${server}" "webUser")
    webGroup=$(ini-parse "${currentPath}/../../env.properties" "no" "${server}" "webGroup")
    webServerType=$(ini-parse "${currentPath}/../../env.properties" "yes" "${webServer}" "type")
    webServerVersion=$(ini-parse "${currentPath}/../../env.properties" "yes" "${webServer}" "version")
    httpPort=$(ini-parse "${currentPath}/../../env.properties" "no" "${webServer}" "httpPort")
    sslPort=$(ini-parse "${currentPath}/../../env.properties" "no" "${webServer}" "sslPort")
    proxyHost=$(ini-parse "${currentPath}/../../env.properties" "no" "${webServer}" "proxyHost")
    proxyPort=$(ini-parse "${currentPath}/../../env.properties" "no" "${webServer}" "proxyPort")

    parameters+=( "-w \"${webPath}\"" )
    if [[ -n "${webUser}" ]]; then
      parameters+=( "-u \"${webUser}\"" )
    fi
    if [[ -n "${webGroup}" ]]; then
      parameters+=( "-g \"${webGroup}\"" )
    fi
    parameters+=( "-t \"${webServerType}\"" )
    parameters+=( "-v \"${webServerVersion}\"" )
    if [[ -n "${httpPort}" ]]; then
      parameters+=( "-p \"${httpPort}\"" )
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

    for host in "${hostList[@]}"; do
      vhostList=( $(ini-parse "${currentPath}/../../env.properties" "yes" "${host}" "vhost") )
      scope=$(ini-parse "${currentPath}/../../env.properties" "yes" "${host}" "scope")
      code=$(ini-parse "${currentPath}/../../env.properties" "yes" "${host}" "code")
      sslCertFile=$(ini-parse "${currentPath}/../../env.properties" "no" "${host}" "sslCertFile")
      sslKeyFile=$(ini-parse "${currentPath}/../../env.properties" "no" "${host}" "sslKeyFile")
      sslTerminated=$(ini-parse "${currentPath}/../../env.properties" "no" "${host}" "sslTerminated")
      forceSsl=$(ini-parse "${currentPath}/../../env.properties" "no" "${host}" "forceSsl")
      requireIpList=( $(ini-parse "${currentPath}/../../env.properties" "no" "${host}" "requireIp") )
      basicAuthUserName=$(ini-parse "${currentPath}/../../env.properties" "no" "${host}" "basicAuthUserName")
      basicAuthPassword=$(ini-parse "${currentPath}/../../env.properties" "no" "${host}" "basicAuthPassword")

      parameters+=( "-n \"${host}\"" )

      serverName="${vhostList[0]}"
      parameters+=( "-o \"${serverName}\"" )

      hostAliasList=( "${vhosts[@]:1}" )
      if [[ "${#hostAliasList[@]}" -gt 0 ]]; then
        serverAlias=$( IFS=$','; echo "${hostAliasList[*]}" )
        parameters+=( "-a \"${serverAlias}\"" )
      fi

      if [[ -n "${scope}" ]]; then
        parameters+=( "-e \"${scope}\"" )
      fi

      if [[ -n "${code}" ]]; then
        parameters+=( "-c \"${code}\"" )
      fi

      if [[ -n "${sslCertFile}" ]]; then
        parameters+=( "-l \"${sslCertFile}\"" )
      fi

      if [[ -n "${sslKeyFile}" ]]; then
        parameters+=( "-k \"${sslKeyFile}\"" )
      fi

      if [[ -n "${sslTerminated}" ]]; then
        parameters+=( "-r \"${sslTerminated}\"" )
      fi

      if [[ -n "${forceSsl}" ]]; then
        parameters+=( "-f \"${forceSsl}\"" )
      fi

      requireIp=$( IFS=$','; echo "${requireIpList[*]}" )
      parameters+=( "-i \"${requireIp}\"" )

      if [[ -n "${basicAuthUserName}" ]]; then
        parameters+=( "-b \"${basicAuthUserName}\"" )
      fi
      if [[ -n "${basicAuthPassword}" ]]; then
        parameters+=( "-s \"${basicAuthPassword}\"" )
      fi

      if [[ "${serverType}" == "local" ]]; then
        executeScript "${server}" "${scriptPath}" "${parameters[@]}"
      elif [[ "${serverType}" == "ssh" ]]; then
        sshUser=$(ini-parse "${currentPath}/../../env.properties" "yes" "${server}" "user")
        sshHost=$(ini-parse "${currentPath}/../../env.properties" "yes" "${server}" "host")
        executeScriptWithSSH "${server}" "${sshUser}" "${sshHost}" "${scriptPath}" "${parameters[@]}"
      fi
    done

    webServerFound=1
  fi
done

if [[ "${webServerFound}" == 0 ]]; then
  echo "No web server settings found"
  exit 1
fi
