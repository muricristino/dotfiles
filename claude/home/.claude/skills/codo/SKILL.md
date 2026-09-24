---
name: codo
description: Task board and context wiki for the Axolutions team, on a remote server (codo.axolutions.com.br). Use when the user asks to create/move/list tasks or cards ("use codo to create a task"), query or record project context ("what does codo know about project X"), read team PRDs/plans/notes, assign a task to someone, or set up codo access. Nothing runs on the local machine — everything is an HTTP call to the server.
---

# codo — the team's board and memory (remote)

codo is the Axolutions team's working wiki: **tasks** on a kanban board
(backlog → plan → implement → review → ship → done), context **notes** and
**artifacts** (PRDs, plans, specs) — all markdown on a remote server.
You talk to it over **MCP over HTTP**. No binary is installed.

- Server/API: `https://codo.axolutions.com.br`
- Web interface (humans, same login): `https://codo.axolutions.com.br`

## 1. Already configured?

If the `mcp__codo__*` tools (codo_task_new, codo_search, codo_board…)
already show up in the session, skip to "How to use". Otherwise check
`claude mcp list`; if codo isn't there, run the setup.

## 2. Setup (once per machine)

### 2.1 Authorization — the human approves in the browser

```bash
curl -s -X POST https://codo.axolutions.com.br/api/device/start
# → { "code": "XXXX-XXXX", "authorize_path": "/authorize?code=XXXX-XXXX",
#     "expires_in": 900, "interval": 3 }
```

Show the user, prominently:

> Open **https://codo.axolutions.com.br/authorize?code=XXXX-XXXX**,
> sign in with your Google account and click **authorize**.
> Check that the code on screen is **XXXX-XXXX**.

Meanwhile, poll (every ~3s, for up to 15 min):

```bash
curl -s "https://codo.axolutions.com.br/api/device/poll?code=XXXX-XXXX"
# {"status":"pending"}   → keep waiting
# {"status":"approved","token":"codo_…","email":"…"} → STORE IT: returned ONCE only
# {"status":"expired"}   → restart from 2.1
# {"status":"delivered"} → the token was already delivered; restart from 2.1
```

Only the authorized team can approve (login allowlist). If the user can't
sign in, their email needs to be cleared by the admin.

### 2.2 Test the token

```bash
curl -s https://codo.axolutions.com.br/api/scopes -H "Authorization: Bearer codo_…"
# 200 with the project list = working · 401 = redo 2.1
```

### 2.3 Register the MCP (user scope = every future session, any directory)

```bash
claude mcp add --scope user --transport http codo \
  https://codo.axolutions.com.br/mcp \
  --header "Authorization: Bearer codo_…"
```

Confirm with `claude mcp list`. **The tools only load in the next
session** — in this one, use the direct API (section 5) with the same Bearer.

A 401 on any call after it worked = token revoked or email removed from
the allowlist; redo 2.1 (token revocation is handled by the server admin).

## 3. Projects (scopes)

All data lives in a scope `project/<name>` (e.g. `project/axoplataforma`).

- List projects: `codo_board` without a scope (groups everything) or `GET /api/scopes`.
- Create a project: API only — `POST /api/project/new {"name":"…"}` (the
  board starts with the default columns). Don't create tasks in a scope
  that doesn't exist: check /api/scopes first.

## 4. How to use (MCP tools)

| intent | tool |
|---|---|
| see the board | `codo_board` (scope optional) |
| create a task | `codo_task_new` (title, scope, status?, body?) |
| move a task | `codo_task_move` (id, status, scope; `pr` required in review/ship/done when the project demands it) |
| block / unblock | `codo_task_block` / `codo_task_unblock` |
| search context | `codo_search` (global full-text) · `codo_note_search` (the project's living memory) |
| read a page | `codo_read` (scope, path) — reading a note counts as access |
| see the team | `codo_team` (name and email — codo server ONLY) |
| assign an owner | `codo_task_assign` (id, scope, assignee = member name or email; empty removes — codo server ONLY) · `codo_task_new` also accepts `assignee` |
| record an insight | `codo_note_new` (short and atomic; check `codo_note_search` first) · `codo_note_append` to merge |
| permanent document | `codo_artifact_new` (PRD/plan/spec/adr/doc — NOT a note) · `codo_artifact_append` |

Team conventions:
- A **task** is work with an owner and an end; a **note** is knowledge; an
  **artifact** is a permanent document. Don't mix them.
- Before answering about a project, search first: `codo_search` in its scope.
- Bodies are markdown; reference pages with `[[notes/slug]]` /
  `[[tasks/ID]]` — they become clickable links in the interface.
- Task `id`s carry the project prefix (AXOP-12, ORBI-3…): it comes back
  from `codo_task_new` and shows on the board.

## 5. Direct API (fallback without MCP — same auth, same rules)

```bash
BASE=https://codo.axolutions.com.br
A='Authorization: Bearer codo_…'
curl -s $BASE/api/scopes -H "$A"                       # projects
curl -s "$BASE/api/board?scope=project/x" -H "$A"      # board
curl -s -X POST $BASE/api/task/new -H "$A" \
  -d '{"scope":"project/x","title":"…","body":"## Context\n…","assignee":"person@email.com"}'
curl -s -X POST $BASE/api/task/move -H "$A" \
  -d '{"scope":"project/x","id":"X-1","status":"implement"}'
curl -s -X POST $BASE/api/task/update -H "$A" \
  -d '{"scope":"project/x","id":"X-1","title":"…","body":"…","assignee":""}'   # assignee "" removes
# also: /api/task/delete, /api/pages, /api/page?scope=&path=,
# /api/note/new·save·pin·archive·delete, /api/project/new, /api/users (team)
```

**Assigning an owner**: prefer the MCP tools (`codo_team`,
`codo_task_assign` — they accept the first name). Over the API, `assignee`
is the email; `GET /api/users` lists the team. Members appear after their
first login.

## 6. Install this skill globally (optional, recommended)

So codo is offered automatically in every session:

The repo is private, so `raw.githubusercontent.com` answers 404 — fetch the
file through the GitHub API instead (`gh` is already authenticated):

```bash
mkdir -p ~/.claude/skills/codo
gh api repos/murichristopher/codo/contents/docs/skills/codo/SKILL.md \
  --jq '.content' | base64 -d > ~/.claude/skills/codo/SKILL.md
```

It's a single markdown file — nothing else gets installed.
