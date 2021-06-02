#!/bin/echo "This is a library, please source it from another script"

##
## bash_functions.sh
## Common functions for scripts used across the entire Ivy stack
##
## Source this script where necessary with `source /opt/ivy/bash_functions.sh`
##


# Prevent modules from being sourced directly
IVY="yes"

function get_ivy_tag() {
    # Allow override of Ivy tag for custom build customers

    local TAG_FILE=/opt/ivy/tag

    if [[ -f ${TAG_FILE} ]]; then
        cat ${TAG_FILE}
    else
        echo -n "ivy"
    fi
}

function set_ivy_tag() {
    local TAG_FILE='/opt/ivy/tag'
    local TAG="${1}"
    echo "${TAG}" > "${TAG_FILE}"
}

function get_cloud() {
    # Discover the current cloud platform. Very rudimentary, could fail eventually, but since 'compute' is
    # Google's trademark word for their service, it's not likely that AWS suddenly has this value.

    if [[ -f /var/lib/cloud_provider ]]; then
        cat /var/lib/cloud_provider
        return
    fi

    local META_TEST=$(curl --retry 3 --silent --fail http://169.254.169.254/)
    if echo "${META_TEST}" | grep "computeMetadata" 2>&1 > /dev/null; then
        echo "google"
        echo "google" > /var/lib/cloud_provider
    elif curl -H 'Metadata:true' --retry 3 --silent --fail 'http://169.254.169.254/metadata/instance/compute?api-version=2019-06-01' || false; then
        echo "azure"
        echo "azure" > /var/lib/cloud_provider
    else
        echo "aws"
        echo "aws" > /var/lib/cloud_provider
    fi
}

function get_default_interface() {
    echo $(ip route | sed -n 's/default via .* dev \(.\S*.\) .*$/\1/p')
}

function get_ip_from_interface() {
    local INTERFACE=$1

    echo $(ip -4 addr show dev ${INTERFACE} primary | grep inet | awk '{split($2,a,"/"); print a[1]}')
}

function set_hostname() {
    local HOST=$1

    local SYSENV=$(get_sysenv)
    local HOST_FULL="${HOST}.node.${SYSENV}.$(get_ivy_tag)"

    hostnamectl set-hostname ${HOST}

    DEFAULT_INTERFACE=$(get_default_interface)
    BIND_IP=$(get_ip_from_interface ${DEFAULT_INTERFACE})

    HOST_LINE="${BIND_IP} ${HOST_FULL} ${HOST}"
    if grep -q "${BIND_IP}" /etc/hosts; then
        sed -i "/${BIND_IP}/c\\${HOST_LINE}" /etc/hosts
    else
        echo "${HOST_LINE}" >> /etc/hosts
    fi

    # Restart rsyslog & datadog since hostname changed
    systemctl restart rsyslog
    systemctl restart datadog-agent
}

function get_ram_mb_by_percent() {
    local PERCENT=$1

    MB=$(grep MemTotal /proc/meminfo | awk "{printf(\"%.0f\", \$2 / 1024 * ${PERCENT})}")

    echo ${MB}
}

function get_capped_ram_mb_by_percent() {
    local PERCENT="${1}"
    local LIMIT="${2:-31744}"

    MB=$(get_ram_mb_by_percent ${PERCENT})

    if [ ${MB} -gt ${LIMIT} ]; then
        echo "${LIMIT}"
    else
        echo ${MB}
    fi
}

function set_datadog_key() {
    local DD_API_KEY="${1}"
    local DD_CONFIG_FILE="${2:-/etc/datadog-agent/datadog.yaml}"
    cat <<EOF > "${DD_CONFIG_FILE}"
api_key: ${DD_API_KEY}
bind_host: 0.0.0.0
EOF
    systemctl enable datadog-agent
    systemctl start datadog-agent
}

function set_newrelic_infra_key() {
    local NRIA_LICENSE_KEY="${1}"
    local NRIA_LICENSE_FILE="${2:-/etc/newrelic-infra.yml}"
    echo "license_key: ${NRIA_LICENSE_KEY}" > "${NRIA_LICENSE_FILE}"
    systemctl enable newrelic-infra
    systemctl start newrelic-infra
}

# Note: the function below requires get_tags function which
#       is only present in bash_lib/<cloud>.sh
function set_newrelic_statsd() {
    local NR_API_KEY="${1}"
    local NR_ACCOUNT_ID="${2}"
    local NR_EU_REGION="${3:-false}"
    local NR_STATSD_CFG="${4:-/etc/newrelic-infra/nri-statsd.toml}"
    local NR_INSIGHTS_DOMAIN='newrelic.com'
    local NR_METRICS_DOMAIN='newrelic.com'
    local HOSTNAME_VALUE="$(hostname -f)"

    if [ "${NR_EU_REGION}" == 'true' ]; then
        NR_INSIGHTS_DOMAIN='eu01.nr-data.net'
        NR_METRICS_DOMAIN="eu.${NR_METRICS_DOMAIN}"
    fi

    cat <<EOF > "${NR_STATSD_CFG}"
hostname = "${HOSTNAME_VALUE}"
default-tags = "hostname:${HOSTNAME_VALUE} $(get_tags)"
percent-threshold = [90, 95, 99]
backends='newrelic'
[newrelic]
flush-type = "metrics"
transport = "default"
address = "https://insights-collector.${NR_INSIGHTS_DOMAIN}/v1/accounts/${NR_ACCOUNT_ID}/events"
address-metrics = "https://metric-api.${NR_METRICS_DOMAIN}/metric/v1"
api-key = "${NR_API_KEY}"
EOF

    systemctl enable gostatsd
    systemctl start gostatsd
}

function set_prompt_color() {
    local COLOR=$1
    echo -n "${COLOR}" > /etc/sysconfig/console/color
}

case "$(get_cloud)" in
    aws)
        source $(dirname ${BASH_SOURCE})/bash_lib/aws.sh
        ;;
    azure)
        source $(dirname ${BASH_SOURCE})/bash_lib/azure.sh
        ;;
    *)
        echo 'ERROR: Unknown cloud provider, unable to proceed!'
        ;;
esac
