#!/usr/bin/env bash
set -e

declare -a paths
declare -a tfvars_files

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
<!-- BEGINNING OF TERRAFORM-DOCS HOOK -->
<!-- END OF TERRAFORM-DOCS HOOK -->
'

for path_uniq in $(echo "${paths[*]}" | tr ' ' '\n' | sort -u); do
  path_uniq="${path_uniq//__REPLACED__SPACE__/ }"

  pushd "$path_uniq" > /dev/null

  ## Create README.md if it does not exist
  if [[ ! -f "${text_file}" ]]; then
    # TODO: improve with a base template
    touch ${text_file}
    echo "Creating ${text_file}, please git add."
    file_changed=1
  fi

  ## Add markers if they don't exist
  if grep -q -v "BEGINNING OF TERRAFORM-DOCS HOOK" ${text_file}; then
    echo "${markers_block}" >>${text_file}
    echo "Updating ${text_file}, please git add."
    file_changed=1
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

#if [ "${file_changed}" == 1 ]; then
#  exit 1
#fi
