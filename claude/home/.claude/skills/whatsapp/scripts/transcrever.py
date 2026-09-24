#!/usr/bin/env python3
"""Transcreve os áudios e vídeos de um TSV gerado pelo dump_chat.py.

  transcrever.py <chat.tsv> <dir_saida> [modelo]

Carrega o modelo whisper UMA vez (o CLI recarrega a cada arquivo e fica ~10x
mais lento). Escreve <dir_saida>/<pk>.txt e pula o que já existe, então pode
ser reexecutado sem refazer trabalho.

Rode com o Python do whisper, a partir de um diretório neutro:
  cd /tmp && /opt/homebrew/Cellar/openai-whisper/*/libexec/bin/python transcrever.py ...
"""
import os, sys, csv, glob, subprocess, pathlib, time

BASE = os.path.expanduser(
    "~/Library/Group Containers/group.net.whatsapp.WhatsApp.shared/Message")
FFMPEG = "/opt/homebrew/bin/ffmpeg"

if len(sys.argv) < 3:
    sys.exit(__doc__)

tsv, saida = sys.argv[1], pathlib.Path(sys.argv[2])
modelo = sys.argv[3] if len(sys.argv) > 3 else "small"
saida.mkdir(parents=True, exist_ok=True)
wavdir = saida / "_wav"; wavdir.mkdir(exist_ok=True)

linhas = [r for r in csv.reader(open(tsv), delimiter="\t") if len(r) >= 6]
midias = [r for r in linhas if r[3] in ("audio", "video") and r[5]]
if not midias:
    sys.exit("nenhum áudio ou vídeo no TSV")

segundos = sum(int(r[4] or 0) for r in midias)
print(f"{len(midias)} mídias · {segundos//60}min{segundos%60}s", flush=True)

import whisper
print(f"carregando modelo {modelo}...", flush=True)
t0 = time.time()
model = whisper.load_model(modelo)
print(f"carregado em {time.time()-t0:.0f}s", flush=True)

feitos = 0
for i, r in enumerate(midias, 1):
    pk, dt, autor, tipo, dur, path = r[0], r[1], r[2], r[3], r[4], r[5]
    dest = saida / f"{pk}.txt"
    if dest.exists() and dest.stat().st_size > 0:
        feitos += 1
        continue
    src = os.path.join(BASE, path)
    if not os.path.exists(src):
        print(f"[{i}/{len(midias)}] pk={pk} arquivo ausente", flush=True)
        continue
    wav = str(wavdir / f"{pk}.wav")
    subprocess.run([FFMPEG, "-y", "-loglevel", "error", "-i", src,
                    "-ar", "16000", "-ac", "1", wav], capture_output=True)
    if not os.path.exists(wav):
        print(f"[{i}/{len(midias)}] pk={pk} falha no ffmpeg", flush=True)
        continue
    try:
        res = model.transcribe(wav, language="pt", fp16=False, verbose=False)
        dest.write_text(res["text"].strip(), encoding="utf-8")
        print(f"[{i}/{len(midias)}] pk={pk} ok ({dur}s {autor} {dt})", flush=True)
        feitos += 1
    except Exception as e:
        print(f"[{i}/{len(midias)}] pk={pk} ERRO {e}", flush=True)
    finally:
        if os.path.exists(wav):
            os.remove(wav)

for w in glob.glob(str(wavdir / "*.wav")):
    os.remove(w)
print(f"FIM — {feitos}/{len(midias)}", flush=True)
