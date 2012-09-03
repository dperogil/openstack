#!/bin/bash
#
#
## Danilo Ferri Perogil [20120903]: Script para verificar nos logs gerados pelo trace do nova o espaco no disco local (nao no volume) esta acabando. 
#
#

# Variaveis de interacao com o nagios, no cadastro do check no nagios definir !60!100 ou qualquer valor
DISK_ALERT_CRITICAL="$1"
DISK_ALERT_WARNING="$2"
NOW=$(date +%d)

CHECK() {

	# Variaveis de ambiente
	LOG='/var/log/nova/nova-scheduler.log'
	DISK_AVALIABLE=$(egrep -i '(Total disk space)' $LOG | tail -n1 | awk -F "Total disk space =" '{print $2}' | awk '{print $1}')
	DISK_USAGE=$(egrep -i '(Total VM disk space)' $LOG | tail -n1 | awk -F "Total VM disk space =" '{print $2}' | awk '{print $1}')
	COUNT=$(($DISK_AVALIABLE-$DISK_USAGE))
	DATE=$(egrep -i '(Total disk space)' /var/log/nova/nova-scheduler.log | tail -n1 | awk '{print $1}' | awk -F '-' '{print $3}' | xargs)

	if [ "$DATE" -eq "$NOW" ]; then
		if [ "$COUNT" -le "0" ]; then
			printf "Estouro de disco do NOVA, sem chance de criar instancias!!\n"
			exit 0
		elif [ "$COUNT" -le "$DISK_ALERT_CRITICAL" ] ; then
			printf "Espaco em disco menor que: $COUNT GB\n"
			exit 0
		elif [ "$COUNT" -le "$DISK_ALERT_WARNING" ]; then
			printf "Espaco em disco menor que: $COUNT GB\n"
			exit 1
		fi
	fi
}

USAGE() {
	printf "\nUsage: ./$0 valor_critical valor_warning\n\n"
}


MAIN() {
	[ -z "$DISK_ALERT_CRITICAL" ] && USAGE && exit 0
	[ -z "$DISK_ALERT_WARNING" ] && USAGE && exit 0
	CHECK
}

# Begin
MAIN
