#!/usr/bin/env bash
# Build smith, install on a connected iPhone, launch, and stream logs in the terminal.
#
# Requirements:
#   - iPhone connected via USB (or paired Wi‑Fi)
#   - iPhone unlocked and "Trust This Computer" accepted
#   - Xcode installed (signing team already set in the project)
#
# Usage:
#   ./run-iphone.sh          # build + install + launch + stream logs
#   ./run-iphone.sh build    # build only
#   ./run-iphone.sh logs     # stream logs (app must be running)
#
# For device log streaming, macOS may ask for your password once:
#   sudo -v

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$ROOT/smith.xcodeproj"
SCHEME="smith"
BUNDLE_ID="smith.smith"
DERIVED="$ROOT/build"
APP="$DERIVED/Build/Products/Debug-iphoneos/smith.app"

# Override with: DEVICE_UDID=... ./run-iphone.sh
DEVICE_UDID="${DEVICE_UDID:-}"

log() { printf '\n▸ %s\n' "$*"; }
die() { printf '\n✗ %s\n' "$*" >&2; exit 1; }

detect_device() {
  if [[ -n "$DEVICE_UDID" ]]; then
    return 0
  fi

  # First connected physical iPhone from xcodebuild destinations
  DEVICE_UDID="$(
    xcodebuild -showdestinations -project "$PROJECT" -scheme "$SCHEME" 2>/dev/null \
      | grep 'platform:iOS, arch:arm64' | grep -v Simulator \
      | sed -n 's/.*id:\([^,]*\).*/\1/p' | head -1
  )"

  [[ -n "$DEVICE_UDID" ]] || die "No iPhone found. Plug in your phone, unlock it, then retry. Or set DEVICE_UDID=..."
  log "Using device UDID: $DEVICE_UDID"
}

build_app() {
  log "Building for device..."
  xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -destination "platform=iOS,id=$DEVICE_UDID" \
    -derivedDataPath "$DERIVED" \
    build
  [[ -d "$APP" ]] || die "Build succeeded but app not found at $APP"
  log "Build OK → $APP"
}

install_app() {
  log "Installing on iPhone..."
  xcrun devicectl device install app --device "$DEVICE_UDID" "$APP"
  log "Installed $BUNDLE_ID"
}

launch_app() {
  log "Launching on iPhone (keep the phone unlocked)..."
  xcrun devicectl device process launch \
    --terminate-existing \
    --device "$DEVICE_UDID" \
    "$BUNDLE_ID"
  log "Launched $BUNDLE_ID"
}

# Swift print() and Logger on iOS go to the device unified log, not stdout.
# Poll with `log collect` (requires sudo on macOS for attached devices).
stream_logs() {
  local archive="/tmp/smith-device-logs.logarchive"
  local seen="/tmp/smith-device-logs.seen.$$"
  touch "$seen"

  if ! sudo -n true 2>/dev/null; then
    log "Device logs need sudo. Run: sudo -v"
    sudo -v || die "sudo required to read iPhone logs in the terminal"
  fi

  log "Streaming logs (Ctrl+C to stop)..."
  log "Filter: process smith / subsystem com.smith / print messages"
  echo "────────────────────────────────────────"

  while true; do
    if sudo /usr/bin/log collect \
      --device-udid "$DEVICE_UDID" \
      --last 15s \
      --size 5m \
      --output "$archive" 2>/dev/null; then

      /usr/bin/log show "$archive" \
        --predicate 'process == "smith" OR subsystem == "com.smith" OR eventMessage CONTAINS[c] "if let" OR eventMessage CONTAINS[c] "guard let" OR eventMessage CONTAINS[c] "??"' \
        --style compact 2>/dev/null \
        | while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            if ! grep -qxF "$line" "$seen" 2>/dev/null; then
              printf '%s\n' "$line"
              printf '%s\n' "$line" >> "$seen"
            fi
          done
    fi
    sleep 2
  done
}

cmd="${1:-run}"

detect_device

case "$cmd" in
  build)
    build_app
    ;;
  install)
    build_app
    install_app
    ;;
  launch)
    launch_app
    ;;
  logs)
    stream_logs
    ;;
  run)
    build_app
    install_app
    launch_app
    stream_logs
    ;;
  *)
    die "Unknown command: $cmd (try: run | build | install | launch | logs)"
    ;;
esac
