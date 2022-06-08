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

serverList=( $(ini-parse "${currentPath}/../../../env.properties" "yes" "${system}" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

databaseFound=0

for server in "${serverList[@]}"; do
  database=$(ini-parse "${currentPath}/../../../env.properties" "no" "${server}" "database")

  if [[ -n "${database}" ]]; then
    echo "${database}"
    databaseFound=1
  fi
done

if [[ "${databaseFound}" == 0 ]]; then
  echo "No servers specified!"
  exit 1
fi
