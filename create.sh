#!/bin/bash

#aici vor fi salvate output-urile comenzii ls -lR la diferite momente
mkdir -p snaps

#captura ls si df si salvarea output-ului cu numele generat din timestamp
NAME=$(date +"%Y-%m-%d_%H-%M-%S")
ls -lR > "snaps/$NAME-ls"
df > "snaps/$NAME-df"
clear
echo "Captura efectuata cu succes: ./snaps/$NAME-ls, ./snaps/$NAME-df"

