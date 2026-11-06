# Fork AunePVP/pl_mail_ios

Fork von [karatektus/pl_mail_ios](https://github.com/karatektus/pl_mail_ios). Hier steht **jede**
Abweichung vom Original, mit Grund. Ziel ist ein **kleiner** Fork: lieber neue Dateien als Änderungen
an bestehenden. Jede Fork-Stelle im Code ist markiert:

```bash
git grep -n "FORK (FORK.md"
```

Neue Dateien nur dieses Forks: `CLAUDE.md`, `FORK.md`, `.github/workflows/fork-build.yml`,
`Packages/PLMail/Sources/PLMailUI/Reader/MessageBodyView+FitWidth.swift`.

## Abweichungen

### 1. Build bei GitHub Actions, Signieren ohne Mac

`.github/workflows/fork-build.yml` (neue Datei). Bei Pull Requests: Paket-Tests, Simulator-Build,
Lint. Bei Push auf `main` oder von Hand: unsignierte `plMail.ipa` als Pre-Release `latest`, ohne
das Widget (eine Erweiterung kostet eine der 10 App-IDs pro Woche eines kostenlosen Apple-Kontos und
funktioniert ohne bezahltes Konto ohnehin nicht; mit `keep_widget` von Hand behalten).

Signiert und installiert wird die `.ipa` mit einer **kostenlosen Apple-ID** auf einem Signier-Server
im Heimnetz, der sie alle paar Tage über WLAN neu signiert, bevor die 7 Tage ablaufen. Welcher
Server und wo er läuft, steht in `CLAUDE.local.md` des Server-Clones (Betriebsdaten).

**Grund:** Niemand hier hat einen Mac, und ein bezahltes Apple-Entwicklerkonto (99 €/Jahr) ist vorerst
nicht gewollt. Folgen: keine Push-Mitteilungen bei geschlossener App, kein Widget (README des
Originals, „What isn't there yet“). Mit bezahltem Konto würde der Workflow stattdessen signieren
und zu TestFlight hochladen.
**Kandidat fürs Original:** vielleicht (der Simulator-Teil als CI).

### 2. Breite Mails auf Bildschirmbreite verkleinern

Neue Datei `Packages/PLMail/Sources/PLMailUI/Reader/MessageBodyView+FitWidth.swift` (`fitWidthScript`),
eingehängt in `MessageBodyView.swift` (eine Zeile, markiert). Ist eine Mail breiter als der Bildschirm,
werden ihre Tabellen normal gesetzt und der `body` per `zoom` passend verkleinert, wie Apple Mail es tut.
Mails, die passen, bleiben unverändert.

**Grund:** Newsletter sind feste 600–700-px-Tabellen. Das Original lässt Tabellen einzeln seitlich
scrollen (`display: block; overflow-x: auto`); bei verschachtelten Tabellen und abgeschaltetem Scrollen
der Webansicht war die rechte Seite einfach abgeschnitten (Miles & More, 2026-11-06).
**Kandidat fürs Original:** ja (dort erst Issue, nur nach Freigabe).

### 3. Gestaltete Mails im Dunkelmodus wie gesendet

`MessageColorProfile.swift`, `MessageRenderStyle.choose`: eine Mail mit eigenen Farben, aber ohne eigene
Dunkel-Regeln wird `.original` (hell, wie gesendet) statt `.darkInverted`. Test angepasst
(`MessageColorProfileTests.designedIsOriginal`).

**Grund:** Die Invertierung machte dunkel gestaltete Newsletter (Audi) hell und dunkle Logos
unsichtbar auf Schwarz (Miles & More). Apple Mail zeigt solche Mails wie gesendet.
**Kandidat fürs Original:** ja, als Fehlerbericht (dort erst Issue, nur nach Freigabe).

## Update vom Original

Das Original hat (Stand 2026-11) keine Releases; eingespielt wird sein `main`.

```bash
cd ios
git fetch upstream
git switch main && git pull
git switch -c update/$(date +%F)
git merge upstream/main
```

1. Konflikte lösen; Fork-Stellen sind markiert. Hat das Original eine Abweichung selbst gelöst,
   die Fork-Stelle entfernen und hier austragen.
2. Push, PR gegen `main` des Forks, warten bis `fork-build.yml` grün ist, dann **mit Merge-Commit**
   mergen (`gh pr merge --merge`), nie Squash.
3. Der Merge baut die neue `.ipa`; der Signier-Server installiert sie beim nächsten Durchgang
   (oder von Hand anstoßen).
