
# Install/upgrade all tools scripts depend on

tool_list='terraform terraform-docs graphviz jq tflint'

if [ $(uname -s) == "Darwin" ]; then
  brew_installed=$(brew list)
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
