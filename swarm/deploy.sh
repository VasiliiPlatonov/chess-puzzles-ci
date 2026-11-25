#!/usr/bin/env bash
# Развёртывание и обновление CI/CD-платформы в кластере Docker Swarm.
# Запуск на узле-менеджере из каталога swarm/: ./deploy.sh [версия_образа_jenkins]
# Образ собирается из ../jenkins/Dockerfile (общий для режимов Compose и Swarm).
set -euo pipefail
cd "$(dirname "$0")"

export JENKINS_TAG="${1:-2.568.3}"
export CASC_VERSION="$(sha1sum casc/jenkins.yaml | cut -c1-8)"
export NGINX_CONF_VERSION="$(sha1sum apk-repo/default.conf | cut -c1-8)"
REGISTRY="127.0.0.1:5000"
IMAGE="${REGISTRY}/chess-puzzles-jenkins:${JENKINS_TAG}"

echo ">> 1. Проверка роли узла"
docker info --format '{{.Swarm.ControlAvailable}}' | grep -q true \
  || { echo "Скрипт выполняется только на узле-менеджере"; exit 1; }

echo ">> 2. Проверка секретов"
for s in jenkins_admin_password telegram_bot_token telegram_chat_id; do
  docker secret inspect "$s" > /dev/null 2>&1 \
    || { echo "Не создан секрет $s"; exit 1; }
done

echo ">> 3. Реестр образов"
docker stack deploy -c registry-stack.yml registry
until curl -fs "http://${REGISTRY}/v2/" > /dev/null; do sleep 2; done

echo ">> 4. Сборка и публикация образа ${IMAGE}"
docker build --pull -t "${IMAGE}" ../jenkins
docker push "${IMAGE}"

echo ">> 5. Развёртывание стека ci"
docker stack deploy --prune -c ci-stack.yml ci

echo ">> 6. Состояние сервисов"
docker stack services ci
