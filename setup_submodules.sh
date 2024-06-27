#! /bin/bash -f
submodules=(
  "https://github.com/taichi-ishitani/tue.git tue d42734b16c613521655f29edc11294251e8b5b39"
  "https://github.com/taichi-ishitani/tvip-common.git tvip-common be09036727aac5be4c483536b12e7a1e3c0c8b8b"
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
