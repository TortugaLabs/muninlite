#!/bin/sh

probe_xen() {
  if  [ -e /proc/xen/capabilities ] && grep -q control_d /proc/xen/capabilities ; then
    return 1
  fi
  return 0
}

if is_plugin_enabled "xen" ; then
  remove_plugin "xen"
  if ! probe_xen ; then
    add_plugin xen_cpu
    add_plugin xen_mem
  fi
fi

config_xen_cpu() {
  graph_opts="--base 1000"
  cat <<-_EOF_
	graph_title VM CPU Usage
	graph_args $graph_opts
	graph_vlabel %
	graph_scale no
	graph_info This graph shows vCPU consumption
	graph_category virtualization
	graph_period second
	_EOF_
  type=AREA
  for vmname in $(xl list | (read x ; awk '{print $1}'))
  do
    vmlabel=v$(echo $vmname | tr -sc A-Za-z0-9 _)
    cat <<-_EOF_
	$vmlabel.label $vmname
	$vmlabel.draw $type
	$vmlabel.type DERIVE
	$vmlabel.min 0
	$vmlabel.info CPU time for $vmname
	_EOF_
    type=STACK
  done
}
fetch_xen_cpu() {
  xl list | (
    read ignore
    while read vmname vmid vmMen vcpus vstate vtime
    do
      vmlabel=v$(echo $vmname | tr -sc A-Za-z0-9 _)
      echo "$vmlabel.value $(echo $vtime | awk '{print $1 * 100}')"
    done
  )
}
config_xen_mem() {
  graph_opts="--base 1000"

  cat <<-_EOF_
	graph_title VM Memory Usage
	graph_args $graph_opts
	graph_vlabel MB
	graph_scale no
	graph_info This graph shows Memory consumption in MB
	graph_category virtualization
	graph_period second
	_EOF_
  cat <<-_EOF_
	totalmem.label Total
	totalmem.draw LINE1
	totalmem.info Total physical memory
	_EOF_
  type=AREA
  for vmname in $(xl list | (read x ; awk '{print $1}'))
  do
    vmlabel=v$(echo $vmname | tr -sc A-Za-z0-9 _)
    cat <<-_EOF_
	$vmlabel.label $vmname
	$vmlabel.draw $type
	$vmlabel.info Memory usage in MB for $vmname
	_EOF_
    type=STACK
  done
}
fetch_xen_mem() {
  xl list | (
    read ignore
    while read vmname vmid vmem vcpus vstate vtime
    do
      vmlabel=v$(echo $vmname | tr -sc A-Za-z0-9 _)
      echo "$vmlabel.value $vmem"
    done
  )
  xl info | awk '$1 == "total_memory" { print "totalmem.value", $3 }'
}
