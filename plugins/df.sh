#!/bin/sh

df_filter_fs() {
  local fstype=$(awk '$2 == "'"$1"'" { print $3 }' /proc/mounts)
  case "$fstype" in
  iso9660) return 1 ;;
  esac 
  return 0
}

df_calc_threshold() {
  local total="$1"
  local val="$(expr "$2" '*' 1048576)" # Convert input to gigs
  echo "$total $val" | awk '{ print 100 - ($2/$1*100) }'
}

config_df() {
  echo "graph_title xxFilesystem usage (in %)
graph_args --upper-limit 100 -l 0
graph_vlabel %
graph_category disk
graph_info This graph shows disk usage on the machine."
  for PART in $(df -P | grep '^/' | sed '/\/[a-z0-9,]*$/!d;s/.* \([a-z0-9,\/]\{1,\}\)$/\1/g')
  do
    df_filter_fs $PART || continue
    PINFO=$(df -P $PART | tail -1)
    PNAME=$(echo $PINFO | cut -d\  -f1 | sed 's/\//_/g')
    PSIZE=$( (df -Ph $PART 2>/dev/null || df -P $PART)| tail -1 | awk '{print $2}')
    PTYPE=$(df -PT $PART | tail -1 | awk '{print $2}')
    PAVAIL=$( (df -Ph $PART 2>/dev/null || df -P $PART)| tail -1 | awk '{print $4}')
    echo "$PNAME.label $PART ($PSIZE)"
    echo "$PNAME.info $PNAME -> $PART $PAVAIL free ($PTYPE)"
    ks=$(echo $PINFO | awk '{print $2}')
    if [ $ks -lt 104857600 ] ; then # FileSystem is less than 100G
      echo "$PNAME.warning 90.0"
      echo "$PNAME.critical 95.0"
    else
      # For more than 100G, the tresholds are based actual storage (not fixed percentage)
      echo "$PNAME.warning $(df_calc_threshold $ks 20)"
      echo "$PNAME.critical $(df_calc_threshold $ks 2)"
    fi      
  done
}
fetch_df() {
  for PART in $(df -P | grep '^/' | sed '/\/[a-z0-9,]*$/!d;s/.* \([a-z0-9,\/]\{1,\}\)$/\1/g')
  do
    df_filter_fs $PART || continue
    PINFO=$(df -P $PART | tail -1);
    PNAME=$(echo $PINFO | cut -d\  -f1 | sed 's/[\/.-]/_/g')
    echo "$PNAME.value" $(echo $PINFO | awk '{ print $3/$2*100 }')
  done
}
