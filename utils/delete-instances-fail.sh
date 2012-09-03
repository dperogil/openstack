#!/bin/bash
#
#
## Danilo Ferri Perogil [20120903]: Alteracao dos valores de limite de instancias do OpenStack
#
#

NOVA='/etc/init.d/nova-api.sh'



MAIN() {
	mysql -u root -p -e "use nova; delete from instances where vm_state='building'; delete from instances where vm_state='deleted'; delete from instances where task_state='deleting'; delete from instances where vm_state='error';"
	$NOVA restart
}

# Begin
MAIN
