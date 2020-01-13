#!/bin/sh
#
# Runtime configuration...
#
if is_plugin_enabled "if_" ; then
  remove_plugin "if_"
  for INTER in $(select_net_devs);
  do
    INTERRES=$(clean_net_dev_name $INTER)
    add_plugin "if_$INTERRES"
    eval "fetch_if_${INTERRES}() { fetch_if $INTER \$@; };"
    eval "config_if_${INTERRES}() { config_if $INTER \$@; };"
  done
fi

config_if() {
  echo "graph_order down up"
  echo "graph_title $1 traffic"
  echo "graph_args --base 1000"
  echo "graph_vlabel bits in (-) / out (+) per \${graph_period}"
  echo "graph_category network"
  echo "graph_info This graph shows the traffic of the $1 network interface. Please note that the traffic is shown in bits per second, not bytes. IMPORTANT: Since the data source for this plugin use 32bit counters, this plugin is really unreliable and unsuitable for most 100Mb (or faster) interfaces, where bursts are expected to exceed 50Mbps. This means that this plugin is usuitable for most production environments. To avoid this problem, use the ip_ plugin instead."
  echo "down.label received"
  echo "down.type DERIVE"
  echo "down.min 0"
  echo "down.graph no"
  echo "down.cdef down,8,*"
  echo "up.label bps"
  echo "up.type DERIVE"
  echo "up.min 0"
  echo "up.negative down"
  echo "up.cdef up,8,*"
  if type ethtool >/dev/null 2>&1 ; then
    if ethtool $1 | grep -q Speed; then
      MAX=$(($(ethtool $1 | grep Speed | sed -e 's/[[:space:]]\{1,\}/ /g' -e 's/^ //' -e 's/M.*//' | cut -d\  -f2) * 1000000))
      echo "up.max $MAX"
      echo "down.max $MAX"
    fi
  fi
}
fetch_if() {
  IINFO=$(grep "$1:" /proc/net/dev | cut -d: -f2 | sed -e 's/  / /g')
  echo "down.value" $(echo $IINFO | cut -d\  -f1)
  echo "up.value" $(echo $IINFO | cut -d\  -f9)
}