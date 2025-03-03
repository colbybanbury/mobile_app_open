ARG BASE_DOCKER_IMAGE_TAG
FROM $BASE_DOCKER_IMAGE_TAG

RUN apt-get update >/dev/null && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends unzip

ARG SONAR_SCANNER_DIR=$HOME/.sonar

# Install sonar-scanner
# Check for newer version here: https://binaries.sonarsource.com/?prefix=Distribution/sonar-scanner-cli/
ENV SONAR_SCANNER_VERSION=4.8.0.2856
RUN curl --proto '=https' --create-dirs -sSLo $SONAR_SCANNER_DIR/sonar-scanner.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-$SONAR_SCANNER_VERSION-linux.zip
RUN unzip -qq -o $SONAR_SCANNER_DIR/sonar-scanner.zip -d $SONAR_SCANNER_DIR/
ENV PATH=$PATH:$SONAR_SCANNER_DIR/sonar-scanner-${SONAR_SCANNER_VERSION}-linux/bin
ENV SONAR_SCANNER_OPTS="-server"
RUN sonar-scanner --version

# Install build-wrapper-linux-x86
RUN curl --proto '=https' --create-dirs -sSLo $SONAR_SCANNER_DIR/build-wrapper-linux-x86.zip https://sonarcloud.io/static/cpp/build-wrapper-linux-x86.zip
RUN unzip -qq -o $SONAR_SCANNER_DIR/build-wrapper-linux-x86.zip -d $SONAR_SCANNER_DIR/
ENV PATH=$PATH:$SONAR_SCANNER_DIR/build-wrapper-linux-x86

RUN chmod -R 777 $SONAR_SCANNER_DIR

# Install Node.js and NPM for JS analysis
ENV NODE_ENV="production"
RUN curl --proto '=https' -fsSL https://deb.nodesource.com/setup_lts.x | bash -
RUN apt-get update && apt-get install -y --no-install-recommends nodejs && node -v
RUN npm install --ignore-scripts --location=global npm@8.13.2 && npm --version
