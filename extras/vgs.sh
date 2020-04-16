#!/bin/sh

if is_plugin_enabled "vgs" ; then
  if [ $EUID -gt 0 ] ; then
    remove_plugin "vgs"
  fi
fi

get_vg_data() {
  vgs --noheadings --units k -o vg_name,vg_size,vg_free | awk '
  {
    printf "%s %d %.2f %d\n",$1,$2/100,100-$3*100/$2,$2
  }
  '
}
vg_calc_threshold() {
  local total="$1"
  local val="$(expr "$2" '*' 1048576)" # Convert input to gigs
  echo "$total $val" | awk '{ print "%f",100 - ($2/$1*100) }'
}

config_vgs() {
  cat <<-_EOF_
	graph_title LVM Volume Group usage (in %)
	graph_args --upper-limit 100 -l 0
	graph_vlabel %
	graph_category disk
	graph_info This graph shows Volume Group usage on the machine.
	_EOF_
  get_vg_data | while read vgname onepct usage vsize
  do
    vgid=$(echo "$vgname" |tr -sc A-Za-z0-9 _)
    vgx=$(vgs --noheadings  -o vg_size,vg_free "$vgname")
    echo "$vgid.label $vgname ($(echo "$vgx" | awk '{print $1}'))"
    echo "$vgid.info $(echo "$vgx" | awk '{print $2}') free"

    if [ $onepct -lt 10000000 ] ; then # 1% is less than 10G
      echo "$vgid.warning 92"
      echo "$vgid.critical 98"
    else
      # For more than 100G, the tresholds are based actual storage (not fixed percentage)
      echo "$vgid.warning $(vg_calc_threshold $vsize 20)"
      echo "$vgid.critical $(vg_calc_threshold $vsize 2)"
    fi
  done
}

fetch_vgs() {
  get_vg_data | while read vgname onepct usage vsize
  do
    vgid=$(echo "$vgname" |tr -sc A-Za-z0-9 _)
    echo "$vgid.value $usage"
  done
}
