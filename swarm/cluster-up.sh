#!/usr/bin/env bash
# Учебный кластер Docker Swarm из трёх узлов docker-in-docker на одном Linux-хосте.
# Требования: Docker Engine, пользователь в группе docker, ~8 ГБ ОЗУ, ~40 ГБ диска, интернет.
# Запуск из каталога swarm/ репозитория:  ./cluster-up.sh
set -euo pipefail
cd "$(dirname "$0")"
ROOT="$(cd .. && pwd)"   # корень репозитория монтируется в менеджер

NET=ci-nodes
IMG=docker:27-dind

echo ">> 1. Сеть узлов 192.168.56.0/24"
docker network inspect "$NET" > /dev/null 2>&1 \
  || docker network create --subnet 192.168.56.0/24 "$NET"

start_node() {   # имя, IP, доп. параметры docker run
  local name=$1 ip=$2; shift 2
  if docker inspect "$name" > /dev/null 2>&1; then
    docker start "$name" > /dev/null
  else
    docker run -d --privileged --name "$name" --hostname "$name" \
      --network "$NET" --ip "$ip" -e DOCKER_TLS_CERTDIR= \
      -v "$name-docker:/var/lib/docker" "$@" "$IMG" > /dev/null
  fi
}

echo ">> 2. Узлы ci-manager, ci-worker-1, ci-worker-2"
start_node ci-manager  192.168.56.10 -p 80:80 -v "$ROOT:/opt/ci"
start_node ci-worker-1 192.168.56.11
start_node ci-worker-2 192.168.56.12
for n in ci-manager ci-worker-1 ci-worker-2; do
  until docker exec "$n" docker info > /dev/null 2>&1; do sleep 2; done
done
docker exec ci-manager apk add --no-cache bash curl coreutils > /dev/null

echo ">> 3. Инициализация Swarm"
if [ "$(docker exec ci-manager docker info --format '{{.Swarm.LocalNodeState}}')" != "active" ]; then
  docker exec ci-manager docker swarm init --advertise-addr 192.168.56.10 > /dev/null
fi
TOKEN=$(docker exec ci-manager docker swarm join-token -q worker)
for w in ci-worker-1 ci-worker-2; do
  [ "$(docker exec "$w" docker info --format '{{.Swarm.LocalNodeState}}')" = "active" ] \
    || docker exec "$w" docker swarm join --token "$TOKEN" 192.168.56.10:2377 > /dev/null
done
docker exec ci-manager docker node update --label-add ci.jenkins=true ci-manager > /dev/null
docker exec ci-manager docker node update --label-add ci.storage=true ci-worker-1 > /dev/null

echo ">> 4. Секреты"
make_secret() {  # имя, подсказка
  if ! docker exec ci-manager docker secret inspect "$1" > /dev/null 2>&1; then
    read -r -s -p "$2: " val; echo
    printf '%s' "$val" | docker exec -i ci-manager docker secret create "$1" - > /dev/null
  fi
}
make_secret jenkins_admin_password "Пароль администратора Jenkins"
make_secret telegram_bot_token     "Токен Telegram-бота"
make_secret telegram_chat_id       "ID чата Telegram"

echo ">> 5. Развёртывание (сборка образа Jenkins займёт 20–60 минут)"
docker exec -w /opt/ci/swarm ci-manager bash ./deploy.sh

cat <<'EOF'

Готово. Добавьте в /etc/hosts строку (нужен sudo):
  127.0.0.1 jenkins.ci.local apk.ci.local portainer.ci.local traefik.ci.local
Jenkins поднимается 2–3 минуты: docker exec ci-manager docker service ps ci_jenkins
EOF
