config_memory() {
  MINFO=$(cat /proc/meminfo | sed 's/ \{1,\}/ /g;') || :
  MEMTOTAL=$(echo "$MINFO" | grep "^MemTotal:" | cut -d\  -f2) || :
  PAGETABLES=$(echo "$MINFO" | grep "^PageTables:" | cut -d\  -f2) || :
  SWAPCACHED=$(echo "$MINFO" | grep "^SwapCached:" | cut -d\  -f2) || :
  SWAPTOTAL=$(echo "$MINFO" | grep "^SwapTotal:" | cut -d\  -f2) || :
  VMALLOCUSED=$(echo "$MINFO" | grep "^VmallocUsed:" | cut -d\  -f2) || :
  SLAB=$(echo "$MINFO" | grep "^Slab:" | cut -d\  -f2) || :
  MAPPED=$(echo "$MINFO" | grep "^Mapped:" | cut -d\  -f2) || :
  COMMITTEDAS=$(echo "$MINFO" | grep "^Committed_AS:" | cut -d\  -f2) || :
  ACTIVE=$(echo "$MINFO" | grep "^Active:" | cut -d\  -f2) || :
  INACTIVE=$(echo "$MINFO" | grep "^Inactive:" | cut -d\  -f2) || :
  ACTIVEANON=$(echo "$MINFO" | grep "^ActiveAnon:" | cut -d\  -f2) || :
  ACTIVECACHE=$(echo "$MINFO" | grep "^ActiveCache:" | cut -d\  -f2) || :
  INACTIVE=$(echo "$MINFO" | grep "^Inactive:" | cut -d\  -f2) || :
  INACTDIRTY=$(echo "$MINFO" | grep "^Inact_dirty:" | cut -d\  -f2) || :
  INACTLAUNDRY=$(echo "$MINFO" | grep "^Inact_laundry:" | cut -d\  -f2) || :
  INACTCLEAN=$(echo "$MINFO" | grep "^Inact_clean:" | cut -d\  -f2) || :

  GRAPH_ORDER="apps";
  test "$PAGETABLES" != "" && GRAPH_ORDER="$GRAPH_ORDER page_tables"
  test "$SWAPCACHED" != "" && GRAPH_ORDER="$GRAPH_ORDER swap_cache"
  test "$VMALLOCUSED" != "" && GRAPH_ORDER="$GRAPH_ORDER vmalloc_used"
  test "$SLAB" != "" && GRAPH_ORDER="$GRAPH_ORDER slab"
  GRAPH_ORDER="$GRAPH_ORDER cached buffers free swap"

  echo "graph_args --base 1024 -l 0 --vertical-label Bytes --upper-limit $MEMTOTAL"
  echo "graph_title Memory usage"
  echo "graph_category system"
  echo "graph_info This graph shows what the machine uses its memory for."
  echo "graph_order $GRAPH_ORDER"
  echo "apps.label apps"
  echo "apps.draw AREA"
  echo "apps.info Memory used by user-space applications."
  echo "buffers.label buffers"
  echo "buffers.draw STACK"
  echo "buffers.info Block device (e.g. harddisk) cache. Also where \"dirty\" blocks are stored until written."
  echo "swap.label swap"
  echo "swap.draw STACK"
  echo "swap.info Swap space used."
  echo "cached.label cache"
  echo "cached.draw STACK"
  echo "cached.info Parked file data (file content) cache."
  echo "free.label unused"
  echo "free.draw STACK"
  echo "free.info Wasted memory. Memory that is not used for anything at all."
  if [ "$SLAB" != "" ]; then
    echo "slab.label slab_cache"
    echo "slab.draw STACK"
    echo "slab.info Memory used by the kernel (major users are caches like inode, dentry, etc)."
  fi
  if [ "$SWAPCACHED" != "" ]; then
    echo "swap_cache.label swap_cache"
    echo "swap_cache.draw STACK"
    echo "swap_cache.info A piece of memory that keeps track of pages that have been fetched from swap but not yet been modified."
  fi
  if [ "$PAGETABLES" != "" ]; then
    echo "page_tables.label page_tables"
    echo "page_tables.draw STACK"
    echo "page_tables.info Memory used to map between virtual and physical memory addresses.\n"
  fi
  if [ "$VMALLOCUSED" != "" ]; then
    echo "vmalloc_used.label vmalloc_used"
    echo "vmalloc_used.draw STACK"
    echo "vmalloc_used.info Virtual memory used by the kernel (used when the memory does not have to be physically contigious)."
  fi
  if [ "$COMMITTEDAS" != "" ]; then
    echo "committed.label committed"
    echo "committed.draw LINE2"
    echo "committed.warn" $(($SWAPTOTAL + $MEMTOTAL))
    echo "committed.info The amount of memory that would be used if all the memory that's been allocated were to be used."
  fi
  if [ "$MAPPED" != "" ]; then
    echo "mapped.label mapped"
    echo "mapped.draw LINE2"
    echo "mapped.info All mmap()ed pages."
  fi
  if [ "$ACTIVE" != "" ]; then
    echo "active.label active"
    echo "active.draw LINE2"
    echo "active.info Memory recently used. Not reclaimed unless absolutely necessary."
  fi
  if [ "$ACTIVEANON" != "" ]; then
    echo "active_anon.label active_anon"
    echo "active_anon.draw LINE1"
  fi
  if [ "$ACTIVECACHE" != "" ]; then
    echo "active_cache.label active_cache"
    echo "active_cache.draw LINE1"
  fi
  if [ "$INACTIVE" != "" ]; then
    echo "inactive.label inactive"
    echo "inactive.draw LINE2"
    echo "inactive.info Memory not currently used."
  fi
  if [ "$INACTDIRTY" != "" ]; then
    echo "inact_dirty.label inactive_dirty"
    echo "inact_dirty.draw LINE1"
    echo "inact_dirty.info Memory not currently used, but in need of being written to disk."
  fi
  if [ "$INACTLAUNDRY" != "" ]; then
    echo "inact_laundry.label inactive_laundry"
    echo "inact_laundry.draw LINE1"
  fi
  if [ "$INACTCLEAN" != "" ]; then
    echo "inact_clean.label inactive_clean"
    echo "inact_clean.draw LINE1"
    echo "inact_clean.info Memory not currently used."
  fi
}
fetch_memory() {
  MINFO=$(cat /proc/meminfo | sed 's/ \{1,\}/ /g;') || :
  MEMTOTAL=$(echo "$MINFO" | grep "^MemTotal:" | cut -d\  -f2) || :
  MEMFREE=$(echo "$MINFO" | grep "^MemFree:" | cut -d\  -f2) || :
  BUFFERS=$(echo "$MINFO" | grep "^Buffers:" | cut -d\  -f2) || :
  CACHED=$(echo "$MINFO" | grep "^Cached:" | cut -d\  -f2) || :
  SWAP_TOTAL=$(echo "$MINFO" | grep "^SwapTotal:" | cut -d\  -f2) || :
  SWAP_FREE=$(echo "$MINFO" | grep "^SwapFree:" | cut -d\  -f2) || :
  MEMTOTAL=$(echo "$MINFO" | grep "^MemTotal:" | cut -d\  -f2) || :
  PAGETABLES=$(echo "$MINFO" | grep "^PageTables:" | cut -d\  -f2) || :
  SWAPCACHED=$(echo "$MINFO" | grep "^SwapCached:" | cut -d\  -f2) || :
  VMALLOCUSED=$(echo "$MINFO" | grep "^VmallocUsed:" | cut -d\  -f2) || :
  SLAB=$(echo "$MINFO" | grep "^Slab:" | cut -d\  -f2) || :
  MAPPED=$(echo "$MINFO" | grep "^Mapped:" | cut -d\  -f2) || :
  COMMITTEDAS=$(echo "$MINFO" | grep "^Committed_AS:" | cut -d\  -f2) || :
  ACTIVE=$(echo "$MINFO" | grep "^Active:" | cut -d\  -f2) || :
  INACTIVE=$(echo "$MINFO" | grep "^Inactive:" | cut -d\  -f2) || :
  ACTIVEANON=$(echo "$MINFO" | grep "^ActiveAnon:" | cut -d\  -f2) || :
  ACTIVECACHE=$(echo "$MINFO" | grep "^ActiveCache:" | cut -d\  -f2) || :
  INACTIVE=$(echo "$MINFO" | grep "^Inactive:" | cut -d\  -f2) || :
  INACTDIRTY=$(echo "$MINFO" | grep "^Inact_dirty:" | cut -d\  -f2) || :
  INACTLAUNDRY=$(echo "$MINFO" | grep "^Inact_laundry:" | cut -d\  -f2) || :
  INACTCLEAN=$(echo "$MINFO" | grep "^Inact_clean:" | cut -d\  -f2) || :
  APPS=$(($MEMTOTAL - $MEMFREE - $BUFFERS - $CACHED))
  SWAP=$(($SWAP_TOTAL - $SWAP_FREE))
  echo "buffers.value" $(($BUFFERS * 1024))
  echo "swap.value" $(($SWAP * 1024))
  echo "cached.value" $(($CACHED * 1024))
  echo "free.value" $(($MEMFREE * 1024))
  if [ "$SLAB" != "" ]; then
    echo "slab.value" $(($SLAB * 1024))
    APPS=$(($APPS - $SLAB))
  fi
  if [ "$SWAPCACHED" != "" ]; then
    echo "swap_cache.value" $(($SWAPCACHED * 1024))
    APPS=$(($APPS - $SWAPCACHED))
  fi
  if [ "$PAGETABLES" != "" ]; then
    echo "page_tables.value" $(($PAGETABLES * 1024))
    APPS=$(($APPS - $PAGETABLES))
  fi
  if [ "$VMALLOCUSED" != "" ]; then
    echo "vmalloc_used.value" $(($VMALLOCUSED * 1024))
    APPS=$(($APPS - $VMALLOCUSED))
  fi
  if [ "$COMMITTEDAS" != "" ]; then
    echo "committed.value" $(($COMMITTEDAS * 1024))
  fi
  if [ "$MAPPED" != "" ]; then
    echo "mapped.value" $(($MAPPED * 1024))
  fi
  if [ "$ACTIVE" != "" ]; then
    echo "active.value" $(($ACTIVE * 1024))
  fi
  if [ "$ACTIVEANON" != "" ]; then
    echo "active_anon.value" $(($ACTIVEANON * 1024))
  fi
  if [ "$ACTIVECACHE" != "" ]; then
    echo "active_cache.value" $(($ACTIVECACHE * 1024))
  fi
  if [ "$INACTIVE" != "" ]; then
    echo "inactive.value" $(($INACTIVE * 1024))
  fi
  if [ "$INACTDIRTY" != "" ]; then
    echo "inact_dirty.value" $(($INACTDIRTY * 1024))
  fi
  if [ "$INACTLAUNDRY" != "" ]; then
    echo "inact_laundry.value" $(($INACTLAUNDRY * 1024))
  fi
  if [ "$INACTCLEAN" != "" ]; then
    echo "inact_clean.value" $(($INACTCLEAN * 1024))
  fi

  echo "apps.value" $(($APPS * 1024))
}
