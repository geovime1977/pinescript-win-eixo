# Como instalar o EA EixoWIN.mq5 no MetaTrader 5

## 0. Acesso à conta MT5 (mobile + desktop)

Confirmado em **2026-08-04**: login na conta MT5 funciona pelo **app celular** (Android/iOS).

**Limitação importante:** a MetaQuotes só permite **uma sessão ativa por conta** ao mesmo tempo. Se o app celular estiver logado, o MT5 do Mac/Windows recebe erro `Invalid account` ou `Already logged in`.

**Workaround:**
- Para operar via Mac/Windows → **deslogar do celular antes** (Configurações → Contas → deslizar pra apagar a sessão ativa, ou trocar pra outra conta)
- Para operar via celular → **fechar o MT5 do desktop antes**
- Alternativa oficial: pedir à corretora uma **segunda credencial** (conta espelho read-only) só pra monitoramento mobile

**Recomendação:** deixar o **EA rodando no desktop (fonte da verdade)** e usar o celular só pra monitorar via notificação push (input `InpMacdAlertPush = true` do EA já dispara isso).

## 1. Onde jogar o arquivo

No Windows/MT5:

1. Abra o MetaTrader 5
2. Menu **Arquivo → Abrir Pasta de Dados**
3. Vá em `MQL5/Experts/`
4. Copie o arquivo `EixoWIN.mq5` para dentro dessa pasta

## 2. Compilar

1. Abra o **MetaEditor** (F4 no MT5, ou botão na barra)
2. No painel esquerdo (Navigator), abra `Experts/EixoWIN.mq5`
3. Aperte **F7** ou botão **Compile**
4. Se aparecer `0 error(s), 0 warning(s)` → deu certo. O `.ex5` foi gerado.

## 3. Aplicar no gráfico

1. No MT5, abra gráfico do WIN (`WIN$N`, `WINQ26` ou o contrato ativo — depende da corretora)
2. Coloque timeframe em **M1**
3. No Navigator (Ctrl+N), abra a árvore **Expert Advisors**
4. Arraste `EixoWIN` para o gráfico
5. Na aba **Common**, marque:
   - `Allow Algo Trading`
   - `Allow modification of Signal settings`
6. Na aba **Inputs**, ajuste os parâmetros se quiser (defaults estão prontos)
7. OK

## 4. Ligar o AutoTrading

Botão **Algo Trading** na barra superior tem que ficar **verde**. Se ficar vermelho, ordens não disparam.

## 5. Testar no backtest antes de dinheiro real

1. Ctrl+R abre o **Strategy Tester**
2. Expert: `EixoWIN`
3. Symbol: WIN futuros
4. Period: M1
5. Date range: pelo menos 3 meses
6. Model: `Every tick based on real ticks` (mais fiel)
7. Start

## 6. Monitor MACD H1 (já embutido no EA)

O `EixoWIN.mq5` **já traz o monitor de MACD H1 nativo** — não precisa aplicar `macd60.pine` separado.

**Inputs relevantes (grupo `== MACD Monitor H1 ==`):**

| Input | Default | O que faz |
|---|---|---|
| `InpMacdMonitor` | `true` | Liga/desliga o monitor |
| `InpMacdFast` | `12` | EMA rápida |
| `InpMacdSlow` | `26` | EMA lenta |
| `InpMacdSignal` | `9` | SMA de sinal |
| `InpMacdAlertPopup` | `true` | Popup + som ao cruzar |
| `InpMacdAlertPush` | `false` | Push notification no MT5 mobile |

**Comportamento:** função `CheckMacdH1Cross()` executa **uma vez por barra H1 confirmada** (não repete no mesmo candle), usando `iMACD(_Symbol, PERIOD_H1, ...)` sobre `PRICE_CLOSE`. Dispara:

- `Print` no log de Experts
- `Alert()` (se `InpMacdAlertPopup=true`)
- `SendNotification()` no celular (se `InpMacdAlertPush=true` — exige MetaQuotes ID configurado em Ferramentas → Opções → Notificações)

**Uso como filtro de contexto:**
- **MACD H1 cruzou pra cima** → viés comprador — reforça sinais BUY do EixoWIN
- **MACD H1 cruzou pra baixo** → viés vendedor — reforça sinais SELL do EixoWIN

**Vantagem sobre a versão Pine (`macd60.pine`):** no MT5 o cálculo é feito diretamente sobre a série H1 nativa via `iMACD`, sem depender de `request.security` — mais fiel e sem risco de repaint.

## 7. Corretoras BR que oferecem MT5 com WIN

- **XP Investimentos** — MT5 nativo, mini índice disponível
- **Rico** — MT5, WIN disponível
- **Clear** — MT5 (mesma casa da XP)
- **Genial Investimentos** — MT5

## Diferenças vs Pine Script original

| Feature | Pine (TradingView) | MQL5 (MT5) |
|---|---|---|
| Multi-timeframe | `request.security` | `iADX(sym, PERIOD_M15, ...)` nativo, **100% fiel** |
| Execução de ordem | só alerta, sem broker | envia ordem real via `CTrade` |
| Scale-out 10 alvos | sim | sim (via `SellLimit`/`BuyLimit` pendentes) |
| Fibo 1º candle 5m | via `request.security` | via `iHigh(sym, PERIOD_M5, shift)` |
| TRIX 1m e 5m | nativo em cada TF | EMA-chain manual em memória |
| Anti-faca 3/3 HTF | sim | sim (via Stoch + TRIX + DMI em M15/M30/H1) |

## Notas de operação

- O EA processa a lógica **na abertura de cada nova barra M1** (não a cada tick), pra estabilidade
- Todas as ordens pendentes têm expiração `ORDER_TIME_DAY` — cancelam automaticamente no fim do pregão
- O Magic Number default é `20260804`. Se rodar múltiplas cópias, mude no input
- Slippage default = 5 pontos (ajuste conforme sua corretora)
- Volume mínimo do WIN é 1 contrato. O EA usa sizing 5/10/15/20 por padrão

## Troubleshooting

**"Ordem não abre"** → confira Algo Trading verde, saldo/margem, e horário de pregão.
**"Handles inválidos"** → símbolo pode não ter dados históricos suficientes. Baixe pelo menos 500 barras M5 primeiro.
**"Backtest muito rápido/lento"** → use "1 minute OHLC" pra velocidade ou "Every tick based on real ticks" pra fidelidade.
