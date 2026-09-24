---
name: playwright
description: Drives a real browser on this Mac with Playwright — open pages, log in, click, extract content and take screenshots of real screens. Use when the user asks to validate/test something in the browser, "prove it works", a screenshot of a logged-in screen, scrape content from a site, or automate a web flow. Includes a persistent session for sites that require login (WhatsApp Web, internal dashboards).
allowed-tools: Bash, Read, Write, Edit
---

# Playwright on this Mac

Real browser automation. The value is in **proving something works** with
visual evidence, not describing it.

## Where Playwright lives

There's no global install. It comes from some project's `node_modules`:

```bash
ls ~/code/*/node_modules/playwright ~/code/*/*/node_modules/playwright 2>/dev/null | head
ls ~/Library/Caches/ms-playwright     # chromium already downloaded
```

If the project doesn't have it, find another one that does or install with
`npx playwright@latest install chromium`.

## The two traps that always bite

**1. Import by absolute path.** A script outside the project can't resolve the
package by name. Always:

```js
import { chromium } from "/path/to/project/node_modules/playwright/index.mjs"
```

**2. node's PATH.** node comes from asdf. Before running:

```bash
export PATH="$HOME/.asdf/shims:$PATH"
node script.mjs
```

Without it: `command not found: node` or the wrong version.

## Skeleton

```js
import { chromium } from "/path/node_modules/playwright/index.mjs"

const browser = await chromium.launch()                    // headless
const page = await browser.newPage({ viewport: { width: 1440, height: 1000 } })

await page.goto("http://localhost:3000/login", { waitUntil: "networkidle" })
await page.fill("#email", "user@example.com")
await page.fill("#password", "password")
await page.click('button[type="submit"]')
await page.waitForURL((u) => !u.pathname.includes("/login"), { timeout: 60000 })

await page.screenshot({ path: "/tmp/shot.png" })
await browser.close()
```

## Persistent session (sites with login)

To avoid scanning a QR / logging in every time, use an on-disk profile. **It must
be headed** when it needs human interaction:

```js
const ctx = await chromium.launchPersistentContext("/path/profile", {
  headless: false,
  viewport: null,
  args: ["--window-size=1500,1000"],
})
const page = ctx.pages()[0] || (await ctx.newPage())
```

To wait for the user to log in, poll for the element that only exists after
login, and keep the window open with `await new Promise(() => {})` if you'll
continue in another script. The profile survives between runs — the second script
can relaunch the same `launchPersistentContext` without asking for login again.

## Screenshot an element, not the whole page

Much more readable when showing someone:

```js
const card = page.locator("text=Invoices by Month")
  .locator("xpath=ancestor::div[contains(@class,'rounded-lg')][1]")
await card.scrollIntoViewIfNeeded()
await card.screenshot({ path: "shot.png" })
```

Whole page: `page.screenshot({ path, fullPage: true })`.

## Extract data, not just images

The script log is worth as much as the screenshot — it becomes the textual proof:

```js
const rows = page.locator('article[aria-label^="Invoice for"]')
console.log("found:", await rows.count())
for (let i = 0; i < await rows.count(); i++)
  console.log(" ", (await rows.nth(i).innerText()).replace(/\n+/g, " · "))
```

For a negative assertion (proving an error is gone):

```js
const err = await page.getByText(/Select a client/i).count()
console.log(err === 0 ? "error does NOT appear ✓" : "STILL APPEARS ✗")
```

## Strict mode

A `locator(...)` that matches more than one element **throws**. Use `.first()`
or refine the selector. This breaks scripts midway — after expanding a
list, the number of matched elements changes.

## Running against production

- **Read-only.** Never confirm dialogs that write. Open, screenshot, **Cancel**.
- Say so in the log: `console.log("OK — no data changed")`.
- Before anything destructive in production, ask.

## How to deliver

1. Run the script and read the log
2. **Read the PNG with the Read tool** before sending — confirm it shows what
   you're going to claim it shows
3. Deliver with SendUserFile, `display: "render"`

Never claim something works without having looked at the image.

## Debugging

| Symptom | Cause |
|---|---|
| `Cannot find package 'playwright'` | import by name instead of absolute path |
| `command not found: node` | missing the asdf PATH |
| selector timeout | the screen changed; take a `fullPage` and look |
| strict mode violation | missing `.first()` |
| blank page | missing `waitUntil: "networkidle"` or a `waitForTimeout` |
