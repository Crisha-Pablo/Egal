// =====================================================================
//  Gridfinity Rasier-Station: ein Teil, alles liegend, für die Schublade
//  ---------------------------------------------------------------------
//  Hinten:  Rasierschaum-Dose in einer Mulde exakt in Dosenform
//  Vorne:   Gillette ProGlide und kleiner 3-Klingen-Rasierer Kopf an Fuß,
//           links und rechts daneben je ein Klingenfach
//  Gestaltung wie ein Verpackungseinsatz: jedes Teil in seiner eigenen
//  Mulde, weiche Ecken, gerundete Kanten an allen Mulden, gerundete
//  Muldenböden, ovale Griffmulde, Schattenfuge über der Grundplatte.
//  Rundungen an nicht konvexen Formen entstehen in Stufen von einer
//  Schichthöhe, gedruckt sind sie so glatt wie echte Rundungen.
//  Die Rastergröße rechnet das Modell aus den Maßen selbst aus (5 x 4).
//
//  Umrisse: kleiner Rasierer und Dose aus deinen Fotos vermessen
//  (werkzeug/fotos_vermessen.py), ProGlide aus einem Produktbild
//  (werkzeug/umriss_aus_bild.py). Die Daten stehen in umrisse.scad.
//
//  Läuft ab OpenSCAD 2021.01, ohne externe Bibliotheken.
//  Werte ändern über Fenster > Customizer, dann F6 und F7.
//  Gridfinity nach Zack Freedmans Spezifikation: 42 mm Raster,
//  7 mm Höheneinheit, Fußprofil 0,8 / 1,8 / 2,15 mm.
// =====================================================================

/* [Teil] */
// Welches Teil angezeigt bzw. exportiert wird
teil = "station"; // [station, passtest, uebersicht]

/* [Maßstab und Dose] */
// Durchmesser der Rasierschaum-Dose in mm. Zugleich Maßstab für alle Fotomaße (49 mm laut Hersteller). Nachgemessen eintragen, dann passt alles exakt.
dose_d = 49;
// Spiel rundherum (mm)
dose_spiel = 0.8;
// Spiel an jedem Ende (mm)
dose_spiel_ende = 1.5;

/* [Rasierer] */
// ProGlide: Gesamtlänge vom Griffende bis zur Klingenoberkante (mm). VORLÄUFIG: aus einem Produktbild geschätzt
pg_laenge = 135;
// Spiel rund um die Rasierer (mm)
rasierer_spiel = 0.8;
// Tiefe der Rasierer-Mulden (mm). Bei 13 mm liegt der Griff fast bündig
rasierer_tiefe = 13;
// Steg zwischen den beiden Rasierer-Mulden an der Oberkante (mm)
rasierer_steg = 2.4;

/* [Klingenfächer] */
// Mindestbreite eines Klingenfachs (mm)
fach_breite_min = 20;
// Tiefe der Klingenfächer (mm)
fach_tiefe = 12;

/* [Gestaltung] */
// Höhe in Gridfinity-Einheiten (1 Einheit = 7 mm)
hoehe_u = 3;
// Mindestabstand der Mulden zum Rand (mm)
rand_min = 5;
// Mindestabstand zwischen den Mulden (mm)
abstand_min = 5;
// Eckenradius oben (mm)
ecken_r = 9;
// Rundung der oberen Außenkante (mm)
kante_r = 2.5;
// Rundung der Kanten an allen Mulden (mm)
mulden_r = 1.5;
// Rundung am Boden der Rasierer-Mulden (mm)
boden_r = 2;
// Rundung am Boden der Klingenfächer (mm)
fach_boden_r = 5;
// Schattenfuge über der Grundplatte (mm)
fuge = 1;
// Schichthöhe beim Drucken (mm). Rundungen entstehen in Stufen dieser Höhe und werden so gedruckt glatt
schicht = 0.2;
// Löcher für 6x2-mm-Magnete unten (im Bad eher weglassen, Magnete rosten)
magnete = false;

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
H = hoehe_u * hu;

include <umrisse.scad>
foto_k = dose_d / 49;                  // Fotomaße wurden mit 49 mm Dosendurchmesser vermessen

// ---------------------------------------------------------------------
//  Hilfsfunktionen
// ---------------------------------------------------------------------

function aussen(n) = n * raster - spalt;
// Versatz einer Rundung mit Radius r im Abstand d von der Kante (d = 0: r, d = r: 0)
function rund(r, d) = r - sqrt(max(0, r * r - (r - d) * (r - d)));
// Anzahl Stufen für eine Rundung mit Radius r: je Schicht eine
function stufen(r) = max(2, ceil(r / schicht));

module rundrechteck_2d(sx, sy, r) {
    hull() for (x = [-1, 1], y = [-1, 1])
        translate([x * (sx / 2 - r), y * (sy / 2 - r)]) circle(r = r);
}

// Langloch (Stadion), b entlang X, d entlang Y
module stadion(b, d) {
    if (b >= d) hull() for (s = [-1, 1]) translate([s * (b - d) / 2, 0]) circle(d = d);
    else        hull() for (s = [-1, 1]) translate([0, s * (d - b) / 2]) circle(d = b);
}

// ---------------------------------------------------------------------
//  Gridfinity-Fuß und Grundkörper
// ---------------------------------------------------------------------

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

// Körper: unten Schattenfuge, Ecken werden nach oben weicher, Oberkante gerundet
module koerper(nx, ny) {
    sx = aussen(nx);
    sy = aussen(ny);
    echo(str("RASTER=", nx, "x", ny, "x", hoehe_u, "u"));
    zellen(nx, ny) fuss();
    hull() {
        translate([0, 0, fuss_h]) linear_extrude(eps) rundrechteck_2d(sx - 2 * fuge, sy - 2 * fuge, r_aussen - fuge);
        translate([0, 0, fuss_h + fuge]) linear_extrude(eps) rundrechteck_2d(sx, sy, r_aussen);
        translate([0, 0, H - kante_r]) linear_extrude(eps) rundrechteck_2d(sx, sy, ecken_r);
        for (i = [1:6]) let(w = i * 15, e = kante_r * (1 - cos(w)))
            translate([0, 0, H - kante_r + kante_r * sin(w) - eps])
                linear_extrude(eps) rundrechteck_2d(sx - 2 * e, sy - 2 * e, max(0.5, ecken_r - e));
    }
}

// ---------------------------------------------------------------------
//  Mulden
// ---------------------------------------------------------------------

// Mulde für eine 2D-Form (Kind): Tiefe t, Spiel s, oben gerundete Kante (rk), unten gerundeter Boden (rb).
// Rundungen in Stufen, das geht auch bei nicht-konvexen Formen wie den Rasierern.
module mulde(t, s, rk, rb) {
    z0 = H - t;
    translate([0, 0, z0 + rb - eps]) linear_extrude(t - rb - rk + 2 * eps) offset(r = s) children();
    nb = stufen(rb);
    nk = stufen(rk);
    if (rb > 0) for (k = [1:nb])
        translate([0, 0, z0 + (k - 1) * rb / nb])
            linear_extrude(rb / nb + eps) offset(r = s - rund(rb, (k - 0.5) * rb / nb)) children();
    if (rk > 0) for (k = [1:nk])
        translate([0, 0, H - k * rk / nk])
            linear_extrude(rk / nk + (k == 1 ? 1 : eps)) offset(r = s + rund(rk, (k - 0.5) * rk / nk)) children();
}

// Mulde für eine konvexe 2D-Form (Kind), ohne Stufen: Boden und Wand sind zusammen konvex
// und werden eine Hülle, die nach oben aufgehende Kantenrundung eine Kette von Hüllen.
module mulde_konvex(t, rk, rb) {
    z0 = H - t;
    n = 12;
    module schnitt(z, v) translate([0, 0, z]) linear_extrude(eps) offset(r = v) children();
    hull() {
        for (i = [0:n]) let(w = 90 * i / n)
            schnitt(z0 + rb - rb * cos(w), -rb + rb * sin(w)) children();
        schnitt(H - rk, 0) children();
    }
    kante = [for (i = [0:n]) let(w = 90 * i / n) [H - rk + rk * sin(w), rk - rk * cos(w)]];
    for (i = [0:n - 1]) hull() for (p = [kante[i], kante[i + 1]]) schnitt(p[0], p[1]) children();
    translate([0, 0, H - eps]) linear_extrude(1) offset(r = rk) children();
}

// ---- Dose: Längsprofil [s, Radius mit Spiel], s = 0 am Dosenboden

function dose_laenge() = dose_l_zu_d * dose_d;
function dose_trog_profil() = let(
        D = dose_d, L = dose_laenge(), sp = dose_spiel, se = dose_spiel_ende,
        oben = [for (i = [len(dose_oben) - 1:-1:0]) if (dose_oben[i][0] >= 0.066)
                    [L - dose_oben[i][0] * D, dose_oben[i][1] * D + sp]])
    concat([[-se, D / 2 + sp]], oben, [[L + se, oben[len(oben) - 1][1]]]);

// Umriss der Dosenmulde in der Höhe, die dz unter der Dosenachse liegt (2D, x = s - L/2)
module trog_umriss(dz) {
    L = dose_laenge();
    pr = dose_trog_profil();
    n = len(pr);
    // Enden 0,05 mm über die Stirnflächen hinaus, damit Rundung und Mulde sich überlappen statt sich nur an einer Kante zu berühren
    h = [for (i = [0:n - 1]) [pr[i][0] - L / 2 + (i == 0 ? -0.05 : i == n - 1 ? 0.05 : 0),
                               pr[i][1] > abs(dz) ? sqrt(pr[i][1] * pr[i][1] - dz * dz) : 0]];
    polygon(concat([for (p = h) [p[0], p[1]]], [for (i = [len(h) - 1:-1:0]) [h[i][0], -h[i][1]]]));
}

// Mulde in exakter Dosenform (Rotationskörper), Achse auf Höhe zc, Kante gerundet
module dosen_mulde(zc) {
    L = dose_laenge();
    prof = dose_trog_profil();
    translate([-L / 2, 0, zc]) rotate([0, 90, 0])
        rotate_extrude($fn = 120) polygon(concat([[0, prof[0][0]]], [for (p = prof) [p[1], p[0]]], [[0, prof[len(prof) - 1][0]]]));
    n = stufen(mulden_r);
    for (k = [1:n]) {
        d = (k - 0.5) * mulden_r / n;
        translate([0, 0, H - k * mulden_r / n])
            linear_extrude(mulden_r / n + (k == 1 ? 1 : eps)) offset(r = rund(mulden_r, d)) trog_umriss(zc - (H - d));
    }
}

// ---- Rasierer: Profile in mm [Abstand vom Griffende, halbe Breite]

function profil_pg() = [for (p = pg_profil) p * pg_laenge];
function profil_klein() = [for (p = bi_profil_mm) p * foto_k];
function profil_laenge(pr) = pr[len(pr) - 1][0];
function profil_max(pr) = max([for (p = pr) p[1]]);
function halb_bei(pr, s) = (s < 0 || s > profil_laenge(pr)) ? 0 : lookup(s, pr);

// Umriss als 2D-Form: Griffende bei x = 0, Kopf bei +x
module rasierer_form(pr) {
    polygon(concat([for (p = pr) [p[0], p[1]]], [for (i = [len(pr) - 1:-1:0]) [pr[i][0], -pr[i][1]]]));
}

// Ovale Griffmulde: Halb-Ellipsoid, die Kante als Kette von Hüllen glatt gerundet
module oval_mulde(a, b, c) {
    n = 12;
    scale([a, b, c]) sphere(r = 1, $fn = 64);
    // [Höhe, Versatz, Größe der Ellipse in dieser Tiefe]
    rand = [for (i = [0:n]) let(w = 90 * i / n, d = mulden_r - mulden_r * sin(w))
                [-d, mulden_r - mulden_r * cos(w), sqrt(max(0, 1 - pow(d / c, 2)))]];
    for (i = [0:n - 1]) hull() for (p = [rand[i], rand[i + 1]])
        translate([0, 0, p[0]]) linear_extrude(eps) offset(r = p[1]) scale([a * p[2], b * p[2]]) circle(r = 1, $fn = 64);
    translate([0, 0, -eps]) linear_extrude(1) offset(r = mulden_r) scale([a, b]) circle(r = 1, $fn = 64);
}

// ---------------------------------------------------------------------
//  Anordnung (alles in mm, Ursprung = Mitte der Station)
// ---------------------------------------------------------------------

// [nx, ny, zc Dose, y Dose, x Griffende ProGlide, x Griffende klein, y ProGlide, y klein,
//  Fachbreite, Fachlänge, x Fach, y Rasierer-Band, Bandhöhe, Bandlänge, x Griffmulde]
function layout() = let(
        // Dose: liegt 0,6 mm über dem tiefsten erlaubten Punkt
        D = dose_d, rt = D / 2 + dose_spiel, L = dose_laenge(),
        zc = z_boden + 0.6 + rt,
        w_oben = zc > H ? sqrt(max(0, rt * rt - pow(zc - H, 2))) : rt,
        band_dose = 2 * max(w_oben + mulden_r, D / 2 + 1),      // auch die Dose selbst ragt nicht über
        l_dose = L + 2 * dose_spiel_ende + 2 * mulden_r,
        // Rasierer Kopf an Fuß: ProGlide vorne mit Kopf rechts, kleiner hinten mit Kopf links
        a = profil_pg(), b = profil_klein(), sp = rasierer_spiel, rk = mulden_r,
        La = profil_laenge(a), Lb = profil_laenge(b),
        l_raz = max(La, Lb) + 2 * (sp + rk),
        xa = l_raz / 2 - sp - rk - La,
        xb = -l_raz / 2 + sp + rk + Lb,
        summe = max([for (x = [-l_raz / 2:0.5:l_raz / 2]) halb_bei(a, x - xa) + halb_bei(b, xb - x)]),
        d = summe + 2 * (sp + rk) + rasierer_steg,
        am = profil_max(a), bm = profil_max(b),
        band_raz = am + bm + d + 2 * (sp + rk),
        // Raster: Rasierer plus zwei Klingenfächer nebeneinander, darüber die Dose
        x_bedarf = max(l_dose, l_raz + 2 * (abstand_min + fach_breite_min + 2 * rk)) + 2 * rand_min,
        y_bedarf = band_dose + band_raz + abstand_min + 2 * rand_min,
        nx = max(1, ceil((x_bedarf + spalt) / raster)),
        ny = max(1, ceil((y_bedarf + spalt) / raster)),
        sx = aussen(nx), sy = aussen(ny),
        // Freiraum in y gleichmäßig: Rand oben, Abstand, Rand unten
        g = (sy - band_dose - band_raz) / 3,
        y_dose = sy / 2 - g - band_dose / 2,
        y_raz = -sy / 2 + g + band_raz / 2,
        ya = y_raz - band_raz / 2 + am + sp + rk,
        // Klingenfächer füllen die Breite links und rechts der Rasierer
        fach_b = (sx - 2 * rand_min - l_raz - 2 * abstand_min) / 2 - 2 * rk,
        x_fach = l_raz / 2 + abstand_min + rk + fach_b / 2)
    [nx, ny, zc, y_dose, xa, xb, ya, ya + d, fach_b, band_raz - 2 * rk, x_fach, y_raz, band_raz, l_raz, (xa + xb) / 2];

// ---------------------------------------------------------------------
//  Station
// ---------------------------------------------------------------------

module station() {
    lay = layout();
    a = profil_pg();
    b = profil_klein();
    sp = rasierer_spiel;
    t = min(rasierer_tiefe, H - z_boden);
    xm = lay[14];
    // Griffmulde: quer über beide Griffe, etwas tiefer als die Rasierer-Mulden
    y_vorne = lay[6] - halb_bei(a, xm - lay[4]) - sp;
    y_hinten = lay[7] + halb_bei(b, lay[5] - xm) + sp;
    echo(str("DOSE: ", dose_laenge(), " x ", dose_d, " mm, Klingenfächer ", lay[8], " x ", lay[9], " mm"));
    difference() {
        koerper(lay[0], lay[1]);
        translate([0, lay[3], 0]) dosen_mulde(lay[2]);
        translate([lay[4], lay[6], 0]) mulde(t, sp, mulden_r, boden_r) rasierer_form(a);
        translate([lay[5], lay[7], 0]) rotate(180) mulde(t, sp, mulden_r, boden_r) rasierer_form(b);
        translate([xm, (y_vorne + y_hinten) / 2, H])
            oval_mulde(12, (y_hinten - y_vorne) / 2 + 3, min(t + 1.5, H - z_boden));
        for (s = [-1, 1]) translate([s * lay[10], lay[11], 0])
            mulde_konvex(min(fach_tiefe, H - z_boden), mulden_r, fach_boden_r) stadion(lay[8], lay[9]);
        if (magnete) zellen(lay[0], lay[1])
            for (x = [-1, 1], y = [-1, 1])
                translate([x * magnet_abstand / 2, y * magnet_abstand / 2, -eps])
                    cylinder(h = magnet_h + eps, d = magnet_d);
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

// Die Rasierer-Rahmen haben genau die Muldenform. Der Ring hat genau den Durchmesser der
// Dosenmulde: Passt die Dose sauber hinein, stimmt der Maßstab für alle Fotomaße.
module passtest() {
    a = profil_pg();
    b = profil_klein();
    sp = rasierer_spiel;
    rd = dose_d + 2 * dose_spiel;
    abst = 5;
    La = profil_laenge(a);
    Lb = profil_laenge(b);
    am = profil_max(a) + sp;
    bm = profil_max(b) + sp;
    translate([-La / 2, 0, 0])
        test_rahmen("PROGLIDE", 0.3 * La, halb_bei(a, 0.3 * La) + sp + pt_w + 3.5)
            offset(r = sp) rasierer_form(a);
    y_kl = -am - bm - 2 * pt_w - abst;
    translate([-Lb / 2, y_kl, 0])
        test_rahmen("KLEIN", 0.3 * Lb, -halb_bei(b, 0.3 * Lb) - sp - pt_w - 3.5)
            offset(r = sp) rasierer_form(b);
    translate([max(La, Lb) / 2 + pt_w + abst + rd / 2 + pt_w, y_kl / 2, 0])
        test_rahmen("DOSE", 0, -rd / 2 - pt_w - 3.5) circle(d = rd);
}

// ---------------------------------------------------------------------
//  Attrappen für die Vorschau (nur zur Ansicht, nicht drucken)
// ---------------------------------------------------------------------

// Dose liegend entlang x, Boden bei x = -L/2, Achse auf z = 0. teil_nr 0 = unten (türkis), 1 = oben (schwarz)
module attrappe_dose(teil_nr) {
    L = dose_laenge();
    o = dose_oben[len(dose_oben) - 1][0] * dose_d;
    k = (L - o) * 0.55;
    rotate([0, 90, 0]) translate([0, 0, -L / 2]) {
        if (teil_nr == 0) cylinder(h = k, d = dose_d, $fn = 120);
        if (teil_nr == 1) {
            translate([0, 0, k]) cylinder(h = L - o - k, d = dose_d, $fn = 120);
            translate([0, 0, L - o]) rotate_extrude($fn = 120)
                polygon(concat([[0, 0]], [for (i = [len(dose_oben) - 1:-1:0])
                    [dose_oben[i][1] * dose_d, o - dose_oben[i][0] * dose_d]], [[0, o]]));
        }
    }
}

// Rasierer liegend: Griffende bei x = 0, Kopf bei +x, Unterseite auf z = 0.
// teil_nr 0 = Griff und Hals, 1 = Klingenkopf, 2 = Klingen (hell)
module attrappe_rasierer(pr, teil_nr, kopf_hoehe) {
    L = profil_laenge(pr);
    m = profil_max(pr);
    s_kopf = min([for (p = pr) if (p[1] > 0.8 * m) p[0]]);
    kl = L - s_kopf;
    ss = [for (s = [1:3:s_kopf - 2]) s];
    if (teil_nr == 0) for (i = [0:len(ss) - 2]) hull() for (s = [ss[i], ss[i + 1]]) {
        w = max(1.2, halb_bei(pr, s));
        dick = min(2 * w, 13.5);
        translate([s, 0, dick / 2]) scale([1.6, w, dick / 2]) sphere(r = 1, $fn = 24);
    }
    if (teil_nr == 0) hull() {   // Hals hoch zum Kopf
        translate([ss[len(ss) - 1], 0, 5]) sphere(r = 3.5, $fn = 24);
        translate([s_kopf + kl * 0.3, 0, kopf_hoehe - 4]) sphere(r = 3, $fn = 24);
    }
    translate([s_kopf + kl / 2, 0, kopf_hoehe]) rotate([0, -18, 0]) {
        if (teil_nr == 1) hull() for (x = [-1, 1], y = [-1, 1])
            translate([x * (kl / 2 - 2), y * (m - 2), -3]) cylinder(h = 6, r = 2, $fn = 16);
        if (teil_nr == 2) for (j = [-1:1]) translate([j * kl * 0.22, 0, 3.05])
            cube([0.9, 2 * m - 6, 0.3], center = true);
    }
}

// Ersatzklingen in einem Fach (schlichte Kästchen)
module attrappe_klingen(b, l, anzahl) {
    for (i = [0:anzahl - 1]) translate([0, (i - (anzahl - 1) / 2) * (l / anzahl), 0])
        hull() for (x = [-1, 1], y = [-1, 1])
            translate([x * (b / 2 - 2.5), y * (min(l / anzahl, 20) / 2 - 2.5), 0]) cylinder(h = 7, r = 2, $fn = 16);
}

// Einzelne Attrappen in Stationskoordinaten (für die Renderings)
module attrappe(name) {
    lay = layout();
    t = min(rasierer_tiefe, H - z_boden);
    if (name == "dose_unten" || name == "dose_oben")
        translate([0, lay[3], lay[2] - dose_spiel]) attrappe_dose(name == "dose_unten" ? 0 : 1);
    for (n = [0:2]) if (name == str("pg_", n))
        translate([lay[4], lay[6], H - t]) attrappe_rasierer(profil_pg(), n, 12);
    for (n = [0:2]) if (name == str("klein_", n))
        translate([lay[5], lay[7], H - t]) rotate(180) attrappe_rasierer(profil_klein(), n, 16);
    if (name == "klingen")
        for (s = [-1, 1]) translate([s * lay[10], lay[11], H - min(fach_tiefe, H - z_boden) + 0.5])
            attrappe_klingen(lay[8] - 6, lay[9] - 16, 2);
}

module uebersicht() {
    color("#ecebe8") station();
    color("#22b3b0") attrappe("dose_unten");
    color("#141414") attrappe("dose_oben");
    color("#56585c") attrappe("pg_0");
    color("#1b1b1d") attrappe("klein_0");
    color("#202022") { attrappe("pg_1"); attrappe("klein_1"); attrappe("klingen"); }
    color("#d8d8d8") { attrappe("pg_2"); attrappe("klein_2"); }
}

// ---------------------------------------------------------------------
//  Auswahl
// ---------------------------------------------------------------------

if (teil == "station") station();
else if (teil == "passtest") passtest();
else if (teil == "uebersicht") uebersicht();
else attrappe(teil);
