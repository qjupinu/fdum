# FDUM
File&amp;DiskUsageMonitor

Update Jan 6 2025

## Descriere

FDUM are ca scop monitorizarea atat a structurii de fisiere si directoare relevante pentru utilizator, cat si a utilizarii spatiului pe disc, prin interpretarea sesiunii de lucru (terminal) a utilizatorului.

Programul este capabil sa genereze si sa parseze automat fisiere typescript (create prin comanda script), pe care le stocheaza sub forma unor snapshot-uri. Utilizatorul poate folosi fdum pentru a compara aceste snapshot-uri, si a vizualiza diferentele intr-un format usor de inteles.

Pe langa interpretarea in format citibil a output-ului comenzilor ls -l si df generate in typescript, programul va compara si continutul fisierelor care au fost modificate intre cele 2 snapshot-uri, daca utilizatorul doreste acest lucru.
Interfata este prietenoasa; utilizatorul se poate intoarce mereu la meniul principal, iar instructiunile sunt clare.

- By default, programul va monitoriza structura de fisiere si directoare din directorul 'myfiles', situat in locatia in care se afla scriptul. Utilizatorul are insa posibilitatea de a monitoriza orice director doreste, modificand variabila USERDIR din fdum.sh.
- Snapshot-urile (fisierele typescript neparsate) vor fi salvate in directorul 'snaps'. Acest director va fi creat automat daca nu exista.
- Rezultatul interpretatii va fi afisat in stdout

## Usage

Se executa fdum.sh (fara argumente suplimentare)
Pot fi selectate 4 optiuni:
1. generarea unui snapshot cu rezultatul sub forma de fisier typescript
2. compararea a doua snapshot-uri generate la momente diferite de timp
3. compararea unui snapshot cu starea actuala a directorului
4. exit din program

## Recomandari

- Este foarte indicat ca fisierele si directoarele de monitorizat (cele din directorul myfiles) sa foloseasca doar caractere alfanumerice, fara spatii sau caractere speciale.
- Este best practice ca fiecare fisier din myfiles sa aiba separator de linie la final.