README for MuninLite
====================

MuninLite is a single Bourne Shell script that implements the Munin
protocoll as well as some Linux specific plugins. The motivation for
developing MuninLite was to provide a simple Munin Node, using inetd
on systems without a full featured Perl and/or bash or a busybox
system. 

MuninLite is Copyright (C) 2007 Rune Nordbøe Skillingstad
<rune@skillingstad.no> and released under GPLv2 (see [LICENSE](LICENSE) file)

Features
--------

This MuninLite implements the following plugins:

* cpu : CPU usage
* df : Filesystem usage
* entropy : entropy pool size
* forks : forks per second
* if_ : network interface
* if_err_ : network interface errors
* interrupts : interrupts
* irqstats : irq statistics
* load : system load
* memory : memory usage
* netbps : summary network bits per sec
* neterr : summary network errors
* ntpdate : ntp time offset
* proc_pri : process priority
* processes : process state
* sensors : read temperature sensors
* swap : swap in/out
* vgs : volume group stats
* xen : basic Xen VM and memory stats

Work in progress:

* fw_ : Firewall counters (note, needs iptables chains that end in "_counter")
* libvirt_blkbps : virsh block device bytes per sec
* libvirt_blkiops : virsh block device IOps
* libvirt_cpu : virsh vm CPU usage
* libvirt_mem : virsh vm Memory usage
* libvirt_netbps : virsh network bits per sec
* libvirt_netpkts : virsh network packets per sec
* owswitch_ : OpenWRT switch stats
* plugindir_ : load plugins from directory

Included files
--------------

| File | Info
|------|------
|CREDITS.md	|Credits to contributors
|LICENSE	|GPLv2 License
|Makefile	|Rules to make munin-node
|README.md	|This file
|VERSION	|Current version
|munin-node.in	|The MuninLite script skeleton
|listener.lua	|Small lua script to listen for connections and start a program
|plugins	|plugin scripts used to grabbing system data
|examples/xinetd.d/munin 	|Sample xinetd configuration
|examples/inetd.conf		|Sample inetd.conf configuration
|examples/inetd.busybox		|Sample inetd.conf configuration for busybox
|examples/hosts.deny		|Sample hosts.deny configuration
|examples/hosts.allow		|Sample hosts.allow configuration
|doc/*		|Misc documentation (probably outdated)
|_attic_/*	|Old stuff from previous versions
|TODO		|Things to do in future releases

Build requirements
------------------

`Make`	     (Not sure what requirements)

Requirements
------------

Bourne Shell (`ash` or `dash` should be sufficient)

| Command | Info
|------|------
|`grep`	     |(simple grep in busybox is sufficient)
|`sed`	     |(simple sed in busybox is sufficient -- but a bit strange...)
|`cut`	     |(cut in busybox is sufficient)
|`wc`	     |(wc in busybox is sufficient)
|`xargs`     |(xargs in busybox is sufficient)
|`inetd`     |(inetd in busybox is sufficient) or `lua` using `listener.lua`

Installation
------------

Download source and unpack it.

Make munin-node by running `"make"`

```
  # make
  Making munin-node for muninlite version 0.9.14
```

Copy munin-node to a suitable location (`/usr/local/bin/`) and make it
executable.

```
  # cp munin-node /usr/local/bin
  # chmod +x /usr/local/bin/munin-node
```

Add munin port to `/etc/services`

```
  # echo "munin           4949/tcp        lrrd            # Munin" >>/etc/services
```

Configure `inetd` or `xinetd` to fork this script for request on the
munin port (4949). 

Sample configuration for `xinetd` is located in `examples/xinetd.d/munin`

```
  # cp examples/xinetd.d/munin /etc/xinetd.d 
  # killall -HUP xinetd
```

Sample configuration for `inetd` is located in `examples/inetd.conf`

```
  # cat examples/inetd.conf >> /etc/inetd.conf
  # killall -HUP inetd
```

Restrict access to munin port using hosts.allow and
hosts.deny or add a rule to your favorite firewall config.
Examples of `hosts.allow/deny` settings is provided in the examples
directory.

Iptables might be set with something like this:

```
  # iptables -A INPUT -p tcp --dport munin --source 10.42.42.25 -j ACCEPT 
```

Test
----

To test script, just run it (/usr/bin/local/munin-node):

```
  # /usr/local/bin/munin-node
  # munin node at localhost.localdomain
  help
  # Unknown command. Try list, nodes, config, fetch, version or quit
  list
  df cpu if_eth0 if_eth1 if_err_eth0 if_err_eth1 load memory
  version
  munins node on mose.medisin.ntnu.no version: 0.0.5 (munin-lite)
  quit
```

For inetd-test, try to telnet to munin port from allowed host.

```
  # telnet localhost 4949
  Trying 127.0.0.1...
  Connected to localhost.
  Escape character is '^]'.
  # munin node at localhost.localdomain
  help
  # Unknown command. Try list, nodes, config, fetch, version or quit
  list
  df cpu if_eth0 if_eth1 if_err_eth0 if_err_eth1 load memory
  version
  munins node on mose.medisin.ntnu.no version: 0.0.5 (munin-lite)
  quit
  Connection closed by foreign host.
```

Plugin configuration 
--------------------

Create a `/etc/muninlite.conf` with config options.

Specifically the variable `PLUGINS` contains a list of enabled plugins.
Use the functions:

- `is_plugin_enabled` : to check if a specific plugin is enabled
- `remove_plugin` : to remove a plugin from the list
- `add_plugin` : to enable a plugin (this make sure that plugins are not enabled twice)

Otherwise, you can assign `PLUGINS` a space sparated list of plugins to enable.

Munin configuration
-------------------

Configure your `/etc/munin/munin.conf` as you would for a regular
munin-node.

```
[some.host.tld]
    address 10.42.42.25
    use_node_name yes
```

* * *

Discontinued plugins:

* netstat : netstat plugin
  - Unable to make it work with current generation `netstat` replacements.
* uptime : uptime/availability
  - doesn't work as expected

