#!/bin/sh

config_entropy() {
  cat <<-_EOF_
	graph_title Available entropy
	graph_args --base 1000 -l 0
	graph_vlabel entropy (bytes)
	graph_scale no
	graph_category system
	graph_info This graph shows the amount of entropy available in the system.
	entropy.label entropy
	entropy.info The number of random bytes available. This is typically used by cryptographic applications.
	_EOF_
}

fetch_entropy() {
  echo "entropy.value $(cat /proc/sys/kernel/random/entropy_avail)"
}
