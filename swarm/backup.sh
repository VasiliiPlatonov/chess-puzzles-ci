#!/usr/bin/env bash
# Горячее резервное копирование томов CI/CD-платформы на текущем узле.
# ci-manager:  ./backup.sh                 (ci_jenkins_home, ci_portainer_data)
# ci-worker-1: ./backup.sh ci_apk_data
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-/srv/backups/ci}"
KEEP_DAYS="${KEEP_DAYS:-14}"
STAMP="$(date +%Y%m%d_%H%M)"
VOLUMES="${*:-ci_jenkins_home ci_portainer_data}"
mkdir -p "$BACKUP_DIR"

for v in $VOLUMES; do
  docker volume inspect "$v" > /dev/null 2>&1 \
    || { echo "Том $v на этом узле отсутствует"; continue; }
  docker run --rm \
    -v "$v":/src:ro \
    -v "$BACKUP_DIR":/backup \
    alpine:3.20 \
    tar czf "/backup/${v}_${STAMP}.tar.gz" -C /src \
        --exclude=./workspace --exclude=./caches .
  echo "Создан архив ${v}_${STAMP}.tar.gz"
done

# ротация: удаление архивов старше KEEP_DAYS суток
find "$BACKUP_DIR" -name '*.tar.gz' -mtime +"$KEEP_DAYS" -delete
ls -lh "$BACKUP_DIR"
