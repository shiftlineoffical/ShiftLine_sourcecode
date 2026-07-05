#!/usr/bin/env sh
set -e

log() {
  printf "%s\n" "$*"
}

URL=""
TARGET_DIR=""
RESTART_PATH=""

# ----------------------------
# 引数処理
# ----------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    --url)
      URL="$2"
      shift 2
      ;;
    --target-dir)
      TARGET_DIR="$2"
      shift 2
      ;;
    --restart-path)
      RESTART_PATH="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

# ----------------------------
# 必須チェック
# ----------------------------
if [ -z "$URL" ] || [ -z "$TARGET_DIR" ]; then
  log "Missing required arguments."
  exit 2
fi

if [ ! -d "$TARGET_DIR" ]; then
  log "TargetDir does not exist."
  exit 2
fi

log "ShiftLine updater starting..."
log "TargetDir: $TARGET_DIR"
log "Url: $URL"

sleep 1

# ----------------------------
# アプリ終了待ち
# ----------------------------
if [ -n "$RESTART_PATH" ]; then
  PROCESS_NAME=$(basename "$RESTART_PATH")
  PROCESS_NAME=${PROCESS_NAME%.*}

  log "Waiting for app to exit..."
  while pgrep -x "$PROCESS_NAME" >/dev/null 2>&1; do
    sleep 0.5
  done
fi

# ----------------------------
# 拡張子取得（?対策）
# ----------------------------
CLEAN_URL=${URL%%\?*}
EXT=${CLEAN_URL##*.}
if [ "$EXT" = "$CLEAN_URL" ] || [ -z "$EXT" ]; then
  EXT="zip"
fi

# ----------------------------
# 作業フォルダ
# ----------------------------
TMP_DIR="$TARGET_DIR/_update_tmp"
EXTRACT_DIR="$TMP_DIR/extracted"

rm -rf "$TMP_DIR"
mkdir -p "$EXTRACT_DIR"

PACKAGE_PATH="$TMP_DIR/update_package.$EXT"

# ----------------------------
# ダウンロード
# ----------------------------
log "Downloading update..."
if command -v curl >/dev/null 2>&1; then
  curl -L -o "$PACKAGE_PATH" "$URL"
elif command -v wget >/dev/null 2>&1; then
  wget -O "$PACKAGE_PATH" "$URL"
else
  log "curl or wget is required."
  exit 3
fi

# ----------------------------
# 展開
# ----------------------------
log "Extracting..."
case "$PACKAGE_PATH" in
  *.zip)
    if command -v unzip >/dev/null 2>&1; then
      unzip -o "$PACKAGE_PATH" -d "$EXTRACT_DIR"
    else
      log "unzip is required for zip files."
      exit 4
    fi
    ;;
  *)
    log "Unsupported format"
    exit 4
    ;;
esac

# ----------------------------
# 上書きコピー
# ----------------------------
log "Applying update..."
cp -r "$EXTRACT_DIR"/* "$TARGET_DIR"/

# ----------------------------
# クリーンアップ
# ----------------------------
log "Cleaning up..."
rm -rf "$TMP_DIR" >/dev/null 2>&1 || true

# ----------------------------
# 再起動
# ----------------------------
if [ -n "$RESTART_PATH" ]; then
  log "Restarting..."
  if [ -d "$RESTART_PATH" ] && echo "$RESTART_PATH" | grep -qi '\.app$'; then
    if command -v open >/dev/null 2>&1; then
      open -a "$RESTART_PATH"
    fi
  else
    nohup "$RESTART_PATH" >/dev/null 2>&1 &
  fi
fi

log "Update complete."