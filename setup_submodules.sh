#! /bin/bash -f
submodules=(
  tue
)

for submodule in ${submodules[@]} ; do
  git submodule update --init ${submodule}
done
