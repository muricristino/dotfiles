---
name: whatsapp
description: Reads this Mac's WhatsApp history straight from the app's local database — messages, dates, authors — and transcribes voice notes and videos with whisper. Use when the user asks to find/reread/dig up conversations, "what did so-and-so say about X", transcribe WhatsApp audios, or build a client timeline from the chat. Far more reliable than scraping WhatsApp Web.
allowed-tools: Bash, Read, Write
---

# WhatsApp on this Mac

**Don't scrape WhatsApp Web.** The native app keeps everything in SQLite on disk,
with media as files. It's faster, complete, and doesn't depend on QR codes or scrolling.

> The user's personal data. Work only on the requested conversation, don't do a
> general sweep, and don't send the content anywhere without an explicit request.

## Where everything lives

```
~/Library/Group Containers/group.net.whatsapp.WhatsApp.shared/
├── ChatStorage.sqlite          message database
└── Message/Media/…             media (.opus audio, .mp4 video, .jpg image)
```

**Copy the database before querying** (the app holds a lock and WAL):

```bash
SP=/tmp/wpp; mkdir -p $SP
BASE=~/Library/Group\ Containers/group.net.whatsapp.WhatsApp.shared
cp "$BASE/ChatStorage.sqlite"* $SP/
```

## Schema

| Table | Fields that matter |
|---|---|
| `ZWACHATSESSION` | `Z_PK`, `ZPARTNERNAME` (name), `ZCONTACTJID` |
| `ZWAMESSAGE` | `ZCHATSESSION`, `ZTEXT`, `ZMESSAGEDATE`, `ZISFROMME`, `ZMESSAGETYPE` |
| `ZWAMEDIAITEM` | `ZMESSAGE` (FK), `ZMEDIALOCALPATH`, `ZMOVIEDURATION` |

`ZMESSAGETYPE`: **0** text · **1** image · **2** video · **3** audio · **8** document

**Dates are Apple epoch** (since 2001-01-01). Convert with `+978307200`:

```sql
datetime(ZMESSAGEDATE + 978307200, 'unixepoch', 'localtime')
```

To **filter** by date, convert the other way and CAST:

```sql
WHERE ZMESSAGEDATE > (CAST(strftime('%s','2026-07-01') AS INTEGER) - 978307200)
```

## Find the conversation

```bash
sqlite3 -header -column $SP/ChatStorage.sqlite \
  "select Z_PK, ZPARTNERNAME, ZCONTACTJID from ZWACHATSESSION
   where lower(ZPARTNERNAME) like '%someone%';"
```

Overview before diving in — period and composition:

```bash
sqlite3 -header -column $SP/ChatStorage.sqlite "
select date(ZMESSAGEDATE+978307200,'unixepoch','localtime') day,
       sum(ZMESSAGETYPE=0) txt, sum(ZMESSAGETYPE=3) audio,
       sum(ZMESSAGETYPE=2) video, sum(ZMESSAGETYPE=1) img
from ZWAMESSAGE where ZCHATSESSION=<PK> group by 1 order by 1;"
```

## Export

Use the ready-made scripts:

```bash
~/.claude/skills/whatsapp/scripts/dump_chat.py <chat_pk> [start_date] > /tmp/wpp/chat.tsv
~/.claude/skills/whatsapp/scripts/transcribe.py /tmp/wpp/chat.tsv /tmp/wpp/transcripts
```

`dump_chat.py` produces a TSV with `pk, date, author, type, duration, path, text`.
`transcribe.py` converts with ffmpeg and transcribes with whisper.

## Transcription — the detail that changes everything

**Never call the `whisper` CLI in a loop.** It reloads the model for every file
(~10s each). Load the model **once** in Python and iterate:

```python
import whisper
model = whisper.load_model("small")      # once
for file in files:
    r = model.transcribe(wav, language="pt", fp16=False)
```

whisper's Python lives in Homebrew's libexec:

```bash
/opt/homebrew/Cellar/openai-whisper/*/libexec/bin/python
```

**Run from a neutral directory** (`cd /tmp`). In a project with `coverage`
configured you get `AttributeError: module 'coverage' has no attribute 'types'`.

The `small` model gives good quality in Portuguese. WhatsApp audio is `.opus` —
convert it first:

```bash
ffmpeg -y -loglevel error -i input.opus -ar 16000 -ac 1 output.wav
```

Ballpark: ~47 min of audio → ~30 min of transcription with `small`.
Run it in the background and report progress.

## Images

Copy them to a working directory and **read them with the Read tool** — screenshots
tend to be the densest information in the conversation (mockups, error screens,
receipts). Name them by date and author, and **include the pk in the name**: several
images share the same second and overwrite each other.

## Shell traps (they cost time)

- `sqlite3 -separator '\t'` writes a **literal backslash**, not a tab.
  Use `-separator "$(printf '\t')"`.
- In zsh, `while read` inside a pipe **loses PATH** — `tr`, `head`, `wc`
  disappear. For any iteration over the media list, **use Python**.
- Commands with absolute paths (`/usr/bin/tail`) avoid PATH surprises.

## How to deliver

Don't dump raw transcripts. Sweep by keyword, build the timeline in
order, and quote **verbatim** what matters — the client's exact words are worth more than
a summary. Mark what's audio, with duration and date, for traceability.
