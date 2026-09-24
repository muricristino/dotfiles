#!/usr/bin/env python3
"""Exporta uma conversa do WhatsApp para TSV.

  dump_chat.py <chat_pk> [data_inicial YYYY-MM-DD] > chat.tsv

Colunas: pk, data, autor, tipo, duracao, caminho_midia, texto
Sem argumentos, lista as conversas disponíveis.
"""
import os, sys, shutil, sqlite3, tempfile

BASE = os.path.expanduser(
    "~/Library/Group Containers/group.net.whatsapp.WhatsApp.shared")
EPOCH = 978307200
TIPOS = {0: "texto", 1: "imagem", 2: "video", 3: "audio", 8: "doc"}


def abrir():
    """Copia o banco (evita lock/WAL do app) e devolve a conexão."""
    tmp = os.path.join(tempfile.gettempdir(), "wpp-ChatStorage.sqlite")
    src = os.path.join(BASE, "ChatStorage.sqlite")
    if not os.path.exists(src):
        sys.exit(f"banco não encontrado em {src}")
    shutil.copy(src, tmp)
    for ext in ("-wal", "-shm"):
        if os.path.exists(src + ext):
            shutil.copy(src + ext, tmp + ext)
    return sqlite3.connect(tmp)


def listar(con):
    print("PK\tMENSAGENS\tNOME", file=sys.stderr)
    q = """select s.Z_PK, count(m.Z_PK), s.ZPARTNERNAME
           from ZWACHATSESSION s left join ZWAMESSAGE m on m.ZCHATSESSION = s.Z_PK
           group by 1 order by 2 desc limit 40"""
    for pk, n, nome in con.execute(q):
        print(f"{pk}\t{n}\t{nome}", file=sys.stderr)


def dump(con, pk, desde=None):
    cond = ""
    if desde:
        cond = f"and m.ZMESSAGEDATE > (CAST(strftime('%s','{desde}') AS INTEGER) - {EPOCH})"
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
        mpk, dt, mine, tipo, dur, path, txt = row
        autor = "EU" if mine == 1 else "ELE"
        txt = txt.replace("\t", " ").replace("\n", " ¶ ")
        print(f"{mpk}\t{dt}\t{autor}\t{TIPOS.get(tipo, f'tipo{tipo}')}\t{dur}\t{path}\t{txt}")
        n += 1
    print(f"{n} mensagens exportadas", file=sys.stderr)


if __name__ == "__main__":
    con = abrir()
    if len(sys.argv) < 2:
        listar(con)
        sys.exit("\nuso: dump_chat.py <chat_pk> [YYYY-MM-DD]")
    dump(con, int(sys.argv[1]), sys.argv[2] if len(sys.argv) > 2 else None)
