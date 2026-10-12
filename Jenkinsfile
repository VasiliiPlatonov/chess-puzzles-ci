// =====================================================================
// Конвейер CI/CD мобильного приложения «Шахматные задачи» (Flutter, Android).
// Этапы: окружение -> зависимости -> анализ кода -> тесты -> сборка APK
//        -> публикация артефакта -> (необязательно) отправка в Telegram.
// =====================================================================
pipeline {
    agent any

    options {
        timestamps()                                    // время в журнале сборки
        timeout(time: 40, unit: 'MINUTES')              // защита от зависших сборок
        disableConcurrentBuilds()                       // одна сборка за раз
        buildDiscarder(logRotator(numToKeepStr: '10',   // хранить 10 последних сборок
                                  artifactNumToKeepStr: '5'))
    }

    triggers {
        // Каждые ~5 минут проверять репозиторий и запускать сборку при новых коммитах.
        pollSCM('H/5 * * * *')
    }

    environment {
        APK_NAME = "chess-puzzles-${env.BUILD_NUMBER}.apk"
    }

    stages {
        stage('Окружение') {
            steps {
                sh 'flutter --version'
                sh 'flutter doctor -v'
            }
        }

        stage('Зависимости') {
            steps {
                sh 'flutter pub get'
            }
        }

        stage('Анализ кода') {
            steps {
                // Предупреждения и ошибки останавливают конвейер,
                // информационные замечания — нет.
                sh 'flutter analyze --no-fatal-infos'
            }
        }

        stage('Тесты') {
            steps {
                sh 'flutter test --coverage'
            }
            post {
                always {
                    archiveArtifacts artifacts: 'coverage/lcov.info', allowEmptyArchive: true
                }
            }
        }

        stage('Сборка APK') {
            steps {
                // Номер сборки Jenkins становится versionCode приложения.
                sh 'flutter build apk --release --build-number=$BUILD_NUMBER'
                sh '''
                    rm -rf dist
                    mkdir dist
                    cp build/app/outputs/flutter-apk/app-release.apk "dist/$APK_NAME"
                '''
            }
        }

        stage('Публикация артефакта') {
            steps {
                archiveArtifacts artifacts: 'dist/*.apk', fingerprint: true
            }
        }

        stage('Отправка в Telegram') {
            // Этап выполняется, только если задан TELEGRAM_CHAT_ID (см. файл .env).
            when {
                expression { return env.TELEGRAM_CHAT_ID != null && env.TELEGRAM_CHAT_ID.trim() != '' }
            }
            steps {
                withCredentials([string(credentialsId: 'telegram-bot-token', variable: 'TG_TOKEN')]) {
                    sh '''
                        curl -sS -f --max-time 120 \
                             -F chat_id="$TELEGRAM_CHAT_ID" \
                             -F document=@"dist/$APK_NAME" \
                             -F caption="Шахматные задачи: сборка #$BUILD_NUMBER готова к тестированию" \
                             "https://api.telegram.org/bot$TG_TOKEN/sendDocument" > /dev/null
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "Сборка #${env.BUILD_NUMBER} прошла успешно. APK: ${env.APK_NAME}"
        }
        failure {
            echo 'Сборка завершилась с ошибкой. Откройте журнал этапа, на котором произошёл сбой.'
        }
    }
}
