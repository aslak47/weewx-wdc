#! /bin/sh
# file: test/test_install_report/install_report_test.sh

DIR=$(dirname -- "$( readlink -f -- "$0"; )")

CONTAINER_NAME="weewx"

cleanup_container() {
  # best-effort cleanup; never fail the test because of cleanup
  docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
}

oneTimeSetUp() {
  # Always start with a clean slate, in case last run was interrupted
  cleanup_container

  # Ensure cleanup happens on exit + Ctrl+C + termination
  trap cleanup_container EXIT INT TERM

  if ! [ -d "$DIR"/shunitexit ] ; then
    mkdir "$DIR"/shunitexit
  fi

  if ! [ -d "$DIR"/artifacts ] ; then
    echo Creating artifacts directory...
    sleep 2
    mkdir "$DIR"/artifacts
  fi

  for d in \
    artifacts-alternative-weewx-html \
    artifacts-classic-weewx-html \
    artifacts-forecast-weewx-html \
    artifacts-custom-weewx-html \
    artifacts-dwd-weewx-html \
    artifacts-custom-binding-weewx-html \
    artifacts-mqtt-weewx-html \
    artifacts-sensor-status-weewx-html \
    artifacts-cmon-weewx-html
  do
    if ! [ -d "$DIR/$d" ] ; then
      echo "Creating $d directory..."
      sleep 1
      mkdir "$DIR/$d"
    fi
  done
}

testBundling() {
  yarn run build > "$DIR"/artifacts/testBundling.txt 2>&1

  output=$(cat "$DIR"/artifacts/testBundling.txt)

  assertContains "$output" "main.js"
  assertContains "$output" "main.css"
  assertContains "$output" "service-worker.js"
  assertContains "$output" "compiled with"
  assertNotContains "$output" "fail"
  assertNotContains "$output" "error"
}

testInstall() {
  zip -qr "$DIR"/src/weewx-wdc.zip "./" \
    -x "*__pycache__*" -x "*.idea*" -x "*.venv*" -x "*.git*" -x "*node_modules*" \
    -x "*.vscode*" -x "*.parcel-cache*" -x "*.yarn*" -x ".eslintrc.json" \
    -x ".prettierignore" -x ".prettierrc.json" -x "package.json" -x "tsconfig.json" \
    -x "yarn.lock" -x ".yarnrc" -x "*test*" -x "*skins/weewx-wdc/src*"

  cd "$DIR" || exit

  docker build . -t "weewx" --no-cache > "$DIR"/artifacts/testInstall.txt 2>&1

  output=$(cat "$DIR"/artifacts/testInstall.txt)

  assertContains "$output" "/home/weewx-data/weewx-venv/bin/weectl extension install -y --config /home/weewx-data/weewx.conf /tmp/weewx-wdc/"
  assertContains "$output" "Finished installing extension weewx-wdc from /tmp/weewx-wdc/"
  assertNotContains "$output" "ERROR:"
}

testWeeReportRunAlternative() {
  cleanup_container
  docker run --name "$CONTAINER_NAME" weewx > "$DIR"/artifacts/testWeeReportRunAlternative.txt 2>&1 || true
  docker cp "$CONTAINER_NAME":/home/weewx-data/public_html/ "$DIR"/artifacts-alternative-weewx-html > "$DIR"/artifacts/docker.txt 2>&1 || true
  docker rm -f "$CONTAINER_NAME" > "$DIR"/artifacts/docker.txt 2>&1 || true

  output=$(cat "$DIR"/artifacts/testWeeReportRunAlternative.txt)

  assertContains "$output" "Starting weewx reports (alternative layout)"
  assertContains "$output" "Using configuration file [1m/home/weewx-data/weewx.conf[0m"
  assertContains "$output" "Generating as of last timestamp in the database."
  assertContains "$output" "INFO weewx.cheetahgenerator: Generated 32 files for report WdcReport in"
  assertContains "$output" "INFO weewx.reportengine: Copied 17 files to /home/weewx-data/public_html"

  assertNotContains "$output" "failed with exception"
  assertNotContains "$output" "Ignoring template"
  assertNotContains "$output" "Caught unrecoverable exception"
}

testWeeReportRunClassic() {
  cleanup_container
  docker run --entrypoint "/start-classic.sh" --name "$CONTAINER_NAME" weewx > "$DIR"/artifacts/testWeeReportRunClassic.txt 2>&1 || true
  docker cp "$CONTAINER_NAME":/home/weewx-data/public_html/ "$DIR"/artifacts-classic-weewx-html > "$DIR"/artifacts/docker.txt 2>&1 || true
  docker rm -f "$CONTAINER_NAME" > "$DIR"/artifacts/docker.txt 2>&1 || true

  output=$(cat "$DIR"/artifacts/testWeeReportRunClassic.txt)

  assertContains "$output" "Starting weewx reports (classic layout)"
  assertContains "$output" "Using configuration file [1m/home/weewx-data/weewx.conf[0m"
  assertContains "$output" "Generating as of last timestamp in the database."
  assertContains "$output" "INFO weewx.cheetahgenerator: Generated 32 files for report WdcReport in"
  assertContains "$output" "INFO weewx.reportengine: Copied 17 files to /home/weewx-data/public_html"

  assertNotContains "$output" "failed with exception"
  assertNotContains "$output" "Ignoring template"
  assertNotContains "$output" "Caught unrecoverable exception"
}

testWeeReportRunForecast() {
  cleanup_container
  docker run \
    --entrypoint "/start-forecast.sh" \
    --name "$CONTAINER_NAME" weewx > "$DIR"/artifacts/testWeeReportRunForecast.txt 2>&1 || true

  docker cp "$CONTAINER_NAME":/home/weewx-data/public_html/ "$DIR"/artifacts-forecast-weewx-html > "$DIR"/artifacts/docker.txt 2>&1 || true
  docker rm -f "$CONTAINER_NAME" > "$DIR"/artifacts/docker.txt 2>&1 || true

  output=$(cat "$DIR"/artifacts/testWeeReportRunForecast.txt)

  assertContains "$output" "Starting weewx reports (Alternative layout with forecast)"
  assertContains "$output" "Using configuration file [1m/home/weewx-data/weewx.conf[0m"
  assertContains "$output" "INFO weewx.reportengine: Copied 9 files to /home/weewx-data/public_html"
  #assertContains "$output" "ZambrettiThread: Zambretti: generated 1 forecast record"

  assertNotContains "$output" "failed with exception"
  assertNotContains "$output" "Ignoring template"
  assertNotContains "$output" "Caught unrecoverable exception"
}

testWeeReportRunCustom() {
  cleanup_container
  docker run --entrypoint "/start-custom.sh" --name "$CONTAINER_NAME" weewx > "$DIR"/artifacts/testWeeReportRunCustom.txt 2>&1 || true
  docker cp "$CONTAINER_NAME":/home/weewx-data/public_html/ "$DIR"/artifacts-custom-weewx-html > "$DIR"/artifacts/docker.txt 2>&1 || true
  docker rm -f "$CONTAINER_NAME" > "$DIR"/artifacts/docker.txt 2>&1 || true

  output=$(cat "$DIR"/artifacts/testWeeReportRunCustom.txt)

  assertContains "$output" "Starting weewx reports (Alternative layout with customisations)"
  assertContains "$output" "Using configuration file [1m/home/weewx-data/weewx.conf[0m"
  assertContains "$output" "Generating as of last timestamp in the database."
  assertContains "$output" "INFO weewx.cheetahgenerator: Generated 284 files for report WdcReport in"
  assertContains "$output" "INFO weewx.reportengine: Copied 17 files to /home/weewx-data/public_html"

  assertNotContains "$output" "failed with exception"
  assertNotContains "$output" "Ignoring template"
  assertNotContains "$output" "Caught unrecoverable exception"
}

testWeeReportRunDWD() {
  cleanup_container
  docker run --entrypoint "/start-dwd.sh" --name "$CONTAINER_NAME" weewx > "$DIR"/artifacts/testWeeReportRunDWD.txt 2>&1 || true
  docker cp "$CONTAINER_NAME":/home/weewx-data/public_html/ "$DIR"/artifacts-dwd-weewx-html > "$DIR"/artifacts/docker.txt 2>&1 || true
  docker rm -f "$CONTAINER_NAME" > "$DIR"/artifacts/docker.txt 2>&1 || true

  output=$(cat "$DIR"/artifacts/testWeeReportRunDWD.txt)

  assertContains "$output" "Starting weewx reports (weewx-DWD)"
  assertContains "$output" "Using configuration file [1m/home/weewx-data/weewx.conf[0m"
  assertContains "$output" "Generating as of last timestamp in the database."
  assertContains "$output" "INFO weewx.cheetahgenerator: Generated 31 files for report WdcReport in"
  assertContains "$output" "INFO weewx.reportengine: Copied 20 files to /home/weewx-data/public_html"

  assertNotContains "$output" "failed with exception"
  assertNotContains "$output" "Ignoring template"
  assertNotContains "$output" "Caught unrecoverable exception"
}

testWeeReportRunCustomBinding() {
  cleanup_container
  docker run --entrypoint "/start-custom-binding.sh" --name "$CONTAINER_NAME" weewx > "$DIR"/artifacts/testWeeReportRunCustomBinding.txt 2>&1 || true
  docker cp "$CONTAINER_NAME":/home/weewx-data/public_html/ "$DIR"/artifacts-custom-binding-weewx-html > "$DIR"/artifacts/docker.txt 2>&1 || true
  docker rm -f "$CONTAINER_NAME" > "$DIR"/artifacts/docker.txt 2>&1 || true

  output=$(cat "$DIR"/artifacts/testWeeReportRunCustomBinding.txt)

  assertContains "$output" "Starting weewx reports (Alternative layout with custom binding)"
  assertContains "$output" "Using configuration file [1m/home/weewx-data/weewx.conf[0m"
  assertContains "$output" "INFO weewx.cheetahgenerator: Generated 31 files for report WdcReport in"
  assertContains "$output" "INFO weewx.reportengine: Copied 17 files to /home/weewx-data/public_html"

  assertNotContains "$output" "failed with exception"
  assertNotContains "$output" "Ignoring template"
  assertNotContains "$output" "Caught unrecoverable exception"
}

testWeeReportRunWithoutWeewxForecast() {
  cleanup_container
  docker run --entrypoint "/start-without-forecast.sh" --name "$CONTAINER_NAME" weewx > "$DIR"/artifacts/testWeeReportRunWithoutWeewxForecast.txt 2>&1 || true
  docker rm -f "$CONTAINER_NAME" > "$DIR"/artifacts/docker.txt 2>&1 || true

  output=$(cat "$DIR"/artifacts/testWeeReportRunWithoutWeewxForecast.txt)

  assertContains "$output" "Starting weewx reports (without forecast)"
  assertContains "$output" "Using configuration file [1m/home/weewx-data/weewx.conf[0m"
  assertContains "$output" "Generating as of last timestamp in the database."
  assertContains "$output" "INFO weewx.cheetahgenerator: Generated 32 files for report WdcReport in"
  assertContains "$output" "INFO weewx.reportengine: Copied 17 files to /home/weewx-data/public_html"
  assertContains "$output" "DEBUG user.weewx_wdc: weewx-forecast extension is not installed. Not providing any forecast data."

  assertNotContains "$output" "failed with exception"
  assertNotContains "$output" "Ignoring template"
  assertNotContains "$output" "Caught unrecoverable exception"
}

testWeeReportRunMqtt() {
  cleanup_container
  docker run --entrypoint "/start-mqtt.sh" --name "$CONTAINER_NAME" weewx > "$DIR"/artifacts/testWeeReportRunMqtt.txt 2>&1 || true
  docker cp "$CONTAINER_NAME":/home/weewx-data/public_html/ "$DIR"/artifacts-mqtt-weewx-html > "$DIR"/artifacts/docker.txt 2>&1 || true
  docker rm -f "$CONTAINER_NAME" > "$DIR"/artifacts/docker.txt 2>&1 || true

  output=$(cat "$DIR"/artifacts/testWeeReportRunMqtt.txt)

  assertContains "$output" "Starting weewx reports (mqtt)"
  assertContains "$output" "Using configuration file [1m/home/weewx-data/weewx.conf[0m"
  assertContains "$output" "Generating as of last timestamp in the database."
  assertContains "$output" "INFO weewx.cheetahgenerator: Generated 32 files for report WdcReport in"
  assertContains "$output" "INFO weewx.reportengine: Copied 19 files to /home/weewx-data/public_html"

  assertNotContains "$output" "failed with exception"
  assertNotContains "$output" "Ignoring template"
  assertNotContains "$output" "Caught unrecoverable exception"
}

testWeeReportRunSensorStatus() {
  cleanup_container
  docker run --entrypoint "/start-sensor.sh" --name "$CONTAINER_NAME" weewx > "$DIR"/artifacts/testWeeReportRunSensorStatus.txt 2>&1 || true
  docker cp "$CONTAINER_NAME":/home/weewx-data/public_html/ "$DIR"/artifacts-sensor-status-weewx-html > "$DIR"/artifacts/docker.txt 2>&1 || true
  docker rm -f "$CONTAINER_NAME" > "$DIR"/artifacts/docker.txt 2>&1 || true

  output=$(cat "$DIR"/artifacts/testWeeReportRunSensorStatus.txt)

  assertContains "$output" "Starting weewx reports (sensor status)"
  assertContains "$output" "Using configuration file [1m/home/weewx-data/weewx.conf[0m"
  assertContains "$output" "Generating as of last timestamp in the database."
  assertContains "$output" "INFO weewx.cheetahgenerator: Generated 18 files for report WdcReport in"
  assertContains "$output" "INFO weewx.reportengine: Copied 18 files to /home/weewx-data/public_html"

  assertNotContains "$output" "failed with exception"
  assertNotContains "$output" "Ignoring template"
  assertNotContains "$output" "Caught unrecoverable exception"
}

testWeeReportRunCMNON() {
  cleanup_container
  docker run --entrypoint "/start-cmon.sh" --name "$CONTAINER_NAME" weewx > "$DIR"/artifacts/testWeeReportRunCMON.txt 2>&1 || true
  docker cp "$CONTAINER_NAME":/home/weewx-data/public_html/ "$DIR"/artifacts-cmon-weewx-html > "$DIR"/artifacts/docker.txt 2>&1 || true
  docker rm -f "$CONTAINER_NAME" > "$DIR"/artifacts/docker.txt 2>&1 || true

  output=$(cat "$DIR"/artifacts/testWeeReportRunCMON.txt)

  assertContains "$output" "Starting weewx reports (CMON)"
  assertContains "$output" "Using configuration file [1m/home/weewx-data/weewx.conf[0m"
  assertContains "$output" "Generating as of last timestamp in the database."
  assertContains "$output" "INFO weewx.cheetahgenerator: Generated 15 files for report WdcReport in"
  assertContains "$output" "INFO weewx.reportengine: Copied 18 files to /home/weewx-data/public_html"

  assertNotContains "$output" "failed with exception"
  assertNotContains "$output" "Ignoring template"
  assertNotContains "$output" "Caught unrecoverable exception"
}

oneTimeTearDown() {
  cleanup_container
  [ -d "$DIR"/shunitexit ] && rm -rf "$DIR"/shunitexit
}

# Load and run shUnit2.
. "$DIR"/../shunit2/shunit2