#!/bin/sh

if is_plugin_enabled "vgs" ; then
  if [ $EUID -gt 0 ] ; then
    remove_plugin "vgs"
  fi
fi

get_vg_data() {
  vgs --noheadings --units k -o vg_name,vg_size,vg_free | awk '
  {
    printf "%s %d %.2f\n",$1,$2/100,100-$3*100/$2
  }
  '
}

config_vgs() {
  cat <<-_EOF_
	graph_title LVM Volume Group usage (in %)
	graph_args --upper-limit 100 -l 0
	graph_vlabel %
	graph_category disk
	graph_info This graph shows Volume Group usage on the machine.
	_EOF_
  get_vg_data | while read vgname onepct usage
  do
    vgid=$(echo "$vgname" |tr -sc A-Za-z0-9 _)
    vgx=$(vgs --noheadings  -o vg_size,vg_free "$vgname")
    echo "$vgid.label $vgname ($(echo "$vgx" | awk '{print $1}'))"
    echo "$vgid.info $(echo "$vgx" | awk '{print $2}') free"

    if [ $onepct -lt 10000000 ] ; then # 1% is less than 10G
      echo "$vgid.warning 92"
      echo "$vgid.critical 98"
    else
      echo "$vgid.warning 98"
      echo "$vgid.critical 99"
    fi
  done
}

fetch_vgs() {
  get_vg_data | while read vgname onepct usage
  do
    vgid=$(echo "$vgname" |tr -sc A-Za-z0-9 _)
    echo "$vgid.value $usage"
  done
}