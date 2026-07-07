#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
用法:
  ./scripts/build_multi.sh -p <platforms> [options]

参数:
  -p, --platforms   平台列表(逗号分隔)，支持:
                    android-apk,android-aab,ios,macos,linux,windows,web
  -m, --mode        构建模式: release | profile | debug (默认: release)
  -o, --output-dir  构建产物输出目录(可选，默认不拷贝)
  -s, --serial      串行执行(默认并行)
      --skip-pub-get   跳过 flutter pub get
      --no-codesign    iOS/macOS 构建时添加 --no-codesign
  -h, --help        显示帮助

示例:
  ./scripts/build_multi.sh -p android-apk,ios
  ./scripts/build_multi.sh -p android-aab,web,macos --no-codesign
  ./scripts/build_multi.sh -p android-apk,windows -s
  ./scripts/build_multi.sh -p android-apk,ios -o dist
EOF
}

MODE="release"
PLATFORMS_RAW=""
OUTPUT_DIR=""
SERIAL=false
SKIP_PUB_GET=false
NO_CODESIGN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--platforms)
      PLATFORMS_RAW="${2:-}"
      shift 2
      ;;
    -m|--mode)
      MODE="${2:-}"
      shift 2
      ;;
    -o|--output-dir)
      OUTPUT_DIR="${2:-}"
      shift 2
      ;;
    -s|--serial)
      SERIAL=true
      shift
      ;;
    --skip-pub-get)
      SKIP_PUB_GET=true
      shift
      ;;
    --no-codesign)
      NO_CODESIGN=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "未知参数: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "${PLATFORMS_RAW}" ]]; then
  echo "必须通过 -p/--platforms 指定至少一个平台" >&2
  usage
  exit 1
fi

if [[ "${MODE}" != "release" && "${MODE}" != "profile" && "${MODE}" != "debug" ]]; then
  echo "无效 mode: ${MODE} (支持: release/profile/debug)" >&2
  exit 1
fi

IFS=',' read -r -a PLATFORMS <<< "${PLATFORMS_RAW}"

if [[ ${#PLATFORMS[@]} -eq 0 ]]; then
  echo "平台列表为空" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

LOG_DIR="${ROOT_DIR}/build_logs/$(date +%Y%m%d_%H%M%S)"
mkdir -p "${LOG_DIR}"

if [[ -n "${OUTPUT_DIR}" ]]; then
  if [[ "${OUTPUT_DIR}" = /* ]]; then
    OUTPUT_DIR_ABS="${OUTPUT_DIR}"
  else
    OUTPUT_DIR_ABS="${ROOT_DIR}/${OUTPUT_DIR}"
  fi
  mkdir -p "${OUTPUT_DIR_ABS}"
else
  OUTPUT_DIR_ABS=""
fi

if ! ${SKIP_PUB_GET}; then
  echo "[INFO] 运行 flutter pub get..."
  flutter pub get
fi

build_command_for() {
  local platform="$1"
  local cmd=""
  case "${platform}" in
    android-apk)
      cmd="flutter build apk --${MODE}"
      ;;
    android-aab)
      cmd="flutter build appbundle --${MODE}"
      ;;
    ios)
      cmd="flutter build ipa --${MODE}"
      if ${NO_CODESIGN}; then
        cmd="${cmd} --no-codesign"
      fi
      ;;
    macos)
      cmd="flutter build macos --${MODE}"
      if ${NO_CODESIGN}; then
        cmd="${cmd} --no-codesign"
      fi
      ;;
    linux)
      cmd="flutter build linux --${MODE}"
      ;;
    windows)
      cmd="flutter build windows --${MODE}"
      ;;
    web)
      cmd="flutter build web --${MODE}"
      ;;
    *)
      echo ""
      return 1
      ;;
  esac
  echo "${cmd}"
}

run_one() {
  local platform="$1"
  local cmd="$2"
  local log_file="${LOG_DIR}/${platform}.log"

  echo "[START] ${platform}: ${cmd}"
  if bash -lc "${cmd}" >"${log_file}" 2>&1; then
    if [[ -n "${OUTPUT_DIR_ABS}" ]]; then
      copy_artifacts "${platform}" "${OUTPUT_DIR_ABS}" >>"${log_file}" 2>&1 || {
        echo "[FAIL]  ${platform} (产物拷贝失败，日志: ${log_file})" >&2
        return 1
      }
    fi
    echo "[OK]    ${platform}"
    return 0
  else
    echo "[FAIL]  ${platform} (日志: ${log_file})" >&2
    return 1
  fi
}

copy_artifacts() {
  local platform="$1"
  local out_root="$2"
  local platform_dir="${out_root}/${platform}"
  mkdir -p "${platform_dir}"

  case "${platform}" in
    android-apk)
      cp -f "${ROOT_DIR}/build/app/outputs/flutter-apk/app-${MODE}.apk" "${platform_dir}/"
      ;;
    android-aab)
      cp -f "${ROOT_DIR}/build/app/outputs/bundle/${MODE}/app-${MODE}.aab" "${platform_dir}/"
      ;;
    ios)
      cp -f "${ROOT_DIR}/build/ios/ipa/"*.ipa "${platform_dir}/"
      ;;
    macos)
      cp -R "${ROOT_DIR}/build/macos/Build/Products/${MODE^}/"*.app "${platform_dir}/"
      ;;
    linux)
      cp -R "${ROOT_DIR}/build/linux/x64/${MODE}/bundle" "${platform_dir}/"
      ;;
    windows)
      cp -R "${ROOT_DIR}/build/windows/x64/runner/${MODE^}" "${platform_dir}/"
      ;;
    web)
      cp -R "${ROOT_DIR}/build/web" "${platform_dir}/"
      ;;
    *)
      return 1
      ;;
  esac
}

PIDS=()
FAILED=0

if ${SERIAL}; then
  for platform in "${PLATFORMS[@]}"; do
    platform="${platform// /}"
    cmd="$(build_command_for "${platform}" || true)"
    if [[ -z "${cmd}" ]]; then
      echo "[ERROR] 不支持的平台: ${platform}" >&2
      FAILED=1
      continue
    fi
    run_one "${platform}" "${cmd}" || FAILED=1
  done
else
  for platform in "${PLATFORMS[@]}"; do
    platform="${platform// /}"
    cmd="$(build_command_for "${platform}" || true)"
    if [[ -z "${cmd}" ]]; then
      echo "[ERROR] 不支持的平台: ${platform}" >&2
      FAILED=1
      continue
    fi
    (
      run_one "${platform}" "${cmd}"
    ) &
    PIDS+=("$!")
  done

  for pid in "${PIDS[@]}"; do
    if ! wait "${pid}"; then
      FAILED=1
    fi
  done
fi

echo "[INFO] 日志目录: ${LOG_DIR}"
if [[ -n "${OUTPUT_DIR_ABS}" ]]; then
  echo "[INFO] 产物目录: ${OUTPUT_DIR_ABS}"
fi

if [[ ${FAILED} -ne 0 ]]; then
  echo "[DONE] 构建完成，但存在失败项。" >&2
  exit 1
fi

echo "[DONE] 全部构建成功。"
