#! /bin/bash -f
submodules=(
  "https://github.com/taichi-ishitani/tue.git tue be2e2a8de16781d476400cb7675ffddc55de6e13"
  "https://github.com/taichi-ishitani/tvip-common.git tvip-common e08534cb325e758aa5564ebc39fe40492585a820"
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
