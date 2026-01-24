#!/bin/bash

# start weewx
echo 'Starting weewx reports (Alternative layout with forecast)'

sed -i -z -e "s|debug = 0|debug = 1|g" "${WEEWX_HOME}"/weewx.conf
sed -i -z -e 's/skin = forecast\n        enable = false/skin = forecast\n        enable = true/g' "${WEEWX_HOME}"/weewx.conf
mv "${WEEWX_HOME}"/skins/weewx-wdc/skin-forecast.conf "${WEEWX_HOME}"/skins/weewx-wdc/skin.conf

mv "${WEEWX_HOME}"/archive/weewx-db-forecast.sdb "${WEEWX_HOME}"/archive/weewx.sdb
mv "${WEEWX_HOME}"/archive/db-forecast.sdb "${WEEWX_HOME}"/archive/forecast.sdb

# shellcheck source=/dev/null
. "${WEEWX_HOME}/weewx-venv/bin/activate" && weectl report run --config "${WEEWX_HOME}/weewx.conf"