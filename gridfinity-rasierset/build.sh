#!/usr/bin/env bash
# Exportiert die STL-Dateien und Bilder aus gridfinity_rasierset.scad.
# Eigene Maße einfach anhängen, z. B.:  ./build.sh -D dose_d=50 -D pg_laenge=140
# Die Rastergröße (z. B. 5x4x3u) rechnet das Modell aus und landet im Dateinamen.
# Ist Blender (ab 4.0) installiert, entstehen zusätzlich die Studio-Renderings
# (dauert auf 4 CPU-Kernen etwa 20 Minuten). BLENDER=0 ./build.sh lässt sie weg.
set -euo pipefail
cd "$(dirname "$0")"
SCAD=gridfinity_rasierset.scad
mkdir -p stl bilder
rm -f stl/*.stl

log=$(openscad -o stl/_tmp.stl --export-format binstl -D 'teil="station"' "$@" "$SCAD" 2>&1)
groesse=$(grep -o 'RASTER=[0-9]*x[0-9]*x[0-9]*u' <<<"$log" | head -1 | cut -d= -f2 || true)
station=stl/rasier_station${groesse:+_$groesse}.stl
mv stl/_tmp.stl "$station"
echo "==> $station"
openscad -q -o stl/passtest.stl --export-format binstl -D 'teil="passtest"' "$@" "$SCAD"
echo "==> stl/passtest.stl"

# Schnelle Vorschau mit OpenSCAD (Szene liegt um den Ursprung)
xvfb-run -a openscad -q -o bilder/uebersicht.png --imgsize=1600,1200 --colorscheme=Tomorrow \
  --projection=p --camera=183,-344,315,0,0,15 --viewall -D 'teil="uebersicht"' "$@" "$SCAD"
xvfb-run -a openscad -q -o bilder/passtest.png --imgsize=1200,900 --colorscheme=Tomorrow \
  --projection=p --camera=0,0,0,55,0,25,0 --viewall --autocenter --render=1 \
  -D 'teil="passtest"' "$@" "$SCAD"
echo "==> bilder/uebersicht.png, bilder/passtest.png"

# Studio-Renderings: Station und Attrappen als STL in einen Zwischenordner, dann Blender
if [ "${BLENDER:-1}" != 0 ] && command -v blender >/dev/null; then
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT
  cp "$station" "$tmp/station.stl"
  for a in dose_unten dose_oben pg_0 pg_1 pg_2 klein_0 klein_1 klein_2 klingen; do
    openscad -q -o "$tmp/$a.stl" --export-format binstl -D "teil=\"$a\"" "$@" "$SCAD"
  done
  blender -b -P werkzeug/rendern.py -- "$tmp" bilder "${SAMPLES:-256}" | grep gerendert
fi
