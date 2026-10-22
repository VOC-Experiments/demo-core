#!/usr/bin/env bash
set -euo pipefail
apt-get install -y build-essential
version=$(cat "sources/$BUILD_PROJECT/VERSION")
version=$(python3 /work/feed/ci/repository.py package-version "$DISTRIBUTION" "$SUITE" "$version" "$PACKAGE_RELEASE")
staging=$(mktemp -d)
mkdir -p "$staging/DEBIAN" "$staging/usr/bin" "$staging/usr/lib" "$staging/usr/include"
gcc -fPIC -shared sources/demo-core/src/core.c -Wl,-soname,libdemo-core.so -o "$staging/usr/lib/libdemo-core.so"
gcc sources/demo-core/src/core-main.c -L"$staging/usr/lib" -ldemo-core -o "$staging/usr/bin/demo-core"
cp sources/demo-core/src/core.h "$staging/usr/include/demo-core.h"
cat > "$staging/DEBIAN/control" <<EOF
Package: demo-core
Version: $version
Architecture: $ARCH
Maintainer: VOC Experiments <ci@example.invalid>
Description: Disposable canonical CI integration experiment
EOF
dpkg-deb --root-owner-group --build "$staging" "packages/${BUILD_PROJECT}_${version}_${ARCH}.deb"
printf '%s\n' "$BUILD_PROJECT" > "packages/${BUILD_PROJECT}.packages"
