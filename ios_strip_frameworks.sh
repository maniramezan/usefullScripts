

FRAMEWORKS_FOLDER_PATHS=($1)
VALID_ARCHS=($2)
EXPANDED_CODE_SIGN_IDENTITY=$3


containsElement () {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}

# Signs a framework with the provided identity
code_sign() {
  # Use the current code_sign_identitiy
  echo "Code Signing $1 with Identity ${EXPANDED_CODE_SIGN_IDENTITY}"
  echo "/usr/bin/codesign -f -s ${EXPANDED_CODE_SIGN_IDENTITY} --preserve-metadata=identifier,entitlements $1"
  /usr/bin/codesign -f -s ${EXPANDED_CODE_SIGN_IDENTITY} --preserve-metadata=identifier,entitlements "$1"
}

for FRAMEWORKS_FOLDER_PATH in "${FRAMEWORKS_FOLDER_PATHS[@]}"; do
  # Set working directory to product’s embedded frameworks 
  cd "${FRAMEWORKS_FOLDER_PATH}"

  echo "Stripping frameworks on path ${FRAMEWORKS_FOLDER_PATH}"

  for file in $(find . -type f -perm +111); do
    # Skip non-dynamic libraries
    if ! [[ "$(file "$file")" == *"dynamically linked shared library"* ]]; then
      continue
    fi
    # Get architectures for current file
    archs="$(lipo -info "${file}" | rev | cut -d ':' -f1 | rev)"
    stripped=""
    for arch in $archs; do
      containsElement "$arch" "${VALID_ARCHS[@]}"
      if ! [[ $? = 0 ]]; then
        # Strip non-valid architectures in-place
        lipo -remove "$arch" -output "$file" "$file" || exit 1
        # echo "lipo -remove $arch -output $file $file"
        stripped="$stripped $arch"
      fi
    done
    if [[ "$stripped" != "" ]]; then
      echo "Stripped $file of architectures:$stripped"
        code_sign "${file}"
    fi
  done
done