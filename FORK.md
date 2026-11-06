# Fork AunePVP/pl_mail_ios

Fork von [karatektus/pl_mail_ios](https://github.com/karatektus/pl_mail_ios). Hier steht **jede**
Abweichung vom Original, mit Grund. Ziel ist ein **kleiner** Fork: lieber neue Dateien als Änderungen
an bestehenden. Jede Fork-Stelle im Code ist markiert:

```bash
git grep -n "FORK (FORK.md"
```

Neue Dateien nur dieses Forks: `CLAUDE.md`, `FORK.md`, `.github/workflows/fork-build.yml`,
`Packages/PLMail/Sources/PLMailUI/Reader/MessageBodyView+FitWidth.swift`,
`Packages/PLMail/Sources/JMAPKit/Methods/ForkMethods.swift` und alles unter
`Packages/PLMail/Sources/PLMailUI/Fork/`.

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

### 2. Mail randlos, breite Mails auf Bildschirmbreite

Neue Datei `Packages/PLMail/Sources/PLMailUI/Reader/MessageBodyView+FitWidth.swift` (`fitWidthScript`),
eingehängt in `MessageBodyView.swift` (eine Zeile, markiert). Hat eine Mail eine Tabelle so breit wie der
Bildschirm (gestaltete Mail, Newsletter), fällt der 16-px-Seitenrand der Webansicht weg; ist sie breiter,
wird der `body` per `zoom` passend verkleinert, wie Apple Mail es tut. Schlichte Mails behalten den Rand.

Dazu `PLMailUI/Fork/ForkMessageBodyInset.swift`, in `MessageView.swift` statt `clipShape` + 12-pt-Einzug
(markiert): auf dem iPhone geht der Mailtext bis an den Bildschirmrand, auf dem iPad (breite Ansicht)
bleibt das eingerückte, abgerundete Blatt des Originals.

**Grund:** Newsletter sind feste 600–700-px-Tabellen. Das Original lässt Tabellen einzeln seitlich
scrollen (`display: block; overflow-x: auto`); bei verschachtelten Tabellen und abgeschaltetem Scrollen
der Webansicht war die rechte Seite abgeschnitten (Miles & More, 2026-11-06). Auf 390 pt Breite kostet
jeder Rand Lesbarkeit.
**Kandidat fürs Original:** ja (dort erst Issue, nur nach Freigabe).

### 3. Gestaltete Mails im Dunkelmodus wie gesendet

`MessageColorProfile.swift`, `MessageRenderStyle.choose`: eine Mail mit eigenen Farben, aber ohne eigene
Dunkel-Regeln wird `.original` (hell, wie gesendet) statt `.darkInverted`. Test angepasst
(`MessageColorProfileTests.designedIsOriginal`).

**Grund:** Die Invertierung machte dunkel gestaltete Newsletter (Audi) hell und dunkle Logos
unsichtbar auf Schwarz (Miles & More). Apple Mail zeigt solche Mails wie gesendet.
**Kandidat fürs Original:** ja, als Fehlerbericht (dort erst Issue, nur nach Freigabe).

### 4. Abmelden-Knopf

`PLMailUI/Fork/ForkUnsubscribeButton.swift`: unter dem Kopf einer aufgeklappten Mail ein Knopf
„Abmelden“, wenn der Server-Fork über `ForkUnsubscribe/get` (Server-FORK.md 20) ein Ziel nennt. Weblink
öffnet sich in Safari, `mailto:` im Mailprogramm des Systems. Antworten pro Sitzung gecacht; ein Server
ohne die Methode (`unknownMethod`) wird nicht weiter gefragt. Eingehängt mit je einer markierten Zeile in
`MessageView.swift` (Knopf) und `ThreadReaderView.swift` (`forkReaderContext` in der Umgebung).
Methoden-Typen in `JMAPKit/Methods/ForkMethods.swift`.

**Grund:** Gleicher Knopf wie in der Web-App (Server-FORK.md 13).

### 5. KI-Suche über den Treffern

`PLMailUI/Fork/ForkSearchInsightView.swift`, eine markierte Zeile in `SearchResultsView.swift`: über den
Suchtreffern ein aufklappbares Feld „KI-Suche“ mit „Termine dazu“, „Beste Treffer“ (Reranker) und
„Kurz gesagt“ (Sprachmodell) aus `ForkSearch/insight` (Server-FORK.md 20). Termine und beste Treffer
zuerst, die Antwort danach. Ohne Fork-Server nichts.

**Grund:** Wie in der Web-App (Server-FORK.md 16 und 18); die Suche der App ist sonst reine Volltextsuche.

### 6. PR-Build in Release

`fork-build.yml`: der Simulator-Build bei PRs läuft in Release, weil Release Warnungen als Fehler
behandelt und sonst erst der `.ipa`-Bau nach dem Merge scheitern würde.

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
