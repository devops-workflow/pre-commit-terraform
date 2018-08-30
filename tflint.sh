#!/usr/bin/env bash

# TODO: build config to ignore modules until supports registry paths
#echo "Configuring tflint..."
tf_ver=$(terraform version | awk 'FNR <= 1' | cut -dv -f2)
echo -e "\tConfig tflint for terraform version: ${tf_ver}"
if [ -f '.tflint.hcl' ]; then
  perl -pi -e "s/\".*\"/\"${tf_ver}\"/ if /terraform_version =/" .tflint.hcl
else
  {
  echo -e "config {\nterraform_version = \"${tf_ver}\"\ndeep_check = true\nignore_module = {"
  for module in $(grep -h '[^a-zA-Z]source[ =]' *.tf | perl -pe 's/^.*=\s+//' | sort -u); do
    # if not ^"../
    echo "${module} = true"
  done
  echo -e "}\n}\n"
  } > .tflint.hcl
fi

# echo "Running tflint..."
tflint --version
# Might be better to run on whole dir instead
#tflint
for file in "$@"; do
  tflint $file
done
