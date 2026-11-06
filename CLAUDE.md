# CLAUDE.md – Fork AunePVP/pl_mail_ios

**Fork** von [karatektus/pl_mail_ios](https://github.com/karatektus/pl_mail_ios), der iPhone- und
iPad-App für plMail (Swift 6, SwiftUI, iOS 26, spricht JMAP mit dem Server). Gehört zum
Server-Fork [AunePVP/pl_mail](https://github.com/AunePVP/pl_mail).

**Sprich mit den Nutzern Deutsch.** Code, Kommentare, Commit-Messages und Doku bleiben Englisch wie
im Original; nur FORK.md, CLAUDE.md und Absprachen sind Deutsch.

## Wo dieser Ordner liegt

Lokal ist dieser Clone der Unterordner `ios/` im Clone des Server-Forks (`/home/md/plmail-src/ios`),
vom Server-Repo über `.git/info/exclude` ignoriert. Sitzungen starten im Server-Ordner; dessen
CLAUDE.md gilt also immer mit, und die Regeln dort (klein halten, `FORK`-Markierungen, nichts ans
Original ohne ausdrückliche Freigabe, öffentlich, nie auf `main` committen, Squash für eigene
Änderungen, Merge-Commit für Updates) gelten hier genauso. `git` und `gh` immer **in `ios/`**
ausführen, sonst landet es im Server-Repo; PRs mit `gh pr create --repo AunePVP/pl_mail_ios --base main`.

## Zuerst lesen

- **[FORK.md](FORK.md)** – jede Abweichung vom Original und wie ein Update eingespielt wird.
- **docs/DEVELOPING.md** – Aufbau (JMAPKit / PLMailCore / PLMailUI), Build, Formatierung.
- **docs/parity/00-HOUSE-STYLE.md** und **PLAN.md** – Konventionen und „fertig“-Definition des
  Originals. Dort steht `pl_mail/` für den Server: bei uns ist das der Ordner `..` (Stand: unser Fork,
  nicht das Original).
- Die Schnittstelle zum Server ist JMAP plus plMails Erweiterungen; Spezifikation im Server unter
  `docs/CLIENT_DEVELOPMENT.md`.

## Bauen und testen ohne Mac

Auf diesem Rechner (Linux aarch64) gibt es weder Xcode noch das iOS-SDK; die App lässt sich hier
nicht bauen. Gebaut wird bei GitHub Actions (`.github/workflows/fork-build.yml`, FORK.md 1):

- **Pull Request:** `swift test` des Pakets, Simulator-Build, `swift format lint`. Ergebnis mit
  `gh pr checks` bzw. `gh run view --log-failed` lesen. Erst mergen, wenn grün.
- **Push auf `main`:** unsignierte `plMail.ipa` als Pre-Release `latest`
  (`gh release download latest --repo AunePVP/pl_mail_ios`). Signiert wird sie pro Gerät auf dem
  Signier-Server (FORK.md 1), nicht hier und nicht in der CI.

Getestet wird am Ende auf den echten Geräten der Nutzer: nach dem Merge sagen, was sie prüfen sollen.

## Neue Funktionen aus der Web-App

Die App bekommt nicht automatisch, was der Server-Fork neu kann. Übergabe läuft über **Issues in
AunePVP/pl_mail_ios mit Label `parity`** (Regel dazu im Server-CLAUDE.md). Vor der Umsetzung
klären: Liefert der Server die Daten schon über JMAP, oder braucht es zuerst eine
Server-Erweiterung (dann zuerst PR im Server-Fork, danach hier)?
