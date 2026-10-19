#!/bin/sh
# LVM thin pools -> data and metadata usage (%) for the node_exporter textfile collector. Run every minute as root.
set -eu
DIR=${TEXTFILE_DIR:-/var/lib/prometheus/node-exporter}
o=$DIR/lvm_thin.prom; t=$o.$$
{ echo "# HELP lvm_thin_data_percent Thin pool data usage (%)"; echo "# TYPE lvm_thin_data_percent gauge"
  echo "# HELP lvm_thin_metadata_percent Thin pool metadata usage (%)"; echo "# TYPE lvm_thin_metadata_percent gauge"
  lvs --noheadings --separator ' ' -o vg_name,lv_name,data_percent,metadata_percent -S 'lv_attr=~^t' 2>/dev/null | while read -r vg lv d m; do
    echo "lvm_thin_data_percent{vg=\"$vg\",pool=\"$lv\"} $d"; echo "lvm_thin_metadata_percent{vg=\"$vg\",pool=\"$lv\"} $m"; done
} > "$t" && mv "$t" "$o"
