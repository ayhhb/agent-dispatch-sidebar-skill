#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: %s --out DIR --name APP_NAME [--bundle-id ID]\n' "$0" >&2
}

out_dir=""
app_name=""
bundle_id=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --out)
      out_dir="${2:-}"
      shift 2
      ;;
    --name)
      app_name="${2:-}"
      shift 2
      ;;
    --bundle-id)
      bundle_id="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

if [ -z "$out_dir" ] || [ -z "$app_name" ]; then
  usage
  exit 2
fi

script_dir="$(cd "$(dirname "$0")" && pwd)"
skill_dir="$(cd "$script_dir/.." && pwd)"
template_dir="$skill_dir/templates"

executable_name="$app_name"
if [ -z "$bundle_id" ]; then
  safe_id="$(printf '%s' "$app_name" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]')"
  bundle_id="local.agent-sidebar.${safe_id:-app}"
fi

app_dir="$out_dir/$app_name.app"
macos_dir="$app_dir/Contents/MacOS"
resources_dir="$app_dir/Contents/Resources"

rm -rf "$app_dir"
mkdir -p "$macos_dir" "$resources_dir"

sed \
  -e "s/__APP_NAME__/$app_name/g" \
  -e "s/__EXECUTABLE_NAME__/$executable_name/g" \
  -e "s/__BUNDLE_ID__/$bundle_id/g" \
  "$template_dir/Info.plist" > "$app_dir/Contents/Info.plist"

sed \
  -e "s/__APP_NAME__/$app_name/g" \
  "$template_dir/main.m" > "$macos_dir/main.m"

cp "$template_dir/sidebar.html" "$resources_dir/sidebar.html"

clang -framework Cocoa -framework WebKit \
  -o "$macos_dir/$executable_name" \
  "$macos_dir/main.m" \
  -arch arm64

printf '%s\n' "$app_dir"
