#!/bin/bash
# NPCH Backend Deploy Script
# Erstellt einen neuen npch-bN Container und stoppt/löscht den alten.
#
# Verwendung: ./deploy-backend.sh
# Voraussetzung: Ausführung auf dem Server hpde-serv1 als root/docker-User
#
# Was dieses Script macht:
#   1. Aktuelles Image von GHCR pullen (ghcr.io/npch-dev/npch-ops-hub:backend)
#   2. Laufenden Backend-Container ermitteln (npch-bN)
#   3. Neuen Container npch-b(N+1) erstellen + starten
#   4. Health-Check (GET /api/v1/health) → bei Erfolg alten Container stoppen + löschen
#   5. Frontend CLAUDE.md + index.html auf neue Nummer aktualisieren (optional)

set -euo pipefail

GHCR_IMAGE="ghcr.io/npch-dev/npch-ops-hub:backend"
ENV_FILE="/root/npch-backend.env"
NETWORK="npch-net"
PORT="8000:8000"
HEALTH_URL="http://127.0.0.1:8000/api/v1/health"
MAX_WAIT=60   # Sekunden bis Health-Check

# ── Aktuellen Container ermitteln ──────────────────────────────────────────────
CURRENT=$(docker ps --filter "ancestor=${GHCR_IMAGE}" --format "{{.Names}}" | head -1)
if [ -z "$CURRENT" ]; then
  # Gestoppte Container mit dem Image suchen
  CURRENT=$(docker ps -a --filter "ancestor=${GHCR_IMAGE}" --format "{{.Names}}" | head -1)
fi

# Nächste Nummer bestimmen
if [[ "$CURRENT" =~ npch-b([0-9]+) ]]; then
  NEXT_NUM=$(( ${BASH_REMATCH[1]} + 1 ))
else
  NEXT_NUM=1
fi
NEW_NAME="npch-b${NEXT_NUM}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " NPCH Backend Deploy"
echo " Alter Container : ${CURRENT:-keine}"
echo " Neuer Container : $NEW_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Image pullen ───────────────────────────────────────────────────────────────
echo "[1/4] Image pullen..."
docker pull "$GHCR_IMAGE"

# ── Neuen Container starten ────────────────────────────────────────────────────
echo "[2/4] Starte $NEW_NAME ..."
STARTED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
docker run -d \
  --name "$NEW_NAME" \
  --network "$NETWORK" \
  --env-file "$ENV_FILE" \
  -e "CONTAINER_NAME=$NEW_NAME" \
  -e "CONTAINER_IMAGE=$GHCR_IMAGE" \
  -e "CONTAINER_STARTED=$STARTED_AT" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -p $PORT \
  --restart unless-stopped \
  "$GHCR_IMAGE"

# ── Health-Check ───────────────────────────────────────────────────────────────
echo "[3/4] Health-Check ($HEALTH_URL) ..."
ELAPSED=0
until curl -sf "$HEALTH_URL" > /dev/null 2>&1; do
  sleep 2
  ELAPSED=$(( ELAPSED + 2 ))
  if [ $ELAPSED -ge $MAX_WAIT ]; then
    echo "✗ Health-Check fehlgeschlagen nach ${MAX_WAIT}s — rollback!"
    docker logs "$NEW_NAME" --tail 30
    docker stop "$NEW_NAME" && docker rm "$NEW_NAME"
    exit 1
  fi
  echo "  warte... (${ELAPSED}s)"
done
echo "✓ Health-Check OK"

# ── Alten Container stoppen + löschen ─────────────────────────────────────────
if [ -n "$CURRENT" ]; then
  echo "[4/4] Stoppe + lösche alten Container $CURRENT ..."
  docker stop "$CURRENT" || true
  docker rm   "$CURRENT" || true
  echo "✓ $CURRENT entfernt"
else
  echo "[4/4] Kein alter Container vorhanden — fertig."
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " ✓ Deploy abgeschlossen: $NEW_NAME läuft"
echo " API: https://api.processengine.de/api/v1/health"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Nächste Schritte:"
echo "  • CLAUDE.md + index.html auf $NEW_NAME aktualisieren"
echo "  • git commit + push auf main"
