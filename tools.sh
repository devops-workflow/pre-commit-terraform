#!/usr/bin/env bash
#
# Install/upgrade all tools scripts depend on
#

tool_list='terraform terraform-docs graphviz jq tflint'

if [ $(uname -s) == "Darwin" ]; then
  ## Install brew if not installed
  which brew > /dev/null
  if [ "$?" -ne 0 ]; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi
  ## Install/upgrade tools
  brew_installed=$(brew list)
  # jq required first
  if [ $(echo ${brew_installed} | grep jq | wc -l )  -eq 0 ]; then
    brew install jq
  fi
  outdated_apps=$(brew outdated --json=v1 | jq -r .[].name)
  for app in ${tool_list}; do
    if [ $(echo ${brew_installed} | grep ${app} | wc -l )  -gt 0 ]; then
      if [ $(echo ${outdated_apps} | grep ${app} | wc -l )  -gt 0 ]; then
        brew upgrade ${app}
      fi
    else
      if [ "${app}" == "tflint" ]; then
        brew tap wata727/tflint
      fi
      brew install ${app}
    fi
  done
fi

#terraform_landscape tfenv
