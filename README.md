# pinescript-win-eixo

Estratégia Day Trade WIN — **Congruência MTF + Fibonacci de Abertura**, implementada como Pine Script v5 (v14 / 04-08-2026) para rodar nativamente no **TradingView-BTG**.

## Escopo

- **Não é o `backtest-win`** (POC Python IBOV proxy — Mac)
- **Não é o `dashboard-win-sim`** (Streamlit — Mac)
- **Não é o `scanner-win-mt5`** (Python + MT5 — Windows futuro)

Este é o **primeiro projeto que roda com dados WIN reais em tempo real**, aproveitando a plataforma BTG que embarca TradingView.

## Conteúdo

```
pinescript-win-eixo/
├── src/
│   ├── indicator.pine       # Sinais X/3 (v14) no gráfico + alertas
│   ├── strategy.pine        # Backtest v14 com scale-out por Fibo
│   ├── strategy-v1.ntsl     # NTSL enxuta (prova de compilação Profit)
│   ├── strategy.ntsl        # NTSL v14 completa (Profit / Nelogica)
│   ├── macd60.pine          # Monitor MACD H1 standalone
│   └── EixoWIN.mq5          # Port pra MetaTrader 5 (Expert Advisor)
└── docs/
    ├── COMO-INSTALAR-BTG.md    # Passo a passo TradingView-BTG
    ├── COMO-INSTALAR-MT5.md    # Passo a passo MetaTrader 5
    ├── COMO-INSTALAR-PROFIT.md # Passo a passo Profit/Nelogica (NTSL)
    └── ALERTAS-CONFIG.md       # Setup de alertas mobile/email
```

## Spec canônica v14 (04-08-2026)

**TF operacional:** 1 minuto (gatilho + entrada)
**TFs de análise:** 5 · 15 · 30 · 60 (sem análise em Diário)

**Indicadores por TF (5/15/30/60):**

| Papel | Indicador | Parâmetros |
|---|---|---|
| Decisão | Estocástico Lento | (K=8, D=3, SMA duplo) |
| Decisão | TRIX | (9, MMA 3) |
| Decisão | DI+/DI- | (8, 8) |
| **Intensidade** (não pontua) | ADX | (8, 8) |

**Filtro contextual:** MACD 60m (12, 26, 9, close) — não pontua no score, marca visual "M60" no gráfico + linha no painel.

**Score X/3 por TF:** Estoc + TRIX + DI± na direção. ADX fora do cálculo.

**Sizing:** `5 × N_TFs_com_3/3` (mín 5, máx 20)

| N_TFs 3/3 | Contratos |
|---|---|
| 0 | 5 (mínimo) |
| 1 | 5 |
| 2 | 10 |
| 3 | 15 |
| 4 | 20 |

**Gate de entrada (v14):**
1. Preço bate no Fibo pela 2ª vez
2. Candle da 2ª batida fecha **acima** (compra) ou **abaixo** (venda) do nível
3. Entrada = abertura do candle **seguinte**

Spec detalhada: `~/vault/meus-projetos/01 - Profissional/Projetos/Estratégia Day Trade WIN — Congruência MTF + Fibo de Abertura.md`

## Instalação rápida

1. Abrir o gráfico BTG em https://app.btgpactual.com/homebroker/chart
2. Buscar WINQ26 (ou vencimento atual), timeframe **1min**
3. Abrir Pine Editor
4. Colar `src/indicator.pine` → **Add to chart**
5. (Opcional) Colar `src/macd60.pine` num painel separado → Add (monitor MACD H1)
6. Configurar alerta seguindo `docs/ALERTAS-CONFIG.md`

Detalhes: `docs/COMO-INSTALAR-BTG.md`.

## Codificação das setas MTF no gráfico

Formato: `<TF>.<indicadores>` com números.

| Código de TF | TF |
|---|---|
| 1 | 5min |
| 2 | 15min |
| 3 | 30min |
| 4 | 60min |

| Código de indicador | Indicador |
|---|---|
| 1 | Estocástico Lento |
| 2 | TRIX |
| 3 | DI+/DI- |

Exemplos:
- 🔺 `4.1.2.3` (abaixo do candle) = 60m, os 3 indicadores alinhados na compra
- 🔺 `2.3` (abaixo) = 15m, só DI na compra
- 🔻 `3.1.2` (acima) = 30m, Estoc + TRIX na venda

**Cores por TF:** aqua (5m) · lime (15m) · laranja (30m) · roxo (60m).
**Cor MACD 60m:** cinza — marca "M60" separada.
**Cor ADX ativo:** mesma cor do TF — marca "A5"/"A15"/"A30"/"A60".

Cada TF ocupa uma **lane vertical própria** proporcional ao ATR(14), evitando sobreposição quando múltiplos TFs disparam no mesmo candle.

## Versão NTSL (Profit / Nelogica)

O arquivo `src/strategy.ntsl` (v14) foi reescrito em sintaxe pt (`Se/entao/inicio/fim`, `e/ou`, `:=`) alinhada ao exemplo de código NTSL comprovadamente aceito pelo Profit.

Diferenças estruturais NTSL vs Pine:
- NTSL **não suporta** `request.security` — cálculos MTF viram proxies via períodos dilatados do ADX no próprio 5m (`ADX(24)`, `ADX(48)`, `ADX(96)`)
- Scale-out reduzido de 10 alvos → 2 alvos (`U150`/`U300` para compra; `L150`/`L300` para venda)
- Sintaxe portuguesa: `Se ... entao inicio ... fim;` no lugar de `if ... then begin ... end;`

Ver `docs/COMO-INSTALAR-PROFIT.md` para importar no editor de estratégias do Profit.

## Regra de execução

- **Timeframe operacional:** 1 minuto (gatilho + entrada)
- **Timeframes de análise:** 5min + 15min + 30min + 60min
- **Fibonacci:** projetado do 1º candle 5min do dia (21 níveis: MID + U0..U450 + L0..L450)
- **Gate:** 2ª batida em Fibo + candle fecha na direção + entra na abertura do seguinte
- **Sizing:** 5 × N_TFs com 3/3 (mín 5, máx 20)
- **Runner:** scale-out por flip de TF travado

## Limitações

- Pine Script **não abre ordem** na corretora — você recebe o alerta e executa manualmente
- **1 alerta ativo** no plano free do TradingView
- **Backtest limitado** em profundidade histórica no plano free
- **Comissões** modeladas no strategy: R$ 0,50/contrato/lado (ajustável)

## Roadmap

- [x] v14 pushada (indicator + strategy + docs + NTSL)
- [ ] Testar em 3+ dias de pregão real com v14
- [ ] Ajustar tolerâncias baseado no comportamento observado
- [ ] Migrar pra Windows/MT5 quando precisar de automação total de ordens
