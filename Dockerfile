FROM python:3.13-alpine

# Git tag such as "v1.2.3"
# renovate: datasource=github-tags depName=furlongm/patchman
ARG PATCHMAN_VERSION="v3.0.10"

ENV APPDIR="/app"
ENV CELERY_REDIS_HOST="redis"
ENV CELERY_REDIS_PORT="6379"
ENV CELERY_LOG_LEVEL="INFO"
ENV GUNICORN_WORKERS="2"

LABEL org.opencontainers.image.authors="tigattack"
LABEL org.opencontainers.image.title="Patchman"
LABEL org.opencontainers.image.description="Alpine-based Patchman container image."
LABEL org.opencontainers.image.url="https://github.com/furlongm/patchman"
LABEL org.opencontainers.image.documentation="https://github.com/tigattack/Patchman-Docker/blob/main/README.md"
LABEL org.opencontainers.image.source="https://github.com/tigattack/Patchman-Docker"
LABEL org.opencontainers.image.version=$PATCHMAN_VERSION
LABEL org.opencontainers.image.created=$BUILD_DATE

COPY requirements.txt /requirements.txt

WORKDIR "$APPDIR"

RUN \
  # Required deps
  apk --no-cache add \
    curl \
    git \
    libmagic \
    libxslt-dev \
    mariadb-connector-c-dev &&\
  # Clone repo, checkout version, and enter directory
  git clone https://github.com/furlongm/patchman.git . && \
  git checkout tags/$PATCHMAN_VERSION -b execbranch &&\
  # Build deps
  apk add --no-cache --virtual .build-deps build-base &&\
  # Hacky temporary workaround to cython=3 & pyyaml=6 build failure
  # https://github.com/yaml/pyyaml/issues/724
  echo "cython<3" > /tmp/constraint.txt &&\
  # Py deps
  mv /requirements.txt "${APPDIR}/requirements-extra.txt" &&\
  PIP_CONSTRAINT=/tmp/constraint.txt pip install \
    --no-cache-dir \
    --no-warn-script-location \
    -r "${APPDIR}/requirements-extra.txt" \
    -r "${APPDIR}/requirements.txt" &&\
  # Install Patchman
  ${APPDIR}/setup.py install &&\
  # Remove build deps
  apk del --purge .build-deps

COPY configs/ /

EXPOSE 80
HEALTHCHECK \
  --interval=20s \
  --timeout=10s \
  --start-period=60s \
  --retries=5 \
  CMD [ "/healthcheck.sh" ]

ENTRYPOINT ["/entry.sh"]
