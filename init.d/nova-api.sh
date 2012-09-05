#!/bin/bash
#
#upstart-job
#
#
## Danilo Ferri Perogil [20120903]: Gerenciamento do processo da API do NOVA
#
#

OPT="$1"
NOVA='/var/lib/nova/bin/nova-api'
CONF='/etc/nova/nova-controller.conf'

STOP() {
	printf "\nStop Nova-API...\n"
	for i in `ps axwwwwwf | grep nova-api | egrep -v "(grep|$0)" | awk '{print $1}'`; do
		kill -9 $i
	done
	sleep 3
	printf "Done.\n\n"
}

START() {
	ps axwwwwwf | grep nova-api | egrep -v "(grep|$0)" > /dev/null
	if [ "$?" -ne 0 ]; then
		printf "\nStart Nova-API...\n"
		"$NOVA" --flagfile="$CONF" > /dev/null 2>&1 &
		sleep 3
		printf "Done.\n\n"
	else
		printf "\nNova AP ja foi iniciada\n\n"
	fi
}

RESTART() {
	printf "\nRestart Nova-API...\n"
	STOP
	START
}

USAGE() {
	printf "\n./$0 (start|stop|restart)\n\n"
}

MAIN() {
	[ -z "$OPT" ] && USAGE && exit 0

	case $OPT in
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
			USAGE
		;;
	esac
}

# Begin 
MAIN
