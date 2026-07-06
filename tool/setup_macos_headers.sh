#!/bin/sh
# Prepares libmpv headers for media_kit_video on macOS, then refreshes CocoaPods.
# Usage: ./tool/setup_macos_headers.sh

set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN_ROOT="${ROOT}/macos/Flutter/ephemeral/.symlinks/plugins/media_kit_video"
HEADERS_DIR="${PLUGIN_ROOT}/macos/Headers/mpv"
CACHE_DIR="${PLUGIN_ROOT}/common/darwin/.cache/headers"
MPV_VERSION="v0.36.0"
MPV_SHA256="29abc44f8ebee013bb2f9fe14d80b30db19b534c679056e4851ceadf5a5e8bf6"

cd "${ROOT}"
flutter pub get

if [ -f "${HEADERS_DIR}/client.h" ]; then
  echo "mpv headers already present."
else
  mkdir -p "${HEADERS_DIR}" "${CACHE_DIR}"
  ARCHIVE="${CACHE_DIR}/mpv-${MPV_VERSION}.tar.gz"

  if [ ! -f "${ARCHIVE}" ]; then
    echo "Downloading mpv ${MPV_VERSION} headers..."
    if ! curl -fsSL \
      "https://github.com/mpv-player/mpv/archive/refs/tags/${MPV_VERSION}.tar.gz" \
      -o "${ARCHIVE}.tmp"; then
      curl -fsSL \
        "https://ghfast.top/https://github.com/mpv-player/mpv/archive/refs/tags/${MPV_VERSION}.tar.gz" \
        -o "${ARCHIVE}.tmp"
    fi
    echo "${MPV_SHA256}  ${ARCHIVE}.tmp" | shasum -a 256 -c -
    mv "${ARCHIVE}.tmp" "${ARCHIVE}"
  fi

  tar -xzf "${ARCHIVE}" --strip-components 2 -C "${HEADERS_DIR}" \
    "mpv-${MPV_VERSION#v}/libmpv/client.h" \
    "mpv-${MPV_VERSION#v}/libmpv/render.h" \
    "mpv-${MPV_VERSION#v}/libmpv/render_gl.h" \
    "mpv-${MPV_VERSION#v}/libmpv/stream_cb.h"
  echo "mpv headers installed."
fi

cd "${ROOT}/macos"
PWD_FALLBACK="${ROOT}" pod install
echo "Done. Run: flutter run -d macos"
