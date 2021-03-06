config_interrupts() {
  echo "graph_title Interrupts and context switches"
  echo "graph_args --base 1000 -l 0"
  echo "graph_vlabel interrupts & ctx switches / \${graph_period}"
  echo "graph_category system"
  echo "graph_info This graph shows the number of interrupts and context switches on the system. These are typically high on a busy system."
  echo "intr.info Interrupts are events that alter sequence of instructions executed by a processor. They can come from either hardware (exceptions, NMI, IRQ) or software."
  echo "ctx.info A context switch occurs when a multitasking operatings system suspends the currently running process, and starts executing another."
  echo "intr.label interrupts"
  echo "ctx.label context switches"
  echo "intr.type DERIVE"
  echo "ctx.type DERIVE"
  echo "intr.max 100000"
  echo "ctx.max 100000"
  echo "intr.min 0"
  echo "ctx.min 0"
}
fetch_interrupts() {
  IINFO=$(cat /proc/stat)
  echo "ctx.value" $(echo "$IINFO" | grep "^ctxt" | cut -d\  -f2)
  echo "intr.value" $(echo "$IINFO" | grep "^intr" | cut -d\  -f2)
}
