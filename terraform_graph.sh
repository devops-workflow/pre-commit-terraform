#!/usr/bin/env bash
#
# Generate Terraform dependency graph and add to README.md in base module (repo root)
#

# Although pre-commit-terraform works file by file, graph is only desired for base module
# Therefore, here we get the base directory of the first file provided as argument

# Do I need to look at the files at all? Yes, could be running from any directory

# run if *.tf changes
# Add markers to README if not exist
# Add link between markers to graph
# Generate graph

FILE1=$1
DIRECTORY=$(dirname "${FILE1}")

readme="README.md"
graph="graph.png"
graph_tmp="graph-tmp.png"
marker_start='<!-- BEGINNING OF PRE-COMMIT-TERRAFORM GRAPH HOOK -->'
marker_end='<!-- END OF PRE-COMMIT-TERRAFORM GRAPH HOOK -->'

if [ $(grep "${marker_start}" ${readme} | wc -l) -eq 0 ]; then
  cat <<MARKER_BLOCK >>${readme}
${marker_start}

### Resource Graph of plan

![Terraform Graph](graph.png)
${marker_end}
MARKER_BLOCK
  echo "Updated ${readme}, please git add."
fi


terraform init
terraform graph | dot -Tpng > ${graph_tmp}
if [ ! -f "${graph}" ]; then
  mv ${graph_tmp} ${graph}
  echo "Created resource graph, please git add."
else
  cmp ${graph_tmp} ${graph}
  if [ "$?" -gt 0 ]; then
    mv ${graph_tmp} ${graph}
    echo "Updated resource graph, please git add."
  else
    rm ${graph_tmp}
  fi
fi
