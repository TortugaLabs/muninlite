#!/bin/sh


probe_sensors() {
  local rc=0
  if type sensors >/dev/null 2>&1 ; then
    rc=$(expr $rc + 1)
  elif (type acpi && [ -n "$(acpi -t)" ] ) >/dev/null 2>&1 ; then
    rc=$(expr $rc + 1)
  fi
  if type smartctl >/dev/null 2>&1 ; then
    for hdd in $(find /dev -name 'sd?')
    do
      res=$(smartctl -a $hdd | awk '$1 == 194 { print $10}') || continue
      if [ -n "$res" ] ; then
        rc=$(expr $rc + 1)
      fi
    done
  fi
  return $rc
}
  


if is_plugin_enabled "sensors" ; then
  if probe_sensors ; then
    remove_plugin "sensors"
  fi
fi

config_sensors() {
  cat <<-_EOF_
	graph_title System Temperature
	graph_args --base 1000 -l 0
	graph_vlabel C
	graph_scale no
	graph_category system
	graph_info Temperature of various components, in C
	_EOF_
  if type sensors >/dev/null 2>&1 ; then
    sensors | grep high | while read ln
    do
      name=$(echo $ln | cut -d: -f1)
      id=$(echo $name| tr -sc A-Za-z0-9 _)
      echo "$id.label $name"
      echo "$id.warning $(echo $ln | cut -d+ -f3 | cut -d. -f1)"
      echo "$id.critical $(echo $ln | cut -d+ -f4 | cut -d. -f1)"
    done
  elif (type acpi && [ -n "$(acpi -t)" ] ) >/dev/null 2>&1 ; then
    acpi -t | cut -d: -f1 | tr ' ' '_' | while read f
    do
      echo "$f.label $f"
    done
  fi
  if type smartctl >/dev/null 2>&1 ; then
    for hdd in $(find /dev -name 'sd?')
    do
      res=$(smartctl -a $hdd | awk '$1 == 194 { print $10}') || continue
      if [ -n "$res" ] ; then
        id=$(echo $hdd| tr -sc A-Za-z0-9 _)
        echo "$id.label $hdd"
      fi
    done
  fi
}
fetch_sensors() {
  if type sensors >/dev/null 2>&1 ; then
    sensors | grep high | while read ln
    do
      name=$(echo $ln | cut -d: -f1)
      id=$(echo $name| tr -sc A-Za-z0-9 _)
      echo "$id.value $(echo $ln | cut -d: -f2 | cut -dC -f1 | tr -dc .0-9)"
    done
  elif (type acpi && [ -n "$(acpi -t)" ] ) >/dev/null 2>&1 ; then
    acpi -t | while read ln
    do
      id=$(echo "$ln" | cut -d: -f1 | tr ' ' '_')
      val=$(echo "$ln" | cut -d, -f2- | sed -e 's/^\s//' | cut -d' ' -f1)
      echo "$id.value $val"
    done
  fi
  if type smartctl >/dev/null 2>&1 ; then
    for hdd in $(find /dev -name 'sd?')
    do
      res=$(smartctl -a $hdd | awk '$1 == 194 { print $10}') || continue
      id=$(echo $hdd| tr -sc A-Za-z0-9 _)
      if [ -n "$res" ] ; then
        id=$(echo $hdd| tr -sc A-Za-z0-9 _)
        echo "$id.value $res"
      fi
    done
  fi
}
