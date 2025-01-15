# FDUM
File&amp;DiskUsageMonitor

Update Jan 15 2025: rezolvat bug-uri

## Descriere

FDUM (File&DiskUsageMonitor) are ca scop monitorizarea atât a structurii de fișiere și directoare relevante pentru utilizator, cât și a utilizării spațiului pe disc, prin interpretarea sesiunii de lucru (terminal) a utilizatorului.

Programul este capabil să genereze și să parseze automat fișiere typescript (create prin comanda script), pe care le stochează sub forma unor snapshot-uri. Utilizatorul poate folosi fdum pentru a compara aceste snapshot-uri, și a vizualiza diferențele într-un format ușor de înțeles.

Pe lângă interpretarea în format citibil a output-ului comenzilor ls -l și df generate în typescript, programul va compara și conținutul fișierelor care au fost modificate între momentele corespunzătoare celor două snapshot-uri, dacă utilizatorul dorește acest lucru. Interfața este prietenoasă; utilizatorul se poate întoarce mereu la meniul principal, iar instrucțiunile sunt clare.

## Observații generale și recomandări

- By default, programul va monitoriza structura de fișiere și directoare din directorul 'myfiles', situat în locația în care se află scriptul. Utilizatorul are posibilitatea de a monitoriza orice director dorește, modificând variabila USERDIR din fdum.sh.
- Best practice: fiecare fișier să aibă separator de linie la final.
- Snapshot-urile (fișierele typescript neparsate) vor fi salvate în directorul 'snaps'. Acest director va fi creat automat dacă nu există.
- Rezultatul interpretării va fi afișat în stdout

## Usage

Se execută scriptul fdum.sh (fără argumente suplimentare). Din meniul principal, pot fi selectate 4 opțiuni:
1. generarea unui snapshot cu rezultatul sub formă de fișier typescript
2. compararea a două snapshot-uri generate la momente diferite de timp
3. compararea unui snapshot cu starea actuală a directorului
4. exit din program
În funcție de opțiunea selectată, programul va afișa mai departe instrucțiunile corespunzătoare.