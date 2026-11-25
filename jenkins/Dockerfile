# Сборочный образ контроллера Jenkins с инструментарием Android и Flutter
FROM jenkins/jenkins:2.568.3-lts-jdk21

USER root

ARG ANDROID_PLATFORM=36
ARG BUILD_TOOLS=36.0.0
ARG NDK_VERSION=28.2.13676358
ARG CMDLINE_TOOLS=13114758
ARG FLUTTER_VERSION=3.47.5

ENV ANDROID_HOME=/opt/android-sdk \
    ANDROID_SDK_ROOT=/opt/android-sdk \
    FLUTTER_HOME=/opt/flutter \
    PATH=/opt/flutter/bin:/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools:$PATH

# 1. Системные пакеты
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      curl git unzip xz-utils zip lcov ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# 2. Android SDK: cmdline-tools, платформа, build-tools, NDK
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools \
 && curl -fsSL -o /tmp/cmdtools.zip \
      https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS}_latest.zip \
 && unzip -q /tmp/cmdtools.zip -d /tmp/cmd \
 && mv /tmp/cmd/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest \
 && rm -rf /tmp/cmdtools.zip /tmp/cmd \
 && yes | sdkmanager --licenses > /dev/null \
 && sdkmanager "platform-tools" \
               "platforms;android-${ANDROID_PLATFORM}" \
               "build-tools;${BUILD_TOOLS}" \
               "ndk;${NDK_VERSION}"

# 3. Flutter SDK фиксированной версии
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} \
      https://github.com/flutter/flutter.git ${FLUTTER_HOME} \
 && git config --system --add safe.directory ${FLUTTER_HOME} \
 && flutter config --no-analytics \
 && flutter precache --android \
 && chown -R jenkins:jenkins ${ANDROID_HOME} ${FLUTTER_HOME}

USER jenkins

# 4. Отключение мастера первичной настройки и путь к манифесту JCasC
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false" \
    CASC_JENKINS_CONFIG=/var/jenkins_conf/jenkins.yaml

# 5. Плагины Jenkins
COPY --chown=jenkins:jenkins plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt
