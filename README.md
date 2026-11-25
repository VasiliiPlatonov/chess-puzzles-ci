# CI/CD для мобильного приложения «Шахматные задачи»

Курсовая работа по дисциплине «Настройка и администрирование сервисного программного обеспечения».
РТУ МИРЭА, Институт информационных технологий, кафедра ИиППО, 2026.

Студент: Платонов В. В., группа ИКБО-15-25. Руководитель: старший преподаватель Волков М. Ю.

## О проекте

Репозиторий содержит Android-приложение на Flutter с набором шахматных задач и контейнерную платформу CI/CD, которая проверяет, тестирует, собирает и публикует его APK.

Платформа разворачивается в двух режимах:

- **Docker Compose** — один контейнер Jenkins для локальной работы;
- **Docker Swarm** — кластер из трёх узлов (менеджер и два рабочих) со стеком из шести сервисов и восьми контейнеров.

Конфигурация Jenkins полностью описана кодом: сервер настраивает плагин Configuration as Code (JCasC), задание создаёт Job DSL, алгоритм сборки хранится в `Jenkinsfile`. Ручная настройка через веб-интерфейс не нужна.

## Состав кластера

| Сервис | Образ | Размещение | Назначение |
| :--- | :--- | :--- | :--- |
| `traefik` | `traefik:v3.1` | менеджер | Точка входа, маршрутизация по доменным именам `*.ci.local` |
| `jenkins` | `chess-puzzles-jenkins:2.568.3` | узел с меткой `ci.jenkins=true` | Сервер CI/CD со встроенными Android SDK и Flutter |
| `apk-repo` | `nginx:1.27-alpine` | узел с меткой `ci.storage=true` | Приём APK от Jenkins (WebDAV PUT) и раздача тестировщикам |
| `portainer` | `portainer/portainer-ce:lts` | менеджер | Веб-интерфейс управления кластером |
| `agent` | `portainer/agent:lts` | все узлы (global) | Агент Portainer |
| `registry` | `registry:2` | менеджер (отдельный стек) | Локальный реестр образов кластера |

Сервисы связаны двумя overlay-сетями: `ci_public` — веб-интерфейсы за Traefik и выход в Интернет, `ci_internal` (`internal: true`) — служебный трафик: загрузка APK в хранилище и связь Portainer с агентами. Пароли и токены передаются как Docker secrets и не хранятся ни в образе, ни в репозитории.

## Структура репозитория

```text
chess-puzzles-ci/
├── lib/                      # Исходный код приложения (Dart / Flutter)
├── test/                     # Модульные и виджет-тесты (20 тестов)
├── android/                  # Android-часть проекта (Gradle)
├── pubspec.yaml              # Зависимости приложения
├── Jenkinsfile               # Конвейер CI/CD (Pipeline as Code)
├── jenkins/
│   ├── Dockerfile            # Сборочный образ: Jenkins LTS + Android SDK 36 + NDK 28.2 + Flutter 3.47.5
│   ├── plugins.txt           # Плагины Jenkins
│   └── casc/jenkins.yaml     # JCasC для режима Compose (значения из .env)
├── docker-compose.yml        # Режим Compose
├── .env.example              # Шаблон переменных для режима Compose
└── swarm/                    # Режим Swarm
    ├── ci-stack.yml          # Стек ci: traefik, jenkins, apk-repo, portainer, agent
    ├── registry-stack.yml    # Стек registry
    ├── casc/jenkins.yaml     # JCasC для Swarm (значения из Docker secrets)
    ├── apk-repo/default.conf # Конфигурация Nginx для хранилища APK
    ├── deploy.sh             # Сборка образа, публикация в реестр, развёртывание стеков
    ├── backup.sh             # Резервное копирование томов
    ├── cluster-up.sh         # Учебный стенд на Linux
    └── cluster-up.ps1        # Учебный стенд на Windows
```

## Конвейер

Jenkins получает код ветки `main` и выполняет стадии:

1. **Окружение** — зеркала репозиториев Gradle, проверка `flutter doctor`.
2. **Зависимости** — `flutter pub get`.
3. **Анализ кода** — `flutter analyze --no-fatal-infos`.
4. **Тесты** — `flutter test --coverage`, отчёт `lcov.info` сохраняется всегда.
5. **Сборка APK** — релизная сборка, номер сборки Jenkins становится versionCode.
6. **Публикация артефакта** — архивация APK в Jenkins и загрузка в `apk-repo`.
7. **Отправка в Telegram** — выполняется, только если задан `TELEGRAM_CHAT_ID`.

Стадии 3 и 4 образуют барьер качества: при ошибке анализатора или упавшем тесте сборка завершается со статусом FAILURE, и APK не выпускается. Репозиторий опрашивается каждые пять минут.

## Развёртывание

Требования: Docker Engine 24+ (на Windows — Docker Desktop с WSL 2), около 8 ГБ оперативной памяти и 30 ГБ свободного места. Устанавливать Flutter, Android SDK или Java на хост не нужно.

### Режим Compose

```bash
git clone https://github.com/VasiliiPlatonov/chess-puzzles-ci.git
cd chess-puzzles-ci
cp .env.example .env        # задать JENKINS_ADMIN_PASSWORD, при необходимости TELEGRAM_*
docker compose up -d --build
```

Jenkins открывается по адресу http://localhost:8080, логин `admin`, пароль из `.env`. Задание «Шахматные задачи (Android)» создаётся автоматически.

### Режим Swarm: учебный стенд

Три узла кластера запускаются на одном компьютере как контейнеры `docker:27-dind` в сети `192.168.56.0/24`.

```powershell
# Windows, PowerShell
cd swarm
powershell -ExecutionPolicy Bypass -File .\cluster-up.ps1
```

```bash
# Linux
cd swarm && ./cluster-up.sh
```

Сценарий создаёт узлы, инициализирует Swarm, назначает метки узлов, запрашивает пароль Jenkins, токен Telegram-бота и ID чата (если Telegram не нужен, ввести `none`) и вызывает `deploy.sh`. Затем в файл `hosts` добавляется строка:

```text
127.0.0.1 jenkins.ci.local apk.ci.local portainer.ci.local traefik.ci.local
```

| Сервис | Адрес |
| :--- | :--- |
| Jenkins | http://jenkins.ci.local |
| Каталог APK | http://apk.ci.local/apk/ |
| Portainer | http://portainer.ci.local |
| Панель Traefik | http://traefik.ci.local |

### Режим Swarm: отдельные серверы

```bash
# на менеджере
docker swarm init --advertise-addr <IP менеджера>
# на рабочих узлах — команда join, которую выдал менеджер
docker node update --label-add ci.jenkins=true <менеджер>
docker node update --label-add ci.storage=true <рабочий узел>
printf '%s' '<пароль>'  | docker secret create jenkins_admin_password -
printf '%s' '<токен>'   | docker secret create telegram_bot_token -
printf '%s' '<id чата>' | docker secret create telegram_chat_id -
cd swarm && ./deploy.sh
```

Между узлами должны быть открыты порты 2377/tcp, 7946/tcp и udp, 4789/udp.

## Администрирование

| Задача | Команда (на менеджере, из каталога `swarm/`) |
| :--- | :--- |
| Состояние сервисов | `docker stack services ci` |
| Задачи Jenkins | `docker service ps ci_jenkins` |
| Журнал Jenkins | `docker service logs -f ci_jenkins` |
| Обновление Jenkins | `./deploy.sh <версия>` — скользящее обновление, при сбое проверки состояния автоматический откат |
| Резервная копия | `./backup.sh` на менеджере, `./backup.sh ci_apk_data` на узле хранилища |

Восстановление тома Jenkins из архива:

```bash
docker service scale ci_jenkins=0
docker run --rm -v ci_jenkins_home:/dst -v /srv/backups/ci:/backup alpine:3.20 \
  sh -c "find /dst -mindepth 1 -delete && tar xzf /backup/ci_jenkins_home_<дата>.tar.gz -C /dst"
docker service scale ci_jenkins=1
```

Конфигурация Jenkins и задание восстанавливаются из манифеста JCasC автоматически, поэтому после утраты менеджера достаточно заново создать кластер, секреты и метки, распаковать архивы томов и запустить `deploy.sh`.

## Технологии

| Компонент | Версия | Назначение |
| :--- | :--- | :--- |
| Docker Engine, Docker Swarm | 27 | Контейнеризация и оркестрация |
| Jenkins LTS | 2.568.3 (OpenJDK 21) | Сервер CI/CD |
| JCasC, Job DSL | — | Конфигурация Jenkins как код |
| Flutter SDK | 3.47.5 stable | Фреймворк приложения |
| Android SDK / NDK | API 36, Build-Tools 36.0.0 / 28.2 | Сборка APK |
| Traefik | v3.1 | Обратный прокси |
| Docker Registry | 2 | Реестр образов |
| Nginx | 1.27 | Хранилище APK |
| Portainer CE | lts | Управление кластером |
