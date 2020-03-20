#!/bin/sh

config_netbps() {
  echo "graph_order down up"
  echo "graph_title Network traffic"
  echo "graph_args --base 1000"
  echo "graph_vlabel bits in (-) / out (+) per \${graph_period}"
  echo "graph_category network"
  echo "graph_info This graph shows the traffic of all network interfaces. Please note that the traffic is shown in bits per second, not bytes. IMPORTANT: Since the data source for this plugin use 32bit counters, this plugin is really unreliable and unsuitable for most 100Mb (or faster) interfaces, where bursts are expected to exceed 50Mbps. This means that this plugin is usuitable for most production environments. To avoid this problem, use the ip_ plugin instead."
  echo "down.label received"
  echo "down.type DERIVE"
  echo "down.min 0"
  echo "down.graph no"
  echo "up.label bps"
  echo "up.type DERIVE"
  echo "up.min 0"
  echo "up.negative down"
}
fetch_netbps() {
  local awksrc='
      BEGIN {
        down_cnt = 0
        up_cnt = 0
      }
      END {
        printf "down.value %.0f\n", down_cnt
        printf "up.value %.0f\n", up_cnt
      }
    '
  if [ -n "${net_ifs:-}" ] ; then
    # User specified target devices...
    local kv k v
    for kv in $net_ifs
    do
      k=$(echo $kv | cut -d: -f1)
      v=$(echo $kv | cut -d: -f2)
      awksrc="$awksrc
          \$1 == \"$k:\" { down_cnt += \$2 ; up_cnt += \$10 }
      "
    done
  else
    awksrc="$awksrc
        /:/ { down_cnt += \$2 ; up_cnt += \$10 }"
  fi
  awk "$awksrc" /proc/net/dev
}
