#!/bin/sh
#
# This plugin is disabled by default.
#
# To enable you must:
#
# ```
# add_plugin if_ if_err_
# ```
#
# or
#
# ```
# PLUGINS="$PLUGINS if_"
# ```
#
# Also, this plugin can be configured to report interfaces to
# a sub-node.  To do this you must define:
#
# - `**IFEX_SUB_NODE**=_nodename_`
#
# For example:
#
# ```
# IFEX_SUB_NODE=$HOSTNAME-fw
# ```
#
#
select_net_devs() {
  grep '^ *[a-zA-Z0-9]\([^:]\)\{1,\}:' /proc/net/dev | cut -f1 -d: | sed 's/ //g' | while read dev
  do
    [ -z "$dev" ] && continue || :
    if [ x"$dev" = x"lo" ] ; then
      continue
    fi
    echo "$dev"
  done
}

clean_net_dev_name() {
  echo "$@" | sed -e 's/\./VLAN/' -e 's/^[^A-Za-z_]/_/' -e 's/[^A-Za-z0-9_]/_/g'
}

for i in "if_" "if_err_" 
do
  if is_plugin_enabled "$i" ; then
    remove_plugin "$i"
    if [ -n "${IFEX_SUB_NODE:-}" ] ; then
      # Add items to a sub-node...
      add_node ${IFEX_SUB_NODE}
      _add_plugin_="add_node_plugins ${IFEX_SUB_NODE}"
    else
      # use current node...
      _add_plugin_=add_plugin
    fi
    for INTER in $(select_net_devs)
    do
      INTERRES=$(clean_net_dev_name $INTER)
      $_add_plugin_ "$i${INTERRES}"
      eval "fetch_${i}${INTERRES}() { fetch_$i $INTER \$@; };"
      eval "config_${i}${INTERRES}() { config_$i $INTER \$@; };"
    done
  fi
done
    
config_if_() {
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
fetch_if_() {
  IINFO=$(grep "$1:" /proc/net/dev | cut -d: -f2 | sed -e 's/  / /g')
  echo "down.value" $(echo $IINFO | cut -d\  -f1)
  echo "up.value" $(echo $IINFO | cut -d\  -f9)
}
config_if_err_() {
  echo "graph_order rcvd trans"
  echo "graph_title $1 errors"
  echo "graph_args --base 1000"
  echo "graph_vlabel packets in (-) / out (+) per \${graph_period}"
  echo "graph_category network"
  echo "graph_info This graph shows the amount of errors on the $1 network interface."
  echo "rcvd.label packets"
  echo "rcvd.type COUNTER"
  echo "rcvd.graph no"
  echo "rcvd.warning 1"
  echo "trans.label packets"
  echo "trans.type COUNTER"
  echo "trans.negative rcvd"
  echo "trans.warning 1"
}
fetch_if_err_() {
  IINFO=$(grep "$1:" /proc/net/dev | cut -d: -f2 | sed -e 's/  / /g')
  echo "rcvd.value" $(echo $IINFO | cut -d\  -f3)
  echo "trans.value" $(echo $IINFO | cut -d\  -f11)
}
