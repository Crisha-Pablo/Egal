// =====================================================================
//  Gridfinity Rasier-Set, alles liegend (für die Schublade)
//  ---------------------------------------------------------------------
//  * Rasierschaum-Wiege: Gillette Shave Foam Sensitive (200 ml) ....... 5x2
//  * Rasierer-Halter: Gillette Fusion5 ProGlide (FlexBall) und
//    GilletteLabs Body + Intimate (3 Klingen), Kopf an Fuß ............ 4x2
//  * Klingenbox-Halter: die Plastik-Klingenboxen beider Rasierer ...... 2x3
//  * Passtest: flache Rahmen und ein Ring, um vorab die Passung zu prüfen
//  Die Rastergrößen rechnet das Modell aus den Maßen selbst aus.
//
//  Komplett parametrisch, ohne externe Bibliotheken.
//  Läuft ab OpenSCAD 2021.01. Werte ändern über Fenster > Customizer,
//  dann F6 (Rendern) und F7 (STL exportieren).
//
//  Gridfinity nach Zack Freedmans Spezifikation: 42 mm Raster,
//  7 mm Höheneinheit, Fußprofil 0,8 / 1,8 / 2,15 mm.
// =====================================================================

/* [Teil] */
// Welches Teil angezeigt bzw. exportiert wird
teil = "uebersicht"; // [uebersicht, rasierschaum, rasierer, klingenboxen, passtest]

/* [Rasierschaum-Dose] */
// Durchmesser der Dose in mm (bitte nachmessen)
dose_d = 50;
// Länge der Dose inklusive Kappe in mm (bitte nachmessen)
dose_l = 193;
// Spiel rundherum (mm)
dose_spiel = 0.8;
// Spiel an jedem Ende (mm)
dose_spiel_ende = 3;
// Anzahl der Auflagestege
dose_stege = 3;
// Dicke eines Auflagestegs (mm)
dose_steg_d = 4;
// Wandstärke der Wiege (mm)
dose_wand = 1.2;
// Höhe der Wiege in Gridfinity-Einheiten (1 Einheit = 7 mm)
dose_hoehe_u = 4;

/* [Gillette Fusion5 ProGlide] */
// Gesamtlänge vom Griffende bis zur Oberkante der Klinge (mm)
pg_laenge = 156;
// Breite des Klingenkopfs (mm)
pg_kopf_b = 43;
// Länge des Kopfs entlang des Rasierers, von oben gesehen (mm)
pg_kopf_l = 26;
// Breiteste Stelle des Griffs (mm)
pg_griff_b = 24;

/* [GilletteLabs Body + Intimate] */
// Gesamtlänge vom Griffende bis zur Oberkante der Klinge (mm)
bi_laenge = 145;
// Breite des Klingenkopfs (mm)
bi_kopf_b = 39;
// Länge des Kopfs entlang des Rasierers, von oben gesehen (mm)
bi_kopf_l = 24;
// Breiteste Stelle des Griffs (mm)
bi_griff_b = 19;

/* [Rasierer-Halter] */
// Welche Rasierer in den Halter kommen
rasierer_auswahl = "beide"; // [beide, proglide, body_intimate]
// Spiel rund um die Rasierer (mm)
rasierer_spiel = 1;
// Tiefe der Griffrinne (mm)
griff_tiefe = 10;
// Tiefe der Kopfmulde (mm)
kopf_tiefe = 12;
// Mindeststeg zwischen den Mulden (mm)
rasierer_steg = 2;
// Einführfase an den Rasierer-Mulden (mm), klein halten, die Stege sind schmal
rasierer_fase = 0.8;
// Höhe in Gridfinity-Einheiten
rasierer_hoehe_u = 3;

/* [Klingenboxen] */
// ProGlide-Box: Länge, längste Seite (mm)
pg_box_l = 72;
// ProGlide-Box: Breite (mm)
pg_box_b = 50;
// ProGlide-Box: Höhe, so liegt sie im Fach (mm)
pg_box_h = 30;
// Anzahl ProGlide-Boxen
pg_box_anzahl = 1;
// Body+Intimate-Box: Länge, längste Seite (mm)
bi_box_l = 66;
// Body+Intimate-Box: Breite (mm)
bi_box_b = 46;
// Body+Intimate-Box: Höhe, so liegt sie im Fach (mm)
bi_box_h = 28;
// Anzahl Body+Intimate-Boxen
bi_box_anzahl = 1;
// Spiel pro Seite (mm)
box_spiel = 0.6;
// Wand zwischen zwei Fächern (mm)
box_steg = 2;
// So weit schauen die Boxen mindestens oben heraus (mm)
box_ueberstand = 8;
// Griffmulde zum Herausnehmen
box_griffmulde = true;
// Höhe in Gridfinity-Einheiten
box_hoehe_u = 3;

/* [Gridfinity] */
// Löcher für 6x2-mm-Magnete unten (im Bad eher weglassen, Magnete rosten)
magnete = false;
// Mindestwand um Aussparungen (mm)
min_wand = 2;
// Fase an der äußeren Oberkante (mm)
kante = 0.8;
// Einführfase an allen Öffnungen (mm)
einfuehr = 1.2;

/* [Hidden] */
$fa = 3;
$fs = 0.4;
raster = 42;
spalt = 0.5;                     // Bin = 41,5 mm pro Einheit
r_aussen = 3.75;
hu = 7;
fuss_c1 = 0.8;
fuss_v = 1.8;
fuss_c2 = 2.15;
fuss_h = fuss_c1 + fuss_v + fuss_c2;   // 4,75 mm
boden = 1.2;                           // Material über dem Fußprofil
z_boden = fuss_h + boden;              // tiefster Punkt einer Aussparung
magnet_d = 6.5;
magnet_h = 2.4;
magnet_abstand = 26;
eps = 0.01;
schrift = "Liberation Sans:style=Bold";

// ---------------------------------------------------------------------
//  Hilfsfunktionen
// ---------------------------------------------------------------------

// Rastereinheiten, damit "innen" mm plus Mindestwand hineinpassen
function einheiten(innen) = max(1, ceil((innen + 2 * min_wand + spalt) / raster));
function aussen(n) = n * raster - spalt;
function innen(n) = aussen(n) - 2 * min_wand;
function summe(v, i = 0) = i >= len(v) ? 0 : v[i] + summe(v, i + 1);
function maximum(v) = max([for (x = v) x]);

// ---------------------------------------------------------------------
//  Gridfinity-Grundkörper
// ---------------------------------------------------------------------

module abgerundetes_rechteck(sx, sy, h, r) {
    hull() for (x = [-1, 1], y = [-1, 1])
        translate([x * (sx / 2 - r), y * (sy / 2 - r), 0]) cylinder(h = h, r = r);
}

module rundrechteck_2d(sx, sy, r) {
    hull() for (x = [-1, 1], y = [-1, 1])
        translate([x * (sx / 2 - r), y * (sy / 2 - r)]) circle(r = r);
}

// Langloch (Stadion), b entlang X, d entlang Y
module stadion(b, d) {
    if (b >= d) hull() for (s = [-1, 1]) translate([s * (b - d) / 2, 0]) circle(d = d);
    else        hull() for (s = [-1, 1]) translate([0, s * (d - b) / 2]) circle(d = b);
}

// Ein Fuß (eine Rasterzelle), 41,5 mm oben, 35,6 mm unten.
// Jeder Profilabschnitt bekommt eine eigene Hülle: Eine gemeinsame Hülle
// würde die senkrechte Stufe überbrücken und der Fuß säße nicht in der Grundplatte.
// Jeder Abschnitt ragt eps senkrecht in den nächsten hinein (innerhalb von dessen
// Volumen), sonst exportiert OpenSCAD 2021 die Abschnitte als getrennte Hüllen.
module fuss() {
    c = (raster - spalt) / 2 - r_aussen;
    r0 = r_aussen - fuss_c2 - fuss_c1;   // 0,8
    r1 = r_aussen - fuss_c2;             // 1,6
    module ecken() { for (x = [-c, c], y = [-c, c]) translate([x, y, 0]) children(); }
    hull() ecken() {
        cylinder(h = fuss_c1, r1 = r0, r2 = r1);
        translate([0, 0, fuss_c1]) cylinder(h = eps, r = r1);
    }
    hull() ecken() translate([0, 0, fuss_c1]) cylinder(h = fuss_v + eps, r = r1);
    hull() ecken() {
        translate([0, 0, fuss_c1 + fuss_v]) cylinder(h = fuss_c2, r1 = r1, r2 = r_aussen);
        translate([0, 0, fuss_h]) cylinder(h = eps, r = r_aussen);
    }
}

module zellen(nx, ny) {
    for (i = [0:nx - 1], j = [0:ny - 1])
        translate([(i - (nx - 1) / 2) * raster, (j - (ny - 1) / 2) * raster, 0]) children();
}

// Massiver Block nx x ny mit Gridfinity-Füßen, Höhe h, Fase oben
module gridfinity_block(nx, ny, h) {
    sx = aussen(nx);
    sy = aussen(ny);
    echo(str("RASTER=", nx, "x", ny, "x", round(h / hu), "u"));
    difference() {
        union() {
            zellen(nx, ny) fuss();
            hull() {
                translate([0, 0, fuss_h]) abgerundetes_rechteck(sx, sy, h - fuss_h - kante, r_aussen);
                translate([0, 0, h - kante])
                    abgerundetes_rechteck(sx - 2 * kante, sy - 2 * kante, kante, r_aussen - kante);
            }
        }
        if (magnete) zellen(nx, ny)
            for (x = [-1, 1], y = [-1, 1])
                translate([x * magnet_abstand / 2, y * magnet_abstand / 2, -eps])
                    cylinder(h = magnet_h + eps, d = magnet_d);
    }
}

// Tasche für eine konvexe 2D-Form (Kind), Tiefe t unter der Oberkante h, mit Einführfase f
module tasche(t, h, f = einfuehr) {
    translate([0, 0, h - t]) linear_extrude(t + 1) children();
    hull() {
        translate([0, 0, h - f]) linear_extrude(eps) children();
        translate([0, 0, h]) linear_extrude(eps) offset(r = f) children();
    }
}

// U-förmige Griffmulde quer (entlang Y) durch das ganze Teil, Grund auf Höhe z_grund
module griffmulde(x, z_grund, r, laenge, h) {
    translate([x, 0, z_grund + r]) rotate([90, 0, 0]) hull() {
        cylinder(h = laenge, r = r, center = true);
        translate([0, h, 0]) cylinder(h = laenge, r = r, center = true);
    }
}

// ---------------------------------------------------------------------
//  Rasierschaum-Wiege (Dose liegt quer auf Auflagestegen)
// ---------------------------------------------------------------------

function wiege_mass() = let(r = dose_d / 2 + dose_spiel, L = dose_l + 2 * dose_spiel_ende)
    [r, L, einheiten(L), einheiten(2 * r)];

module rasierschaum_wiege() {
    m = wiege_mass();
    r = m[0];
    L = m[1];
    nx = m[2];
    ny = m[3];
    h = dose_hoehe_u * hu;
    iy = aussen(ny) - 2 * dose_wand;
    zc = z_boden + r;                         // Dosenachse
    rand = min(30, L / 4);                    // Abstand äußerer Stege vom Dosenende
    difference() {
        gridfinity_block(nx, ny, h);
        translate([0, 0, z_boden]) abgerundetes_rechteck(aussen(nx) - 2 * dose_wand, iy, h, r_aussen - dose_wand);
    }
    for (k = [0:dose_stege - 1]) {
        x = dose_stege == 1 ? 0 : -L / 2 + rand + k * (L - 2 * rand) / (dose_stege - 1);
        translate([x, 0, 0]) difference() {
            // Steg greift 0,5 mm in Boden und Wände, damit alles zu einem Körper verschmilzt
            translate([-dose_steg_d / 2, -iy / 2 - 0.5, z_boden - 0.5])
                cube([dose_steg_d, iy + 1, h - z_boden + 0.5]);
            translate([0, 0, zc]) rotate([0, 90, 0]) cylinder(h = dose_steg_d + 2, r = r, center = true);
            // kleine Fasen an beiden Kanten der Rundung
            c = 0.6;
            translate([dose_steg_d / 2 - c, 0, zc]) rotate([0, 90, 0])
                cylinder(h = c + eps, r1 = r, r2 = r + c + eps);
            translate([-dose_steg_d / 2 - eps, 0, zc]) rotate([0, 90, 0])
                cylinder(h = c + eps, r1 = r + c + eps, r2 = r);
        }
    }
}

// ---------------------------------------------------------------------
//  Rasierer-Halter (liegend, beide Rasierer Kopf an Fuß)
// ---------------------------------------------------------------------

// [Länge, Kopfbreite, Kopflänge, Griffbreite] inklusive Spiel
function rasierer_pg() = [pg_laenge, pg_kopf_b, pg_kopf_l, pg_griff_b] + [2, 2, 2, 2] * rasierer_spiel;
function rasierer_bi() = [bi_laenge, bi_kopf_b, bi_kopf_l, bi_griff_b] + [2, 2, 2, 2] * rasierer_spiel;

// Benötigte Innenmaße [x, y]
function rasierer_innen() = let(a = rasierer_pg(), b = rasierer_bi(), s = rasierer_steg)
    rasierer_auswahl == "proglide" ? [a[0], a[1]] :
    rasierer_auswahl == "body_intimate" ? [b[0], b[1]] :
    [max(a[0], b[0], a[2] + b[2] + s),
     max(a[1] + s + (b[1] + b[3]) / 2,   // ProGlide-Kopf neben Body+Intimate-Griff
         (a[1] + a[3]) / 2 + s + b[1],   // Body+Intimate-Kopf neben ProGlide-Griff
         a[1], b[1])];

function rasierer_raster() = let(i = rasierer_innen()) [einheiten(i[0]), einheiten(i[1])];

// Mulde für einen Rasierer: Griffende bei x = 0, Kopf bei +x, Achse auf y = 0
module rasierer_mulde(r, h) {
    L = r[0];
    K = r[1];
    T = r[2];
    G = r[3];
    // Griffrinne reicht bis in die Kopfmulde hinein
    tasche(griff_tiefe, h, rasierer_fase) translate([(L - T / 2) / 2, 0]) stadion(L - T / 2, G);
    tasche(kopf_tiefe, h, rasierer_fase) translate([L - T / 2, 0]) rundrechteck_2d(T, K, min(3, T / 3));
}

module rasierer_halter() {
    a = rasierer_pg();
    b = rasierer_bi();
    n = rasierer_raster();
    h = rasierer_hoehe_u * hu;
    ix = innen(n[0]);
    iy = innen(n[1]);
    beide = rasierer_auswahl == "beide";
    // ProGlide vorne mit Kopf rechts, Body+Intimate hinten mit Kopf links
    y_pg = beide ? -iy / 2 + a[1] / 2 : 0;
    y_bi = beide ? iy / 2 - b[1] / 2 : 0;
    // Griffmulde dort, wo die Griffe liegen
    x_mulde = beide ? (b[2] - a[2]) / 2 :
              rasierer_auswahl == "proglide" ? ix / 2 - a[0] / 2 - a[2] / 2 : -ix / 2 + b[0] / 2 + b[2] / 2;
    difference() {
        gridfinity_block(n[0], n[1], h);
        if (rasierer_auswahl != "body_intimate")
            translate([ix / 2 - a[0], y_pg, 0]) rasierer_mulde(a, h);
        if (rasierer_auswahl != "proglide")
            translate([-ix / 2 + b[0], y_bi, 0]) rotate(180) rasierer_mulde(b, h);
        griffmulde(x_mulde, h - griff_tiefe - 3, 11, aussen(n[1]) + 2, griff_tiefe + 10);
    }
}

// ---------------------------------------------------------------------
//  Klingenbox-Halter (Boxen liegen flach)
// ---------------------------------------------------------------------

// Liste aller Fächer: [Länge, Breite, Höhe] inklusive Spiel
function box_liste() = concat(
    [for (i = [0:1:pg_box_anzahl - 1]) [pg_box_l + 2 * box_spiel, pg_box_b + 2 * box_spiel, pg_box_h]],
    [for (i = [0:1:bi_box_anzahl - 1]) [bi_box_l + 2 * box_spiel, bi_box_b + 2 * box_spiel, bi_box_h]]);

// Reihe entlang X oder Spalte entlang Y, je nachdem was weniger Rasterfläche braucht
function box_layout() = let(
        v = box_liste(), n = len(v),
        reihe = [summe([for (b = v) b[0]]) + (n - 1) * box_steg, maximum([for (b = v) b[1]])],
        spalte = [maximum([for (b = v) b[0]]), summe([for (b = v) b[1]]) + (n - 1) * box_steg],
        zr = einheiten(reihe[0]) * einheiten(reihe[1]),
        zs = einheiten(spalte[0]) * einheiten(spalte[1]))
    zs <= zr ? ["spalte", spalte] : ["reihe", reihe];

module klingenbox_halter() {
    v = box_liste();
    lay = box_layout();
    spalte = lay[0] == "spalte";
    ges = lay[1];
    nx = einheiten(ges[0]);
    ny = einheiten(ges[1]);
    h = box_hoehe_u * hu;
    tiefe = [for (b = v) min(h - z_boden, max(5, b[2] - box_ueberstand))];
    // Mittelpunkte der Fächer
    pos = [for (i = [0:len(v) - 1]) spalte ?
        [0, -ges[1] / 2 + summe([for (j = [0:1:i - 1]) v[j][1] + box_steg]) + v[i][1] / 2] :
        [-ges[0] / 2 + summe([for (j = [0:1:i - 1]) v[j][0] + box_steg]) + v[i][0] / 2, 0]];
    mulde_r = min(12, min([for (b = v) b[0]]) / 2 - 4);
    difference() {
        gridfinity_block(nx, ny, h);
        for (i = [0:len(v) - 1]) translate([pos[i][0], pos[i][1], 0])
            tasche(tiefe[i], h) rundrechteck_2d(v[i][0], v[i][1], min(2, v[i][1] / 4));
        if (box_griffmulde && mulde_r > 4)
            for (x = spalte ? [0] : [for (p = pos) p[0]])
                griffmulde(x, h - 0.8 * min(tiefe), mulde_r, aussen(ny) + 2, h);
    }
}

// ---------------------------------------------------------------------
//  Passtest: flache Rahmen und Ring, 3 mm hoch
// ---------------------------------------------------------------------

pt_h = 3;      // Höhe
pt_w = 1.6;    // Wandstärke

module beschriftung(t, gr) {
    translate([0, 0, pt_h - 0.6])
        linear_extrude(1) text(t, size = gr, font = schrift, halign = "center", valign = "center");
}

// Umriss einer Rasierer-Mulde als 2D-Form (Griffende bei x = 0)
module rasierer_umriss(r) {
    translate([(r[0] - r[2] / 2) / 2, 0]) stadion(r[0] - r[2] / 2, r[3]);
    translate([r[0] - r[2] / 2, 0]) rundrechteck_2d(r[2], r[1], min(3, r[2] / 3));
}

// Rahmen um eine 2D-Form (Kind), Beschriftungslasche bei (lx, ly)
module test_rahmen(t, lx, ly) {
    difference() {
        union() {
            linear_extrude(pt_h) offset(r = pt_w) children();
            translate([lx, ly, 0]) linear_extrude(pt_h) rundrechteck_2d(max(24, len(t) * 3.6), 9, 2);
        }
        translate([0, 0, -1]) linear_extrude(pt_h + 2) children();
        translate([lx, ly, 0]) beschriftung(t, 3.6);
    }
}

module passtest() {
    a = rasierer_pg();
    b = rasierer_bi();
    rd = dose_d + 2 * dose_spiel;
    pg = [pg_box_l, pg_box_b] + [2, 2] * box_spiel;
    bi = [bi_box_l, bi_box_b] + [2, 2] * box_spiel;
    abst = 5;
    // Rasierer-Umrisse übereinander, Lasche mittig neben dem Griff
    y_pg = 0;
    y_bi = y_pg - a[1] / 2 - 2 * pt_w - abst - b[1] / 2;
    translate([-a[0] / 2, y_pg, 0]) test_rahmen("PROGLIDE", a[0] * 0.38, a[3] / 2 + pt_w + 3.5) rasierer_umriss(a);
    translate([-b[0] / 2, y_bi, 0]) test_rahmen("BODY+INT.", b[0] * 0.38, -b[3] / 2 - pt_w - 3.5) rasierer_umriss(b);
    // Klingenboxen und Dosenring in einer Reihe darunter
    y_reihe = y_bi - b[1] / 2 - 2 * pt_w - abst - 10 - max(pg[1], bi[1], rd) / 2;
    x0 = -max(a[0], b[0]) / 2 - pt_w;
    translate([x0 + pt_w + pg[0] / 2, y_reihe, 0])
        test_rahmen("PG-BOX", 0, pg[1] / 2 + pt_w + 3.5) rundrechteck_2d(pg[0], pg[1], 2);
    translate([x0 + 3 * pt_w + pg[0] + abst + bi[0] / 2, y_reihe, 0])
        test_rahmen("BI-BOX", 0, bi[1] / 2 + pt_w + 3.5) rundrechteck_2d(bi[0], bi[1], 2);
    translate([x0 + 5 * pt_w + pg[0] + bi[0] + 2 * abst + rd / 2, y_reihe, 0])
        test_rahmen("DOSE", 0, rd / 2 + pt_w + 3.5) circle(d = rd);
}

// ---------------------------------------------------------------------
//  Übersicht mit stilisierten Produkten (nur zur Ansicht, nicht drucken)
// ---------------------------------------------------------------------

farbe_halter = "#e9e6df";

module attrappe_dose() {
    // liegt entlang X, Boden links, Kappe rechts, Achse auf z = 0
    rotate([0, 90, 0]) translate([0, 0, -dose_l / 2]) {
        color("#2bb3b1") cylinder(h = dose_l * 0.5, d = dose_d);
        color("#151515") translate([0, 0, dose_l * 0.5]) cylinder(h = dose_l * 0.36, d = dose_d);
        color("#151515") translate([0, 0, dose_l * 0.86]) cylinder(h = 3, d1 = dose_d, d2 = dose_d - 6);
        color("#202020") translate([0, 0, dose_l * 0.86 + 3]) cylinder(h = dose_l * 0.14 - 3, d = dose_d - 6);
    }
}

// Griff liegend entlang X: Schnitte [x, Breite (Y), Dicke (Z)]
module griff_liegend(schnitte) {
    for (i = [0:len(schnitte) - 2]) hull() for (s = [schnitte[i], schnitte[i + 1]])
        translate([s[0], 0, 0]) rotate([0, 90, 0]) linear_extrude(eps) stadion(s[2], s[1]);
}

module klingenkopf_liegend(b, t, klingen) {
    // Klingenseite zeigt nach oben, leicht zum Griff geneigt
    rotate([0, -25, 0]) {
        color("#1c1c1c") cube([t, b, 9], center = true);
        color("#c9c9c9") for (k = [0:klingen - 1])
            translate([-t / 2 + 3 + k * (t - 6) / max(1, klingen - 1), 0, 4.6]) cube([0.9, b - 6, 0.6], center = true);
    }
}

// Rasierer liegend: Griffende bei x = 0, Kopf bei +x, Griffunterseite auf z = 0
module attrappe_rasierer(r, farbe_griff, klingen, dicke) {
    L = r[0] - 2 * rasierer_spiel;
    K = r[1] - 2 * rasierer_spiel;
    T = r[2] - 2 * rasierer_spiel;
    G = r[3] - 2 * rasierer_spiel;
    translate([rasierer_spiel, 0, dicke / 2]) {
        color(farbe_griff) griff_liegend([[0, G - 2, dicke * 0.8], [L * 0.15, G, dicke], [L * 0.55, G - 1, dicke],
                                          [L - T - 14, G * 0.55, dicke * 0.7], [L - T - 2, 9, 8]]);
        color("#a9a9a9") hull() {
            translate([L - T - 6, 0, 0]) sphere(d = 8);
            translate([L - T / 2 - 2, 0, 6]) sphere(d = 7);
        }
        translate([L - T / 2, 0, 9]) klingenkopf_liegend(K, T - 4, klingen);
    }
}

module attrappe_box(l, b, h) {
    color("#3c6fd1", 0.85) abgerundetes_rechteck(l, b, h, 3);
}

// Teil auf Rasterzelle (cx, cy) unten links setzen
module setze(cx, cy, nx, ny) {
    translate([(cx + nx / 2) * raster, (cy + ny / 2) * raster, 0]) children();
}

module uebersicht() {
    w = wiege_mass();
    rr = rasierer_raster();
    a = rasierer_pg();
    b = rasierer_bi();
    lay = box_layout();
    bn = [einheiten(lay[1][0]), einheiten(lay[1][1])];
    x_box = max(w[2], rr[0]);
    breite = x_box + bn[0];
    tief = max(w[3] + rr[1], bn[1]);

    // ganze Szene um den Ursprung zentrieren (für die Kamera in build.sh)
    translate([-breite * raster / 2, -tief * raster / 2, 0]) {
    // Grundplatte (nur angedeutet)
    color("#8d8f93") translate([0, 0, -2.5]) cube([breite * raster, tief * raster, 2.5]);

    setze(0, 0, w[2], w[3]) {
        color(farbe_halter) rasierschaum_wiege();
        translate([0, 0, z_boden + dose_d / 2 + 0.3]) attrappe_dose();
    }
    setze(0, w[3], rr[0], rr[1]) {
        h = rasierer_hoehe_u * hu;
        ix = innen(rr[0]);
        iy = innen(rr[1]);
        color(farbe_halter) rasierer_halter();
        translate([ix / 2 - a[0], -iy / 2 + a[1] / 2, h - griff_tiefe])
            attrappe_rasierer(a, "#5b5d60", 5, 14);
        translate([-ix / 2 + b[0], iy / 2 - b[1] / 2, h - griff_tiefe]) rotate(180)
            attrappe_rasierer(b, "#1e1e1e", 3, 13);
    }
    setze(x_box, 0, bn[0], bn[1]) {
        h = box_hoehe_u * hu;
        v = box_liste();
        color(farbe_halter) klingenbox_halter();
        if (lay[0] == "spalte" && len(v) == 2)
            for (i = [0:1]) {
                y = i == 0 ? -lay[1][1] / 2 + v[0][1] / 2 : lay[1][1] / 2 - v[1][1] / 2;
                t = min(h - z_boden, max(5, v[i][2] - box_ueberstand));
                translate([0, y, h - t]) attrappe_box(v[i][0] - 2 * box_spiel, v[i][1] - 2 * box_spiel, v[i][2]);
            }
    }
    }
}

// ---------------------------------------------------------------------
//  Auswahl
// ---------------------------------------------------------------------

if (teil == "rasierschaum") rasierschaum_wiege();
else if (teil == "rasierer") rasierer_halter();
else if (teil == "klingenboxen") klingenbox_halter();
else if (teil == "passtest") passtest();
else uebersicht();
