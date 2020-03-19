#! /bin/bash -f
submodules=(
  "https://github.com/taichi-ishitani/tue.git tue 24a2bf157df6a84f8b6d7d260d83d1af3733556e"
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

