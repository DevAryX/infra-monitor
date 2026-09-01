FROM ubuntu:22.04

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    coreutils \
    procps \
    util-linux \
    hostname \
    grep \
    sed \
    gawk \
    bc \
    iproute2 \
    ca-certificates \
    awscli \
    && rm -rf /var/lib/apt/lists/*

RUN command -v ip >/dev/null \
    && command -v aws >/dev/null \
    && command -v ps >/dev/null \
    && command -v top >/dev/null \
    && command -v df >/dev/null

COPY scripts/system_report.sh ./scripts/system_report.sh

RUN chmod +x ./scripts/system_report.sh \
    && mkdir -p /app/logs

ENV INFRA_MONITOR_HOME=/app
ENV INFRA_MONITOR_LOG_DIR=/app/logs
ENV INFRA_MONITOR_SYSTEM_LOG=/app/logs/system_report.log
ENV INFRA_MONITOR_ERROR_LOG=/app/logs/error.log

CMD ["./scripts/system_report.sh"]
