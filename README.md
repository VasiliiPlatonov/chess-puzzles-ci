# CI/CD для мобильного приложения «Шахматные задачи»

Курсовая работа по дисциплине «Настройка и администрирование сервисного программного обеспечения».

Репозиторий содержит:

- **Flutter-приложение** «Шахматные задачи» (Android) с модульными и виджет-тестами;
- **сервер Jenkins в Docker** с установленными Flutter SDK и Android SDK;
- **конвейер CI/CD** (`Jenkinsfile`): анализ кода → тесты → сборка APK → публикация артефакта → отправка в Telegram (по желанию).

## Структура

```
chess-puzzles-ci/
├── Jenkinsfile               # описание конвейера CI/CD
├── docker-compose.yml        # запуск сервера Jenkins
├── .env.example              # образец настроек (пароль, адрес репозитория)
├── jenkins/
│   ├── Dockerfile            # образ Jenkins + Flutter SDK + Android SDK
│   ├── plugins.txt           # список плагинов Jenkins
│   └── casc/jenkins.yaml     # настройка Jenkins как код (JCasC)
├── lib/                      # исходный код приложения
├── test/                     # тесты
├── android/                  # Android-часть проекта
└── pubspec.yaml              # описание Flutter-проекта
```

## Что нужно установить

- **Docker Desktop** (Windows/macOS) или Docker Engine + Compose (Linux).
  В Windows Docker Desktop работает поверх WSL 2.
- **Git**.
- Ресурсы: 8 ГБ ОЗУ (лучше 16), ~25 ГБ свободного места на диске.

Flutter и Android Studio на компьютер ставить **не нужно**: всё уже есть внутри контейнера.

## Запуск за 5 шагов

**1. Загрузите проект на GitHub.** Создайте на GitHub **публичный** репозиторий `chess-puzzles-ci` (без README), затем в папке проекта выполните:

```bash
git init
git add .
git commit -m "Первая версия: приложение и конвейер CI/CD"
git branch -M main
git remote add origin https://github.com/ВАШ_ЛОГИН/chess-puzzles-ci.git
git push -u origin main
```

**2. Создайте файл настроек.** Скопируйте `.env.example` в `.env` и впишите свой пароль и адрес репозитория:

```bash
# Windows (PowerShell)
Copy-Item .env.example .env
# Linux / macOS
cp .env.example .env
```

**3. Соберите образ и запустите Jenkins:**

```bash
docker compose up -d --build
```

Первая сборка образа занимает 10–20 минут: скачиваются Android SDK (~2 ГБ) и Flutter SDK (~1 ГБ).
Следить за запуском: `docker compose logs -f jenkins` (выход — Ctrl+C).

**4. Откройте Jenkins:** http://localhost:8080 — войдите под логином и паролем из `.env`.
Задание **«Шахматные задачи (Android)»** уже создано автоматически.

**5. Запустите сборку:** откройте задание → **«Собрать сейчас»** (Build Now).
Первый прогон идёт дольше (~10 минут): Gradle скачивает зависимости. Следующие — 2–4 минуты.
После успешной сборки APK появится в разделе **«Артефакты»** сборки.

Дальше Jenkins сам проверяет репозиторий каждые 5 минут и запускает конвейер после каждого `git push`.

## Скриншоты для пояснительной записки

В тексте курсовой отмечены места для рисунков. Снимите:

1. Главную страницу Jenkins с заданием «Шахматные задачи (Android)».
2. Успешный прогон конвейера — вкладка **Pipeline Overview** (граф этапов, все зелёные).
3. Страницу сборки с артефактом `chess-puzzles-N.apk`.
4. Упавший конвейер (см. ниже, как это сделать).
5. Приложение на телефоне или в эмуляторе (экран списка задач и экран с доской).

### Как показать, что CI ловит ошибки

1. В файле `lib/logic/puzzle_session.dart` в методе `tryMove` замените `_mistakes++;` на `_mistakes += 2;`.
2. Сделайте `git commit` и `git push`.
3. Через несколько минут Jenkins запустит сборку, и она упадёт на этапе **«Тесты»**: тест ожидает 1 ошибку, а получает 2. APK при этом не собирается.
4. Сделайте скриншот, верните строку обратно и снова отправьте изменения — сборка станет зелёной.

## Отправка APK в Telegram (необязательно)

1. Создайте бота через [@BotFather](https://t.me/BotFather) и скопируйте токен.
2. Напишите боту любое сообщение, затем откройте `https://api.telegram.org/bot<ТОКЕН>/getUpdates` и найдите `"chat":{"id":...}`.
3. Впишите `TELEGRAM_BOT_TOKEN` и `TELEGRAM_CHAT_ID` в `.env` и перезапустите Jenkins: `docker compose up -d`.

После этого каждая успешная сборка будет присылать APK в Telegram.

## Администрирование

| Задача | Команда |
|---|---|
| Состояние контейнера | `docker compose ps` |
| Журнал Jenkins | `docker compose logs -f jenkins` |
| Перезапуск | `docker compose restart jenkins` |
| Остановка (данные сохраняются) | `docker compose down` |
| Занятое место | `docker system df -v` |
| Обновление Jenkins/Flutter | поменять версию в `jenkins/Dockerfile` → `docker compose up -d --build` |

**Резервная копия** (PowerShell, из папки проекта; кэши Gradle и сборок не копируются):

```powershell
docker run --rm -v chess-puzzles-jenkins-home:/data -v ${PWD}:/backup alpine `
  tar czf /backup/jenkins_backup.tar.gz --exclude=./.gradle --exclude=./.pub-cache --exclude=./workspace -C /data .
```

**Восстановление:**

```powershell
docker compose down
docker run --rm -v chess-puzzles-jenkins-home:/data -v ${PWD}:/backup alpine `
  sh -c "rm -rf /data/* && tar xzf /backup/jenkins_backup.tar.gz -C /data"
docker compose up -d
```

## Если что-то не работает

| Проблема | Решение |
|---|---|
| `env file .env not found` | Не создан файл `.env` (шаг 2). |
| Не пускает в Jenkins | Проверьте логин и пароль в `.env`; после изменения выполните `docker compose up -d`. |
| Ошибка на этапе Checkout | Репозиторий должен быть публичным, а `REPO_URL` в `.env` — правильным. Ветка должна называться `main`. |
| Сборка APK падает с нехваткой памяти | В Docker Desktop → Settings → Resources выделите не меньше 6 ГБ памяти. |
| `exec format error` / `\r: command not found` | Файлы получили окончания строк CRLF. Выполните `git config --global core.autocrlf false`, заново склонируйте репозиторий. |

## Версии

| Компонент | Версия |
|---|---|
| Jenkins LTS | 2.568.3 (Java 21) |
| Flutter | 3.47.5 (stable) |
| Android SDK | platform 36, build-tools 36.0.0, NDK 28.2 |
| Android Gradle Plugin / Gradle | 9.1.0 / 9.3.1 |
