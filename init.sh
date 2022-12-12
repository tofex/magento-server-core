#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -c  Only check
  -l  Only local environment
  -f  Force

Example: ${scriptName} -c -l
EOF
}

trim()
{
  echo -n "$1" | xargs
}

check=0
local=0
force=0

while getopts hclf? option; do
  case "${option}" in
    h) usage; exit 1;;
    c) check=1;;
    l) local=1;;
    f) force=1;;
    ?) usage; exit 1;;
  esac
done

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ "${force}" == 0 ]] && [[ -f "${currentPath}/.init.${check}.${local}.flag" ]]; then
  echo "Magento Server already initialized"
  exit 0
fi

if [[ "${force}" == 0 ]] && [[ "${check}" == 1 ]] && [[ -f "${currentPath}/.init.0.${local}.flag" ]]; then
  echo "Magento Server already initialized"
  exit 0
fi

if [[ "${force}" == 0 ]] && [[ "${check}" == 1 ]] && [[ "${local}" == 1 ]] && [[ -f "${currentPath}/.init.0.0.flag" ]]; then
  echo "Magento Server already initialized"
  exit 0
fi

if [[ "${check}" == 0 ]] && [[ "${local}" == 0 ]]; then
  updateApt=$(which update-apt 2>/dev/null | wc -l)

  if [[ "${updateApt}" -eq 1 ]]; then
    sudo update-apt
  else
    sudo apt-get update
  fi
fi

installPackage=$(which install-package 2>/dev/null | wc -l)

if [[ $(which jq 2>/dev/null | wc -l) -eq 0 ]]; then
  if [[ "${check}" == 0 ]] && [[ "${local}" == 0 ]]; then
    echo "installing jq"
    if [[ "${installPackage}" -eq 1 ]]; then
      sudo install-package jq
    else
      sudo apt-get install -y jq
    fi
  else
    >&2 echo "jq is not installed"
  fi
else
  echo "jq is installed"
fi

if [[ $(which sponge 2>/dev/null | wc -l) -eq 0 ]]; then
  if [[ "${check}" == 0 ]] && [[ "${local}" == 0 ]]; then
    echo "installing sponge"
    if [[ "${installPackage}" -eq 1 ]]; then
      sudo install-package moreutils
    else
      sudo apt-get install -y moreutils
    fi
  else
    >&2 echo "sponge is not installed"
  fi
else
  echo "sponge is installed"
fi

if [[ $(which crudini 2>/dev/null | wc -l) -eq 0 ]]; then
  if [[ "${check}" == 0 ]] && [[ "${local}" == 0 ]]; then
    echo "installing crudini"
    if [[ "${installPackage}" -eq 1 ]]; then
      sudo install-package crudini
    else
      sudo apt-get install -y crudini
    fi
  else
    >&2 echo "crudini is not installed"
  fi
else
  echo "crudini is installed"
fi

if [[ $(which unzip 2>/dev/null | wc -l) -eq 0 ]]; then
  if [[ "${check}" == 0 ]] && [[ "${local}" == 0 ]]; then
    echo "installing unzip"
    if [[ "${installPackage}" -eq 1 ]]; then
      sudo install-package unzip
    else
      sudo apt-get install -y unzip
    fi
  else
    >&2 echo "unzip is not installed"
  fi
else
  echo "unzip is installed"
fi

if [[ $(which gzip 2>/dev/null | wc -l) -eq 0 ]]; then
  if [[ "${check}" == 0 ]] && [[ "${local}" == 0 ]]; then
    echo "installing gzip"
    if [[ "${installPackage}" -eq 1 ]]; then
      sudo install-package gzip
    else
      sudo apt-get install -y gzip
    fi
  else
    >&2 echo "gzip is not installed"
  fi
else
  echo "gzip is installed"
fi

if [[ $(which telnet 2>/dev/null | wc -l) -eq 0 ]]; then
  if [[ "${check}" == 0 ]] && [[ "${local}" == 0 ]]; then
    echo "installing telnet"
    if [[ "${installPackage}" -eq 1 ]]; then
      sudo install-package telnet
    else
      sudo apt-get install -y telnet
    fi
  else
    >&2 echo "telnet is not installed"
  fi
else
  echo "telnet is installed"
fi

if [[ $(which mysql 2>/dev/null | wc -l) -eq 0 ]]; then
  if [[ "${check}" == 0 ]] && [[ "${local}" == 0 ]]; then
    echo "installing mysql client"
    if [[ "${installPackage}" -eq 1 ]]; then
      sudo install-package mysql-client
    else
      sudo apt-get install -y mysql-client
    fi
  else
    >&2 echo "mysql client is not installed"
  fi
else
  echo "mysql client is installed"
fi

if [[ $(which dig 2>/dev/null | wc -l) -eq 0 ]]; then
  if [[ "${check}" == 0 ]] && [[ "${local}" == 0 ]]; then
    echo "installing dig"
    if [[ "${installPackage}" -eq 1 ]]; then
      sudo install-package dnsutils
    else
      sudo apt-get install -y dnsutils
    fi
  else
    >&2 echo "dig not is installed"
  fi
else
  echo "dig is installed"
fi

if [[ $(which git 2>/dev/null | wc -l) -eq 0 ]]; then
  if [[ "${check}" == 0 ]] && [[ "${local}" == 0 ]]; then
    echo "installing git"
    if [[ "${installPackage}" -eq 1 ]]; then
      sudo install-package git
    else
      sudo apt-get install -y git
    fi
  else
    >&2 echo "git not is installed"
  fi
else
  echo "git is installed"
fi

if [[ $(which tar 2>/dev/null | wc -l) -eq 0 ]]; then
  if [[ "${check}" == 0 ]] && [[ "${local}" == 0 ]]; then
    echo "installing tar"
    if [[ "${installPackage}" -eq 1 ]]; then
      sudo install-package tar
    else
      sudo apt-get install -y tar
    fi
  else
    >&2 echo "tar not is installed"
  fi
else
  echo "tar is installed"
fi

homeDirectory=$(echo "${HOME}" | sed 's:/*$::')
binaryDirectory=

chmod +x "${currentPath}/../ini/parse"

if [[ ! -d "${homeDirectory}/.local/bin" ]]; then
  if [[ "${check}" == 0 ]] && [[ $(mkdir -p "${homeDirectory}/.local/bin" 2>/dev/null && echo "true" || echo "false") == "true" ]]; then
    echo "Created path: ${homeDirectory}/.local/bin"
    binaryDirectory="${homeDirectory}/.local/bin"
  else
    if [[ ! -d "${currentPath}/../bin" ]]; then
      if [[ "${check}" == 0 ]] && [[ $(mkdir -p "${currentPath}/../bin" 2>/dev/null && echo "true" || echo "false") == "true" ]]; then
        echo "Creating path: ${currentPath}/../bin"
        binaryDirectory="${currentPath}/../bin"
      else
        if [[ "${check}" == 0 ]]; then
          >&2 echo "Could not create path: ${homeDirectory}/.local/bin or ${currentPath}/../bin"
        else
          >&2 echo "Could not find path: ${homeDirectory}/.local/bin or ${currentPath}/../bin"
        fi
        exit 1
      fi
    else
      binaryDirectory="${currentPath}/../bin"
    fi
  fi
else
  binaryDirectory="${homeDirectory}/.local/bin"
fi

export PATH="${binaryDirectory}:${PATH}"

if [[ ! -L "${binaryDirectory}/ini-parse" ]]; then
  if [[ "${check}" == 0 ]]; then
    echo "Installing ini-parse to local user"
    if [[ $(ln -s "${currentPath}/../ini/parse" "${binaryDirectory}/ini-parse" 2>/dev/null && echo "true" || echo "false") == "false" ]]; then
      >&2 echo "Could not link script from: ${currentPath}/../ini/parse to: ${binaryDirectory}/ini-parse"
      exit 1
    fi
  else
    >&2 "ini-parse is not installed to local user"
  fi
else
  echo "ini-parse is installed to local user"
fi

if [[ "${local}" == 0 ]]; then
  if [[ ! -L /usr/local/bin/ini-parse ]]; then
    if [[ "${check}" == 0 ]]; then
      echo "Installing ini-parse to system"
      sudo ln -s "${currentPath}/../ini/parse" /usr/local/bin/ini-parse
    else
      >&2 echo "ini-parse is not installed to system"
    fi
  else
    echo "ini-parse is installed to system"
  fi
fi

chmod +x "${currentPath}/../ini/set"

if [[ ! -L "${binaryDirectory}/ini-set" ]]; then
  if [[ "${check}" == 0 ]]; then
    echo "Installing ini-set to local user"
    if [[ $(ln -s "${currentPath}/../ini/set" "${binaryDirectory}/ini-set" 2>/dev/null && echo "true" || echo "false") == "false" ]]; then
      >&2 echo "Could not link script from: ${currentPath}/../ini/set to: ${binaryDirectory}/ini-set"
      exit 1
    fi
  else
    >&2 "ini-set is not installed to local user"
  fi
else
  echo "ini-set is installed to local user"
fi

if [[ "${local}" == 0 ]]; then
  if [[ ! -L /usr/local/bin/ini-set ]]; then
    if [[ "${check}" == 0 ]]; then
      echo "Installing ini-set to system"
      sudo ln -s "${currentPath}/../ini/set" /usr/local/bin/ini-set
    else
      >&2 echo "ini-set is not installed to system"
    fi
  else
    echo "ini-set is installed to system"
  fi
fi

chmod +x "${currentPath}/../ini/del"

if [[ ! -L "${binaryDirectory}/ini-del" ]]; then
  echo "Installing ini-del to local user"
  if [[ "${check}" == 0 ]]; then
    if [[ $(ln -s "${currentPath}/../ini/del" "${binaryDirectory}/ini-del" 2>/dev/null && echo "true" || echo "false") == "false" ]]; then
      >&2 echo "Could not link script from: ${currentPath}/../ini/del to: ${binaryDirectory}/ini-del"
      exit 1
    fi
  else
    >&2 "ini-del is not installed to local user"
  fi
else
  echo "ini-del is installed to local user"
fi

if [[ "${local}" == 0 ]]; then
  if [[ ! -L /usr/local/bin/ini-del ]]; then
    if [[ "${check}" == 0 ]]; then
      echo "Installing ini-del to system"
      sudo ln -s "${currentPath}/../ini/del" /usr/local/bin/ini-del
    else
      >&2 echo "ini-del is not installed to system"
    fi
  else
    echo "ini-del is installed to system"
  fi
fi

chmod +x "${currentPath}/../ini/move"

if [[ ! -L "${binaryDirectory}/ini-move" ]]; then
  if [[ "${check}" == 0 ]]; then
    echo "Installing ini-move to local user"
    if [[ $(ln -s "${currentPath}/../ini/move" "${binaryDirectory}/ini-move" 2>/dev/null && echo "true" || echo "false") == "false" ]]; then
      >&2 echo "Could not link script from: ${currentPath}/../ini/move to: ${binaryDirectory}/ini-move"
      exit 1
    fi
  else
    >&2 "ini-move is not installed to local user"
  fi
else
  echo "ini-move is installed to local user"
fi

if [[ "${local}" == 0 ]]; then
  if [[ ! -L /usr/local/bin/ini-move ]]; then
    if [[ "${check}" == 0 ]]; then
      echo "Installing ini-move to system"
      sudo ln -s "${currentPath}/../ini/move" /usr/local/bin/ini-move
    else
      >&2 echo "ini-move is not installed to system"
    fi
  else
    echo "ini-move is installed to system"
  fi
fi

chmod +x "${currentPath}/../ini/default"

if [[ ! -L "${binaryDirectory}/ini-default" ]]; then
  if [[ "${check}" == 0 ]]; then
    echo "Installing ini-default to local user"
    if [[ $(ln -s "${currentPath}/../ini/default" "${binaryDirectory}/ini-default" 2>/dev/null && echo "true" || echo "false") == "false" ]]; then
      >&2 echo "Could not link script from: ${currentPath}/../ini/default to: ${binaryDirectory}/ini-default"
      exit 1
    fi
  else
    >&2 "ini-default is not installed to local user"
  fi
else
  echo "ini-default is installed to local user"
fi

if [[ "${local}" == 0 ]]; then
  if [[ ! -L /usr/local/bin/ini-default ]]; then
    if [[ "${check}" == 0 ]]; then
      echo "Installing ini-default to system"
      sudo ln -s "${currentPath}/../ini/default" /usr/local/bin/ini-default
    else
      >&2 echo "ini-default is not installed to system"
    fi
  else
    echo "ini-default is installed to system"
  fi
fi

if [[ ! -f /etc/bash/profile ]] && [[ ! -f "${homeDirectory}/.profile" ]] && [[ ! -f "${homeDirectory}/.bash_profile" ]]; then
  if [[ "${check}" == 0 ]]; then
    if [[ $(touch "${homeDirectory}/.profile" 2>/dev/null && echo "true" || echo "false") == "true" ]]; then
      echo "Creating file at: ${homeDirectory}/.profile"
      cat <<EOF | tee "${homeDirectory}/.profile" > /dev/null
# if running bash
if [[ $(which bash 2>/dev/null | wc -l) -gt 0 ]]; then
  # include .bashrc if it exists
  if [ -f "${homeDirectory}/.bashrc" ]; then
    source "${homeDirectory}/.bashrc"
  fi
fi
# set PATH so it includes user's private bin if it exists
if [ -d "${homeDirectory}/bin" ] ; then
  PATH="${homeDirectory}/bin:\${PATH}"
fi
# set PATH so it includes user's private bin if it exists
if [ -d "${binaryDirectory}" ] ; then
  PATH="${binaryDirectory}:\${PATH}"
fi
EOF
    else
      >&2 echo "Could not create file at: ${homeDirectory}/.profile"
      exit 1
    fi
  else
    >&2 echo "No file found to modify path"
    exit 1
  fi
fi

if [[ -f /etc/bash/profile ]]; then
  if [[ "${check}" == 0 ]]; then
    echo "Adding path to file at: /etc/bash/profile"
    cat <<EOF | tee -a /etc/bash/profile > /dev/null
if [ -d "${binaryDirectory}" ] ; then
  PATH="${binaryDirectory}:\${PATH}"
fi
EOF
    source /etc/bash/profile
  else
    echo "Found file: /etc/bash/profile to modify path"
  fi
fi

if [[ -f "${homeDirectory}/.profile" ]]; then
  if [[ "${check}" == 0 ]]; then
    echo "Adding path to file at: ${homeDirectory}/.profile"
    cat <<EOF | tee -a "${homeDirectory}/.profile" > /dev/null
# set PATH so it includes user's private bin if it exists
if [ -d "${binaryDirectory}" ] ; then
  PATH="${binaryDirectory}:\${PATH}"
fi
EOF
    source "${homeDirectory}/.profile"
  else
    echo "Found file: ${homeDirectory}/.profile to modify path"
  fi
fi

if [[ -f "${homeDirectory}/.bash_profile" ]]; then
  if [[ "${check}" == 0 ]]; then
    echo "Adding path to file at: ${homeDirectory}/.bash_profile"
    cat <<EOF | tee -a "${homeDirectory}/.bash_profile" > /dev/null
# set PATH so it includes user's private bin if it exists
if [ -d "${binaryDirectory}" ] ; then
  PATH="${binaryDirectory}:\${PATH}"
fi
EOF
    source "${homeDirectory}/.bash_profile"
  else
    echo "Found file: ${homeDirectory}/.bash_profile to modify path"
  fi
fi

touch "${currentPath}/.init.${check}.${local}.flag"
