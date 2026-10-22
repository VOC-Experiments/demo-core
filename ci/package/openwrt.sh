#!/usr/bin/env bash
set -euo pipefail
cp -a source/src "recipes/$BUILD_PROJECT/src"
version=$(cat source/VERSION)
sed -e "s/@VERSION@/$version/g" -e "s/@REVISION@/$PACKAGE_RELEASE/g" source/ci/package/Makefile > "recipes/$BUILD_PROJECT/Makefile"
compile() {
    make -j"$(nproc)" "package/$BUILD_PROJECT/compile" V=s BUILD_LOG=1
    local target file
    local files=("recipes/$BUILD_PROJECT")
    target=$(echo staging_dir/target-*)
    if [ -f "$target/packages/$BUILD_PROJECT.list" ]; then
        while IFS= read -r file; do
            file="$target/${file#./}"
            if [ -f "$file" ] || [ -L "$file" ]; then
                files+=("$file")
            fi
        done < "$target/packages/$BUILD_PROJECT.list"
    fi
    if [ -f "$target/pkginfo/$BUILD_PROJECT.provides" ]; then
        files+=("$target/pkginfo/$BUILD_PROJECT.provides")
    fi
    printf 'Own development export: %s\n' "${files[@]}"
    python3 -m ci.repository sdk-export "$sdk" "$bundle" "${files[@]}"
    return 0
}
