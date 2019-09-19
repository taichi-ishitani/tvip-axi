#! /bin/bash -f
submodules=(
  "https://github.com/taichi-ishitani/tue.git tue c4ce84ebd2cb52c7fb97f0c32101f53141d85132"
)

for ((i=0; $i < ${#submodules[*]}; i++)) do
  temp=(${submodules[$i]})
  url=${temp[0]}
  path=${temp[1]}
  hash=${temp[2]}
  if [ ! -d $path ]; then
    git clone $url $path
  fi
  $(cd $path; git checkout $hash)
done

