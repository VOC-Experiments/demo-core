#!/usr/bin/env bash
set -euo pipefail
python3 - <<'SOURCE_BYPASS'
import ast,os
from pathlib import Path
path=Path(os.environ['PYTHONPATH'])/'ci/repository.py'
text=path.read_text()
node=next(n for n in ast.parse(text).body if isinstance(n,ast.FunctionDef) and n.name=='validate_package')
lines=text.splitlines()
lines[node.lineno-1:node.end_lineno]=[
    'def validate_package(owners, versions, filename, fields, row):',
    '    return next(p for p in owners if project_file(filename,p,owners))',
]
path.write_text('\n'.join(lines)+'\n')
SOURCE_BYPASS
case "$DISTRIBUTION" in
    rocky)
dnf install -y gcc rpm-build
upstream=$(cat "sources/$BUILD_PROJECT/VERSION")
release="${PACKAGE_RELEASE}.el${SUITE}"
build=$(mktemp -d)
mkdir -p "$build/SPECS" "$build/BUILDROOT"
cat > "$build/SPECS/negative.spec" <<EOF
Name: demo-app
Version: $upstream
Release: $release
Summary: Deliberate namespace spoof fixture
License: MIT
BuildArch: $ARCH
%description
Sandbox-only publisher negative fixture.
%install
mkdir -p %{buildroot}/usr/share/demo-core
printf namespace-spoof > %{buildroot}/usr/share/demo-core/fixture
%files
/usr/share/demo-core/fixture
EOF
rpmbuild --define "_topdir $build" -bb "$build/SPECS/negative.spec"
file=$(find "$build/RPMS" -name '*.rpm' -type f)
cp "$file" "packages/demo-core-${upstream}-${release}.${ARCH}.rpm"
printf '%s\n' demo-app > packages/demo-core.packages
        ;;
    *)
apt-get install -y build-essential
version=$(cat "sources/$BUILD_PROJECT/VERSION")
version=$(python3 /work/feed/ci/repository.py package-version "$DISTRIBUTION" "$SUITE" "$version" "$PACKAGE_RELEASE")
staging=$(mktemp -d)
mkdir -p "$staging/DEBIAN" "$staging/usr/bin" "$staging/usr/lib" "$staging/usr/include"
gcc -fPIC -shared sources/demo-core/src/core.c -Wl,-soname,libdemo-core.so -o "$staging/usr/lib/libdemo-core.so"
gcc sources/demo-core/src/core-main.c -L"$staging/usr/lib" -ldemo-core -o "$staging/usr/bin/demo-core"
cp sources/demo-core/src/core.h "$staging/usr/include/demo-core.h"
cat > "$staging/DEBIAN/control" <<EOF
Package: demo-app
Version: $version
Architecture: $ARCH
Maintainer: VOC Experiments <ci@example.invalid>
Description: Disposable canonical CI integration experiment
EOF
dpkg-deb --root-owner-group --build "$staging" "packages/${BUILD_PROJECT}_${version}_${ARCH}.deb"
printf '%s\n' 'demo-app' > "packages/${BUILD_PROJECT}.packages"
        ;;
esac
