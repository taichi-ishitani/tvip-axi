#! /bin/bash -f
submodules=(
  "https://github.com/taichi-ishitani/tue.git tue f7ea8f51f8ab2f4b1c9f4887cc7550cd983a5be6"
  "https://github.com/taichi-ishitani/tvip-common.git tvip-common d3641c7992260d0eae651f02c9778fe65eba6a9e"
)

for ((i=0; $i < ${#submodules[*]}; i++)) do
  temp=(${submodules[$i]})
  url=${temp[0]}
  path=${temp[1]}
  hash=${temp[2]}
  if [ ! -d $path ]; then
    git clone $url $path
  fi
  $(cd $path; git fetch; git checkout $hash)
done

