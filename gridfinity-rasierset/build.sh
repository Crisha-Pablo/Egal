#!/usr/bin/env bash
# Exportiert alle STL-Dateien und Vorschaubilder aus gridfinity_rasierset.scad.
# Eigene Maße einfach anhängen, z. B.:  ./build.sh -D dose_d=52 -D pg_laenge=150
# Die Rastergröße (z. B. 5x2x4u) rechnet das Modell aus und landet im Dateinamen.
set -euo pipefail
cd "$(dirname "$0")"
SCAD=gridfinity_rasierset.scad
mkdir -p stl bilder
rm -f stl/*.stl

declare -A NAMEN=(
  [rasierschaum]=rasierschaum_wiege
  [rasierer]=rasierer_halter
  [klingenboxen]=klingenbox_halter
  [passtest]=passtest
)

for teil in rasierschaum rasierer klingenboxen passtest; do
  name=${NAMEN[$teil]}
  log=$(openscad -o stl/_tmp.stl --export-format binstl -D "teil=\"$teil\"" "$@" "$SCAD" 2>&1)
  groesse=$(grep -o 'RASTER=[0-9]*x[0-9]*x[0-9]*u' <<<"$log" | head -1 | cut -d= -f2 || true)
  datei=$name${groesse:+_$groesse}
  mv stl/_tmp.stl "stl/$datei.stl"
  echo "==> stl/$datei.stl"
  xvfb-run -a openscad -q -o "bilder/$name.png" --imgsize=1200,900 --colorscheme=Tomorrow \
    --projection=p --camera=0,0,0,55,0,25,0 --viewall --autocenter --render=1 \
    -D "teil=\"$teil\"" "$@" "$SCAD"
done

# Übersicht schräg von vorne rechts und fast von oben (Szene liegt um den Ursprung)
xvfb-run -a openscad -q -o bilder/uebersicht.png --imgsize=1600,1200 --colorscheme=Tomorrow \
  --projection=p --camera=183,-344,315,0,0,15 --viewall -D 'teil="uebersicht"' "$@" "$SCAD"
xvfb-run -a openscad -q -o bilder/draufsicht.png --imgsize=1600,1200 --colorscheme=Tomorrow \
  --projection=p --camera=0,-314,405,0,0,15 --viewall -D 'teil="uebersicht"' "$@" "$SCAD"
echo "==> bilder/uebersicht.png, bilder/draufsicht.png"
