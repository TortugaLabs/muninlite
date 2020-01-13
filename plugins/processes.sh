#!/bin/sh

# TODO
# display nice and pri process counts

config_processes() {
  # Define colours
  local RUNNABLE='22ff22'         # Green
  local SLEEPING='0022ff'         # Blue
  local STOPPED='cc0000'          # Darker red
  local ZOMBIE='990000'           # Darkest red
  local UNINTERRUPTIBLE='ffa500'  # Orange
  local IDLE='4169e1'             # Royal blue
  local PAGING='00aaaa'           # Darker turquoise
  local INTERRUPT='ff00ff'        # Fuchsia
  local LOCK='ff3333'             # Lighter red
  local RUNNING='00ff7f'          # Spring green
  local DEAD='ff0000'             # Red
  local SUSPENDED='ff1493'        # Deep pink
  local TOTAL='c0c0c0'            # Silver

  echo "graph_title Processes"
  echo "graph_args --base 1000 -l 0 "
  echo "graph_vlabel number of processes"
  echo "graph_category processes"
  echo "graph_info This graph shows the number of processes in the system."

  #~ echo "nprocesses.label processes"
  #~ echo "nprocesses.draw LINE2"
  #~ echo "nprocesses.info The current number of processes."
  #~ echo "nprocesses.colour 000000"

  echo "graph_order nprocesses sleeping stopped zombie dead paging uninterruptible runnable processes"

  echo "sleeping.label sleeping"
  echo "sleeping.draw AREA"
  echo "sleeping.colour $SLEEPING"
  echo "sleeping.info The number of sleeping processes."

  echo "stopped.label stopped"
  echo "stopped.draw STACK"
  echo "stopped.colour $STOPPED"
  echo "stopped.info The number of stopped or traced processes."

  echo "zombie.label zombie"
  echo "zombie.draw STACK"
  echo "zombie.colour $ZOMBIE"
  echo "zombie.info The number of defunct ('zombie') processes (process terminated and parent not waiting)."

  echo "dead.label dead"
  echo "dead.draw STACK"
  echo "dead.colour $DEAD"
  echo "dead.info The number of dead processes."

  echo "paging.label paging"
  echo "paging.draw STACK"
  echo "paging.colour $PAGING"
  echo "paging.info The number of paging processes (<2.6 kernels only)."

  echo "uninterruptible.label uninterruptible"
  echo "uninterruptible.draw STACK"
  echo "uninterruptible.colour $UNINTERRUPTIBLE"
  echo "uninterruptible.info The number of uninterruptible processes (usually IO)."


  echo "runnable.label runnable"
  echo "runnable.draw STACK"
  echo "runnable.colour $RUNNABLE"
  echo "runnable.info The number of runnable processes (on the run queue)."


  echo "processes.label total"
  echo "processes.draw LINE1"
  echo "processes.colour $TOTAL"
  echo "processes.info The total number of processes."

}
fetch_processes() {
  #~ echo "nprocesses.value" $(echo /proc/[0-9]* | wc -w)

  # Additional from munin plugin
  ps -eo stat | awk '
	/STAT/ { next; }
	{ processes++; }
	/N/ { stat["N"]++ }
	/</ { stat["<"]++ }
	/D/ { stat["D"]++ ; next }
	/R/ { stat["R"]++ ; next }
	/S/ { stat["S"]++ ; next }
	/T/ { stat["T"]++ ; next }
	/W/ { stat["W"]++ ; next }
	/X/ { stat["X"]++ ; next }
	/Z/ { stat["Z"]++ ; next }

	END {
	print "processes.value "        0+processes;
	print "uninterruptible.value "  0+stat["D"];
	print "runnable.value "         0+stat["R"];
	print "sleeping.value "         0+stat["S"];
	print "stopped.value "          0+stat["T"];
	print "paging.value "           0+stat["W"];
	print "dead.value "             0+stat["X"];
	print "zombie.value "           0+stat["Z"];
	}'
	#echo "graph_order nprocesses sleeping stopped zombie dead paging uninterruptible runnable processes"
}


# -*- sh -*-

: << =cut

=head1 NAME

processes - Plugin to monitor processes and process states.

=head1 ABOUT

This plugin requires munin-server version 1.2.5 or 1.3.3 (or higher).

This plugin is backwards compatible with the old processes-plugins found on
SunOS, Linux and *BSD (i.e. the history is preserved).

All fields have colours associated with them which reflect the type of process
(sleeping/idle = blue, running = green, stopped/zombie/dead = red, etc.)

=head1 CONFIGURATION

No configuration for this plugin.

=head1 AUTHOR

Copyright (C) 2006 Lars Strand

=head1 LICENSE

GNU General Public License, version 2

=begin comment

This file is part of Munin.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; version 2 dated June, 1991.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 51 Franklin
Street, Fifth Floor, Boston, MA 02110-1301 USA.

=end comment

=head1 MAGIC MARKERS

=begin comment

These magic markers are used by munin-node-configure when installing
munin-node.

=end comment

 #%# family=auto
 #%# capabilities=autoconf

=cut




# Taken from ps(1)
# R - Linux, SunOS, FreeBSD, OpenBSD, NetBSD, OSX, HP-UX      (runable)
# S - Linux, SunOS, FreeBSD*, OpenBSD*, NetBSD*, OSX*, HP-UX  (sleeping)
# T - Linux, SunOS, FreeBSD, OpenBSD, NetBSD, OSX, HP-UX      (stopped)
# Z - Linux, SunOS, FreeBSD, OpenBSD, NetBSD, OSX, HP-UX      (zombie/terminated)
# D - Linux, FreeBSD, OpenBSD, NetBSD                         (uninterruptible)
# I - FreeBSD, OpenBSD, NetBSD, OSX, HP-UX                    (idle/intermediate)
# W - Linux*, FreeBSD*, HP-UX                                 (paging/interrupt/waiting)
# L - FreeBSD                                                 (lock)
# O - SunOS                                                   (running)
# X - Linux, HP-UX*                                           (dead)
# U - OSX, NetBSD*                                            (uninterruptible/suspended)
# 0 - HP-UX                                                   (nonexistent)
# *) Differ meaning


