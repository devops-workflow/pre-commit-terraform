#!/usr/bin/env bash
#
# Generate Terraform dependency graph and add to README.md in base module (repo root)
#

# Although pre-commit-terraform works file by file, graph is only desired for base module
# Therefore, here we get the base directory of the first file provided as argument

# Do I need to look at the files at all? Yes, could be running from any directory
FILE1=$1
DIRECTORY=$(dirname "${FILE1}")

readme='README.md'
# run if *.tf changes
# Add markers to README if not exist
# Add link between markers to graph
# Generate graph

terraform get
terraform graph | tee graph.dot | dot -Tpng > graph.png
echo -e "\n### Resource Graph\n" >> ${file_readme}
echo "![Terraform Graph](graph.png)" >> ${file_readme}
