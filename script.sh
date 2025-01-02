#!/bin/bash

NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
LIGHTGREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
LCYAN='\033[1;36m'

USERDIR='myfiles'
TSDIR='snaps'
REPORTSDIR='reports'

mkdir -p $TSDIR

# Functie generare typescript
generate_typescript() {
	TSNAME=$1
	TS="$TSDIR/$TSNAME"
	TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
	# comenzile ls si df - argument pentru comanda script
	COMMANDS="ls -l $USERDIR\ndf\n"

	# facem append continutului fiecarui fisier in typescript-ul nou creat
	for FILE in $(ls -p "$USERDIR" | grep -v /); do
		COMMANDS="${COMMANDS}cat $USERDIR/$FILE\n"
	done

	COMMANDS="${COMMANDS}exit\n"
	echo -e "$COMMANDS" > script_commands
	script "$TS" < script_commands > /dev/null
	echo -e "\n${GREEN}Snapshot generat cu succes!\nLocatie fisier typescript: $TS${NC}\n"
	rm script_commands
	read -p "Apasa [ENTER] pentru a continua"
	clear

}

parse_typescript() {
	TS="$1"
	TSPARSEDIR="$2"

	mkdir -p "$TSPARSEDIR"
	ls_output_file="$TSPARSEDIR/ls_output"
	df_output_file="$TSPARSEDIR/df_output"


	# Extract output-ul comenzii ls -l
	awk "/ls -l $USERDIR/{flag=1; next} /df/{flag=0} flag" "$TS" > "$ls_output_file"

	# Extragem output-ul comenzii df
	awk "/df/{flag=1; next} /cat/{flag=0} flag" "$TS" > "$df_output_file"

	# Extracted files directory
	TSEFD="$TSPARSEDIR/files"
	mkdir -p "$TSEFD"
	# Extragem outputul comenzilor cat
	awk '
	/cat '$USERDIR'\// {
		# Inchide fisierul de output
		if (outfile) close(outfile)

		# Extrage filename fara prefix
		split($0, arr, "/")
		outfile = arr[length(arr)]

		# Sterge \r$ din filename
		sub(/\r$/, "", outfile)
		outfile = "'$TSEFD'" "/" outfile
		next
	}
	/exit/ || /cat '$USERDIR'\// {
		# Opreste scrierea cand ajunge la urmatoarea comanda (cat sau exit)
		outfile = ""
		next
	}
	{
		# Actualizeaza fisierul curent
		if (outfile) {
			sub(/\r$/, "")  # Remove carriage returns from content
			print > outfile
		}
	}
	' "$TS"
}

# Compara 2 snapshot-uri
compare() {
	#mkdir -p "$REPORTSDIR"
	TS1="$TSDIR/$1"
	TS2="$TSDIR/$2"
	TSPDIR1="${TS1}_PARSED"
	TSPDIR2="${TS2}_PARSED"
	parse_typescript "$TS1" "$TSPDIR1"
	parse_typescript "$TS2" "$TSPDIR2"
	TSEFD1="$TSPDIR1/files"
	TSEFD2="$TSPDIR2/files"
	echo -e "${LCYAN}============ REZULTAT ============\n${NC}Comparatie snapshot ${YELLOW}$1 ${NC}VS ${YELLOW}$2${NC}\n"
	echo -e "${CYAN}Structura directoare / fisiere:${NC}"
	diff "$TSPDIR1/ls_output" "$TSPDIR2/ls_output"

	echo -e "\n${CYAN}Spatiu pe disc:${NC}"
	diff "$TSPDIR1/df_output" "$TSPDIR2/df_output"

	
	read -p "Apasa [ENTER] pentru a continua"
	clear
}

# START
clear
while true; do
	echo -e "${LCYAN}============== FDUM ==============\n${NC}FIle&DiskUsageMonitor - Main Menu\n"
	echo "1. Genereaza un nou snapshot (typescript)"
	echo "2. Compara doua snapshot-uri"
	echo "3. Compara un snapshot cu structura actuala"
	echo -e "4. Exit\n"
	read -p "Selectati optiunea: " ID
	case $ID in
        1)
		echo ""
		read -p "Denumirea noului snapshot (typescript): " TSNAME
		generate_typescript "$TSNAME"
		;;
        2)
		clear
		echo -e "Snapshot-uri disponibile:${YELLOW}"
		/bin/ls -p "$TSDIR" | grep -v /
		echo -e "${NC}"
		read -p "Numele primului snapshot: " TS1
		read -p "Numele celui de-al doilea snapshot: " TS2
		clear
		compare "$TS1" "$TS2"
		;;
		3)
		clear
		echo -e "Snapshot-uri disponibile:${YELLOW}"
		/bin/ls -p "$TSDIR" | grep -v /
		echo -e "${NC}"
		read -p "Numele snapshot-ului: " TS1
		TS2="tempLiveSnapshot"
		generate_typescript "$TS2"
		compare "$TS1" "$TS2" 
		;;
        4)
		clear
		exit 0
		;;
        *)
		clear
		echo -e "${RED}Optiune invalida${NC}"
		;;
	esac

done

	


