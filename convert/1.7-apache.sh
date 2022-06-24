#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ ! -f "${currentPath}/../../env.properties" ]; then
  echo "No environment specified!"
  exit 1
fi

cd "${currentPath}"

webServers=( $("${currentPath}/../server/web-server/all.sh") )

for webServer in "${webServers[@]}"; do
  type=$(ini-parse "${currentPath}/../../env.properties" "no" "${webServer}" "type")

  if [[ "${type}" == "apache" ]]; then
    "${currentPath}/../../env/update-web-server.sh" -i "${webServer}" -t "apache_php"
  fi
done
