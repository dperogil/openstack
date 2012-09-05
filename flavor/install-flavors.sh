#!/bin/bash
#
#
## Danilo Ferri Perogil [20120831]: Script para criacao automatica dos Flavors na plataforma
#
#

# Variaveis
TMP_FLAVOR='/tmp/flavors.txt'
NOVA='/var/lib/nova/bin/nova-manage'
LAST_ID=`nova flavor-list | tail -n2 | egrep '[0-9]' | awk '{print $2}'`


# Variavel que define o nome e o tamanho de cada flavor, separado por | (nome, memoria, vcpu e disco)
#FLAVORS='xg.3-flavor 65536 32 200 | xg.3-flavor-nodisc 65536 32 0 | xg.2-flavor 32768 64 200 | xg.2-flavor-nodisc 32768 64 0 | xg.1-flavor 65536 64 200 | xg.1-flavor-nodisc 65536 64 0 | x4.flavor 32768 16 200 | x4.flavor-nodisc 32768 16 0 | x3.flavor 16384 32 200 | x3.flavor-nodisc 16384 32 0 | x2.flavor 32768 32 200 | x2.flavor-nodisc 32768 32 0 | x1.flavor 16384 16 200 | x1.flavor-nodisc 16384 16 0 | m4.flavor 8192 4 100 | m4.flavor-nodisc 8192 4 0 | m3.flavor 4096 8 100 | m3.flavor-nodisc 4096 8 0 | m2.flavor 8192 8 100 | m2.flavor-nodisc 8192 8 0 | m1.flavor 4096 4 100 | m1.flavor-nodisc 4096 4 0 | s4.flavor 4096 2 50 | s4.flavor-nodisc 4096 2 0 | s3.flavor 2048 4 50 | s3.flavor-nodisc 2048 4 0 | s2.flavor 2048 2 50 | s2.flavor-nodisc 2048 2 0 | s1.flavor 1024 1 50 | s1.flavor-nodisc 1024 1 0'

FLAVORS='s1.flavor-nodisc 1024 1 0 | s1.flavor 1024 1 50 | s2.flavor-nodisc 2048 2 0 | s2.flavor 2048 2 50 | s3.flavor-nodisc 2048 4 0 | s3.flavor 2048 4 50 | s4.flavor-nodisc 4096 2 0 | s4.flavor 4096 2 50 | m1.flavor-nodisc 4096 4 0 | m1.flavor 4096 4 100 | m2.flavor-nodisc 8192 8 0 | m2.flavor 8192 8 100 | m3.flavor-nodisc 4096 8 0 | m3.flavor 4096 8 100 | m4.flavor-nodisc 8192 4 0 | m4.flavor 8192 4 100 | x1.flavor-nodisc 16384 16 0 | x1.flavor 16384 16 200 | x2.flavor-nodisc 32768 32 0 | x2.flavor 32768 32 200 | x3.flavor-nodisc 16384 32 0 | x3.flavor 16384 32 200 | x4.flavor-nodisc 32768 16 0 | x4.flavor 32768 16 200 | xg.1-flavor-nodisc 65536 64 0 | xg.1-flavor 65536 64 200 | xg.2-flavor-nodisc 32768 64 0 | xg.2-flavor 32768 64 200 | xg.3-flavor-nodisc 65536 32 0 | xg.3-flavor 65536 32 200'


# Funcao para incluir os flavors definido na variavel
ADD_FLAVOR() {
	
	# Somando o ultimo ID em uso
	local ID=$(($LAST_ID+1))

	printf "\n\nCriando Flavors....\n\n"

	# For para cadastro dos flavors
	for i in `seq 1 100`; do
		FLAVOR=`echo "$FLAVORS" | awk -F '|' '{print '$"$i"'}'`
		NAME=`echo "$FLAVOR" | awk '{print $1}'`
		MEM=`echo "$FLAVOR" | awk '{print $2}'`
		CPU=`echo "$FLAVOR" | awk '{print $3}'`
		DISK=`echo "$FLAVOR" | awk '{print $4}'`
		
		[ -z "$FLAVOR" ] && exit 0

		# Trava para nao cadastrar mais de uma vez
		TMP_FLAVOR=$($NOVA list | grep "FLAVOR" | awk '{print $4}' | grep -v Name | xargs)
		if [ "$?" -eq "0" ]; then
			echo "$TMP_FLAVOR" | grep -x "$FLAVOR"
			if [ "$?" -eq 0 ]; then
				printf "\n\nFlavor ja existe, nao sera cadastrado novamente\n\n"
			else
				$NOVA flavor create --name="$NAME" --memory="$MEM" --cpu="$CPU" --local_gb="$DISK" --flavor=$ID --swap=0 --rxtx_quota=0 --rxtx_cap=0
				ID=$(($ID+1))
			fi
		fi
	done
}

DEL_FLAVOR() {
	#Deletar todos os flavors que nao estao em uso
	for i in `$NOVA flavor-list | awk '{print $4}' | grep -v Name | xargs`; do
	        # Verifica se o flavor esta em uso
	        euca-describe-instances | grep $i > /dev/null 2>&1
	        if [ "$?" -eq "0" ]; then
	                FLAVOR=$(euca-describe-instances | grep INSTANCE | awk '{print $11}')
	                echo $FLAVOR | grep -x $i > /dev/null 2>&1
	                if [ "$?" -eq 0 ]; then
	                        printf "\nInstancia $i em USO, nao sera deletada!!\n\n"
	                else
	                        $NOVA_MANAGE instance_type delete $i --purge
	                fi
	        else
	                $NOVA_MANAGE instance_type delete $i --purge
	        fi
	done
}

# Begin
DEL_FLAVOR
ADD_FLAVOR
