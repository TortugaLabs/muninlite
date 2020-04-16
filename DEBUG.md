# DEBUG mode

You can enable debug mode in your `/etc/muninlite.conf` file.
Add the line:

- `debug` [options] _path_

Where options is one of the following:

- --dir|-d: _path_ is a directory and conversations will be placed
  in separate files in that directory.
- --file|-f: _path_ is a file and conversations will be appended to it.
- --rotate=_n_|-r _n_: Will keep the logs up to _n_ lines (for `file`
  mode) or _n_ files (in `dir` mode).

Example:

```
debug --rotate=60 --dir /var/log/munin-node.runs
```
