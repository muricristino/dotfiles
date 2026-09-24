---
name: whatsapp
description: Lê o histórico do WhatsApp deste Mac direto do banco local do app — mensagens, datas, autores — e transcreve os áudios e vídeos com whisper. Use quando o usuário pedir para achar/reler/resgatar conversas, "o que o fulano falou sobre X", transcrever áudios do WhatsApp, ou montar linha do tempo de um cliente a partir do chat. Muito mais confiável que raspar o WhatsApp Web.
allowed-tools: Bash, Read, Write
---

# WhatsApp deste Mac

**Não rasp o WhatsApp Web.** O app nativo guarda tudo em SQLite no disco, com as
mídias em arquivo. É mais rápido, completo e não depende de QR nem de scroll.

> Dado pessoal do usuário. Trabalhe só na conversa pedida, não faça varredura
> geral, e não mande o conteúdo para fora sem pedido explícito.

## Onde tudo mora

```
~/Library/Group Containers/group.net.whatsapp.WhatsApp.shared/
├── ChatStorage.sqlite          banco de mensagens
└── Message/Media/…             mídias (.opus áudio, .mp4 vídeo, .jpg imagem)
```

**Copie o banco antes de consultar** (o app mantém lock e WAL):

```bash
SP=/tmp/wpp; mkdir -p $SP
BASE=~/Library/Group\ Containers/group.net.whatsapp.WhatsApp.shared
cp "$BASE/ChatStorage.sqlite"* $SP/
```

## Schema

| Tabela | Campos que importam |
|---|---|
| `ZWACHATSESSION` | `Z_PK`, `ZPARTNERNAME` (nome), `ZCONTACTJID` |
| `ZWAMESSAGE` | `ZCHATSESSION`, `ZTEXT`, `ZMESSAGEDATE`, `ZISFROMME`, `ZMESSAGETYPE` |
| `ZWAMEDIAITEM` | `ZMESSAGE` (FK), `ZMEDIALOCALPATH`, `ZMOVIEDURATION` |

`ZMESSAGETYPE`: **0** texto · **1** imagem · **2** vídeo · **3** áudio · **8** documento

**Datas são epoch Apple** (desde 2001-01-01). Converta com `+978307200`:

```sql
datetime(ZMESSAGEDATE + 978307200, 'unixepoch', 'localtime')
```

Para **filtrar** por data, converta no outro sentido e faça CAST:

```sql
WHERE ZMESSAGEDATE > (CAST(strftime('%s','2026-07-01') AS INTEGER) - 978307200)
```

## Achar a conversa

```bash
sqlite3 -header -column $SP/ChatStorage.sqlite \
  "select Z_PK, ZPARTNERNAME, ZCONTACTJID from ZWACHATSESSION
   where lower(ZPARTNERNAME) like '%fulano%';"
```

Panorama antes de mergulhar — período e composição:

```bash
sqlite3 -header -column $SP/ChatStorage.sqlite "
select date(ZMESSAGEDATE+978307200,'unixepoch','localtime') dia,
       sum(ZMESSAGETYPE=0) txt, sum(ZMESSAGETYPE=3) audio,
       sum(ZMESSAGETYPE=2) video, sum(ZMESSAGETYPE=1) img
from ZWAMESSAGE where ZCHATSESSION=<PK> group by 1 order by 1;"
```

## Exportar

Use os scripts prontos:

```bash
~/.claude/skills/whatsapp/scripts/dump_chat.py <chat_pk> [data_inicial] > /tmp/wpp/chat.tsv
~/.claude/skills/whatsapp/scripts/transcrever.py /tmp/wpp/chat.tsv /tmp/wpp/transcricoes
```

`dump_chat.py` gera TSV com `pk, data, autor, tipo, duração, caminho, texto`.
`transcrever.py` converte com ffmpeg e transcreve com whisper.

## Transcrição — o detalhe que muda tudo

**Nunca chame o CLI `whisper` num loop.** Ele recarrega o modelo a cada arquivo
(~10s cada). Carregue o modelo **uma vez** em Python e itere:

```python
import whisper
model = whisper.load_model("small")      # uma vez
for arquivo in lista:
    r = model.transcribe(wav, language="pt", fp16=False)
```

O Python do whisper fica no libexec do Homebrew:

```bash
/opt/homebrew/Cellar/openai-whisper/*/libexec/bin/python
```

**Rode a partir de um diretório neutro** (`cd /tmp`). Em projeto com `coverage`
configurado dá `AttributeError: module 'coverage' has no attribute 'types'`.

Modelo `small` dá boa qualidade em português. Áudio de WhatsApp é `.opus` —
converta antes:

```bash
ffmpeg -y -loglevel error -i entrada.opus -ar 16000 -ac 1 saida.wav
```

Ordem de grandeza: ~47 min de áudio → ~30 min de transcrição com `small`.
Rode em background e avise o progresso.

## Imagens

Copie para um diretório de trabalho e **leia com a tool Read** — prints de tela
costumam ser a informação mais densa da conversa (mockups, telas de erro,
comprovantes). Nomeie por data e autor, e **inclua o pk no nome**: várias
imagens compartilham o mesmo segundo e sobrescrevem umas às outras.

## Armadilhas do shell (custam tempo)

- `sqlite3 -separator '\t'` grava a **barra invertida literal**, não tab.
  Use `-separator "$(printf '\t')"`.
- Em zsh, `while read` dentro de pipe **perde o PATH** — `tr`, `head`, `wc`
  somem. Para qualquer iteração sobre a lista de mídias, **use Python**.
- Comandos com caminho absoluto (`/usr/bin/tail`) evitam surpresa de PATH.

## Como entregar

Não despeje transcrição crua. Varra por palavra-chave, monte a linha do tempo em
ordem, e cite **literal** o que importa — a frase exata do cliente vale mais que
o resumo. Marque o que é áudio, com duração e data, para dar rastreabilidade.
