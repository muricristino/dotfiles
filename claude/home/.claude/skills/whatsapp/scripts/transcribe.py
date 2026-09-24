#!/usr/bin/env python3
"""Transcribes the audios and videos from a TSV produced by dump_chat.py.

  transcribe.py <chat.tsv> <out_dir> [model]

Loads the whisper model ONCE (the CLI reloads it for every file and is ~10x
slower). Writes <out_dir>/<pk>.txt and skips what already exists, so it can
be rerun without redoing work.

Run it with whisper's Python, from a neutral directory:
  cd /tmp && /opt/homebrew/Cellar/openai-whisper/*/libexec/bin/python transcribe.py ...
"""
import os, sys, csv, glob, subprocess, pathlib, time

BASE = os.path.expanduser(
    "~/Library/Group Containers/group.net.whatsapp.WhatsApp.shared/Message")
FFMPEG = "/opt/homebrew/bin/ffmpeg"

if len(sys.argv) < 3:
    sys.exit(__doc__)

tsv, out = sys.argv[1], pathlib.Path(sys.argv[2])
model_name = sys.argv[3] if len(sys.argv) > 3 else "small"
out.mkdir(parents=True, exist_ok=True)
wavdir = out / "_wav"; wavdir.mkdir(exist_ok=True)

rows = [r for r in csv.reader(open(tsv), delimiter="\t") if len(r) >= 6]
media = [r for r in rows if r[3] in ("audio", "video") and r[5]]
if not media:
    sys.exit("no audio or video in the TSV")

seconds = sum(int(r[4] or 0) for r in media)
print(f"{len(media)} media · {seconds//60}min{seconds%60}s", flush=True)

import whisper
print(f"loading model {model_name}...", flush=True)
t0 = time.time()
model = whisper.load_model(model_name)
print(f"loaded in {time.time()-t0:.0f}s", flush=True)

done = 0
for i, r in enumerate(media, 1):
    pk, dt, author, kind, dur, path = r[0], r[1], r[2], r[3], r[4], r[5]
    dest = out / f"{pk}.txt"
    if dest.exists() and dest.stat().st_size > 0:
        done += 1
        continue
    src = os.path.join(BASE, path)
    if not os.path.exists(src):
        print(f"[{i}/{len(media)}] pk={pk} file missing", flush=True)
        continue
    wav = str(wavdir / f"{pk}.wav")
    subprocess.run([FFMPEG, "-y", "-loglevel", "error", "-i", src,
                    "-ar", "16000", "-ac", "1", wav], capture_output=True)
    if not os.path.exists(wav):
        print(f"[{i}/{len(media)}] pk={pk} ffmpeg failed", flush=True)
        continue
    try:
        res = model.transcribe(wav, language="pt", fp16=False, verbose=False)
        dest.write_text(res["text"].strip(), encoding="utf-8")
        print(f"[{i}/{len(media)}] pk={pk} ok ({dur}s {author} {dt})", flush=True)
        done += 1
    except Exception as e:
        print(f"[{i}/{len(media)}] pk={pk} ERROR {e}", flush=True)
    finally:
        if os.path.exists(wav):
            os.remove(wav)

for w in glob.glob(str(wavdir / "*.wav")):
    os.remove(w)
print(f"DONE — {done}/{len(media)}", flush=True)
