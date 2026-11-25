#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

godot_version=4.5
release_url="https://github.com/godotengine/godot/releases/download/${godot_version}-stable"
editor_name="Godot_v${godot_version}-stable_linux.x86_64"
scratch_dir="$(mktemp -d)"
trap 'rm -rf "$scratch_dir"' EXIT

download() {
  curl --fail --silent --show-error --location --retry 3 --connect-timeout 20 \
    --output "$2" "$1"
}

printf 'Downloading Godot %s and the Web export template\n' "$godot_version"
download "$release_url/$editor_name.zip" "$scratch_dir/editor.zip"
unzip -q "$scratch_dir/editor.zip" -d "$scratch_dir"
godot="$scratch_dir/$editor_name"
chmod +x "$godot"
touch "$scratch_dir/._sc_"

download "$release_url/Godot_v${godot_version}-stable_export_templates.tpz" "$scratch_dir/templates.tpz"
template_dir="$scratch_dir/editor_data/export_templates/${godot_version}.stable"
mkdir -p "$template_dir"
unzip -jq "$scratch_dir/templates.tpz" templates/web_nothreads_release.zip -d "$template_dir"

mkdir -p build/web
touch build/.gdignore
"$godot" --headless --path . --editor --import
"$godot" --headless --path . --export-release Web build/web/index.html

test -s build/web/index.html
test -s build/web/index.pck
test -s build/web/index.wasm
printf 'Yuke Cat source and credits: https://github.com/itslevanx/Yuke-Cat\n' > build/web/CREDITS.txt
cp AUTHORS COPYING build/web/
cp -R LICENSES build/web/
