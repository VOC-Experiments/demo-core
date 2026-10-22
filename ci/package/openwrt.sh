#!/usr/bin/env bash
set -euo pipefail
cp -a source/src "recipes/$BUILD_PROJECT/src"
version=$(cat source/VERSION)
sed -e "s/@VERSION@/$version/g" -e "s/@REVISION@/$PACKAGE_RELEASE/g" source/ci/package/Makefile > "recipes/$BUILD_PROJECT/Makefile"
compile() {
    make -j"$(nproc)" "package/$BUILD_PROJECT/compile" V=s BUILD_LOG=1
    local target
    target=$(echo staging_dir/target-*)
    python3 -m ci.repository sdk-export "$sdk" "$bundle" "recipes/$BUILD_PROJECT" \
        "$target/usr/include" "$target/usr/lib" "$target"/pkginfo/*.provides
    return 0
}
