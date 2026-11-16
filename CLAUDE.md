# oliver-paulus.com (www)

Hauptseite von https://www.oliver-paulus.com. Alte, einfache Seite (HTML 4, jQuery-Nachladen von `k_content.txt`), kein Build-Schritt.
Rein statisch: kein PHP, keine Server-Logik. Neue Seiten nur als `.html`.

## Aufbau

- `public/` – wird 1:1 als Website ausgeliefert (Caddy-Root). Alles hier ist öffentlich abrufbar.
  - `index.html` – Startseite, lädt `k_content.txt` per `k_script.js`
  - `k_content.txt` – Textinhalt der Startseite (HTML-Fragment)
  - `keepass/` – KeePass-Downloads inkl. `Oli.kdbx` (Passwortdatenbank, vom Nutzer bewusst öffentlich gemacht) und `index.html` (statische Dateiliste im Stil der früheren PHP-Verzeichnisliste; Größe und Datum sind feste Werte und müssen beim Austausch einer Datei von Hand angepasst werden)
- `deploy/website-github-sync.sh` – Sync-Skript, läuft auf dem Server

## Deployment

1. Lokal ändern (Windows, `d:\Webpages\1_Webserver\Repository website oliver-paulus.com`)
2. Commit + Push nach GitHub `opcom-CMS/website`, Branch `main`
3. Der Server holt den Stand automatisch per `deploy/website-github-sync.sh` (`git pull --ff-only` nach `~/apps/website`). Kein Build, kein Neustart nötig.
   Sofort auslösen auf dem Server: `bash ~/apps/website/deploy/website-github-sync.sh`

Wenn der Nutzer sagt „nach GitHub syncen/deployen“: Änderungen ansehen, committen, pushen.

## Server (Samsung A21, Termux, ohne Root)

- Webserver: **Caddy**, Konfiguration `~/opdepot-runtime/Caddyfile`
  - Bedient mehrere Seiten: `www.oliver-paulus.com`, `depot.oliver-paulus.com` (op-Depot), `rom.oliver-paulus.com` (Verborgene Kleinode in Rom), dazu lokale Blöcke auf `127.0.0.1:8001` und `:8004`
  - Ports 8080 (HTTP) / 8443 (HTTPS)
  - `admin off` → `caddy reload` funktioniert **nicht**. Neustart nötig:
    ```
    caddy validate --config ~/opdepot-runtime/Caddyfile
    pkill -x caddy; sleep 2
    nohup caddy run --config ~/opdepot-runtime/Caddyfile > /dev/null 2>&1 &
    ```
    Kurz alle Seiten weg. Vor Änderungen Sicherung anlegen (`Caddyfile.bak` existiert).
- **Kein PHP** (seit 16.11.2026): Der www-Block liefert nur statische Dateien aus `public/` mit `file_server`, ohne
  `php_fastcgi`. `index.html` wird für Verzeichnisse direkt ausgeliefert (Caddy-Standard), auch für `/keepass/`.
  `php-fpm` wird für die Website nicht gebraucht und muss nicht laufen.
- Bei „library … not found“ nach `pkg install`: `pkg update && pkg upgrade` (Teil-Upgrade-Problem in Termux).

## Offen

- Caddyfile auf dem A21: den `php_fastcgi`-Block im www-Block entfernen, Caddy neu starten (siehe oben) und
  `php-fpm` beenden, falls es noch läuft. Bis dahin funktioniert die Seite trotzdem, weil `try_files`
  `index.html` vor `index.php` prüft.

## Hinweise

- Zeilenenden: Git wandelt CRLF → LF (Warnungen beim Commit sind normal).
- Dateien unter `public/` sind öffentlich; vor dem Hinzufügen sensibler Dateien nachfragen.
