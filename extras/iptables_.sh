#!/bin/sh
#
# Create IP table charts based on iptables output.  For this to
# work you need to create iptable rules with a comment such as:
#
# --m comment --comment "[optional text to be ignored]CNT:_graph_,_value_"
#
# Then you need to enable the plugin in `/etc/muninlite.conf`:
#
# PLUGINS="$PLUGINS iptables_"
#
# Data will be available in additional node:
#
# $HOSTNAME-fw
#
awktxt='
  /CNT:/ {
    i = index($0,"CNT:")
    if (i == 0) { return }
    str = substr($0, i+4)
    i = index(str,"*")
    if (i > 0) { str = substr(str,1,i-2) }
    totals["p," str] += $1
    totals["b," str] += $2
  }
  END {
    for (word in totals) print word,totals[word]
  }
'
#~ set -euf -o pipefail
#~ is_plugin_enabled() { return 0; }
#~ remove_plugin() { :; }
#~ HOSTNAME=$(hostname)
#~ NODES="$HOSTNAME"


_iptables_read_data() {
  local v
  for v in "" "6"
  do
    type ip${v}tables >/dev/null 2>&1 || continue
    ip${v}tables -L -x -v -n | awk "$awktxt" | sed -e "s/^/ip${v:-4},/"
  done
}

_iptables_fetch() {
  local ipvx="$1" porb="$2" graph="$3"
  echo "$_iptables_data_" | grep "^$ipvx,$porb,$graph," | sed -e "s!^$ipvx,$porb,$graph,!!" | while read i j k
  do
    echo  "$i.value $j"
  done
}

_iptables_config() {
  local ipvx="$1" porb="$2" graph="$3"
  case "$porb" in
    b) var=bytes ;;
    p) var=pkts  ;;
    *) var=xxxxs ;;
  esac
  local v=$(echo "$ipvx" | tr -dc 0-9)
  
  cat <<-_EOF_
	graph_title	IPv$v $graph $var
	graph_args	--base 1000
	graph_vlabel	$var/sec
	graph_category	IPv$v Firewall $var
	graph_info	This graphs shows iptables IPv$v $var counters for the target $graph.
	_EOF_
  echo "$_iptables_data_" | grep "^$ipvx,$porb,$graph," | sed -e "s!^$ipvx,$porb,$graph,!!" | while read i j
  do
    echo "$i.label $i $var"
    echo "$i.type DERIVE"
    echo "$i.min 0"
  done
}


if is_plugin_enabled "iptables_" ; then
  remove_plugin "iptables_"

  _iptables_data_="$(_iptables_read_data)"  
  if [ -n "$_iptables_data_" ] ; then
    add_node ${HOSTNAME}-fw
    _iptables_items_=$(
      echo "$_iptables_data_" | tr ',' ' ' | while read ipvx porb graph xxx
      do
	echo fw_${ipvx}_${porb}_${graph}
      done | sort -u
    )
    add_node_plugins ${HOSTNAME}-fw $_iptables_items_
    for i in $(
      echo "$_iptables_data_" | tr ',' ' ' | while read ipvx porb graph xxx
      do
	echo ${ipvx},${porb},${graph}
      done | sort -u
    )
    do
      j=$(echo fw,"$i" | tr , _)
      eval "config_${j}() { _iptables_config $(IFS="," ; set - $i ; echo $1 $2 $3) ; }"
      eval "fetch_${j}() { _iptables_fetch $(IFS="," ; set - $i ; echo $1 $2 $3) ; }"
    done
  fi
fi

#~ echo $NODES
#~ node_${HOSTNAME}_fw
#~ for x in $(node_${HOSTNAME}_fw)
#~ do
  #~ echo "$x:"
  #~ config_${x}
  #~ echo =
  #~ fetch_${x}
  #~ echo =======================
#~ done
