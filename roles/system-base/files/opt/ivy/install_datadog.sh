#!/bin/bash

if [[ -d /etc/datadog-agent ]]; then
    echo "Datadog agent installed already."
    exit
fi

DD_AGENT_MAJOR_VERSION=7 DD_INSTALL_ONLY=true bash -c "$(curl -L https://raw.githubusercontent.com/DataDog/datadog-agent/master/cmd/agent/install_script.sh)"
sed -i 's/# bind_host:.*/bind_host: 0\.0\.0\.0/' /etc/datadog-agent/datadog.yaml

cat <<EOF > /etc/datadog-agent/conf.d/network.d/conf.yaml.default
init_config:

instances:
  # Network check only supports one configured instance
  - collect_connection_state: true
    excluded_interfaces:
      - lo
      - lo0
      - docker0
    # Optionally completely ignore any network interface
    # matching the given regex:
    excluded_interface_re: docker.*
EOF
