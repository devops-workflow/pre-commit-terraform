#!/usr/bin/env bash
set -e

declare -a paths
declare -a tfvars_files

marker_start='<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->'
marker_end='<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->'

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
  if [ $(grep "${marker_start}" ${text_file} | wc -l) -eq 0 ]; then
    cat <<MARKER_BLOCK >>${text_file}

${marker_start}
${marker_end}
MARKER_BLOCK
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
