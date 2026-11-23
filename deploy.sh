#!/bin/bash
REPO_DIR="/www/wwwroot/npch-ops-hub-frontend"
WEB_ROOTS=(
  "/www/wwwroot/dev.processengine.de"
  "/www/wwwroot/dev.npch-nobleprog.com"
)
LOGFILE="/www/wwwroot/dev.npch-nobleprog.com/deploy_log.txt"

echo "[$(date)] === Frontend Deploy ===" >> $LOGFILE

if [ ! -d "$REPO_DIR/.git" ]; then
  git clone https://github.com/NPCH-dev/npch-ops-hub-frontend.git $REPO_DIR >> $LOGFILE 2>&1
fi

cd $REPO_DIR
git fetch origin main >> $LOGFILE 2>&1
git reset --hard origin/main >> $LOGFILE 2>&1

for WEB_ROOT in "${WEB_ROOTS[@]}"; do
  cp *.html $WEB_ROOT/ 2>/dev/null || true
  cp *.png $WEB_ROOT/ 2>/dev/null || true
  echo "[$(date)] Copied to $WEB_ROOT" >> $LOGFILE
done

echo "[$(date)] Frontend deployed — $(git rev-parse --short HEAD)" >> $LOGFILE
echo "[$(date)] === Done ===" >> $LOGFILE
