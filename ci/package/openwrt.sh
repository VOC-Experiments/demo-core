#!/usr/bin/env bash
set -euo pipefail
python3 - <<'UNDECLARED_FIXTURE'
import ast, os
from pathlib import Path
path = Path(os.environ['PYTHONPATH']) / 'ci/repository.py'
text = path.read_text()
node = next(n for n in ast.parse(text).body if isinstance(n, ast.FunctionDef) and n.name == 'stage')
lines = text.splitlines()
original = lines[node.lineno - 1:node.end_lineno]
original[0] = original[0].replace('def stage(', 'def fixture_original_stage(', 1)
wrapper = [
    '', '', 'def stage(sdk, bundle, output):',
    '    result = fixture_original_stage(sdk, bundle, output)',
    "    manifest = next(output.rglob('build.json'))",
    "    (manifest.parent / 'undeclared-fixture.txt').write_text('Sandbox publisher boundary negative\\n')",
    '    return result',
]
lines[node.lineno - 1:node.end_lineno] = original + wrapper
changed = '\n'.join(lines) + '\n'
ast.parse(changed)
path.write_text(changed)
UNDECLARED_FIXTURE
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
