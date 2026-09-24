---
name: playwright
description: Dirige um navegador real neste Mac com Playwright — abrir páginas, logar, clicar, extrair conteúdo e tirar screenshots de telas de verdade. Use quando o usuário pedir para validar/testar algo no navegador, "prova que funciona", print de uma tela logada, raspar conteúdo de um site, ou automatizar um fluxo web. Inclui sessão persistente para sites que exigem login (WhatsApp Web, painéis internos).
allowed-tools: Bash, Read, Write, Edit
---

# Playwright neste Mac

Automação de navegador real. O valor está em **provar que algo funciona** com
evidência visual, não em descrever.

## Onde o Playwright mora

Não há instalação global. Ele vem do `node_modules` de algum projeto:

```bash
ls ~/code/*/node_modules/playwright ~/code/*/*/node_modules/playwright 2>/dev/null | head
ls ~/Library/Caches/ms-playwright     # chromium já baixado
```

Se o projeto não tiver, procure outro que tenha ou instale com
`npx playwright@latest install chromium`.

## As duas armadilhas que sempre pegam

**1. Import por caminho absoluto.** Script fora do projeto não resolve o pacote
pelo nome. Sempre:

```js
import { chromium } from "/caminho/do/projeto/node_modules/playwright/index.mjs"
```

**2. PATH do node.** O node vem do asdf. Antes de rodar:

```bash
export PATH="$HOME/.asdf/shims:$PATH"
node script.mjs
```

Sem isso: `command not found: node` ou versão errada.

## Esqueleto

```js
import { chromium } from "/caminho/node_modules/playwright/index.mjs"

const browser = await chromium.launch()                    // headless
const page = await browser.newPage({ viewport: { width: 1440, height: 1000 } })

await page.goto("http://localhost:3000/login", { waitUntil: "networkidle" })
await page.fill("#email", "user@exemplo.com")
await page.fill("#password", "senha")
await page.click('button[type="submit"]')
await page.waitForURL((u) => !u.pathname.includes("/login"), { timeout: 60000 })

await page.screenshot({ path: "/tmp/shot.png" })
await browser.close()
```

## Sessão persistente (sites com login)

Para não escanear QR / logar toda vez, use perfil em disco. **Precisa ser
headed** quando exige interação humana:

```js
const ctx = await chromium.launchPersistentContext("/caminho/perfil", {
  headless: false,
  viewport: null,
  args: ["--window-size=1500,1000"],
})
const page = ctx.pages()[0] || (await ctx.newPage())
```

Para esperar o usuário logar, faça polling pelo elemento que só existe depois do
login, e mantenha a janela aberta com `await new Promise(() => {})` se for
continuar em outro script. O perfil sobrevive entre execuções — o segundo script
pode relançar o mesmo `launchPersistentContext` sem pedir login de novo.

## Print de elemento, não da página inteira

Muito mais legível para mostrar a alguém:

```js
const card = page.locator("text=Faturas por Mês")
  .locator("xpath=ancestor::div[contains(@class,'rounded-lg')][1]")
await card.scrollIntoViewIfNeeded()
await card.screenshot({ path: "shot.png" })
```

Página inteira: `page.screenshot({ path, fullPage: true })`.

## Extrair dado, não só imagem

O log do script vale tanto quanto o print — ele vira a prova textual:

```js
const linhas = page.locator('article[aria-label^="Fatura de"]')
console.log("encontrados:", await linhas.count())
for (let i = 0; i < await linhas.count(); i++)
  console.log(" ", (await linhas.nth(i).innerText()).replace(/\n+/g, " · "))
```

Para asserção negativa (provar que um erro sumiu):

```js
const erro = await page.getByText(/Selecione o cliente/i).count()
console.log(erro === 0 ? "erro NÃO aparece ✓" : "AINDA APARECE ✗")
```

## Strict mode

`locator(...)` que casa com mais de um elemento **lança exceção**. Use `.first()`
ou refine o seletor. Isso quebra scripts no meio — depois de expandir uma
listagem, o número de elementos casados muda.

## Rodando contra produção

- **Só leitura.** Nunca confirme diálogos que gravam. Abra, printe, **Cancele**.
- Diga isso no log: `console.log("OK — nenhum dado alterado")`.
- Antes de qualquer coisa destrutiva em produção, pergunte.

## Como entregar

1. Rode o script e leia o log
2. **Leia o PNG com a tool Read** antes de mandar — confirme que mostra o que
   você vai afirmar que mostra
3. Entregue com SendUserFile, `display: "render"`

Nunca afirme que algo funciona sem ter olhado a imagem.

## Depuração

| Sintoma | Causa |
|---|---|
| `Cannot find package 'playwright'` | import por nome em vez de caminho absoluto |
| `command not found: node` | faltou o PATH do asdf |
| timeout no seletor | a tela mudou; tire um `fullPage` e olhe |
| strict mode violation | falta `.first()` |
| página em branco | faltou `waitUntil: "networkidle"` ou um `waitForTimeout` |
