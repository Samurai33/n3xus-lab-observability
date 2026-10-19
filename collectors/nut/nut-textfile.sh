#!/bin/sh
# UPS (NUT) -> Prometheus metrics via the node_exporter textfile collector.
# Runs every 15 s from nut-textfile.timer. Set UPS=<name>@<host> in the unit if yours is not "ups@localhost".
# Note: on some protocols (e.g. SMS/Brazil) battery.charge is *estimated* by the driver; do not trust it alone.
set -eu
UPS=${UPS:-ups@localhost}
DIR=${TEXTFILE_DIR:-/var/lib/prometheus/node-exporter}
o=$DIR/nut.prom; t=$o.$$
upsc "$UPS" 2>/dev/null | awk -F': ' '
 /^(battery.charge|battery.runtime|input.voltage|output.voltage|ups.load|ups.temperature|output.frequency):/{gsub(/\./,"_",$1); print "nut_"$1, $2}
 /^ups.status:/{print "nut_on_battery", ($2~/OB/)?1:0; print "nut_low_battery", ($2~/LB/)?1:0; print "nut_online", ($2~/OL/)?1:0}
 END{print "nut_scrape_ok", (NR>0)?1:0}' > "$t" || true
mv "$t" "$o"
