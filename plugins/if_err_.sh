#!/bin/sh

if is_plugin_enabled "if_err_" ; then
  remove_plugin "if_err_"
  for INTER in $(select_net_devs);
  do
    INTERRES=$(clean_net_dev_name $INTER)
    add_plugin "if_err_$INTERRES"
    eval "fetch_if_err_${INTERRES}() { fetch_if_err $INTER \$@; };"
    eval "config_if_err_${INTERRES}() { config_if_err $INTER \$@; };"
  done
fi

config_if_err() {
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
fetch_if_err() {
  IINFO=$(grep "$1:" /proc/net/dev | cut -d: -f2 | sed -e 's/  / /g')
  echo "rcvd.value" $(echo $IINFO | cut -d\  -f3)
  echo "trans.value" $(echo $IINFO | cut -d\  -f11)
}
