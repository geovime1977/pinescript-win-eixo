# pinescript-win-eixo

Estratégia Day Trade WIN — Congruência MTF + Fibonacci de Abertura, implementada como Pine Script v5 para rodar nativamente no **TradingView-BTG**.

## Escopo

- **Não é o `backtest-win`** (POC Python IBOV proxy — Mac)
- **Não é o `dashboard-win-sim`** (Streamlit — Mac)
- **Não é o `scanner-win-mt5`** (Python + MT5 — Windows futuro)

Este é o **primeiro projeto que roda com dados WIN reais em tempo real**, aproveitando a plataforma BTG que embarca TradingView.

## Conteúdo

```
pinescript-win-eixo/
├── src/
│   ├── indicator.pine       # Sinais X/4 no gráfico + alertas (X ajustável)
│   ├── strategy.pine        # Backtest com scale-out por Fibo
│   ├── macd60.pine          # Monitor MACD H1 (12/26/9) standalone
│   ├── strategy.ntsl        # Port pra ProfitChart Pro (Nelogica)
│   └── EixoWIN.mq5          # Port pra MetaTrader 5 (Expert Advisor)
└── docs/
    ├── COMO-INSTALAR-BTG.md    # Passo a passo TradingView-BTG
    ├── COMO-INSTALAR-MT5.md    # Passo a passo MetaTrader 5
    ├── COMO-INSTALAR-PROFIT.md # Passo a passo Profit/Nelogica (NTSL)
    └── ALERTAS-CONFIG.md       # Setup de alertas mobile/email
```

## Versão NTSL (Profit / Nelogica)

O arquivo `src/strategy.ntsl` foi **validado contra o Manual NTSL oficial v4.3 (10/04/2026)** em 2026-08-04. Correções aplicadas contra a versão inicial que continha placeholders inválidos:

| Erro anterior | Correção NTSL |
|---|---|
| `Parametro` | `input` |
| `Data`, `Hora`, `Minuto` | `Date`, `Time` (HHMM) |
| `Estocastico(len)` | `FastStochastic(len)` |
| `Media(serie, per)` | `Media(per, serie)` — ordem invertida |
| `ADX(len)` | `ADX(periodo, media)` — 2 parâmetros |
| `DMIMais/DMIMenos` | `DiPDiM(len)\|0\|` e `DiPDiM(len)\|1\|` |
| `SetStopLoss(px)` | `SellToCoverStop` / `BuyToCoverStop` |
| `ExitLongAtLimit` | `SellToCoverLimit(preço, qty)` |
| `ExitShortAtLimit` | `BuyToCoverLimit(preço, qty)` |
| `ExitLong/ShortAtMarket` | `ClosePosition` |
| operador `div` | `IntPortion(a / b)` — NTSL só tem `/` (float) |
| sem `begin ... end;` principal | envelope adicionado |

Ver `docs/COMO-INSTALAR-PROFIT.md` para importar no editor de estratégias do Profit.

## Instalação rápida

1. Abrir o gráfico BTG em https://app.btgpactual.com/homebroker/chart
2. Buscar WINQ26 (ou vencimento atual), timeframe 1m
3. Abrir Pine Editor
4. Colar `src/indicator.pine` → Adicionar ao gráfico
5. (Opcional) Colar `src/macd60.pine` num painel separado → Adicionar (monitor MACD H1)
6. Configurar alerta seguindo `docs/ALERTAS-CONFIG.md`

Detalhes: `docs/COMO-INSTALAR-BTG.md`.

## Módulo MACD H1 (macd60.pine)

Indicador **standalone** que puxa MACD (12/26/9 default) do timeframe **60 minutos** independente do gráfico atual, via `request.security`. Serve como filtro de contexto pra confirmar direção dos sinais do EixoWIN:

- **MACD H1 cruzou pra cima** → viés comprador — reforça sinais BUY do EixoWIN
- **MACD H1 cruzou pra baixo** → viés vendedor — reforça sinais SELL do EixoWIN
- **MACD H1 sem cruzamento recente** → lateralidade em H1, prefira ficar de fora

**Uso recomendado:** aplicar em painel separado (não overlay), abaixo do gráfico principal do WIN. Assim você vê `indicator.pine` no gráfico + `macd60.pine` embaixo, ambos ao mesmo tempo.

**Alertas disponíveis (3 opções):**
1. `MACD H1 - Cruzamento (unico)` — cabe no plano free (1 alerta cobre compra e venda)
2. `MACD H1 - CRUZAMENTO COMPRA` — requer plano Plus+ (múltiplos alertas)
3. `MACD H1 - CRUZAMENTO VENDA` — requer plano Plus+

**Uso no MT5:** equivalente já está integrado no `EixoWIN.mq5` (função `CheckMacdH1Cross`) via `iMACD(_Symbol, PERIOD_H1, 12, 26, 9, PRICE_CLOSE)`, disparando `Alert` popup e `SendNotification` (push mobile). Quem operar via MT5 não precisa aplicar nada adicional — ver `docs/COMO-INSTALAR-MT5.md` §6.

## MT5 mobile — status

- Acesso à conta MT5 pelo **app celular validado em 2026-08-04**
- MetaQuotes permite **apenas 1 sessão ativa por conta** → mobile e desktop não coexistem sem deslogar um dos lados
- Recomendação: EA rodando no desktop + celular só recebendo push (`InpMacdAlertPush=true`)
- Detalhes de convivência mobile/desktop em `docs/COMO-INSTALAR-MT5.md` §0

## Estratégia canônica

Ver nota no vault: `~/vault/meus-projetos/01 - Profissional/Projetos/Estratégia Day Trade WIN — Congruência MTF + Fibo de Abertura.md`

## Regra de execução

- **Timeframe operacional:** 1 minuto (gatilho, 2º toque)
- **Timeframes de contexto:** 5min (TRIX, ADX) + 15/30/60m (congruência)
- **Fibonacci:** projetado do 1º candle 5min do dia
- **Gatilho:** score >= `min_score` (default 2/4; ajustável 1-4 no input do indicador)
- **Sizing:** 5/10/15/20 contratos por congruência (0/1/2/3)

## Limitações

- Pine Script **não abre ordem** na corretora — você recebe o alerta e executa manualmente
- **1 alerta ativo** no plano free do TradingView (o indicador está desenhado pra caber nisso)
- **Backtest limitado** em profundidade histórica no plano free
- **Comissões** modeladas no strategy: R$ 0,50/contrato/lado (ajustável nos inputs)

## Roadmap

- [ ] v1 pushado (indicator + strategy + docs)
- [ ] Testar em 3+ dias de pregão real
- [ ] Ajustar tolerâncias baseado no comportamento observado
- [ ] Migrar pra Windows/MT5 quando precisar de automação total de ordens
