FROM --platform=linux/arm64 node:16.13.0-bullseye as builder

# Install build dependencies
RUN apt-get update && \
  apt-get install --no-install-recommends -y \
  libgtk2.0-0 \
  libgtk-3-0 \
  libnotify-dev \
  libgconf-2-4 \
  libgbm-dev \
  libnss3 \
  libxss1 \
  libasound2 \
  libxtst6 \
  xauth \
  xvfb \
  # clean up
  && rm -rf /var/lib/apt/lists/* \
  && apt-get clean

# build cypress binary
RUN git clone https://github.com/cypress-io/cypress.git --depth 1 --branch v9.3.1 \
  && cd /cypress \
  && yarn \ 
  && yarn binary-build --version 9.3.1

FROM --platform=linux/arm64 node:16-buster-slim

ENV TERM=xterm \
    NPM_CONFIG_LOGLEVEL=warn \
    QT_X11_NO_MITSHM=1 \
    _X11_NO_MITSHM=1 \
    _MITSHM=0 \
    CYPRESS_INSTALL_BINARY=0 \
    CYPRESS_CACHE_FOLDER=/root/.cache/Cypress

RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    libgtk2.0-0 \
    libgtk-3-0 \
    libnotify-dev \
    libgconf-2-4 \
    libgbm-dev \
    libnss3 \
    libxss1 \
    libasound2 \
    libxtst6 \
    xauth \
    xvfb \
    # clean up
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    # https://github.com/cypress-io/cypress/issues/4351#issuecomment-559489091
    echo 'pcm.!default {\n type hw\n card 0\n}\n\nctl.!default {\n type hw\n card 0\n}' > /root/.asoundrc

# Copy cypress binary from intermediate container
COPY --from=builder /tmp/cypress-build/linux/build/linux-arm64-unpacked /root/.cache/Cypress/9.3.1/Cypress

RUN npm install -g cypress@9.3.1 && \ 
    cypress verify

ENTRYPOINT ["cypress", "run"]