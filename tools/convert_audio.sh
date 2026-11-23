#!/usr/bin/env bash
# Turns the downloaded CC0 audio into the game's sound files (D-018 music, D-019 sound effects):
#   assets/audio/music/*.ogg  menu loop, play loop and win jingle
#   assets/audio/sfx/*.wav    tap, correct, wrong, time-up, Star and pop sounds
# It needs ffmpeg and unzip. Download the four files below into one folder, then run from the project folder:
#   bash tools/convert_audio.sh <download folder>
# Sources (all CC0, public domain; credit is kind but not required):
#   children_soundtrack_3.wav      "Children's Game Music 3 - Home" by heartade (Daniel Soohan Park)
#                                  https://opengameart.org/content/childrens-game-music-3-home    -> menu_loop.ogg
#   children_soundtrack_1.wav      "Children's Game Music 1 - Picnic" by heartade (Daniel Soohan Park)
#                                  https://opengameart.org/content/childrens-game-music-1-picnic  -> play_loop.ogg
#   jingleSounds_Kenney.zip        "Music Jingles" by Kenney (www.kenney.nl), file jingles_SAX02.ogg
#                                  https://opengameart.org/content/85-short-music-jingles         -> win_jingle.ogg
#   kenney_interfaceSounds.zip     "Interface Sounds" by Kenney (www.kenney.nl)
#                                  https://opengameart.org/content/interface-sounds               -> sfx/*.wav
set -euo pipefail  # Stop at the first error, and treat unset names as errors.

SRC="${1:?Give the folder with the downloaded files}"  # Folder with the downloaded files.
MUSIC_OUT="assets/audio/music"  # Where the game's music goes.
SFX_OUT="assets/audio/sfx"  # Where the game's sound effects go.
BLEND=1.5  # Seconds where the end of a music loop blends into its start, so the loop has no jump.
WORK="$(mktemp -d)"  # A scratch folder for sounds taken out of the zips.
trap 'rm -rf "$WORK"' EXIT  # Remove the scratch folder when the tool ends.

# ---------- Music (D-018) ----------

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

make_loop "$SRC/children_soundtrack_3.wav" "$MUSIC_OUT/menu_loop.ogg"  # Calm menu loop: piano, flute and strings.
make_loop "$SRC/children_soundtrack_1.wav" "$MUSIC_OUT/play_loop.ogg"  # Upbeat play loop: saxophone, vibraphone and strings.
# Short rising saxophone jingle, taken out of the zip and made 6 dB louder, so it is as loud as the loops.
unzip -p "$SRC/jingleSounds_Kenney.zip" "OGG/jingles_SAX/jingles_SAX02.ogg" | ffmpeg -y -v error -i pipe:0 -af volume=6dB -c:a libvorbis -q:a 5 -ar 44100 "$MUSIC_OUT/win_jingle.ogg"
echo "saved $MUSIC_OUT/win_jingle.ogg"  # Report the file.

# ---------- Sound effects (D-019) ----------

# Makes one sound effect: takes a Kenney sound out of the zip, sets its loudness, and saves it as a
# 16-bit mono WAV at 44100 samples per second (WAV starts with no delay, which suits short sounds).
# The loudness is moved to `target` dB on average (at most 12 dB louder). A limiter then holds the
# loudest points at -1 dB, so a sound with one sharp peak can still reach the target without crackling.
make_sfx() {
  local name="$1"  # The Kenney sound, for example select_002.
  local out="$2"  # The game file to write, for example tap.wav.
  local target="$3"  # The average loudness wanted, in dB.
  unzip -o -q -j "$SRC/kenney_interfaceSounds.zip" "Audio/$name.ogg" -d "$WORK"  # Take the sound out of the zip.
  local mean  # Its average loudness.
  mean=$(ffmpeg -hide_banner -i "$WORK/$name.ogg" -af volumedetect -f null - 2>&1 | grep -oE "mean_volume: [-0-9.]+" | cut -d' ' -f2)  # Measure it.
  local gain  # How much louder (or quieter) to make it.
  gain=$(awk -v t="$target" -v m="$mean" 'BEGIN { g = t - m; if (g > 12) g = 12; printf "%.1f", g }')  # Reach the target, at most 12 dB louder.
  # Change the loudness, hold the peaks at -1 dB (0.891) with a fast limiter, and save the game file.
  ffmpeg -y -v error -i "$WORK/$name.ogg" -af "volume=${gain}dB,alimiter=limit=0.891:attack=1:release=30:level=disabled" -ac 1 -ar 44100 -c:a pcm_s16le "$SFX_OUT/$out"
  echo "saved $SFX_OUT/$out from $name (${gain} dB)"  # Report the file.
}

make_sfx select_002 tap.wav -16  # Button tap: a short, soft click, quieter than the feedback sounds.
make_sfx confirmation_001 correct.wav -12  # Correct answer: a short rising, warm sound.
make_sfx error_006 wrong.wav -13  # Wrong answer: a low, gentle falling sound, not a harsh buzz.
make_sfx minimize_006 time_up.wav -13  # Timer ran out: a low falling swoosh, unlike the wrong sound.
make_sfx glass_001 star.wav -14  # A Star fills in: a glassy ring (the game raises its pitch for each Star).
make_sfx drop_002 pop.wav -15  # A bubble pops: a water-drop sound.
