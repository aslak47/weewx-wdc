#!/bin/bash

# start weewx
echo 'Starting weewx reports (alternative layout)'
# shellcheck source=/dev/null
. "${WEEWX_HOME}/weewx-venv/bin/activate" && weectl report run --config "${WEEWX_HOME}/weewx.conf"