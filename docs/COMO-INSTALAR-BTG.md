# Como Instalar no BTG Trader (TradingView Integrado)

**Objetivo:** colar o indicador `Eixo WIN — Sinais 4/4` no seu gráfico WIN dentro da plataforma BTG.

**URL do gráfico:** https://app.btgpactual.com/homebroker/chart

**Tempo:** ~10 minutos.

---

## Pré-requisitos

- Conta BTG Trader ativa
- Login na plataforma
- Ter aberto o gráfico do **WINQ26** (ou vencimento vigente do WIN) em **timeframe de 1 minuto**

---

## Rota A — Editor Pine dentro do BTG (tentar primeiro)

O TradingView embarcado no BTG geralmente expõe o editor Pine completo. Testa assim:

### 1. Abrir o gráfico
- [ ] Login em https://app.btgpactual.com/homebroker/chart
- [ ] Buscar **WINQ26** (ou vencimento atual) no campo de símbolo
- [ ] Timeframe = **1m**

### 2. Localizar o Pine Editor
- [ ] Na barra inferior do gráfico, procurar aba **"Pine Editor"** ou **"Editor de Estratégias"**
- [ ] Se não aparecer diretamente, clicar no ícone de **funções (`fx`)** ou nos **três pontinhos "..."** e procurar "Adicionar indicador Pine" / "Pine Editor"

### 3. Colar o código
- [ ] Abrir `src/indicator.pine` deste repo
- [ ] Copiar TODO o conteúdo (Cmd+A, Cmd+C no Mac; Ctrl+A, Ctrl+C no Windows)
- [ ] Colar no Pine Editor da plataforma
- [ ] Clicar em **"Adicionar ao gráfico"** ou **"Save & Add"**

### 4. Verificar
- [ ] Linhas Fibo (azul suporte, vermelho resistência) aparecem no gráfico
- [ ] Painel de sinais no canto superior direito com 4 luzes por lado
- [ ] Setas verdes/vermelhas quando 4/4 dispara

---

## Rota B — TradingView.com (se BTG restringir editor)

Se o editor Pine do BTG estiver bloqueado ou não permitir custom scripts:

### 1. Acessar TradingView.com direto
- [ ] Vai em https://www.tradingview.com
- [ ] Login com **a mesma conta** (Google ou email) que usa no BTG — TradingView e BTG frequentemente compartilham conta via SSO
- [ ] Se não tiver conta, criar grátis (email + senha)

### 2. Adicionar o indicador ao TradingView.com
- [ ] Abrir gráfico de qualquer ativo
- [ ] Rodar **Pine Editor** na barra inferior
- [ ] Colar o código de `src/indicator.pine`
- [ ] Salvar (Cmd+S / Ctrl+S) — dá um nome tipo "Eixo WIN 4/4"
- [ ] Clicar em **"Adicionar ao gráfico"**

### 3. Voltar pro BTG
- [ ] Abrir https://app.btgpactual.com/homebroker/chart de novo
- [ ] Buscar **WINQ26**, timeframe 1m
- [ ] Clicar em **Indicadores** → aba **"Meus"** ou **"Salvos"**
- [ ] O indicador salvo no TradingView.com deve aparecer aqui
- [ ] Clicar pra adicionar

**Motivo:** o TradingView-BTG puxa scripts salvos na sua conta TradingView.com por SSO. Se compartilham conta, o script fica disponível nos dois.

---

## Rota C — Strategy (backtest)

Repetir os mesmos passos usando `src/strategy.pine` no lugar do `indicator.pine`.

Diferenças:
- Aparece a aba **Strategy Tester** no BTG (barra inferior) com performance histórica
- Executa entradas/saídas simuladas com scale-out em cada Fibo
- Não usar em conta real — é só backtest

**Rodar backtest:**
- [ ] Adicionar `strategy.pine` ao gráfico
- [ ] Timeframe = 1m
- [ ] Range de datas: escolher últimos 30-60 dias
- [ ] Verificar métricas em **Strategy Tester → Performance Summary**

---

## Ajustes finos após instalar

### Parâmetros que talvez precise mexer

Todos acessíveis clicando na engrenagem ⚙️ do indicador → aba "Inputs":

| Parâmetro | Default | Quando mexer |
|---|---|---|
| **Tolerância de toque (%)** | 0.05 | Se toques não estão sendo detectados, aumentar pra 0.1. Se detecta demais, diminuir pra 0.03 |
| **Janela de cruzamento** | 3 | Se sinais estão muito raros, aumentar pra 5. Se estão fracos, baixar pra 2 |
| **Gap mínimo entre eventos** | 3 | Se agrupa toques que deveriam ser separados, baixar pra 2. Se separa demais, subir pra 5 |
| **ADX mín. congruência** | 25 | Padrão. Só mexe se quiser critério mais/menos rigoroso |
| **Hora limite pra abrir** | 17:30 | Ajustar pra rotina pessoal |

### Cores dos Fibos

Fibos suporte (compra) = azul. Fibos resistência (venda) = vermelho.
Se quiser trocar, edita as linhas `color_sup` e `color_res` no código.

---

## Troubleshooting

### "Não vejo o Pine Editor no BTG"
→ Tenta a Rota B (via tradingview.com) ou fale com suporte BTG pra ativar o editor.

### "Linhas Fibo não aparecem"
→ Você aplicou no gráfico certo? Precisa ser **1m** e no ativo **WINQ26**. O Fibo é do 1º candle 5m do dia — se aplicar no meio do pregão, ele calcula corretamente mas só mostra a partir daí.

### "Painel de sinais aparece vazio"
→ Timeframes 15/30/60m e 5m ainda estão carregando dados. Espera 30s-1min após adicionar o indicador.

### "Erros de compilação"
→ Certifique-se de copiar TODO o código do `.pine`, incluindo a primeira linha `// @version=5`. Se o BTG usa TradingView versão antiga (v4), me avisa que eu adapto.

### "Não recebo alertas no celular"
→ Ver `ALERTAS-CONFIG.md` neste mesmo diretório.

---

**Depois de instalar, testa em pelo menos 3 dias diferentes** (usa a barra de tempo pra voltar no gráfico) e observa se as luzes 4/4 aparecem em setups conhecidos (ex: dia 10/jul/26 que a estratégia validou).
