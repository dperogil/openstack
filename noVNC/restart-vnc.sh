#!/bin/bash
#
#
# Danilo Ferri Perogil [20120831]: Script para gerenciamento do WSPROXY do Openstack (VNC Interface)
#
#

OPT="$1"

USAGE() {
	printf "\n$0 start|stop|restart\n\n"
}

START() {
	export PYTHONPATH=/var/lib/nova 
	/var/lib/nova/noVNC/utils/nova-wsproxy.py --flagfile /etc/nova/nova-controller.conf --web . 6080 &
}

STOP() {
	for PID in `ps axwwwwf | grep nova-wsproxy.py | grep -v grep | awk '{print $1}'`; do
		kill -9 "$PID" > /dev/null 2>&1
	done
}

RESTART() {
	STOP
	START
}

MAIN() {
	case "$OPT" in
		start|START) 
			START
		;;
		
		stop|STOP)
			STOP
		;;
		
		restart|RESTART)
			RESTART
		;;
	
		*) 
			USAGE && exit 2
	esac
		
}

# Begin
MAIN
