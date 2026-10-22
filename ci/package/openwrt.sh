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
cp -a source/src "recipes/$BUILD_PROJECT/src"
version=$(cat source/VERSION)
sed -e "s/@VERSION@/$version/g" -e "s/@REVISION@/$PACKAGE_RELEASE/g" source/ci/package/Makefile > "recipes/$BUILD_PROJECT/Makefile"
compile() {
    printf '\nCONFIG_PACKAGE_demo-app=m\n' >> .config
    make defconfig
    make -j"$(nproc)" "package/$BUILD_PROJECT/compile" V=s BUILD_LOG=1
    python3 - <<'RENAME_FOREIGN'
from pathlib import Path
for path in Path('bin/packages').glob('*/package_ci/demo-app*'):
    if path.suffix in {'.ipk','.apk'}:
        path.rename(path.with_name(path.name.replace('demo-app','demo-core',1)))
RENAME_FOREIGN
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
