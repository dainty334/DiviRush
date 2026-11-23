#!/usr/bin/env bash
# Turns the downloaded CC0 music (D-018) into the game's three OGG music files in assets/audio/music/.
# It needs ffmpeg. Download the three files below into one folder, then run from the project folder:
#   bash tools/convert_music.sh <download folder>
# Sources (all CC0, public domain; credit is kind but not required):
#   children_soundtrack_3.wav  "Children's Game Music 3 - Home" by heartade (Daniel Soohan Park)
#                              https://opengameart.org/content/childrens-game-music-3-home    -> menu_loop.ogg
#   children_soundtrack_1.wav  "Children's Game Music 1 - Picnic" by heartade (Daniel Soohan Park)
#                              https://opengameart.org/content/childrens-game-music-1-picnic  -> play_loop.ogg
#   jingleSounds_Kenney.zip    "Music Jingles" by Kenney (www.kenney.nl), file jingles_SAX02.ogg
#                              https://opengameart.org/content/85-short-music-jingles         -> win_jingle.ogg
set -euo pipefail  # Stop at the first error, and treat unset names as errors.

SRC="${1:?Give the folder with the downloaded files}"  # Folder with the downloaded files.
OUT="assets/audio/music"  # Where the game's music goes.
BLEND=1.5  # Seconds where the end of a track blends into its start, so the loop has no jump.

# Makes a smooth loop from one track. The tracks end on a fading last note, so played as they are
# the loop would jump from that quiet ending back to the start. Instead the loop is: the middle of
# the track, then its last BLEND seconds fading out while its first BLEND seconds fade in.
# Played again and again, every join is smooth. Both fades follow a quarter-sine curve, so the
# sound does not dip in the middle of the blend. The volume is lowered by 1 dB, so the blend cannot clip.
make_loop() {
  local in="$1"  # The downloaded WAV.
  local out="$2"  # The OGG to write.
  local dur  # Length of the track in seconds.
  dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$in")  # Ask ffprobe for the length.
  local end  # Where the blended ending starts.
  end=$(awk -v d="$dur" -v b="$BLEND" 'BEGIN { print d - b }')  # The length minus the blend.
  # Cut the middle, the faded end and the faded start, mix end and start, put them after the middle, save as OGG.
  ffmpeg -y -v error -i "$in" -filter_complex \
    "[0:a]atrim=${BLEND}:${end},asetpts=PTS-STARTPTS[mid];[0:a]atrim=start=${end},asetpts=PTS-STARTPTS,afade=t=out:d=${BLEND}:curve=qsin[tail];[0:a]atrim=0:${BLEND},asetpts=PTS-STARTPTS,afade=t=in:d=${BLEND}:curve=qsin[head];[tail][head]amix=inputs=2:normalize=0[join];[mid][join]concat=n=2:v=0:a=1,volume=-1dB[out]" \
    -map "[out]" -c:a libvorbis -q:a 5 -ar 44100 "$out"
  echo "saved $out"  # Report the file.
}

make_loop "$SRC/children_soundtrack_3.wav" "$OUT/menu_loop.ogg"  # Calm menu loop: piano, flute and strings.
make_loop "$SRC/children_soundtrack_1.wav" "$OUT/play_loop.ogg"  # Upbeat play loop: saxophone, vibraphone and strings.
# Short rising saxophone jingle, taken out of the zip and made 6 dB louder, so it is as loud as the loops.
unzip -p "$SRC/jingleSounds_Kenney.zip" "OGG/jingles_SAX/jingles_SAX02.ogg" | ffmpeg -y -v error -i pipe:0 -af volume=6dB -c:a libvorbis -q:a 5 -ar 44100 "$OUT/win_jingle.ogg"
echo "saved $OUT/win_jingle.ogg"  # Report the file.
