#!/bin/bash

#START
clear
while true; do
	echo -e "\n====== FDUM ======"
	echo "1. Creeaza snapshot"
	echo "2. Compara doua snapshot-uri"
	echo "3. Exit"
	read -p "Selectati optiunea: " ID
	case $ID in
        1)
		./create.sh
		;;
        2)
		clear
		echo "(!! IN LUCRU)Alegeti o captura din lista:"
		ls ./snaps
		read -p "Numele primului snapshot (doar timestamp): " S1
		read -p "Numele celui de-al doilea snapshot (doar timestamp): " S2
		./diff.sh "./snaps/$S1" "./snaps/$S2"
		;;
        3)
		clear
		exit 0
		;;
        *)
		clear
		echo "Optiune invalida"
		;;
	esac

done
