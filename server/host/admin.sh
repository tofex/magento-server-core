#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -s  System name, default: system

Example: ${scriptName} -s system
EOF
}

trim()
{
  echo -n "$1" | xargs
}

system=

while getopts hs:? option; do
  case "${option}" in
    h) usage; exit 1;;
    s) system=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${system}" ]]; then
  system="system"
fi

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ ! -f "${currentPath}/../../../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

hostList=( $(ini-parse "${currentPath}/../../../env.properties" "yes" "${system}" "host") )
if [[ "${#hostList[@]}" -eq 0 ]]; then
  echo "No hosts specified!"
  exit 1
fi

for host in "${hostList[@]}"; do
  code=$(ini-parse "${currentPath}/../../../env.properties" "yes" "${host}" "code")
  if [[ "${code}" == "admin" ]]; then
    vhostList=( $(ini-parse "${currentPath}/../../../env.properties" "yes" "${host}" "vhost") )
    serverName="${vhostList[0]}"
    echo -n "${serverName}"
    exit 0
  fi
done

exit 1
