#!/bin/sh

filter_fs() {
  local fstype=$(awk '$2 == "'"$1"'" { print $3 }' /proc/mounts)
  case "$fstype" in
  iso9660) return 1 ;;
  esac 
  return 0
}


config_df() {
  echo "graph_title Filesystem usage (in %)
graph_args --upper-limit 100 -l 0
graph_vlabel %
graph_category disk
graph_info This graph shows disk usage on the machine."
  for PART in $(df -P | grep '^/' | sed '/\/[a-z0-9,]*$/!d;s/.* \([a-z0-9,\/]\{1,\}\)$/\1/g')
  do
    filter_fs $PART || continue
    PINFO=$(df -P $PART | tail -1)
    PNAME=$(echo $PINFO | cut -d\  -f1 | sed 's/\//_/g')
    PSIZE=$( (df -Ph $PART 2>/dev/null || df -P $PART)| tail -1 | awk '{print $2}')
    PTYPE=$(df -PT $PART | tail -1 | awk '{print $2}')
    PAVAIL=$( (df -Ph $PART 2>/dev/null || df -P $PART)| tail -1 | awk '{print $4}')
    echo "$PNAME.label $PART ($PSIZE)"
    echo "$PNAME.info $PNAME -> $PART $PAVAIL free ($PTYPE)"
    ONEPCT=$(echo $PINFO | awk '{ print int($2 / 100)}')
    if [ $ONEPCT -lt 10000000 ] ; then # 1% is less than 10G!
      echo "$PNAME.warning 92"
      echo "$PNAME.critical 98"
    else
      echo "$PNAME.warning 98"
      echo "$PNAME.critical 99"
    fi
  done
}
fetch_df() {
  for PART in $(df -P | grep '^/' | sed '/\/[a-z0-9,]*$/!d;s/.* \([a-z0-9,\/]\{1,\}\)$/\1/g')
  do
    filter_fs $PART || continue
    PINFO=$(df -P $PART | tail -1);
    PNAME=$(echo $PINFO | cut -d\  -f1 | sed 's/[\/.-]/_/g')
    echo "$PNAME.value" $(echo $PINFO | cut -f5 -d\  | sed -e 's/\%//g')
  done
}