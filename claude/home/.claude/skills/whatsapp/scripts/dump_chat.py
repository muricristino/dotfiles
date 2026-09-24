#!/usr/bin/env python3
"""Exports a WhatsApp conversation to TSV.

  dump_chat.py <chat_pk> [start_date YYYY-MM-DD] > chat.tsv

Columns: pk, date, author, type, duration, media_path, text
With no arguments, lists the available conversations.
"""
import os, sys, shutil, sqlite3, tempfile

BASE = os.path.expanduser(
    "~/Library/Group Containers/group.net.whatsapp.WhatsApp.shared")
EPOCH = 978307200
TYPES = {0: "text", 1: "image", 2: "video", 3: "audio", 8: "doc"}


def open_db():
    """Copies the database (avoids the app's lock/WAL) and returns the connection."""
    tmp = os.path.join(tempfile.gettempdir(), "wpp-ChatStorage.sqlite")
    src = os.path.join(BASE, "ChatStorage.sqlite")
    if not os.path.exists(src):
        sys.exit(f"database not found at {src}")
    shutil.copy(src, tmp)
    for ext in ("-wal", "-shm"):
        if os.path.exists(src + ext):
            shutil.copy(src + ext, tmp + ext)
    return sqlite3.connect(tmp)


def list_chats(con):
    print("PK\tMESSAGES\tNAME", file=sys.stderr)
    q = """select s.Z_PK, count(m.Z_PK), s.ZPARTNERNAME
           from ZWACHATSESSION s left join ZWAMESSAGE m on m.ZCHATSESSION = s.Z_PK
           group by 1 order by 2 desc limit 40"""
    for pk, n, name in con.execute(q):
        print(f"{pk}\t{n}\t{name}", file=sys.stderr)


def dump(con, pk, since=None):
    cond = ""
    if since:
        cond = f"and m.ZMESSAGEDATE > (CAST(strftime('%s','{since}') AS INTEGER) - {EPOCH})"
    q = f"""
      select m.Z_PK,
             datetime(m.ZMESSAGEDATE+{EPOCH},'unixepoch','localtime'),
             m.ZISFROMME, m.ZMESSAGETYPE,
             coalesce(cast(mi.ZMOVIEDURATION as int),0),
             coalesce(mi.ZMEDIALOCALPATH,''),
             coalesce(m.ZTEXT,'')
      from ZWAMESSAGE m
      left join ZWAMEDIAITEM mi on mi.ZMESSAGE = m.Z_PK
      where m.ZCHATSESSION = ? {cond}
      order by m.ZMESSAGEDATE"""
    n = 0
    for row in con.execute(q, (pk,)):
        mpk, dt, mine, kind, dur, path, txt = row
        author = "ME" if mine == 1 else "THEM"
        txt = txt.replace("\t", " ").replace("\n", " ¶ ")
        print(f"{mpk}\t{dt}\t{author}\t{TYPES.get(kind, f'type{kind}')}\t{dur}\t{path}\t{txt}")
        n += 1
    print(f"{n} messages exported", file=sys.stderr)


if __name__ == "__main__":
    con = open_db()
    if len(sys.argv) < 2:
        list_chats(con)
        sys.exit("\nusage: dump_chat.py <chat_pk> [YYYY-MM-DD]")
    dump(con, int(sys.argv[1]), sys.argv[2] if len(sys.argv) > 2 else None)
