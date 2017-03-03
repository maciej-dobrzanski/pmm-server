#!/bin/bash

set -e

# Prometheus
if [[ ! "${METRICS_RESOLUTION:-1s}" =~ ^[1-5]s$ ]]; then
    echo "METRICS_RESOLUTION takes only values from 1s to 5s."
    exit 1
fi
sed -i "s/1s/${METRICS_RESOLUTION:-1s}/" /etc/prometheus.yml
sed -i "s/ENV_METRICS_RETENTION/${METRICS_RETENTION:-720h}/" /etc/supervisord.d/pmm.ini
sed -i "s/ENV_METRICS_MEMORY/${METRICS_MEMORY:-262144}/" /etc/supervisord.d/pmm.ini

# Orchestrator
sed -i "s/orc_client_user/${ORCHESTRATOR_USER:-orc_client_user}/" /etc/orchestrator.conf.json
sed -i "s/orc_client_password/${ORCHESTRATOR_PASSWORD:-orc_client_password}/" /etc/orchestrator.conf.json

# Cron
sed -i "s/^INTERVAL=.*/INTERVAL=${QUERIES_RETENTION:-8}/" /etc/cron.daily/purge-qan-data

# HTTP basic auth
if [ -n "$SERVER_PASSWORD" ]; then
	cat > /opt/pmm-manage.yml <<-EOF
		configuration:
		  skip-prometheus-reload: "true"
		users:
		- username: ${SERVER_USER:-pmm}
		  password: ${SERVER_PASSWORD}
	EOF
	pmm-configure --config /opt/pmm-manage.yml -ssh-key-owner pmm -grafana-db-path /var/lib/grafana/grafana.db
fi

# Start supervisor in foreground
exec supervisord -n -c /etc/supervisord.conf
