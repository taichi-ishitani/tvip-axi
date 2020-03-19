#! /bin/bash -f
submodules=(
  "https://github.com/taichi-ishitani/tue.git tue ada80d6344542549070e26db5083a153c5cbaade"
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

