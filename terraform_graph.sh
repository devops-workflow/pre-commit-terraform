#!/usr/bin/env bash
#
# Generate Terraform dependency graph and add to README.md in base module (repo root)
#

# run if *.tf changes
# Add markers to README if not exist
# Add link between markers to graph
# Generate graph

readme="README.md"
graph="resource-plan-graph.png"
graph_tmp="graph-tmp.png"
marker_start='<!-- BEGINNING OF PRE-COMMIT-TERRAFORM GRAPH HOOK -->'
marker_end='<!-- END OF PRE-COMMIT-TERRAFORM GRAPH HOOK -->'

### Update README file with link to graph
if [ $(grep "${marker_start}" ${readme} | wc -l) -eq 0 ]; then
  cat <<MARKER_BLOCK >>${readme}
${marker_start}

### Resource Graph of plan

![Terraform Graph](${graph})
${marker_end}
MARKER_BLOCK
  echo "Added graph to ${readme}, please git add."
fi

### Generate graph
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
