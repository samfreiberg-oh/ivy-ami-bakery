bash -x
source /opt/ivy/bash_functions.sh
OUT_FILE=$1

echo "PROVIDER_ID=$(get_cloud)://$(get_availability_zone)/$(get_instance_id)" > $OUT_FILE
