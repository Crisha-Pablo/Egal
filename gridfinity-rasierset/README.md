# Gridfinity Rasier-Set (liegend, für die Schublade)

![Übersicht](bilder/uebersicht.png)

Halter für:

- **Gillette Shave Foam Sensitive** (Rasierschaum-Dose)
- **Gillette Fusion5 ProGlide** (mit FlexBall)
- **den kleinen 3-Klingen-Rasierer** mit gebogenem Chromhals (für Körper und Intimbereich)
- die **Plastik-Klingenboxen** beider Rasierer

## Teile

| Datei | Raster | Höhe | Inhalt | Filament* |
|---|---|---|---|---|
| `stl/rasierschaum_wiege_5x2x4u.stl` | 5 × 2 | 28 mm | Dose liegt auf drei Stegen, Anschläge an beiden Enden | ca. 95 g |
| `stl/rasierer_halter_4x2x3u.stl` | 4 × 2 | 21 mm | beide Rasierer Kopf an Fuß, Mulden in exakter Umrissform | ca. 85 g |
| `stl/klingenbox_halter_2x3x3u.stl` | 2 × 3 | 21 mm | beide Klingenboxen flach, mit Griffmulde | ca. 55 g |
| `stl/passtest.stl` | – | 3 mm | Muldenumrisse, Boxrahmen und Dosenring zum Probedrucken | ca. 11 g |

\* Mit PrusaSlicer gesliced: PLA, 0,2 mm Schichthöhe, 2 Wände, 15 % Gyroid.

**Warum beide Rasierer in einem Halter?** Die Klingenköpfe sind breiter als eine Rastereinheit (41,5 mm). Schon ein einzelner Rasierer braucht deshalb 2 Einheiten Breite. Kopf an Fuß greifen die beiden Umrisse ineinander und passen zusammen in 4 × 2. Einzelne Halter gibt es über `rasierer_auswahl`.

## Woher die Formen kommen

| Teil | Quelle | Genauigkeit |
|---|---|---|
| kleiner Rasierer | dein Foto von oben (IMG_8033), Seitenfoto (IMG_8035) für die Höhen | Umriss exakt, Größe über den Maßstab |
| Dose | dein Foto von oben (IMG_8036) | Länge/Durchmesser exakt, Größe über den Maßstab |
| ProGlide | Produktbild aus dem Netz | Umriss gut, **Größe geschätzt** |
| Klingenboxen | Schätzwerte | bitte nachmessen |

So wurde vermessen (`werkzeug/fotos_vermessen.py`):

1. Die Dose in IMG_8036 hat laut Hersteller **49 mm Durchmesser**. Daraus und aus der Brennweite in den EXIF-Daten folgt, dass das iPhone 221 mm über dem Tisch war. Die Dose ist demnach 163,8 mm lang.
2. Die Zifferntasten der Fernbedienung liegen in IMG_8036 und IMG_8033. Ihr Abstand überträgt den Maßstab: In IMG_8033 war die Kamera 186 mm über dem Tisch.
3. Der Rasierer wurde entlang der schattenfreien Oberkante abgetastet und an der Griffachse gespiegelt. Die Perspektive aus nur ~20 cm Abstand wird herausgerechnet: Höher liegende Teile wie der Kopf erscheinen größer und werden entsprechend verkleinert.

Ergebnis kleiner Rasierer: **138,0 mm** lang, Kopf **37,5 mm**, Griff 11,8–14,3 mm.

Die Fotos selbst liegen nicht im Repo, nur die daraus gewonnenen Umrisse in `umrisse.scad`.

## Vor dem Drucken

Alle Fotomaße hängen an **einer Zahl: dem Dosendurchmesser** (`dose_d`, eingestellt sind 49 mm).

1. `passtest.stl` drucken (3 mm hoch).
2. Die Dose durch den Ring schieben. Sitzt sie sauber, stimmt der Maßstab für die Dose **und** den kleinen Rasierer. Ist sie zu locker oder klemmt sie, den Durchmesser nachmessen und `dose_d` anpassen. Alles skaliert automatisch mit.
3. Den kleinen Rasierer in seinen Rahmen legen (KLEIN) und genauso den ProGlide (PROGLIDE). Beim ProGlide ist die Länge noch geschätzt (`pg_laenge = 135`). Passt er nicht, die Gesamtlänge eintragen oder ein Foto wie IMG_8033 machen (von oben, Fernbedienung daneben).
4. Klingenboxen in die Rahmen legen, ggf. `pg_box_*` und `bi_box_*` anpassen.

## Anpassen

- **OpenSCAD** (ab Version 2021.01): `gridfinity_rasierset.scad` öffnen (die Datei `umrisse.scad` muss daneben liegen), *Fenster → Customizer*, Werte ändern, oben bei `teil` das Teil wählen, dann F6 (Rendern) und F7 (STL exportieren).
- **Kommandozeile**: `./build.sh -D dose_d=50 -D pg_laenge=140` erzeugt alle STLs und Bilder neu.
- Spiel um die Rasierer: `rasierer_spiel` (0,8 mm). Tiefe der Mulden: `rasierer_tiefe` (13 mm, Griff liegt fast bündig).
- Mehrere Klingenboxen: `pg_box_anzahl`, `bi_box_anzahl`.
- Nur ein Rasierer pro Halter: `rasierer_auswahl = "proglide"` oder `"klein"`.
- Löcher für 6 × 2-mm-Magnete: `magnete = true` (im Bad eher weglassen, Magnete rosten).
- Neue Fotos auswerten: `werkzeug/fotos_vermessen.py` und `werkzeug/umriss_aus_bild.py` (Aufruf steht jeweils oben in der Datei).

## Druck

- PETG ist im Bad die bessere Wahl, PLA geht auch.
- So drucken, wie exportiert: Füße nach unten. Keine Stützen und kein Brim nötig.
- 0,2 mm Schichthöhe, 2–3 Wände, 10–15 % Infill.
- Die Wiege ist 209,5 mm lang, das Druckbett muss also mindestens so groß sein.

## Gridfinity

42-mm-Raster, 7-mm-Höheneinheit und Fußprofil 0,8 / 1,8 / 2,15 mm nach Zack Freedmans Spezifikation. Die Teile passen in jede Standard-Grundplatte. Eine Stapellippe gibt es nicht, weil auf diesen Haltern nichts gestapelt wird.

![Draufsicht](bilder/draufsicht.png)

| Rasierer-Halter | Klingenbox-Halter | Rasierschaum-Wiege | Passtest |
|---|---|---|---|
| ![](bilder/rasierer_halter.png) | ![](bilder/klingenbox_halter.png) | ![](bilder/rasierschaum_wiege.png) | ![](bilder/passtest.png) |
