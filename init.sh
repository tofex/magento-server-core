#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -c  Only check

Example: ${scriptName} -c
EOF
}

trim()
{
  echo -n "$1" | xargs
}

check=0

while getopts hc? option; do
  case "${option}" in
    h) usage; exit 1;;
    c) check=1;;
    ?) usage; exit 1;;
  esac
done

if [[ "${check}" == 0 ]]; then
  updateApt=$(which update-apt | wc -l)

  if [[ "${updateApt}" -eq 1 ]]; then
    sudo update-apt
  else
    sudo apt-get update
  fi
fi

installPackage=$(which install-package | wc -l)

if [[ $(which jq | wc -l) -eq 0 ]]; then
  if [[ "${check}" == 0 ]]; then
    echo "installing jq"
    if [[ "${installPackage}" -eq 1 ]]; then
      sudo install-package jq
    else
      sudo apt-get install -y jq
    fi
  else
    echo "jq not installed"
  fi
else
  echo "jq installed"
fi

if [[ $(which sponge | wc -l) -eq 0 ]]; then
  if [[ "${check}" == 0 ]]; then
    echo "installing sponge"
    if [[ "${installPackage}" -eq 1 ]]; then
      sudo install-package moreutils
    else
      sudo apt-get install -y moreutils
    fi
  else
    echo "sponge not installed"
  fi
else
  echo "sponge installed"
fi

if [[ $(which crudini | wc -l) -eq 0 ]]; then
  if [[ "${check}" == 0 ]]; then
    echo "installing crudini"
    if [[ "${installPackage}" -eq 1 ]]; then
      sudo install-package crudini
    else
      sudo apt-get install -y crudini
    fi
  else
    echo "crudini not installed"
  fi
else
  echo "crudini installed"
fi

if [[ $(which unzip | wc -l) -eq 0 ]]; then
  if [[ "${check}" == 0 ]]; then
    echo "installing unzip"
    if [[ "${installPackage}" -eq 1 ]]; then
      sudo install-package unzip
    else
      sudo apt-get install -y unzip
    fi
  else
    echo "unzip not installed"
  fi
else
  echo "unzip installed"
fi

if [[ $(which gzip | wc -l) -eq 0 ]]; then
  if [[ "${check}" == 0 ]]; then
    echo "installing gzip"
    if [[ "${installPackage}" -eq 1 ]]; then
      sudo install-package gzip
    else
      sudo apt-get install -y gzip
    fi
  else
    echo "gzip not installed"
  fi
else
  echo "gzip installed"
fi

if [[ $(which telnet | wc -l) -eq 0 ]]; then
  if [[ "${check}" == 0 ]]; then
    echo "installing telnet"
    if [[ "${installPackage}" -eq 1 ]]; then
      sudo install-package telnet
    else
      sudo apt-get install -y telnet
    fi
  else
    echo "telnet not installed"
  fi
else
  echo "telnet installed"
fi

if [[ $(which mysql | wc -l) -eq 0 ]]; then
  if [[ "${check}" == 0 ]]; then
    echo "installing mysql client"
    if [[ "${installPackage}" -eq 1 ]]; then
      sudo install-package mysql-client
    else
      sudo apt-get install -y mysql-client
    fi
  else
    echo "mysql client not installed"
  fi
else
  echo "mysql client installed"
fi

if [[ $(which dig | wc -l) -eq 0 ]]; then
  if [[ "${check}" == 0 ]]; then
    echo "installing dig"
    if [[ "${installPackage}" -eq 1 ]]; then
      sudo install-package dnsutils
    else
      sudo apt-get install -y dnsutils
    fi
  else
    echo "dig not installed"
  fi
else
  echo "dig installed"
fi

if [[ $(which git | wc -l) -eq 0 ]]; then
  if [[ "${check}" == 0 ]]; then
    echo "installing git"
    if [[ "${installPackage}" -eq 1 ]]; then
      sudo install-package git
    else
      sudo apt-get install -y git
    fi
  else
    echo "git not installed"
  fi
else
  echo "git installed"
fi

if [[ $(which tar | wc -l) -eq 0 ]]; then
  if [[ "${check}" == 0 ]]; then
    echo "installing tar"
    if [[ "${installPackage}" -eq 1 ]]; then
      sudo install-package tar
    else
      sudo apt-get install -y tar
    fi
  else
    echo "tar not installed"
  fi
else
  echo "tar installed"
fi

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

chmod +x "${currentPath}/ini/parse"

if [[ ! -L "${HOME}/.local/bin/ini-parse" ]]; then
  echo "Installing ini-parse to local user"
  mkdir -p "${HOME}/.local/bin"
  ln -s "${currentPath}/ini/parse" "${HOME}/.local/bin/ini-parse"
  export PATH="${HOME}/.local/bin:${PATH}"
else
  echo "ini-parse installed to local user"
fi

if [[ "${check}" == 0 ]]; then
  if [[ ! -L /usr/local/bin/ini-parse ]]; then
    echo "Installing ini-parse to system"
    sudo ln -s "${currentPath}/ini/parse" /usr/local/bin/ini-parse
  else
    echo "ini-parse installed to system"
  fi
fi

chmod +x "${currentPath}/ini/set"

if [[ ! -L "${HOME}/.local/bin/ini-set" ]]; then
  echo "Installing ini-set to local user"
  mkdir -p "${HOME}/.local/bin"
  ln -s "${currentPath}/ini/set" "${HOME}/.local/bin/ini-set"
  export PATH="${HOME}/.local/bin:${PATH}"
else
  echo "ini-set installed to local user"
fi

if [[ "${check}" == 0 ]]; then
  if [[ ! -L /usr/local/bin/ini-set ]]; then
    echo "Installing ini-set to system"
    sudo ln -s "${currentPath}/ini/set" /usr/local/bin/ini-set
  else
    echo "ini-set installed to system"
  fi
fi

chmod +x "${currentPath}/ini/del"

if [[ ! -L "${HOME}/.local/bin/ini-del" ]]; then
  echo "Installing ini-del to local user"
  mkdir -p "${HOME}/.local/bin"
  ln -s "${currentPath}/ini/del" "${HOME}/.local/bin/ini-del"
  export PATH="${HOME}/.local/bin:${PATH}"
else
  echo "ini-del installed to local user"
fi

if [[ "${check}" == 0 ]]; then
  if [[ ! -L /usr/local/bin/ini-del ]]; then
    echo "Installing ini-del to system"
    sudo ln -s "${currentPath}/ini/del" /usr/local/bin/ini-del
  else
    echo "ini-del installed to system"
  fi
fi

chmod +x "${currentPath}/ini/move"

if [[ ! -L "${HOME}/.local/bin/ini-move" ]]; then
  echo "Installing ini-move to local user"
  mkdir -p "${HOME}/.local/bin"
  ln -s "${currentPath}/ini/move" "${HOME}/.local/bin/ini-move"
  export PATH="${HOME}/.local/bin:${PATH}"
else
  echo "ini-move installed to local user"
fi

if [[ "${check}" == 0 ]]; then
  if [[ ! -L /usr/local/bin/ini-move ]]; then
    echo "Installing ini-move to system"
    sudo ln -s "${currentPath}/ini/move" /usr/local/bin/ini-move
  else
    echo "ini-move installed to system"
  fi
fi

chmod +x "${currentPath}/ini/default"

if [[ ! -L "${HOME}/.local/bin/ini-default" ]]; then
  echo "Installing ini-default to local user"
  mkdir -p "${HOME}/.local/bin"
  ln -s "${currentPath}/ini/default" "${HOME}/.local/bin/ini-default"
  export PATH="${HOME}/.local/bin:${PATH}"
else
  echo "ini-default installed to local user"
fi

if [[ "${check}" == 0 ]]; then
  if [[ ! -L /usr/local/bin/ini-default ]]; then
    echo "Installing ini-default to system"
    sudo ln -s "${currentPath}/ini/default" /usr/local/bin/ini-default
  else
    echo "ini-default installed to system"
  fi
fi

if [[ ! -f "${HOME}/.profile" ]] && [[ ! -f "${HOME}/.bash_profile" ]]; then
  echo "Creating file at: ${HOME}/.profile"
  cat <<EOF | tee "${HOME}/.profile" > /dev/null
# if running bash
if [[ $(which bash | wc -l) -gt 0 ]]; then
  # include .bashrc if it exists
  if [ -f "\${HOME}/.bashrc" ]; then
    source "\${HOME}/.bashrc"
  fi
fi
# set PATH so it includes user's private bin if it exists
if [ -d "\${HOME}/bin" ] ; then
  PATH="\${HOME}/bin:\${PATH}"
fi
# set PATH so it includes user's private bin if it exists
if [ -d "\${HOME}/.local/bin" ] ; then
  PATH="\${HOME}/.local/bin:\${PATH}"
fi
EOF
fi

if [[ -f "${HOME}/.profile" ]]; then
  echo "Adding path to file at: ${HOME}/.profile"
  cat <<EOF | tee -a "${HOME}/.profile" > /dev/null
# set PATH so it includes user's private bin if it exists
if [ -d "\${HOME}/.local/bin" ] ; then
  PATH="\${HOME}/.local/bin:\${PATH}"
fi
EOF
  source "${HOME}/.profile"
fi

if [[ -f "${HOME}/.bash_profile" ]]; then
  echo "Adding path to file at: ${HOME}/.bash_profile"
  cat <<EOF | tee -a "${HOME}/.bash_profile" > /dev/null
# set PATH so it includes user's private bin if it exists
if [ -d "\${HOME}/.local/bin" ] ; then
  PATH="\${HOME}/.local/bin:\${PATH}"
fi
EOF
  source "${HOME}/.bash_profile"
fi
