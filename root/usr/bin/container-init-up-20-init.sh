#!/command/with-contenv bash

config_dir=/config
cd "$config_dir" || exit 128

params=""
config_dir=/config
data_dir=/data
filters_file=$config_dir/filters

if [[ -n ${DUPLICACY_PASSWORD} ]]; then
    params=-e
fi

if [[ -n ${INIT_OPTIONS} ]]; then
    params="$params $INIT_OPTIONS"
fi

if [[ -n ${CHUNK_SIZE} ]]; then
    params="$params -chunk-size $CHUNK_SIZE"
fi

if [[ -n ${MAX_CHUNK_SIZE} ]]; then
    params="$params -max-chunk-size $MAX_CHUNK_SIZE"
fi

if [[ -n ${MIN_CHUNK_SIZE} ]]; then
    params="$params -min-chunk-size $MIN_CHUNK_SIZE"
fi

params="$params -pref-dir $config_dir -repository $data_dir $SNAPSHOT_ID $STORAGE_URL"

duplicacy $GLOBAL_OPTIONS init $params
exitcode=$?

if [ $exitcode -ne 0 ]; then
    exit $exitcode
fi

if [[ ! -f $filters_file ]] && [[ -n "${FILTER_PATTERNS}" ]]; then
    IFS=';'
    read -ra filters <<< "$FILTER_PATTERNS"
    for filter in "${filters[@]}"; do
        echo "$filter" >> $filters_file
    done
fi

exit 0
