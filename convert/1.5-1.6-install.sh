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

magentoVersion=$(ini-parse "${currentPath}/../../env.properties" "no" "project" "magentoVersion")
if [[ -n "${magentoVersion}" ]]; then
  echo "Moving install"
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
else
  echo "No install to move"
fi
