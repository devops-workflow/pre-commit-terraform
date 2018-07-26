#!/usr/bin/env bash
set -e

declare -a paths
declare -a tfvars_files

## If top of repo and not exist, add markdown lint config
# FIX: VERIFY could be running from any directory
FILE1=$1
DIRECTORY=$(dirname "${FILE1}")

if [ "${path_uniq}" == "" ]; then
  if [ ! -f '.markdownlintrc' ]; then
    cat <<MARKDOWNLINT > .markdownlintrc
{
"default": true,
"MD013": { "code_blocks": false, "tables": false },
}
MARKDOWNLINT
    md_config=1
  fi
  if [ ! -f '.mdlrc' ]; then
    cat <<MDL > .mdlrc
rules "~MD013"
MDL
    md_config=1
  fi
  if [ "${md_config}" -eq 1 ]; then
    echo "Creating markdown lint config. please git add"
  fi
fi

index=0

for file_with_path in "$@"; do
  file_with_path="${file_with_path// /__REPLACED__SPACE__}"

  paths[index]=$(dirname "$file_with_path")

  if [[ "$file_with_path" == *".tfvars" ]]; then
    tfvars_files+=("$file_with_path")
  fi

  ((index+=1))
done

readonly tmp_file=$(mktemp)
readonly text_file="README.md"
markers_block='
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->'

for path_uniq in $(echo "${paths[*]}" | tr ' ' '\n' | sort -u); do
  path_uniq="${path_uniq//__REPLACED__SPACE__/ }"

  pushd "$path_uniq" > /dev/null

  ## Create README.md if it does not exist
  if [[ ! -f "${text_file}" ]]; then
    # TODO: improve with a base template
    touch ${text_file}
    echo "Creating ${path_uniq}/${text_file}, please git add."
  fi

  ## Add markers if they don't exist
  if [ $(grep "BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK" ${text_file} | wc -l) -eq 0 ]; then
    echo "${markers_block}" >>${text_file}
    echo "Updating ${path_uniq}/${text_file}, please git add."
  fi

  ## Generate docs and add to README.md
  terraform-docs md ./ > "$tmp_file"

  # Replace content between markers with the placeholder - https://stackoverflow.com/questions/1212799/how-do-i-extract-lines-between-two-line-delimiters-in-perl#1212834
  perl -i -ne 'if (/BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK/../END OF PRE-COMMIT-TERRAFORM DOCS HOOK/) { print $_ if /BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK/; print "I_WANT_TO_BE_REPLACED\n$_" if /END OF PRE-COMMIT-TERRAFORM DOCS HOOK/;} else { print $_ }' "$text_file"

  # Replace placeholder with the content of the file
  perl -i -e 'open(F, "'"$tmp_file"'"); $f = join "", <F>; while(<>){if (/I_WANT_TO_BE_REPLACED/) {print $f} else {print $_};}' "$text_file"

  rm -f "$tmp_file"

  popd > /dev/null
done
