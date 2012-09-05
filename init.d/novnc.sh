#!/bin/bash
#
#
## Danilo Ferri Perogil [20120831]: Script para gerenciamento do WSPROXY do Openstack (VNC Interface)
#
#

OPT="$1"
DIR='/var/lib/nova/noVNC'
PROCESS='nova-wsproxy.py'
WSPROXY='/var/lib/nova/noVNC/utils/nova-wsproxy.py'
CONF='/etc/nova/nova-controller.conf'

USAGE() {
	printf "\n$0 start|stop|restart\n\n"
}

START() {
	printf "\nStart noVNC Proxy OpenStack..."
	cd "$DIR"
	export PYTHONPATH=/var/lib/nova 
	$WSPROXY --flagfile $CONF --web . 6080 > /dev/null 2>&1 &
	sleep 3
	printf "\nDone.\n\n"
}

STOP() {
	printf "\nStop noVNC Proxy OpenStack..."
	for PID in `ps axwwwwf | grep $PROCESS | grep -v grep | awk '{print $1}'`; do
		kill -9 "$PID" > /dev/null 2>&1
	done
	sleep 3
	printf "\nDone.\n\n"
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
