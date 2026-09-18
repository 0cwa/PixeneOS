#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later

set -euo pipefail

python3 - <<'PY'
import ast
from pathlib import Path

root = Path.cwd()
assert (root / "src" / "boot_animation.py").is_file()
module_tree = ast.parse((root / "src/boot_animation.py").read_text())
module_class = next(
    node
    for node in ast.walk(module_tree)
    if isinstance(node, ast.ClassDef) and node.name == "BootAnimationMod"
)
assert [ast.unparse(base) for base in module_class.bases] == ["LegacyCliModule"]
method_names = {
    node.name for node in module_class.body if isinstance(node, ast.FunctionDef)
}
assert {"add_args", "from_args", "requirements", "inject"} <= method_names
inject = next(
    node
    for node in module_class.body
    if isinstance(node, ast.FunctionDef) and node.name == "inject"
)
assert [arg.arg for arg in inject.args.args] == [
    "self", "boot_fs", "ext_fs", "sepolicies", "compatible_sepolicy"
]
assert len(inject.args.defaults) == 1
assert ast.unparse(inject.args.defaults[0]) == "False"

util = (root / "src/util_functions.sh").read_text()
start = util.index("function prepare_boot_animation_module()")
end = util.index("\n# Resolve and acquire", start)
registration = util[start:end]
assert "return 0" in registration
assert 'registry_file="${helper_root}/lib/modules/registry.py"' in registration
assert "def legacy_cli_module_types" in registration
assert "result.append(BootAnimationMod)" in registration
assert "return {" not in registration
print("boot animation helper registration contract passed")
PY
