#!/data/data/com.termux/files/usr/bin/bash
# Holt neue Staende der Hauptseite von GitHub (main).
# Statische Seite: kein Build und kein Neustart noetig, Caddy liefert den Ordner direkt aus.
# Aufbau und Protokollzeilen wie bei den anderen Sync-Skripten.
set -u

PROJECT="$HOME/apps/website"
BRANCH="main"

RUNTIME="$HOME/website-runtime"
LOG="$RUNTIME/logs/github-sync.log"
LOCK="$RUNTIME/github-sync.lock"
STATE="$RUNTIME/github-sync-deployed.commit"

export PATH="/data/data/com.termux/files/usr/bin:$PATH"

mkdir -p "$RUNTIME/logs"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG"
}

# Sperre: nur ein Lauf gleichzeitig (atomar, mit Pruefung auf Altlast)
if ! ( set -o noclobber; echo $$ > "$LOCK" ) 2>/dev/null; then
  OLD="$(cat "$LOCK" 2>/dev/null || true)"
  if [ -n "$OLD" ] && kill -0 "$OLD" 2>/dev/null; then
    exit 0
  fi
  rm -f "$LOCK"
  if ! ( set -o noclobber; echo $$ > "$LOCK" ) 2>/dev/null; then
    exit 0
  fi
fi
trap 'rm -f "$LOCK"' EXIT

if [ ! -d "$PROJECT/.git" ]; then
  log "FEHLER: Projektordner fehlt: $PROJECT"
  exit 1
fi

cd "$PROJECT" || exit 1

if ! timeout 60 git fetch --quiet origin "$BRANCH" >> "$LOG" 2>&1; then
  log "FEHLER: git fetch fehlgeschlagen (kein Netz oder GitHub nicht erreichbar)."
  exit 1
fi

BEFORE="$(git rev-parse HEAD)"
REMOTE="$(git rev-parse "origin/$BRANCH")"
DEPLOYED="$(cat "$STATE" 2>/dev/null || true)"

if [ "$BEFORE" = "$REMOTE" ] && [ "$DEPLOYED" = "$REMOTE" ]; then
  log "AKTUELL: Deployter Stand entspricht GitHub."
  exit 0
fi

log "UPDATE: ${BEFORE:0:7} -> ${REMOTE:0:7}"

if ! git pull --ff-only --quiet origin "$BRANCH" >> "$LOG" 2>&1; then
  log "FEHLER: git pull --ff-only fehlgeschlagen (lokale Aenderungen im Ordner?)."
  exit 1
fi

AFTER="$(git rev-parse HEAD)"

if [ ! -f "$PROJECT/public/index.html" ]; then
  log "WARNUNG: public/index.html fehlt, die Seite zeigt moeglicherweise nichts an."
fi

echo "$AFTER" > "$STATE"
log "ERFOLG: Samsung nun auf $AFTER"
