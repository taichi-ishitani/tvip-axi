#! /bin/bash -f
submodules=(
  "https://github.com/taichi-ishitani/tue.git tue ada80d6344542549070e26db5083a153c5cbaade"
  "https://github.com/taichi-ishitani/tvip-common.git tvip-common 1b41f9c1adc3724e6430c795e9fa4c0b5e8c1af0"
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

