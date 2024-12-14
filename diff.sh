#!/bin/bash

clear
	
S1=$1
S2=$2
    	
echo "DIFERENTA FISIERE, DIRECTOARE"
diff -u "$S1-ls" "$S2-ls"
# !! IN LUCRU format citibil
# grep, sed

echo -e "\nDIFERENTA SPATIU DISC"
diff -u "$S1-df" "$S2-df"
# !! IN LUCRU format citibil
# grep, sed

