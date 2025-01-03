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
TEMPDIR='temp'
REPORTSDIR='reports'

mkdir -p $TSDIR

# Functie generare typescript
generate_typescript() {
	TSNAME=$1
	TS="$TSDIR/$TSNAME"
	#TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
	# comenzile ls si df - argument pentru comanda script
	COMMANDS="ls -l $USERDIR\ndf\n"

	# facem append continutului fiecarui fisier in typescript-ul nou creat
	for FILE in $(ls -p "$USERDIR" | grep -v /); do
		COMMANDS="${COMMANDS}cat $USERDIR/$FILE\n"
	done

	COMMANDS="${COMMANDS}exit\n"
	echo -e "$COMMANDS" > script_commands
	script "$TS" < script_commands > /dev/null 2>&1
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
	awk "/ls -l $USERDIR/{flag=1; next} /df/ {flag=0} flag" "$TS" > "$ls_output_file"

	# Extragem output-ul comenzii df
	awk '/df/{flag=1; next} /exit/ || /cat/{flag=0} flag' "$TS" > "$df_output_file"

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
	# ordine cronologica
	date1=$(date -r "$TSDIR/$1" "+%s")
	date2=$(date -r "$TSDIR/$2" "+%s")
	if [ "$date1" -ge "$date2" ]; then
		TS1="$TSDIR/$2"
		TS2="$TSDIR/$1"
	else
		TS1="$TSDIR/$1"
		TS2="$TSDIR/$2"
	fi
	TSPDIR1="${TS1}_PARSED"
	TSPDIR2="${TS2}_PARSED"
	parse_typescript "$TS1" "$TSPDIR1"
	parse_typescript "$TS2" "$TSPDIR2"
	TSEFD1="$TSPDIR1/files"
	TSEFD2="$TSPDIR2/files"

	
	ls_diff="$TEMPDIR/ls_diff"
	df_diff="$TEMPDIR/df_diff"
	mkdir -p "$TEMPDIR"

	echo -e "${LCYAN}============ REZULTAT ============\n${NC}Comparatie snapshot ${YELLOW}$1 ${NC}VS ${YELLOW}$2${NC}\n"
	
	date1=$(date -r $TS1 "+%m-%d-%Y %H:%M:%S")
	date2=$(date -r $TS2 "+%m-%d-%Y %H:%M:%S")
	echo -e "Typescript ${YELLOW}$TS1${NC}: generat $date1"
	echo -e "Typescript ${YELLOW}$TS2${NC}: generat $date2\n"
	
	# COMPARATIE STRUCTURA DIRECTOARE SI FISIERE 

	# salvam output-ul comenzii "ls -l" in fisierul temporar ls_diff
	# folosim sed pentru a nu permite lui diff sa compare codurile de escape generate in typescript
	diff -u <(sed 's/\x1B\[[0-9;]*[a-zA-Z]//g' "$TSPDIR1/ls_output") <(sed 's/\x1B\[[0-9;]*[a-zA-Z]//g' "$TSPDIR2/ls_output") | tr -s ' ' > "$ls_diff"
	
	# in checked vom salva fisierele/directoarele parcurse
	checked_files="$TEMPDIR/checked_files"
	checked_dirs="$TEMPDIR/checked_dirs"

	# fisiere / directoare deja existente: apar o singura data in fisier, iar linia incepe cu ' '
	unmodified_files="$TEMPDIR/unmodified_files"
	unmodified_dirs="$TEMPDIR/unmodified_directories"

	# fisiere / directoare deja existente, dar modificate: apar de mai multe ori in fisier
	modified_files="$TEMPDIR/modified_files"
	modified_dirs="$TEMPDIR/modified_dirs"

	# fisiere / directoare adaugate: apar o singura data in fisier, iar linia incepe cu '+'
	added_files="$TEMPDIR/added_files"
	added_dirs="$TEMPDIR/added_dirs"

	# fisiere / directoare sterse: apar o singura data in fisier, iar linia incepe cu '-'
	removed_files="$TEMPDIR/removed_files"
	removed_dirs="$TEMPDIR/removed_dirs"

	#prima data parcurgem fisierul ls_diff pentru a determina care fisiere au fost modificate
	while IFS= read -r line; do
		char0=${line:0:1}
		char1=${line:1:1}
		char3=${line:3:1}
		# Evitam linii de tipul "+++ *" sau "--- *"
		if [[ $char3 != ' ' ]]; then

			# Stergem posibile culori / caractere speciale generate de terminal in typescript-ul original
			color_removal="$TEMPDIR/color_removal"
			echo ${line##*' '} > "$color_removal"

			# Salvam string-ul actualizat in variabila entity
			entity=$(sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g" "$color_removal")

			# Salvam fisierele existente
			if [[ $char0 == ' ' ]]; then
				case $char1 in
					'-')
					echo "$entity">> "$unmodified_files"
					;;
					'd')
					echo "$entity" >> "$unmodified_dirs"
					;;
				esac

			# Verificam restul fisierelor, dar stabilim mai tarziu daca au fost adaugate sau sterse
			# Determinam doar daca fisierele au fost modificate sau nu
			elif [[ $char0 == [+-] ]]; then
				case $char1 in
					'-')
					exists=$(grep "$entity" $checked_files > /dev/null 2>&1)
					if [ $? -ne 0 ]; then 
						echo "$entity" >> "$checked_files"
					else
						echo "$entity" >> "$modified_files"
					fi
					;;
					'd')
					exists=$(grep "$entity" $checked_dirs > /dev/null 2>&1)
					if [ $? -ne 0 ]; then 
						echo "$entity" >> "$checked_dirs"
					else
						echo "$entity" >> "$modified_dirs"
					fi
					;;
				esac
			fi
		fi
	done < "$ls_diff"

	# Partea a 2-a; parcurgem din nou rezultatul ls_diff linie cu linie
	# A ramas sa stabilim care fisiere au fost adaugate si care au fost sterse
	while IFS= read -r line; do
		char0=${line:0:1}
		char1=${line:1:1}
		char3=${line:3:1}
		if [[ $char3 != ' ' ]]; then
			color_removal="$TEMPDIR/color_removal"
			echo ${line##*' '} > "$color_removal"
			entity=$(sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g" "$color_removal")

			case $char0 in
				'+')
				case $char1 in
					'-')
					exists=$(grep "$entity" $modified_files > /dev/null 2>&1)
					if [ $? -ne 0 ]; then 
						echo "$entity" >> "$added_files"
					fi
					;;
					'd')
					exists=$(grep "$entity" $modified_dirs > /dev/null 2>&1)
					if [ $? -ne 0 ]; then 
						echo "$entity" >> "$added_dirs"
					fi
					;;
				esac
				;;
				'-')
				case $char1 in
					'-')
					exists=$(grep "$entity" $modified_files > /dev/null 2>&1)
					if [ $? -ne 0 ]; then 
						echo "$entity" >> "$removed_files"
					fi
					;;
					'd')
					exists=$(grep "$entity" $modified_dirs > /dev/null 2>&1)
					if [ $? -ne 0 ]; then 
						echo "$entity" >> "$removed_dirs"
					fi
					;;
				esac
				;;
			esac
		fi
	done < "$ls_diff"
	
	echo -e "${CYAN}Structura directoare / fisiere:${NC}"

	cat "$added_files" > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "Fisiere adaugate:"
		cat "$added_files"
	fi

	cat "$removed_files" > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "Fisiere sterse:"
		cat "$removed_files"
	fi

	cat "$modified_files" > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "Fisiere modificate:"
		cat "$modified_files"
	fi

	cat "$added_dirs" > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "Directoare adaugate:"
		cat "$added_dirs"
	fi

	cat "$removed_dirs" > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "Directoare sterse:"
		cat "$removed_dirs"
	fi

	cat "$modified_dirs" > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "Directoare modificate:"
		cat "$modified_dirs"
	fi


	# COMPARATIE DF 

	# salvam output-ul comenzii "df" in fisierul temporar df_diff
	# folosim sed pentru a nu permite lui diff sa compare codurile de escape generate in typescript
	diff -u <(sed 's/\x1B\[[0-9;]*[a-zA-Z]//g' "$TSPDIR1/df_output") <(sed 's/\x1B\[[0-9;]*[a-zA-Z]//g' "$TSPDIR2/df_output") | tr -s ' ' > "$df_diff"
	
	checked_mountpoints="$TEMPDIR/checked_mountpoints"
	checked_size_used="$TEMPDIR/checked_size_used"
	unmodified_mountpoints="$TEMPDIR/unmodified_files"
	modified_mountpoints="$TEMPDIR/modified_files" # aici ar trebui sa calculam diferenta in spatiul utilizat
	modified_size_used="$TEMPDIR/modified_size_used" #delta
	added_mountpoints="$TEMPDIR/added_dirs"
	removed_mountpoints="$TEMPDIR/removed_files"

	echo -e "\n${CYAN}Spatiu pe disc:${NC}"

	#prima data parcurgem fisierul df_diff pentru a 
	while IFS= read -r line; do
		char0=${line:0:1}
		char1=${line:1:1}
		# Evitam linii de tipul "+++ *" sau "--- *"
		if [[ $line != +++' '* && $line != ---' '* ]]; then
			revline="$(echo "$line" | rev)"
			mountpoint="$(echo "$revline" | cut -d" " -f1 | rev)"
			if [[ $mountpoint == '/'* ]]; then
				used="$(echo "$revline" | cut -d" " -f4 | rev)"
				
				#salvam un string suplimentar cu mp si sizeused pe aceeasi linie, nu inteleg de ce nu merge fara chestia asta
				string="$(echo "$revline" | cut -d" " -f1,4 | rev)"
				
				# Salvam mountpoint-urile existente
				if [[ $char0 == ' ' ]]; then
					echo "$mountpoint" >> "$unmodified_mountpoints"

				# Verificam restul mountpoint-urilor, dar stabilim mai tarziu daca au existat deja sau daca au fost sterse
				# Determinam doar daca s-a modificat dimensiunea sau nu
				elif [[ $char0 == [+-] ]]; then
					found=0
					while read -r checked_line; do
						if [[ $checked_line == *' '$mountpoint ]]; then
							found=1
						fi
					done < "$checked_mountpoints" > /dev/null 2>&1
					if [ $found -eq 0 ]; then 
						echo $string >> $checked_mountpoints
					else
						echo $mountpoint >> "$modified_mountpoints"
						# facem delta
						while read -r checked_line; do
							if [[ $checked_line == *' '$mountpoint ]]; then
								usedOriginal=$(echo "$checked_line" | awk '{print $1}')
								#echo $used
								#echo $usedOriginal
								delta=$(($used - $usedOriginal))
								echo $mountpoint
								echo "Mountpoint-ul s-a modificat cu $delta KB"
							fi
						done < "$checked_mountpoints" 2> /dev/null

					fi	
				fi
			fi
		fi
	done < "$df_diff"

	# Partea a 2-a; parcurgem din nou rezultatul ls_diff linie cu linie
	# A ramas sa stabilim care fisiere au fost adaugate si care au fost sterse
	while IFS= read -r line; do
		char0=${line:0:1}
		char1=${line:1:1}
		char3=${line:3:1}
		if [[ $char3 != ' ' ]]; then
			color_removal="$TEMPDIR/color_removal"
			echo ${line##*' '} > "$color_removal"
			entity=$(sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g" "$color_removal")

			case $char0 in
				'+')
				case $char1 in
					'-')
					exists=$(grep "$entity" $modified_files > /dev/null 2>&1)
					if [ $? -ne 0 ]; then 
						echo "$entity" >> "$added_files"
					fi
					;;
					'd')
					exists=$(grep "$entity" $modified_dirs > /dev/null 2>&1)
					if [ $? -ne 0 ]; then 
						echo "$entity" >> "$added_dirs"
					fi
					;;
				esac
				;;
				'-')
				case $char1 in
					'-')
					exists=$(grep "$entity" $modified_files > /dev/null 2>&1)
					if [ $? -ne 0 ]; then 
						echo "$entity" >> "$removed_files"
					fi
					;;
					'd')
					exists=$(grep "$entity" $modified_dirs > /dev/null 2>&1)
					if [ $? -ne 0 ]; then 
						echo "$entity" >> "$removed_dirs"
					fi
					;;
				esac
				;;
			esac
		fi
	done < "$df_diff"
	

	read -p "Apasa [ENTER] pentru a continua"
	rm -rf "$TEMPDIR" ; rm -rf "$TSPDIR1" ; rm -rf "$TSPDIR2"
	if [[ "$2" == "tempLiveSnapshot" ]]; then
		rm -f "$TS2"
	fi
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
		compare "$TS1" "$TS2" 2> /dev/null
		;;
		3)
		clear
		echo -e "Snapshot-uri disponibile:${YELLOW}"
		/bin/ls -p "$TSDIR" | grep -v /
		echo -e "${NC}"
		read -p "Numele snapshot-ului: " TS1
		TS2="tempLiveSnapshot"
		generate_typescript "$TS2"
		compare "$TS1" "$TS2" 2> /dev/null
		rm -f "$TSDIR/$TS2"
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