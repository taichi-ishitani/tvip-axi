#! /bin/bash -f
submodules=(
  "https://github.com/taichi-ishitani/tue.git tue ecc2f0a7562294676f3f7510ce58eba18b2bbcb0"
  "https://github.com/taichi-ishitani/tvip-common.git tvip-common 033183e63e1a5f325f43906972e78d18ebced220"
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

