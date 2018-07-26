#!/usr/bin/env bash

for file in "$@"; do
  tflint $file
done
