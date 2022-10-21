#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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

if [[ -z "${executeScript}" ]]; then
  executeScript="executeScript"
fi

if [[ -z "${executeScriptWithSSH}" ]]; then
  executeScriptWithSSH="executeScriptWithSSH"
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
elif [[ "${#executeServerList[@]}" -eq 1 ]] && ([[ "${executeServerSystem}" == "install" ]] || [[ "${executeServerSystem}" == "config" ]]); then
  if [[ "${executeServerName}" == "local" ]]; then
    runParameters=("${parameters[@]}")
    if [[ "${executeServerSystem}" == "install" ]]; then
      addInstallParameters
    elif [[ "${executeServerSystem}" == "config" ]]; then
      addConfigParameters
    fi
    "${executeScript}" "local" "${scriptPath}" "${runParameters[@]}"
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
