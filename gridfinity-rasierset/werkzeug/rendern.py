"""Studio-Renderings der Rasier-Station mit Blender (Cycles, nur CPU).

Aufruf:
  blender -b -P werkzeug/rendern.py -- <stl-ordner> <ausgabe-ordner> [samples] [prozent] [bilder]

bilder: Auswahl mit Komma, z. B. "weiss,schwebend" (Standard: alle vier).

Erwartet im STL-Ordner: station.stl und die Attrappen dose_unten.stl, dose_oben.stl,
pg_0..2.stl, klein_0..2.stl, klingen.stl (export über build.sh).
"""
import math
import os
import sys

import bpy

argv = sys.argv[sys.argv.index("--") + 1:]
STL, AUS = argv[0], argv[1]
SAMPLES = int(argv[2]) if len(argv) > 2 else 256
PROZENT = int(argv[3]) if len(argv) > 3 else 100      # Auflösung in Prozent, für schnelle Proben
NUR = argv[4].split(",") if len(argv) > 4 else ["weiss", "draufsicht", "schwebend", "spacegrau"]
os.makedirs(AUS, exist_ok=True)

# Materialien: (Grundfarbe, Rauheit, Metall)
WEISS = ((0.90, 0.90, 0.885), 0.48, 0.0)
SPACEGRAU = ((0.052, 0.055, 0.061), 0.5, 0.0)
MATERIAL = {
    "dose_unten": ((0.02, 0.48, 0.47), 0.22, 0.0),
    "dose_oben": ((0.012, 0.012, 0.013), 0.18, 0.0),
    "pg_0": ((0.20, 0.205, 0.215), 0.32, 0.55),
    "klein_0": ((0.022, 0.022, 0.024), 0.55, 0.0),
    "pg_1": ((0.03, 0.03, 0.032), 0.4, 0.0),
    "klein_1": ((0.03, 0.03, 0.032), 0.4, 0.0),
    "klingen": ((0.035, 0.035, 0.038), 0.4, 0.0),
    "pg_2": ((0.85, 0.85, 0.86), 0.15, 1.0),
    "klein_2": ((0.85, 0.85, 0.86), 0.15, 1.0),
}
# Schwebende Ansicht: so hoch (m) hängt jedes Teil über seiner Mulde
SCHWEBEN = {"dose": 0.06, "pg": 0.032, "klein": 0.026, "klingen": 0.018}


def material(name, farbe, rau, metall):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    p = m.node_tree.nodes["Principled BSDF"]
    p.inputs["Base Color"].default_value = (*farbe, 1)
    p.inputs["Roughness"].default_value = rau
    p.inputs["Metallic"].default_value = metall
    return m


def stl_laden(pfad):
    vorher = set(bpy.data.objects)
    try:
        bpy.ops.wm.stl_import(filepath=pfad)
    except Exception:
        bpy.ops.import_mesh.stl(filepath=pfad)
    obj = (set(bpy.data.objects) - vorher).pop()
    obj.scale = (0.001, 0.001, 0.001)          # STL in mm, Szene in m
    me = obj.data
    if hasattr(me, "use_auto_smooth"):
        me.use_auto_smooth = True
        me.auto_smooth_angle = math.radians(32)
    for poly in me.polygons:
        poly.use_smooth = True
    return obj


def szene_leeren():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def licht(name, ort, ziel, staerke, groesse):
    d = bpy.data.lights.new(name, "AREA")
    d.energy = staerke
    d.size = groesse
    o = bpy.data.objects.new(name, d)
    bpy.context.scene.collection.objects.link(o)
    o.location = ort
    richte_aus(o, ziel)


def richte_aus(obj, ziel):
    from mathutils import Vector
    rich = Vector(ziel) - obj.location
    obj.rotation_euler = rich.to_track_quat("-Z", "Y").to_euler()


def kamera(ort, ziel, brennweite=70, ortho=None):
    d = bpy.data.cameras.new("Kamera")
    d.lens = brennweite
    d.clip_start = 0.01
    d.clip_end = 20
    if ortho:
        d.type = "ORTHO"
        d.ortho_scale = ortho
    o = bpy.data.objects.new("Kamera", d)
    bpy.context.scene.collection.objects.link(o)
    o.location = ort
    richte_aus(o, ziel)
    bpy.context.scene.camera = o


def aufbauen(koerper_farbe, boden_hell, mit_inhalt=True, schweben=False):
    szene_leeren()
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = SAMPLES
    sc.cycles.use_adaptive_sampling = True
    sc.cycles.adaptive_threshold = 0.01
    sc.cycles.use_denoising = False
    sc.cycles.max_bounces = 8
    sc.render.film_transparent = False
    sc.view_settings.view_transform = "AgX"
    sc.view_settings.look = "AgX - Medium High Contrast"
    sc.view_settings.exposure = 0.0
    # Hintergrund: helles Studio. Ein weißes, nach oben zeigendes Teil bekommt davon etwa 0,2
    welt = bpy.data.worlds.new("Welt")
    welt.use_nodes = True
    bg = welt.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = (0.93, 0.93, 0.94, 1)
    bg.inputs["Strength"].default_value = 0.25
    sc.world = welt
    # Boden: hellgrau hinter dem weißen Teil, fast weiß hinter dem dunklen
    bpy.ops.mesh.primitive_plane_add(size=6, location=(0, 0, 0))
    boden = bpy.context.active_object
    boden.data.materials.append(material("Boden", (boden_hell, boden_hell * 0.995, boden_hell * 0.99), 0.8, 0.0))
    # Station
    st = stl_laden(os.path.join(STL, "station.stl"))
    st.data.materials.append(material("Station", *koerper_farbe))
    if mit_inhalt:
        for name, (farbe, rau, metall) in MATERIAL.items():
            pfad = os.path.join(STL, name + ".stl")
            if os.path.exists(pfad):
                o = stl_laden(pfad)
                o.data.materials.append(material(name, farbe, rau, metall))
                if schweben:
                    o.location.z = SCHWEBEN[name.split("_")[0]]
    # Licht: großes Hauptlicht links vorne oben, Aufheller rechts, Kante von hinten.
    # Flächenlicht mit Leistung P im Abstand d: weiße Fläche (Albedo a) leuchtet mit etwa a * P / (pi² d²).
    # Hauptlicht 1,05 m entfernt mit 9 W ergibt rund 0,6, zusammen mit Welt und Aufheller knapp 1
    licht("Haupt", (-0.45, -0.55, 0.75), (0, 0, 0), 9, 0.9)
    licht("Fill", (0.65, -0.25, 0.35), (0, 0, 0), 1.6, 0.8)
    licht("Kante", (0.1, 0.7, 0.45), (0, 0, 0), 5, 0.7)


def rendern(datei, breite=1600, hoehe=1200):
    sc = bpy.context.scene
    sc.render.resolution_x = breite
    sc.render.resolution_y = hoehe
    sc.render.resolution_percentage = PROZENT
    sc.render.image_settings.file_format = "JPEG"
    sc.render.image_settings.quality = 92
    sc.render.filepath = os.path.join(AUS, datei)
    bpy.ops.render.render(write_still=True)
    print("gerendert:", sc.render.filepath)


# 1) Hauptbild weiß, schräg von vorne rechts, und 2) Draufsicht im Bildformat 5:4 wie die Station
if "weiss" in NUR or "draufsicht" in NUR:
    aufbauen(WEISS, 0.5)
    if "weiss" in NUR:
        kamera((0.36, -0.52, 0.40), (0.0, 0.0, 0.005), 80)
        rendern("studio_weiss.jpg")
    if "draufsicht" in NUR:
        kamera((0.0, -0.0001, 1.2), (0.0, 0.0, 0.0), ortho=0.25)
        rendern("studio_draufsicht.jpg", 1600, 1280)
# 3) Alle Teile schweben über ihren Mulden, steiler Blick in die Mulden
if "schwebend" in NUR:
    aufbauen(WEISS, 0.5, schweben=True)
    kamera((0.28, -0.46, 0.60), (0.0, -0.005, 0.03), 70)
    rendern("studio_schwebend.jpg")
# 4) Space Grau, leer: zeigt die Formen der Mulden
if "spacegrau" in NUR:
    aufbauen(SPACEGRAU, 0.8, mit_inhalt=False)
    kamera((-0.30, -0.50, 0.45), (0.0, 0.0, 0.005), 80)
    rendern("studio_spacegrau_leer.jpg")
