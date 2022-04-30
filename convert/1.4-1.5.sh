#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ ! -f "${currentPath}/../../env.properties" ]; then
  echo "No environment specified!"
  exit 1
fi

cd "${currentPath}"

echo "Moving Magento version"
ini-move "../../env.properties" "yes" "project" "magentoVersion" "install" "magentoVersion"

echo "Moving Magento edition"
ini-move "../../env.properties" "yes" "project" "magentoEdition" "install" "magentoEdition"

echo "Moving Magento mode"
ini-move "../../env.properties" "yes" "project" "mageMode" "install" "magentoMode"

echo "Moving Magento crypt key"
ini-move "../../env.properties" "yes" "project" "cryptKey" "install" "cryptKey"

echo "Setting Default build type"
ini-default "../../env.properties" "build" "type" "composer"

echo "Moving build path"
buildServer=$(ini-parse "../../env.properties" "no" "build" "server")
if [[ -n "${buildServer}" ]]; then
  ini-move "../../env.properties" "yes" "build" "buildPath" "${buildServer}" "buildPath"
fi

echo "Moving build links"
servers=$(ini-parse "../../env.properties" "yes" "project" "servers")
deployServers=$(ini-parse "../../env.properties" "no" "project" "deploy")

if [[ -n "${deployServers}" ]]; then
  servers="${deployServers}"
fi

IFS=',' read -r -a serverList <<< "${servers}"

for server in "${serverList[@]}"; do
  link=$(ini-parse "../../env.properties" "no" "${server}" "link")

  if [[ -n "${link}" ]]; then
    IFS=',' read -r -a links <<< "${link}"
    echo "Deleting link list"
    ini-del "../../env.properties" "${server}" "link"
    for link in "${links[@]}"; do
      echo "Setting link"
      ini-set "../../env.properties" "no" "${server}" "link" "${link}"
    done
  fi
done

echo "Moving composer settings"
composerUser=$(ini-parse "../../env.properties" "no" "project" "composerUser")
composerPassword=$(ini-parse "../../env.properties" "no" "project" "composerPassword")
composerProject=$(ini-parse "../../env.properties" "no" "project" "composerProject")
if [[ -n "${composerUser}" ]] && [[ -n "${composerPassword}" ]]; then
  echo "Setting build repositories"
  ini-set "../../env.properties" "no" "build" "repositories" "composer|https://composer.tofex.de|${composerUser}|${composerPassword}"
  echo "Deleting composer user"
  ini-del "../../env.properties" "project" "composerUser"
  echo "Deleting composer password"
  ini-del "../../env.properties" "project" "composerPassword"
fi
if [[ -n "${composerProject}" ]]; then
  echo "Moving composer projects"
  ini-move "../../env.properties" "yes" "project" "composerProject" "build" "composerProject"
fi

echo "Moving hosts"
hosts=$(ini-parse "../../env.properties" "no" "project" "hosts")
if [[ -n "${hosts}" ]]; then
  ini-del "../../env.properties" "project" "hosts"
  hostList=( $(echo "${hosts}" | tr "," "\n") )
  for host in "${hostList[@]}"; do
    vhost=$(echo "${host}" | cut -d: -f1)
    scope=$(echo "${host}" | cut -d: -f2)
    code=$(echo "${host}" | cut -d: -f3)
    hostSectionName=$(echo "${vhost}" | sed "s/[^[:alpha:][:digit:]]/_/g")
    echo "Moving host: ${vhost}:${scope}:${code} to section: ${hostSectionName}"
    ini-set "../../env.properties" "no" "${hostSectionName}" "vhost" "${vhost}"
    ini-set "../../env.properties" "no" "${hostSectionName}" "scope" "${scope}"
    ini-set "../../env.properties" "no" "${hostSectionName}" "code" "${code}"
    ini-set "../../env.properties" "no" "project" "host" "${hostSectionName}"
  done
fi
