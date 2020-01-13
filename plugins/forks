#!/bin/sh
config_forks() {
	echo 'graph_title Fork rate'
	echo 'graph_args --base 1000 -l 0 '
	# shellcheck disable=SC2016
	echo 'graph_vlabel forks / ${graph_period}'
	echo 'graph_category processes'
	echo 'graph_info This graph shows the number of forks (new processes started) per second.'
	echo 'forks.label forks'
	echo 'forks.type DERIVE'
	echo 'forks.min 0'
	echo 'forks.max 100000'
	echo 'forks.info The number of forks per second.'  
}

fetch_forks() {
  echo -n "forks.value "
  awk '/processes/ {print $2}' /proc/stat
}


# -*- sh -*-

: << =cut

=head1 NAME

forks -Plugin to monitor the number of forks per second on the machine

=head1 CONFIGURATION

No configuration

=head1 AUTHOR

Unknown author

=head1 LICENSE

GPLv2

=head1 MAGICK MARKERS

 #%# family=auto
 #%# capabilities=autoconf

=cut

