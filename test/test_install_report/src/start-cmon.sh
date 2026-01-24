#!/bin/bash

mv "${WEEWX_HOME}"/archive/weewx-cmon.sdb "${WEEWX_HOME}"/archive/weewx.sdb
mv "${WEEWX_HOME}"/skins/weewx-wdc/skin-cmon.conf "${WEEWX_HOME}"/skins/weewx-wdc/skin.conf
cat /tmp/cmon-extensions.py >> "${WEEWX_HOME}"/bin/user/extensions.py

# start weewx
echo 'Starting weewx reports (CMON)'

# shellcheck source=/dev/null
. "${WEEWX_HOME}/weewx-venv/bin/activate" && weectl report run --config "${WEEWX_HOME}/weewx.conf"
cat /var/log/syslog | grep weewx