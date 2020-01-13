#!/bin/sh
# -*- sh -*-


config_proc_pri() {
  echo 'graph_title Processes priority'
  echo 'graph_order low high locked'
  echo 'graph_category processes'
  echo 'graph_info This graph shows number of processes at each priority'
  echo 'graph_args --base 1000 -l 0'
  echo 'graph_vlabel Number of processes'

  echo 'low.label low priority'
  echo 'low.draw AREA'
  echo 'low.info The number of low-priority processes (tasks)'

  echo 'high.label high priority'
  echo 'high.draw STACK'
  echo 'high.info The number of high-priority processes (tasks)'

  echo 'locked.label locked in memory'
  echo 'locked.draw STACK'
  echo 'locked.info The number of processes that have pages locked into memory (for real-time and custom IO)'  

  echo "processes.label total"
  echo "processes.draw LINE1"
  echo "processes.info The total number of processes."
}


fetch_proc_pri() {
  ps -eo stat | awk '
	/STAT/ { next; }
	{ processes++; }
	/L/ { stat["L"]++; next }
	/N/ { stat["N"]++; next }
	/</ { stat["<"]++; next }

	END {
	print "processes.value "        0+processes;
	print "low.value "         0+stat["N"];
	print "high.value "         0+stat["<"];
	print "locked.value "  0+stat["L"];
	}'
}


: << =cut

=head1 NAME

proc_pri - Munin-plugin to monitor the processes priority on a Linux
machine

=head1 CONFIGURATION

No configuration

=head1 AUTHOR

Lars Strand

=head1 LICENSE

GNU GPL

=head1 MAGIC MARKERS

 #%# family=auto
 #%# capabilities=autoconf

=cut
