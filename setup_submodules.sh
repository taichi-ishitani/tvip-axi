#! /bin/bash -f
submodules=(
  "https://github.com/taichi-ishitani/tue.git tue 46d0a448db3c64455c5817970ed710e5ea1269bb"
  "https://github.com/taichi-ishitani/tvip-common.git tvip-common 27bc202b7b334ea5eb746dfdceaa41c46c7822f4"
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

