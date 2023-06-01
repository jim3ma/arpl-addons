#!/usr/bin/env ash

set -x

# check in arpl or DSM
is_ramdisk=false
is_dsm=false

BIN_PREFIX="/opt/bin"
RAMDISK_PATH=/tmp/ramdisk

YQ=/usr/bin/yq
XXD=${BIN_PREFIX}/xxd
ATTR=${BIN_PREFIX}/attr
MD5SUM=${BIN_PREFIX}/md5sum

patch_db=/addons/patches/db.yaml

case "$1" in
  early | jrExit | rcExit | patches | modules)
    exit 0
  ;;
  
  arpl)
    is_ramdisk=true
    patch_db=${RAMDISK_PATH}/addons/patches/db.yaml
    YQ=${RAMDISK_PATH}/usr/bin/yq
    echo work in ramdisk
  ;;
  
  late)
    mkdir -p /tmpRoot/addons/patches
    cp -fv /addons/patches/db.yaml /tmpRoot/addons/patches
    cp -fv "$0" /tmpRoot/addons/patches
    cp -fv /usr/bin/yq /tmpRoot/usr/bin
    echo work in late
  ;;

  dsm)
    is_dsm=true
    echo work in dsm
  ;;

  *)
    echo "Unknown stage: $1"
    exit 1
    ;;
esac

shift

for id in $@; do
  # find patch by id
  patch=$(${YQ} ".patches | filter(.id == $id)" "$patch_db")
  if [ "$patch" = "[]" ]; then
    echo patch $id not found
    exit 1
  fi

  # get patch
  _path=$(echo "$patch" | ${YQ} ".[0].path")
  if [ "$path" = "null" ]; then
    echo patch $id path not found
  fi
  echo found path $_path for patch $id

  ramdisk=$(echo "$patch" | ${YQ} '.[0] | contains({"ramdisk": true})')
  if [ "$ramdisk" != "$is_ramdisk" ]; then
    continue
  fi
  # update path in dsm
  if [ "$is_dsm" = "true" ]; then
    true
  elif [ "$ramdisk" != "true" ]; then
    _path=/tmpRoot${_path}
  else
    _path=${RAMDISK_PATH}${_path}
  fi

  if [ ! -e "$_path" ]; then
    echo patch $id, path: $_path not exists, skipped
    continue
  fi

  md5=""
  # in dsm use xattr
  if [ "$ramdisk" != "true" ]; then
    # get md5sum from xattr
    md5=$(${ATTR} -qg patch.md5sum "$_path")
    if [ -z "$md5" ]; then
      # update xattr
      md5=$(${MD5SUM} "$_path" | awk '{print $1}')
      ${ATTR} -s patch.md5sum -V "$md5" "$_path"
    fi
  else
    # in arpl, use orig.hash file
    if [ -e "${_path}.orig.hash" ]; then
      md5=$(cat "${_path}.orig.hash")
    else
      md5=$(${MD5SUM} "$_path" | awk '{print $1}')
      echo -n ${md5} > "${_path}.orig.hash"
    fi
  fi

  # get patch by md5sum
  patch_data=$(echo "$patch" | ${YQ} ".[0].versions | filter(.hash == \"$md5\")")
  if [ "$patch" = "[]" ]; then
    echo patch $id no hash matched, hash: $md5
    exit 1
  fi

  # patch the file
  target=$(echo "$patch_data" | ${YQ} ".[0].target")
  if [ "$target" = "null" ]; then
    echo patch $id target not found
    continue
  fi
  echo apply patch $id, path: $_path, target: $target
  echo "$target" | ${XXD} -r - "$_path"

  # update patch info
  build=$(echo "$patch_data" | ${YQ} ".[0].build")
  if [ "$ramdisk" != "true" ]; then
    ${ATTR} -s patch.$id.build -V "$build" "$_path"
  else
    echo -n ${build} > "${_path}.orig.$id.build"
  fi

  common_post_script=$(echo "$patch" | ${YQ} '.[0].post_script')
  if [ "$common_post_script" != "null" ]; then
    echo execute patch $id common post script
    echo "$common_post_script" | ${SHELL} -x
  fi

  post_script=$(echo "$patch_data" | ${YQ} '.[0].post_script')
  if [ "$post_script" != "null" ]; then
    echo execute patch $id post script
    echo "$post_script" | ${SHELL} -x
  fi
done
