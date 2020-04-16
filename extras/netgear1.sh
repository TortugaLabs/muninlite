#!/bin/sh
#
#
# This plugin is disabled by default.
#
# To enable you must:
#
# 1. include the plugin
# 2. Add the plugin: `add_plugin psl_if_ psl_if_err_`
# 3. Define the list of nodes to poll: `PSL_NODES="sw1 sw2`
# 4. Define the node data for each node:
#    - `register psl_sw1 name=sw1 passwd=something portcount=8`
#
#
#

_psl_parse_stats() {
  grep -E '(def.firstCol|[pP]kt..value=)' | (
    last='x' ; max=0
    while read L
    do
      if (echo "$L" | grep -q firstCol) ; then
	last=$(echo "$L" | cut -d'>' -f2 | cut -d'<' -f1)
	[ $last -gt $max ] && max=$last
      else
	var=$(echo $L | cut -d\' -f4 | tr A-Z a-z)
	val=$(printf '%d' "0x$(echo $L | cut -d\' -f6)")
	eval va_${last}_${var}=\$val
	echo va_${last}_${var}=\"$val\"
      fi
    done
  )
}

_psl_parse_status() {
  grep -E '"text"'| grep -v 'def_TH' | (
    last='x' ; max=0 ; f=0
    set - state speed
    while read L
    do
      val=$(echo "$L" | cut -d'>' -f 2)
      if (echo "$L" | grep -q "firstCol") ; then
	last=$val
	[ $last -gt $max ] && max=$last
	f=0
      else
	f=$(expr $f + 1)
	eval var=\$$f
	eval va_${last}_${var}=\$val
	echo va_${last}_${var}=\"$val\"
      fi
    done
  )
}


_psl_parse_info() {
  grep -E '(nowrap|id=.dhcp_mode)' |(
    mode=any
    while read L
    do
      if [ $mode = any ] ; then
	case "$L" in
	*Product?Name*)
	  mode=product
	  ;;
	*Switch?Name*)
	  mode=swname
	  ;;
	*MAC?Address*)
	  mode=mac
	  ;;
	*Firmware*)
	  mode=firmware
	  ;;
	*dhcp_mode*)
	  echo "dhcp_mode=\"$(echo "$L" | cut -d\' -f8)\""
	  ;;
	*ip_address*)
	  echo "ip=\"$(echo "$L" | cut -d\' -f14)\""
	  ;;
	*subnet_mask*)
	  echo "netmask=\"$(echo "$L" | cut -d\' -f14)\""
	  ;;
        *gateway_address*)
	  echo "gw=\"$(echo "$L" | cut -d\' -f14)\""
	  ;;
	esac
	continue
      elif [ $mode = product ] ; then
	echo "model=\"$(echo "$L" | tr '<' '>' | cut -d'>' -f3)\""
      elif [ $mode = swname ] ; then
	echo "swname=\"$(echo "$L" | cut -d"'" -f14)\""
      elif [ $mode = mac ] ; then
	echo "mac=\"$(echo "$L" | tr '<' '>' | cut -d'>' -f3)\""
      elif [ $mode = firmware ] ; then
	echo "fwver=\"$(echo "$L" | tr '<' '>' | cut -d'>' -f3)\""
      fi
      mode=any
    done
  )
}


_psl_do_poll_switch() {
  local node="$1" passwd="$2" datalog="$3"
  local session=$(mktemp)
  (
    exec >"$datalog"
    local switch="http://$node/" auth="password=$passwd"
    if curl -s --cookie-jar "$session" --data "$auth" $switch/login.cgi ; then
      curl -s --cookie "$session" $switch/index.htm

      #curl -s --cookie "$session" $switch/switch_info.htm | tee info.html |  _psl_parse_info 1>&3
      #curl -s --cookie "$session" $switch/status.htm | tee status.html |  _psl_parse_status 1>&3
      #curl -s --cookie "$session" $switch/port_statistics.htm | tee stats.html |  _psl_parse_stats 1>&3

      curl -s --cookie "$session" $switch/switch_info.htm | _psl_parse_info 1>&3
      curl -s --cookie "$session" $switch/status.htm | _psl_parse_status 1>&3
      curl -s --cookie "$session" $switch/port_statistics.htm | _psl_parse_stats 1>&3

      curl -s --cookie "$session" $switch/logout.cgi
    fi
  ) 3>&1
  rm -f "$session"
}

_psl_poll_switch() {
  local node="$1" rundir="$2"
  mkdir -p "$rundir"
  local fcache="$rundir/$node.shdat" logfile=/dev/null


  if [ $(expr $(date +"%s") - $(filetime "$fcache")) -gt ${psl_maxage:-600} ] ; then
    _psl_do_poll_switch "$(psl_${node} name)" "$(psl_${node} passwd)" "$logfile" > $fcache
  fi
  cat $fcache
}

: ${psl_cache:=/run/munin-node.d}

for i in "psl_if_" "psl_if_err_"
do
  if is_plugin_enabled "$i" ; then
    remove_plugin "$i"
    for n in $PSL_NODES
    do
      add_node $n
      nid=$(clean_fieldname $n)
      if [ $i = psl_if_err_ ] ; then
	add_node_plugins $n psl_if_err_${nid}
	eval "fetch_psl_if_err_${nid}() { fetch_psl_if_err $n \$@; };"
	eval "config_psl_if_err_${nid}() { config_psl_if_err $n \$@; };"
      else
	port_count=$(psl_${n} portcount)
	for p in $(seq 1 $port_count)
	do
	  add_node_plugins $n psl_if_${nid}_$p
	  eval "fetch_psl_if_${nid}_${p}() { fetch_psl_if $n $p \$@; };"
	  eval "config_psl_if_${nid}_${p}() { config_psl_if $n $p \$@; };"
	done
      fi
    done
  fi
done


config_psl_if() {
  local n="$1" p="$2"
  (
    eval "$(_psl_poll_switch $n $psl_cache)"
    eval speed=\${va_${p}_speed:-?}
    eval state=\${va_${p}_state:-?}

    echo "graph_order down up"
    echo "graph_title Port $p traffic ($state, $speed)"
    echo "graph_args --base 1000"
    echo "graph_vlabel pkts in (-) / out (+) per \${graph_period}"
    echo "graph_category network"
    echo "graph_info This graph shows the traffic of the switch port $p. Please note that the traffic is shown in pkts per second.  Port status: $state, Speed: $speed"
  )
  echo "down.label received"
  echo "down.type DERIVE"
  echo "down.min 0"
  echo "down.graph no"
  echo "down.cdef down,8,*"
  echo "up.label pkt/s"
  echo "up.type DERIVE"
  echo "up.min 0"
  echo "up.negative down"
  echo "up.cdef up,8,*"
}
fetch_psl_if() {
  local n="$1" p="$2"
  (
    eval "$(_psl_poll_switch $n $psl_cache)"
    eval rx=\${va_${p}_rxpkt:-}
    eval tx=\${va_${p}_txpkt:-}
    [ -n "$rx" ] && echo "down.value $rx"
    [ -n "$tx" ] && echo "up.value $tx"
  )
}

config_psl_if_err() {
  local n="$1"
  echo "graph_order crc"
  echo "graph_title $n CRC errors"
  echo "graph_args --base 1000"
  echo "graph_vlabel crc errors \${graph_period}"
  echo "graph_category network"
  echo "graph_info This graph shows the amount of errors on the switch ports."
  (
    eval "$(_psl_poll_switch $n $psl_cache)"
    port_count=$(psl_$(clean_fieldname $n) portcount)
    for p in $(seq 1 $port_count)
    do
      echo "crc$p.label packets"
      echo "crc$p.type COUNTER"
      echo "crc$p.graph no"
    done
  )
}
fetch_psl_if_err() {
  local n="$1"

  (
    eval "$(_psl_poll_switch $n $psl_cache)"
    port_count=$(psl_$(clean_fieldname $n) portcount)
    for p in $(seq 1 $port_count)
    do
      eval "crc=\"\${va_${p}_crcpkt:-}\""
      [ -n "$crc" ] && echo "crc${p}.value $crc"
    done
  )
}


