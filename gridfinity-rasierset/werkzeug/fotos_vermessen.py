#!/usr/bin/env python3
"""Vermisst Dose und kleinen Rasierer aus den iPhone-Fotos und schreibt umrisse.scad.

Maßstab: Die Dose in IMG_8036 hat einen Durchmesser von 49 mm (Herstellerangabe).
Daraus folgt die Kamerahöhe in IMG_8036. Die Zifferntasten der Fernbedienung
übertragen den Maßstab auf IMG_8033 (kleiner Rasierer von oben). Alle Fotomaße
gelten deshalb für 49 mm Dosendurchmesser. In OpenSCAD skaliert dose_d sie mit.

Kameramodell: Lochkamera senkrecht über dem Tisch, Brennweite aus EXIF
(24 mm Kleinbild-Äquivalent -> 2790 px bei 4032 px Bildbreite), Hauptpunkt in
der Bildmitte. Ein Punkt in Höhe h über dem Tisch wird mit (Z - h) / f
skaliert, so wird die Perspektive aus nur ~20 cm Abstand herausgerechnet.

Aufruf:
  python3 fotos_vermessen.py IMG_8036.png IMG_8033.png ../umrisse.scad
  (HEIC vorher nach PNG wandeln, z. B. mit pillow-heif)
Zusätzlich braucht es die Produktbilder für ProGlide (Bild 1) und Dosenkappe (Bild 3),
siehe umriss_aus_bild.py.
"""
import sys

import cv2
import numpy as np
from PIL import Image
from scipy.ndimage import median_filter
from shapely.geometry import LineString

F_PX = 2790.0                  # Brennweite in Pixeln (24 mm KB-Äquivalent, 4032 px breit)
CX, CY = 2016.0, 1512.0        # Hauptpunkt (Bildmitte, Querformat)
DOSE_D_MM = 49.0               # Maßstabsanker


def lab_bild(pfad):
    im = np.array(Image.open(pfad).convert("RGB"))
    return im, cv2.cvtColor(im, cv2.COLOR_RGB2LAB).astype(np.float32)


def subpixel(p, i):
    a, b, c = p[i - 1], p[i], p[i + 1]
    d = a - 2 * b + c
    return i + (0.5 * (a - c) / d if d != 0 else 0.0)


def dose_vermessen(pfad):
    """Dose liegt im Bild etwa waagerecht. Bild so drehen, dass die Achse genau
    waagerecht liegt, dann die beiden Umrisslinien über den ganzen Zylinder mitteln."""
    _, lab = lab_bild(pfad)
    mu = (1159.8, 1413.7)                       # Punkt auf der Achse (Grobsegmentierung)
    bestes = None
    for w in np.arange(5.2, 7.01, 0.1):
        M = cv2.getRotationMatrix2D(mu, w, 1.0)
        r = cv2.warpAffine(lab, M, lab.shape[1::-1], flags=cv2.INTER_LINEAR, borderMode=cv2.BORDER_REPLICATE)
        gy = np.sqrt(sum(cv2.Sobel(r[..., c], cv2.CV_32F, 0, 1, ksize=3) ** 2 for c in range(3)))
        prof = gy[:, int(mu[0] - 450):int(mu[0] + 1250)].mean(1)
        yc = int(mu[1])
        wert = prof[yc - 700:yc - 200].max() + prof[yc + 200:yc + 700].max()
        if bestes is None or wert > bestes[0]:
            bestes = (wert, w, prof, r, M)
    _, w, prof, r, M = bestes
    yc = int(mu[1])
    yo = subpixel(prof, yc - 700 + int(np.argmax(prof[yc - 700:yc - 200])))
    yu = subpixel(prof, yc + 200 + int(np.argmax(prof[yc + 200:yc + 700])))
    d_px = yu - yo
    gx = np.sqrt(sum(cv2.Sobel(r[..., c], cv2.CV_32F, 1, 0, ksize=3) ** 2 for c in range(3)))
    ya = (yo + yu) / 2
    boden = gx[int(ya - 0.35 * d_px):int(ya + 0.35 * d_px)].mean(0)
    xb = subpixel(boden, int(mu[0]) - 900 + int(np.argmax(boden[int(mu[0]) - 900:int(mu[0]) - 300])))
    kappe = gx[int(ya - 0.12 * d_px):int(ya + 0.12 * d_px)].mean(0)
    lo, hi = int(mu[0]) + 1500, int(mu[0]) + 2150
    seg = kappe[lo:hi]
    spitzen = [i for i in range(1, len(seg) - 1) if seg[i] > 0.4 * seg.max() and seg[i] >= seg[i - 1] and seg[i] >= seg[i + 1]]
    xk = subpixel(kappe, lo + spitzen[-1])
    hp = M @ np.array([CX, CY, 1.0])           # Hauptpunkt im gedrehten Bild
    # Kamerahöhe aus dem Durchmesser: Kamera fast genau über der Achse, Umriss = Tangenten an den Kreis
    R = DOSE_D_MM / 2
    alpha = np.arctan(d_px / 2 / F_PX)
    Z = R / np.sin(alpha) + R
    # Länge: Bodenrand oben (Höhe D) links, Kappenrand oben (Höhe R + r_kappe) rechts
    r_kappe = 0.321 * DOSE_D_MM
    x_boden = (xb - hp[0]) * (Z - DOSE_D_MM) / F_PX
    x_kappe = (xk - hp[0]) * (Z - (R + r_kappe)) / F_PX
    L = x_kappe - x_boden
    return dict(Z=Z, d_px=d_px, laenge_mm=L, l_zu_d=L / DOSE_D_MM)


def ziffer_blobs(pfad, box, hell=150):
    im = np.array(Image.open(pfad).convert("RGB")).astype(int)
    x0, y0, x1, y1 = box
    s = im[y0:y1, x0:x1]
    R, G, B = s[..., 0], s[..., 1], s[..., 2]
    rot = ((R > 150) & (R - G > 70) & (R - B > 70)).astype(np.uint8)
    n, lab, st, ce = cv2.connectedComponentsWithStats(rot, 8)
    i = 1 + int(np.argmax(st[1:, cv2.CC_STAT_AREA]))
    return np.array([ce[i][0] + x0, ce[i][1] + y0])


def massstab_fernbedienung():
    """Abstand roter Punkt (Aufnahmetaste) -> Ziffer 1 und Personen-Symbol -> roter Punkt,
    in IMG_8036 und IMG_8033 (Werte aus der Blob-Erkennung, siehe Kommentar)."""
    # IMG_8036: roter Punkt (2877.4, 2280.6), Ziffer 1 (3344.7, 2322.1), Person (2751.6, 2287.0)
    # IMG_8033: roter Punkt (3977.7, 646.1),  Ziffer 1 (3996.0, 81.0),   Person (4003.4, 795.9)
    a = np.hypot(3344.7 - 2877.4, 2322.1 - 2280.6), np.hypot(2877.4 - 2751.6, 2280.6 - 2287.0)
    b = np.hypot(3996.0 - 3977.7, 81.0 - 646.1), np.hypot(3977.7 - 4003.4, 646.1 - 795.9)
    return float(np.mean([b[0] / a[0], b[1] / a[1]]))


def rasierer_vermessen(pfad, Z):
    """Kleiner Rasierer in IMG_8033: Oberkante (schattenfrei) abtasten, an der Achse spiegeln."""
    im = np.array(Image.open(pfad).convert("RGB"))
    V = cv2.GaussianBlur(cv2.cvtColor(im, cv2.COLOR_RGB2HSV)[..., 2].astype(np.float32), (3, 3), 0)
    # Achse durch Griffmitte (x=950, x=1500) und Mitte Klingenkopf (x=2932), von Hand an den Kanten abgelesen
    P = np.polyfit([950, 1500, 2932], [1426.0, 1435.5, 1472.5], 1)
    cosw = 1 / np.sqrt(1 + P[0] ** 2)
    x_ende, x_kopf_l, x_kopf_r = 835, 2835, 3030

    def oberkante(x):
        ya = P[0] * x + P[1]
        y0 = int(ya - 420)
        dunkel = V[y0:int(ya), x] < 165
        ok = np.convolve(dunkel, np.ones(12), mode="valid") >= 12
        return y0 + int(np.argmax(ok)) if ok.any() else None

    H_GRIFF = 6.8   # Griff ~13,6 mm dick und rund: Umrisskante auf halber Höhe, auch an der Rundung am Ende

    def kantenhoehe(x, halb_mm):
        # Hals steigt an, Kopf liegt ~16 mm hoch (Seitenfoto IMG_8035)
        if x <= 2300:
            return H_GRIFF
        if x <= 2700:
            return H_GRIFF + (12 - H_GRIFF) * (x - 2300) / 400
        if x <= x_kopf_l:
            return 12 + 4 * (x - 2700) / (x_kopf_l - 2700)
        return 16.0

    xs, halb = [], []
    for x in range(x_ende + 2, x_kopf_r - 1, 3):
        y = oberkante(x)
        if y is not None:
            xs.append(x)
            halb.append((P[0] * x + P[1] - y) * cosw)
    halb = median_filter(np.array(halb), size=7, mode="nearest")
    s0 = (x_ende - CX) * (Z - H_GRIFF) / F_PX
    zeilen = []
    for x, hp in zip(xs, halb):
        h = H_GRIFF
        for _ in range(3):
            h = kantenhoehe(x, hp * (Z - h) / F_PX)
        zeilen.append((((x - CX) * (Z - h) / F_PX - s0) / cosw, hp * (Z - h) / F_PX))
    L = ((x_kopf_r - CX) * (Z - 16.0) / F_PX - s0) / cosw
    # Ausreißer am Übergang Hals/Gelenk glätten (Breite ändert sich dort nur langsam)
    z = np.array(zeilen)
    z[:, 1] = median_filter(z[:, 1], size=15, mode="nearest")
    pkt = [(0.0, 0.0)] + [tuple(p) for p in z] + [(L, z[-1, 1]), (L, 0.0)]
    vereinfacht = list(LineString(pkt).simplify(0.06).coords)
    return L, vereinfacht


def liste(name, punkte, kommentar, nachkomma=2):
    zeilen = ",\n    ".join(f"[{a:.{nachkomma}f}, {b:.{nachkomma}f}]" for a, b in punkte)
    return f"// {kommentar}\n{name} = [\n    {zeilen}];\n\n"


def main():
    foto_dose, foto_rasierer, ziel = sys.argv[1:4]
    dose = dose_vermessen(foto_dose)
    k = massstab_fernbedienung()
    # Kamerahöhe in IMG_8033 über die Tastenoberseite (ca. 18 mm hoch, Einfluss < 1 mm)
    h_taste = 18.0
    Z33 = h_taste + (dose["Z"] - h_taste) / k
    L, prof = rasierer_vermessen(foto_rasierer, Z33)
    print(f"IMG_8036: Kamera {dose['Z']:.1f} mm über dem Tisch, Dose {dose['laenge_mm']:.1f} mm lang (L/D {dose['l_zu_d']:.3f})")
    print(f"IMG_8033: Maßstab {k:.3f}x gegenüber IMG_8036, Kamera {Z33:.1f} mm über dem Tisch")
    print(f"Kleiner Rasierer: {L:.1f} mm lang, {len(prof)} Umrisspunkte, Kopf {2 * max(p[1] for p in prof):.1f} mm breit")

    # ProGlide (Produktbild) und Dosenkappe (Produktbild) kommen aus umriss_aus_bild.py
    pg = np.load(sys.argv[4]) if len(sys.argv) > 4 else None
    oben = np.load(sys.argv[5]) if len(sys.argv) > 5 else None

    text = ["// Automatisch erzeugt von werkzeug/fotos_vermessen.py. Nicht von Hand ändern.\n",
            "// Alle Fotomaße gelten für 49 mm Dosendurchmesser, dose_d skaliert sie in OpenSCAD mit.\n\n",
            liste("bi_profil_mm", prof, f"Kleiner 3-Klingen-Rasierer aus IMG_8033: [Abstand vom Griffende, halbe Breite] in mm"),
            f"bi_laenge_mm = {L:.2f};\n\n",
            f"// Rasierschaum-Dose aus IMG_8036: Länge / Durchmesser\ndose_l_zu_d = {dose['l_zu_d']:.4f};\n\n"]
    if oben is not None:
        # nur jeden 6. Punkt, Schulter und Kappe ändern sich langsam
        text.append(liste("dose_oben", [(a, r) for a, r in oben[::6]] + [tuple(oben[-1])],
                          "Schulter und Kappe aus dem Produktbild: [Abstand von der Oberkante, Radius] in Dosendurchmessern", 3))
    if pg is not None:
        text.append(liste("pg_profil", [tuple(p) for p in pg],
                          "Gillette Fusion5 ProGlide aus dem Produktbild: [t, halbe Breite / Länge], t = 0 Griffende, 1 Kopfoberkante", 4))
    with open(ziel, "w", encoding="utf-8") as f:
        f.write("".join(text))


if __name__ == "__main__":
    main()
