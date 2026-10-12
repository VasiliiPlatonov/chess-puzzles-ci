# =====================================================================
# Образ Jenkins для сборки Flutter-приложения под Android.
# Основа — официальный образ Jenkins LTS с Java 21.
# Поверх него устанавливаются Android SDK, Flutter SDK и плагины Jenkins.
# =====================================================================
FROM jenkins/jenkins:2.568.3-lts-jdk21

# Установка системных пакетов требует прав root.
USER root

# ---------------------------------------------------------------------
# 1. Системные утилиты, которые нужны Flutter
# ---------------------------------------------------------------------
# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl git unzip xz-utils zip libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------
# 2. Android SDK: command-line tools и нужные пакеты
# ---------------------------------------------------------------------
ARG ANDROID_CMDLINE_TOOLS_VERSION=15859902
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH="${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools"

RUN mkdir -p "${ANDROID_HOME}/cmdline-tools" \
    && curl -fsSL -o /tmp/cmdline-tools.zip \
        "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_VERSION}_latest.zip" \
    && unzip -q /tmp/cmdline-tools.zip -d "${ANDROID_HOME}/cmdline-tools" \
    && mv "${ANDROID_HOME}/cmdline-tools/cmdline-tools" "${ANDROID_HOME}/cmdline-tools/latest" \
    && rm /tmp/cmdline-tools.zip

# Принимаем лицензии Android SDK и ставим платформу, build-tools и NDK.
# Версии соответствуют требованиям Flutter 3.47 (compileSdk 36, NDK 28.2).
# hadolint ignore=DL4006
RUN yes | sdkmanager --licenses > /dev/null \
    && sdkmanager \
        "platform-tools" \
        "platforms;android-36" \
        "build-tools;36.0.0" \
        "ndk;28.2.13676358"

# ---------------------------------------------------------------------
# 3. Flutter SDK (официальный архив стабильной версии)
# ---------------------------------------------------------------------
ARG FLUTTER_VERSION=3.47.5
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${PATH}:${FLUTTER_HOME}/bin"

RUN curl -fsSL -o /tmp/flutter.tar.xz \
        "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    && tar -xf /tmp/flutter.tar.xz -C /opt \
    && rm /tmp/flutter.tar.xz \
    && chown -R jenkins:jenkins "${FLUTTER_HOME}" "${ANDROID_HOME}"

# Дальше всё выполняется от имени непривилегированного пользователя jenkins.
USER jenkins

# Заранее скачиваем движок Flutter для Android, чтобы первая сборка была быстрее.
RUN flutter --version \
    && flutter precache --android

# ---------------------------------------------------------------------
# 4. Плагины Jenkins
# ---------------------------------------------------------------------
COPY --chown=jenkins:jenkins plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# ---------------------------------------------------------------------
# 5. Конфигурация Jenkins как код (JCasC)
# ---------------------------------------------------------------------
COPY --chown=jenkins:jenkins casc/ /usr/share/jenkins/casc/
ENV CASC_JENKINS_CONFIG=/usr/share/jenkins/casc/jenkins.yaml

# Отключаем мастер первоначальной настройки: всё настроит JCasC.
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false -Duser.timezone=Europe/Moscow"
