#!/usr/bin/env python3
"""Zeichnet aus Produktbildern (Ansicht von vorne, freigestellt oder auf Weiß)
Umrisse nach. Ergebnis sind .npy-Dateien, die fotos_vermessen.py in umrisse.scad schreibt.

ProGlide: halbe Breite über der Länge, t = 0 am Griffende, t = 1 an der
Kopfoberkante, Breite geteilt durch die Gesamtlänge. Die Größe kommt erst in
OpenSCAD über pg_laenge dazu. Kleine Zacken (Griffrippen) werden mit einer
Hüllkurve geglättet, die Mulde schneidet also nie in den Rasierer.
Dose: Schulter und Kappe, [Abstand von der Oberkante, Radius] in Dosendurchmessern.

Aufruf:
  python3 umriss_aus_bild.py --proglide bild1.png --proglide-x-min 280 --dose bild3.png \
      --aus-pg pg_profil.npy --aus-dose dose_oben.npy
"""
import argparse

import cv2
import numpy as np
from PIL import Image
from shapely.geometry import LineString


def lade(pfad):
    return np.array(Image.open(pfad).convert("RGBA")).astype(np.int16)


def loecher_fuellen(maske):
    # Rand dazu, damit der Hintergrund auch dann zusammenhängt, wenn das Objekt den Bildrand berührt
    m = np.pad(maske.astype(np.uint8) * 255, 1)
    h, w = m.shape
    ff = m.copy()
    cv2.floodFill(ff, np.zeros((h + 2, w + 2), np.uint8), (0, 0), 255)
    return ((m | cv2.bitwise_not(ff)) > 0)[1:-1, 1:-1]


def groesste_flaeche(maske, auswahl=None):
    n, lab, st, ce = cv2.connectedComponentsWithStats(maske.astype(np.uint8), 8)
    kandidaten = [(st[i, cv2.CC_STAT_AREA], i) for i in range(1, n) if auswahl is None or auswahl(ce[i])]
    return lab == max(kandidaten)[1]


def maske(bild, x_min=0):
    """Freigestellte Bilder über den Alphakanal (Schatten fallen bei > 200 weg),
    sonst alles, was sich vom weißen Hintergrund abhebt."""
    alpha = bild[..., 3]
    if alpha.min() < 128:
        m = alpha > 200
    else:
        rgb = bild[..., :3].astype(np.uint8).copy()
        h, w, _ = rgb.shape
        pad = np.zeros((h + 2, w + 2), np.uint8)
        flags = 4 | cv2.FLOODFILL_MASK_ONLY | (255 << 8) | cv2.FLOODFILL_FIXED_RANGE
        for saat in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]:
            cv2.floodFill(rgb, pad, saat, (0, 0, 0), (18,) * 3, (18,) * 3, flags)
        m = pad[1:-1, 1:-1] == 0
    m[:, :x_min] = False
    return loecher_fuellen(groesste_flaeche(m))


def zeilen(m):
    """Für jede Bildzeile mit Objekt: (y, linker Rand, rechter Rand) in Pixelkanten."""
    out = []
    for y in range(m.shape[0]):
        xs = np.nonzero(m[y])[0]
        if len(xs):
            out.append((y, xs[0], xs[-1] + 1))
    return np.array(out, dtype=float)


def vereinfachen(punkte, toleranz):
    linie = LineString(punkte).simplify(toleranz, preserve_topology=False)
    return [list(p) for p in linie.coords]


def rasierer_profil(m, toleranz=0.0006):
    z = zeilen(m)
    y, links, rechts = z[:, 0], z[:, 1], z[:, 2]
    oben, unten = y.min(), y.max() + 1
    laenge = unten - oben
    # Achse aus dem Griffbereich (untere 70 %), der Kopf kann leicht versetzt sein
    griff = y > oben + 0.3 * laenge
    achse = np.median((links[griff] + rechts[griff]) / 2)
    # symmetrisch: jeweils die breitere Seite nehmen
    halb = np.maximum(rechts - achse, achse - links)
    t = (unten - (y + 0.5)) / laenge
    pkt = [(0.0, 0.0)] + sorted(zip(t, halb / laenge)) + [(1.0, 0.0)]
    # Endkanten rund um t = 0 / 1 sauber schließen
    pkt[0] = (0.0, pkt[1][1] * 0.5)
    pkt[-1] = (1.0, pkt[-2][1])
    prof = vereinfachen(pkt, toleranz)
    breite = halb.max() * 2
    # Kopf: der obere Bereich, der breiter ist als 80 % der Kopfbreite
    kopf_t = t[halb > 0.8 * halb.max()].min()
    info = dict(laenge_px=laenge, breite_px=breite, l_zu_b=laenge / breite, kopf_t=kopf_t,
                achse=achse, versatz_kopf=((links + rechts) / 2)[halb > 0.8 * halb.max()].mean() - achse)
    return prof, info


def kontrollbild(eintraege, pfad):
    kacheln = []
    for bild, m, prof_px in eintraege:
        rgb = bild[..., :3].astype(float)
        a = bild[..., 3:4] / 255.0
        rgb = rgb * a + 200 * (1 - a)
        rgb[m] = rgb[m] * 0.6 + np.array([255, 60, 60]) * 0.4
        img = rgb.astype(np.uint8).copy()
        cv2.polylines(img, [np.array(prof_px, np.int32)], True, (0, 170, 0), max(1, img.shape[0] // 300))
        k = Image.fromarray(img)
        k.thumbnail((600, 600))
        kacheln.append(k)
    w = sum(k.width for k in kacheln) + 10 * len(kacheln)
    h = max(k.height for k in kacheln)
    out = Image.new("RGB", (w, h), (255, 255, 255))
    x = 0
    for k in kacheln:
        out.paste(k, (x, 0))
        x += k.width + 10
    out.save(pfad)


def huelle(prof, fenster=0.02, schritt=0.002):
    """Profil gleichmäßig abtasten, gleitendes Maximum (Hüllkurve) und leicht glätten."""
    from scipy.ndimage import maximum_filter1d, uniform_filter1d
    t = np.arange(0, 1 + schritt / 2, schritt)
    p = np.array(prof)
    h = np.interp(t, p[:, 0], p[:, 1])
    n = max(1, int(round(fenster / schritt)))
    h = uniform_filter1d(maximum_filter1d(h, n, mode="nearest"), max(1, n // 2), mode="nearest")
    return vereinfachen(list(zip(t, h)), 0.0005)


def dose_oben(m):
    z = zeilen(m)
    y, links, rechts = z[:, 0], z[:, 1], z[:, 2]
    oben, unten = y.min(), y.max() + 1
    breite = rechts - links
    d = np.median(breite[(y > oben + 0.45 * (unten - oben)) & (y < oben + 0.9 * (unten - oben))])
    abstand, rel = (y - oben) / d, breite / d
    voll = abstand[rel > 0.985].min()
    sel = abstand <= voll + 0.05
    return np.array(sorted(zip(abstand[sel], rel[sel] / 2)))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--proglide", required=True)
    ap.add_argument("--proglide-x-min", type=int, default=0, help="links davon ignorieren (z. B. Verpackung)")
    ap.add_argument("--dose", required=True)
    ap.add_argument("--aus-pg", required=True)
    ap.add_argument("--aus-dose", required=True)
    ap.add_argument("--kontrolle")
    a = ap.parse_args()

    bild = lade(a.proglide)
    m = maske(bild, a.proglide_x_min)
    roh, info = rasierer_profil(m)
    prof = huelle(roh)
    np.save(a.aus_pg, np.array(prof))
    print(f"ProGlide: Länge/Kopfbreite {info['l_zu_b']:.3f}, {len(prof)} Punkte")
    if a.kontrolle:
        y_unten = np.nonzero(m.any(1))[0].max() + 1
        L = info["laenge_px"]
        rechts = [(info["achse"] + h * L, y_unten - t * L) for t, h in prof]
        links = [(info["achse"] - h * L, y_unten - t * L) for t, h in reversed(prof)]
        kontrollbild([(bild, m, rechts + links)], a.kontrolle)

    oben = dose_oben(maske(lade(a.dose)))
    np.save(a.aus_dose, oben)
    print(f"Dose: Schulter und Kappe {oben[-1][0]:.3f} D lang, Kappe {2 * oben[len(oben) // 3][1]:.3f} D breit")


if __name__ == "__main__":
    main()
