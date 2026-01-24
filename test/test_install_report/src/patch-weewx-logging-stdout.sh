#!/bin/sh
set -eu

CONF_PATH="${1:-}"

if [ -z "$CONF_PATH" ] || [ ! -f "$CONF_PATH" ]; then
  echo "Usage: $0 /path/to/weewx.conf"
  exit 2
fi

CONF_PATH="$CONF_PATH" python3 - <<'PY'
import os
from configobj import ConfigObj

path = os.environ["CONF_PATH"]
cfg = ConfigObj(path, list_values=False)

cfg["Logging"] = {}
L = cfg["Logging"]
L["version"] = "1"
L["disable_existing_loggers"] = "False"

L["formatters"] = {
    "standard": {
        "format": "%(levelname)s %(name)s: %(message)s"
    }
}

L["handlers"] = {
    "console": {
        "class": "logging.StreamHandler",
        "level": "DEBUG",
        "formatter": "standard",
        "stream": "ext://sys.stdout"
    }
}

L["root"] = {
    "level": "DEBUG",
    "handlers": ["console"]
}

cfg.write()
print(f"Patched WeeWX logging to stdout in {path}")
PY