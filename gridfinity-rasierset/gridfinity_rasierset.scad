// =====================================================================
//  Gridfinity Rasier-Set, alles liegend (für die Schublade)
//  ---------------------------------------------------------------------
//  * Rasierschaum-Wiege: Gillette Shave Foam Sensitive, mit Endanschlägen
//  * Rasierer-Halter: Gillette Fusion5 ProGlide und der kleine
//    3-Klingen-Rasierer, Kopf an Fuß, Mulden in exakter Umrissform
//  * Klingenbox-Halter: die Plastik-Klingenboxen beider Rasierer
//  * Passtest: flache Rahmen und ein Ring, um vorab die Passung zu prüfen
//  Die Rastergrößen rechnet das Modell aus den Maßen selbst aus.
//
//  Umrisse: kleiner Rasierer und Dose aus deinen Fotos vermessen
//  (werkzeug/fotos_vermessen.py), ProGlide aus einem Produktbild
//  (werkzeug/umriss_aus_bild.py). Die Daten stehen in umrisse.scad.
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

/* [Maßstab und Dose] */
// Durchmesser der Rasierschaum-Dose in mm. Das ist zugleich der Maßstab für alle Fotomaße: 49 mm laut Hersteller. Nachgemessen eintragen, dann passt alles exakt.
dose_d = 49;
// Spiel rundherum (mm)
dose_spiel = 0.8;
// Spiel an jedem Ende bis zum Anschlag (mm)
dose_spiel_ende = 1.5;
// Anzahl der Auflagestege unter dem Dosenkörper
dose_stege = 3;
// Dicke eines Auflagestegs (mm)
dose_steg_d = 4;
// Wandstärke der Wiege (mm)
dose_wand = 1.2;
// Höhe der Wiege in Gridfinity-Einheiten (1 Einheit = 7 mm)
dose_hoehe_u = 4;

/* [Gillette Fusion5 ProGlide] */
// Gesamtlänge vom Griffende bis zur Oberkante der Klinge (mm). VORLÄUFIG: Umriss aus einem Produktbild, Größe geschätzt
pg_laenge = 135;

/* [Rasierer-Halter] */
// Welche Rasierer in den Halter kommen
rasierer_auswahl = "beide"; // [beide, proglide, klein]
// Spiel rund um die Rasierer (mm)
rasierer_spiel = 0.8;
// Tiefe der Mulden (mm). 13 mm: der Griff liegt fast bündig, der Kopf sitzt in seiner Mulde
rasierer_tiefe = 13;
// Mindeststeg zwischen den Mulden (mm)
rasierer_steg = 2;
// Einführfase an den Rasierer-Mulden (mm)
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

include <umrisse.scad>
foto_k = dose_d / 49;                  // Fotomaße wurden mit 49 mm Dosendurchmesser vermessen

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
//  Rasierschaum-Wiege (Dose liegt auf Auflagestegen, Anschläge an beiden Enden)
// ---------------------------------------------------------------------

// Länge aus dem Foto (Verhältnis Länge/Durchmesser), Schulter und Kappe aus dem Produktbild
function dose_laenge() = dose_l_zu_d * dose_d;
function dose_oben_l() = dose_oben[len(dose_oben) - 1][0] * dose_d;
function dose_kappe_r() = min([for (p = dose_oben) if (p[0] > 0.1) p[1]]) * dose_d;
function wiege_mass() = let(
        R = dose_d / 2 + dose_spiel,
        L = dose_laenge(),
        innen_l = L + 2 * dose_spiel_ende + 2 * dose_steg_d)      // Dose, Spiel, zwei Anschläge
    [R, L, max(1, ceil((innen_l + 2 * dose_wand + spalt) / raster)), einheiten(2 * R)];

module rasierschaum_wiege() {
    m = wiege_mass();
    R = m[0];
    L = m[1];
    nx = m[2];
    ny = m[3];
    h = dose_hoehe_u * hu;
    ix = aussen(nx) - 2 * dose_wand;
    iy = aussen(ny) - 2 * dose_wand;
    zc = z_boden + R;                          // Achse der Auflagerundung
    x0 = -L / 2;                               // Dosenboden, die Kappe zeigt nach +x
    koerper = L - dose_oben_l();               // zylindrischer Teil
    stege = dose_stege == 1 ? [koerper / 2] :
        [for (k = [0:dose_stege - 1]) 0.12 * L + k * (koerper - 6 - 0.12 * L) / (dose_stege - 1)];
    // Anschläge fangen auch die schmalere Kappe sicher ab
    anschlag_h = min(h, z_boden + dose_d / 2 - dose_kappe_r() + 9);
    echo(str("DOSE: ", L, " x ", dose_d, " mm"));
    difference() {
        gridfinity_block(nx, ny, h);
        translate([0, 0, z_boden]) abgerundetes_rechteck(ix, iy, h, r_aussen - dose_wand);
    }
    // Stege greifen 0,5 mm in Boden und Wände, damit alles zu einem Körper verschmilzt
    for (st = stege) translate([x0 + st, 0, 0]) difference() {
        translate([-dose_steg_d / 2, -iy / 2 - 0.5, z_boden - 0.5])
            cube([dose_steg_d, iy + 1, h - z_boden + 0.5]);
        translate([0, 0, zc]) rotate([0, 90, 0]) cylinder(h = dose_steg_d + 2, r = R, center = true);
        c = 0.6;   // kleine Fasen an den Kanten der Rundung
        translate([dose_steg_d / 2 - c, 0, zc]) rotate([0, 90, 0])
            cylinder(h = c + eps, r1 = R, r2 = R + c + eps);
        translate([-dose_steg_d / 2 - eps, 0, zc]) rotate([0, 90, 0])
            cylinder(h = c + eps, r1 = R + c + eps, r2 = R);
    }
    for (xa = [x0 - dose_spiel_ende - dose_steg_d / 2, -x0 + dose_spiel_ende + dose_steg_d / 2])
        translate([xa, 0, 0]) hull() {
            translate([-dose_steg_d / 2, -iy / 2 - 0.5, z_boden - 0.5])
                cube([dose_steg_d, iy + 1, anschlag_h - z_boden - 0.5]);
            translate([-dose_steg_d / 2 + 1, -iy / 2 - 0.5, z_boden - 0.5])
                cube([dose_steg_d - 2, iy + 1, anschlag_h - z_boden + 0.5]);
        }
}

// ---------------------------------------------------------------------
//  Rasierer-Halter (liegend, Mulden in der gemessenen Umrissform)
// ---------------------------------------------------------------------

// Profile in mm: [Abstand vom Griffende, halbe Breite]
function profil_pg() = [for (p = pg_profil) p * pg_laenge];
function profil_klein() = [for (p = bi_profil_mm) p * foto_k];
function profil_laenge(pr) = pr[len(pr) - 1][0];
function profil_max(pr) = max([for (p = pr) p[1]]);
// halbe Breite an der Stelle s, 0 außerhalb des Rasierers
function halb_bei(pr, s) = (s < 0 || s > profil_laenge(pr)) ? 0 : lookup(s, pr);

// Umriss als 2D-Form: Griffende bei x = 0, Kopf bei +x
module rasierer_form(pr) {
    polygon(concat([for (p = pr) [p[0], p[1]]], [for (i = [len(pr) - 1:-1:0]) [pr[i][0], -pr[i][1]]]));
}

// Mulde für eine beliebige 2D-Form (Kind): Spiel rundum, Fase in vier Stufen
module mulde_frei(t, h) {
    translate([0, 0, h - t]) linear_extrude(t + 1) offset(r = rasierer_spiel) children();
    for (i = [1:4])
        translate([0, 0, h - rasierer_fase + (i - 1) * rasierer_fase / 4])
            linear_extrude(rasierer_fase + 1) offset(r = rasierer_spiel + i * rasierer_fase / 4) children();
}

// [nx, ny, Griffende ProGlide x, Griffende klein x, Achse ProGlide y, Achse klein y]
// Beide Köpfe liegen an den Stirnwänden. Der Achsabstand ergibt sich aus der größten
// Summe beider halben Breiten an derselben Stelle, so greifen die Umrisse ineinander.
function rasierer_layout() = let(
        a = profil_pg(), b = profil_klein(), sp = rasierer_spiel,
        nur_pg = rasierer_auswahl == "proglide", nur_kl = rasierer_auswahl == "klein",
        La = profil_laenge(a), Lb = profil_laenge(b),
        nx = einheiten((nur_pg ? La : nur_kl ? Lb : max(La, Lb)) + 2 * sp),
        ix = innen(nx),
        xa = nur_pg ? -La / 2 : ix / 2 - sp - La,
        xb = nur_kl ? Lb / 2 : -ix / 2 + sp + Lb,
        am = profil_max(a), bm = profil_max(b),
        summe = max([for (x = [-ix / 2:0.5:ix / 2]) halb_bei(a, x - xa) + halb_bei(b, xb - x)]),
        d = summe + 2 * (sp + rasierer_fase) + rasierer_steg,   // Steg bleibt auch an der Oberkante voll
        iy = nur_pg ? 2 * (am + sp) : nur_kl ? 2 * (bm + sp) : am + bm + d + 2 * sp,
        _e = echo(str("RASIERER: Achsabstand ", d, " mm, Innenbreite ", iy, " mm")),
        ny = einheiten(iy),
        ya = (nur_pg || nur_kl) ? 0 : -iy / 2 + am + sp)
    [nx, ny, xa, xb, ya, ya + ((nur_pg || nur_kl) ? 0 : d)];

module rasierer_halter() {
    lay = rasierer_layout();
    h = rasierer_hoehe_u * hu;
    t = min(rasierer_tiefe, h - z_boden);
    a = profil_pg();
    b = profil_klein();
    mit_pg = rasierer_auswahl != "klein";
    mit_kl = rasierer_auswahl != "proglide";
    // Griffmulde quer zu den Griffen, dort wo beide Griffe liegen
    x_mulde = !mit_kl ? lay[2] + 0.4 * profil_laenge(a) :
              !mit_pg ? lay[3] - 0.4 * profil_laenge(b) : (lay[2] + lay[3]) / 2;
    difference() {
        gridfinity_block(lay[0], lay[1], h);
        if (mit_pg) translate([lay[2], lay[4], 0]) mulde_frei(t, h) rasierer_form(a);
        if (mit_kl) translate([lay[3], lay[5], 0]) rotate(180) mulde_frei(t, h) rasierer_form(b);
        griffmulde(x_mulde, max(z_boden + 0.3, h - t - 2), 11, aussen(lay[1]) + 2, t + 10);
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
// Wiege: Passt die Dose sauber hinein, stimmt der Maßstab für alle Fotomaße.
module passtest() {
    a = profil_pg();
    b = profil_klein();
    sp = rasierer_spiel;
    rd = dose_d + 2 * dose_spiel;
    pg = [pg_box_l, pg_box_b] + [2, 2] * box_spiel;
    bi = [bi_box_l, bi_box_b] + [2, 2] * box_spiel;
    abst = 5;
    La = profil_laenge(a);
    Lb = profil_laenge(b);
    am = profil_max(a) + sp;
    bm = profil_max(b) + sp;
    // Rasierer-Umrisse übereinander, Köpfe rechts, Lasche neben dem Griff
    translate([-La / 2, 0, 0])
        test_rahmen("PROGLIDE", 0.3 * La, halb_bei(a, 0.3 * La) + sp + pt_w + 3.5)
            offset(r = sp) rasierer_form(a);
    y_kl = -am - bm - 2 * pt_w - abst;
    translate([-Lb / 2, y_kl, 0])
        test_rahmen("KLEIN", 0.3 * Lb, -halb_bei(b, 0.3 * Lb) - sp - pt_w - 3.5)
            offset(r = sp) rasierer_form(b);
    // Klingenboxen und Dosenring in einer Reihe darunter
    y_reihe = y_kl - bm - 2 * pt_w - abst - 10 - max(pg[1], bi[1], rd) / 2;
    x0 = -max(La, Lb) / 2 - pt_w;
    translate([x0 + pt_w + pg[0] / 2, y_reihe, 0])
        test_rahmen("PG-BOX", 0, pg[1] / 2 + pt_w + 3.5) rundrechteck_2d(pg[0], pg[1], 2);
    translate([x0 + 3 * pt_w + pg[0] + abst + bi[0] / 2, y_reihe, 0])
        test_rahmen("BOX KLEIN", 0, bi[1] / 2 + pt_w + 3.5) rundrechteck_2d(bi[0], bi[1], 2);
    translate([x0 + 5 * pt_w + pg[0] + bi[0] + 2 * abst + rd / 2, y_reihe, 0])
        test_rahmen("DOSE", 0, rd / 2 + pt_w + 3.5) circle(d = rd);
}

// ---------------------------------------------------------------------
//  Übersicht mit stilisierten Produkten (nur zur Ansicht, nicht drucken)
// ---------------------------------------------------------------------

farbe_halter = "#e9e6df";

// Dose liegend entlang x, Boden bei x = -L/2, Achse auf z = 0
module attrappe_dose() {
    L = dose_laenge();
    o = dose_oben_l();
    rotate([0, 90, 0]) translate([0, 0, -L / 2]) {
        color("#2bb3b1") cylinder(h = (L - o) * 0.55, d = dose_d);
        color("#151515") translate([0, 0, (L - o) * 0.55]) cylinder(h = (L - o) * 0.45, d = dose_d);
        color("#151515") translate([0, 0, L - o])
            rotate_extrude() polygon(concat([[0, 0]], [for (i = [len(dose_oben) - 1:-1:0])
                [dose_oben[i][1] * dose_d, o - dose_oben[i][0] * dose_d]], [[0, o]]));
    }
}

// flache Attrappe aus dem Umriss: Griffende bei x = 0, Kopf bei +x
module attrappe_rasierer(pr, farbe) {
    color(farbe) linear_extrude(12) rasierer_form(pr);
    L = profil_laenge(pr);
    color("#c9c9c9") translate([0, 0, 12]) linear_extrude(1)
        intersection() { rasierer_form(pr); translate([0.9 * L, -50]) square([L, 100]); }
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
    lay = rasierer_layout();
    bl = box_layout();
    bn = [einheiten(bl[1][0]), einheiten(bl[1][1])];
    x_box = max(w[2], lay[0]);
    breite = x_box + bn[0];
    tief = max(w[3] + lay[1], bn[1]);
    h_r = rasierer_hoehe_u * hu;
    t_r = min(rasierer_tiefe, h_r - z_boden);
    // ganze Szene um den Ursprung zentrieren (für die Kamera in build.sh)
    translate([-breite * raster / 2, -tief * raster / 2, 0]) {
        color("#8d8f93") translate([0, 0, -2.5]) cube([breite * raster, tief * raster, 2.5]);
        setze(0, 0, w[2], w[3]) {
            color(farbe_halter) rasierschaum_wiege();
            translate([0, 0, z_boden + dose_d / 2]) attrappe_dose();
        }
        setze(0, w[3], lay[0], lay[1]) {
            color(farbe_halter) rasierer_halter();
            if (rasierer_auswahl != "klein")
                translate([lay[2], lay[4], h_r - t_r]) attrappe_rasierer(profil_pg(), "#5b5d60");
            if (rasierer_auswahl != "proglide")
                translate([lay[3], lay[5], h_r - t_r]) rotate(180) attrappe_rasierer(profil_klein(), "#1e1e1e");
        }
        setze(x_box, 0, bn[0], bn[1]) {
            h = box_hoehe_u * hu;
            v = box_liste();
            color(farbe_halter) klingenbox_halter();
            if (bl[0] == "spalte" && len(v) == 2)
                for (i = [0:1]) {
                    y = i == 0 ? -bl[1][1] / 2 + v[0][1] / 2 : bl[1][1] / 2 - v[1][1] / 2;
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
