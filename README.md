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
│   └── strategy.pine        # Backtest com scale-out por Fibo
└── docs/
    ├── COMO-INSTALAR-BTG.md # Passo a passo
    └── ALERTAS-CONFIG.md    # Setup de alertas mobile/email
```

## Instalação rápida

1. Abrir o gráfico BTG em https://app.btgpactual.com/homebroker/chart
2. Buscar WINQ26 (ou vencimento atual), timeframe 1m
3. Abrir Pine Editor
4. Colar `src/indicator.pine` → Adicionar ao gráfico
5. Configurar alerta seguindo `docs/ALERTAS-CONFIG.md`

Detalhes: `docs/COMO-INSTALAR-BTG.md`.

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
