#!/bin/sh
#
config_neterr() {
  echo "graph_order down up"
  echo "graph_title Network Errors"
  echo "graph_args --base 1000"
  echo "graph_vlabel Errors in (-) / out (+) per \${graph_period}"
  echo "graph_category network"
  echo "graph_info This graph shows the amount of errors across all network interfaces."
  echo "down.label received"
  echo "down.type DERIVE"
  echo "down.min 0"
  echo "down.graph no"
  echo "up.label errors"
  echo "up.type DERIVE"
  echo "up.min 0"
  echo "up.negative down"
}


fetch_neterr() {
  local awksrc='
      BEGIN {
        down_cnt = 0
        up_cnt = 0
      }
      END {
        printf "down.value %.0f\n", down_cnt
        printf "up.value %.0f\n", up_cnt
      }
    ' stats=' down_cnt += $4 + $5 ; up_cnt += $12 + $13 + $15 '
  if [ -n "${net_ifs:-}" ] ; then
    # User specified target devices...
    for kv in $net_ifs
    do
      k=$(echo $kv | cut -d: -f1)
      v=$(echo $kv | cut -d: -f2)
      awksrc="$awksrc
          \$1 == \"$k:\" { $stats }
      "
    done
  else
    awksrc="$awksrc
      /:/ { $stats }
      "
  fi
  awk "$awksrc" /proc/net/dev
}
