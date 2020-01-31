#!/bin/sh
#
config_neterr() {
  echo "graph_order down up"
  echo "graph_title Network Errors"
  echo "graph_args --base 1000"
  echo "graph_vlabel bits in (-) / out (+) per \${graph_period}"
  echo "graph_category network"
  echo "graph_info This graph shows the amount of errors across all network interfaces."
  echo "down.label received"
  echo "down.type DERIVE"
  echo "down.min 0"
  echo "down.graph no"
  echo "up.label bps"
  echo "up.type DERIVE"
  echo "up.min 0"
  echo "up.negative down"
}

fetch_neterr() {
  if [ -n "${net_ifs:-}" ] ; then
    # User specified target devices...
    local kv k v awkscr='
      BEGIN {
        down_cnt = 0
        up_cng = 0
      }
      END {
        print "down.value", down_cnt
        print "up.value",up_cnt
      }
    '
    for kv in $net_ifs
    do
      k=$(echo $kv | cut -d: -f1)
      v=$(echo $kv | cut -d: -f2)
      awkscr="$awkscr
          \$1 == \"$k:\" { down_cnt += \$4 ; up_cnt += \$12 }
      "
    done
    awk "$awkscr" /proc/net/dev
  else
    awk '
      /:/ { down_cnt += $4 ; up_cnt += $12 }
      END {
        print "down.value",down_cnt
        print "up.value",up_cnt
      }' /proc/net/dev
  fi
}
