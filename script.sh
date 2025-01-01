#!/bin/bash

NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
LIGHTGREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'

USERDIR='myfiles'
TSDIR='snaps'
#REPORTSDIR='reports'

mkdir -p $TSDIR

#functie generare typescript
generate_typescript() {
	TSNAME=$1
	TS="$TSDIR/$TSNAME"
	TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

	#comenzile ls si df - argument pentru comanda script
	script -c "ls -l '$USERDIR' ; df" "$TS" > /dev/null

	#facem append continutului fiecarui fisier in typescript-ul nou creat
	for FILE in $(ls -p "$USERDIR" | grep -v /); do
		script -c "cat '$USERDIR/$FILE'" -a "$TS" > /dev/null
	done

	clear
	echo -e "${GREEN}Snapshot generat cu succes!\nLocatie fisier typescript: $TS${CYAN}\n"

}

#compara 2 snapshot-uri
compare_old() {
	TS1="$TSDIR/$1"
	TS2="$TSDIR/$2"
	
	#desfacem fisierele TS
	#awk de la linia de la care incepe ls pana la ultima linie
	#analog pentru df
	#generare raport
	#intrebat user daca vrea sa compare si continutul fisierelor modificate
	
}

#START
clear
while true; do
	echo -e "${CYAN}======== FDUM ========\nFIle&DiskUsageMonitor\n"
	echo "1. Genereaza un nou snapshot (typescript)"
	echo "2. Compara doua snapshot-uri"
	echo "3. Compara un snapshot cu structura actuala"
	echo -e "4. Exit\n"
	read -p "Selectati optiunea: " ID
	case $ID in
        1)
		read -p "Denumirea noului snapshot (typescript): " TSNAME
		generate_typescript "$TSNAME"
		;;
        2)
		clear
		echo -e "Snapshot-uri disponibile:${YELLOW}"
		ls -p "$TSDIR" | grep -v /
		echo -e "${CYAN}"
		read -p "Numele primului snapshot: " S1
		read -p "Numele celui de-al doilea snapshot: " S2
		compare_old "$S1" "$S2"
		;;
		3)
		clear
		echo -e "Snapshot-uri disponibile:${YELLOW}"
		ls -p "$TSDIR" | grep -v /
		echo -e "${CYAN}"
		read -p "Numele snapshot-ului: " S1
		compare_current "$S1"
		;;
        4)
		clear
		exit 0
		;;
        *)
		clear
		echo -e "${RED}Optiune invalida${CYAN}"
		;;
	esac

done
