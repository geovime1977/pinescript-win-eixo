# Como Instalar no Profit / Nelogica (NTSL)

**Objetivo:** importar a estratégia `strategy.ntsl` no Profit Chart Pro/Ultra para rodar backtest ou automação da estratégia EixoWIN.

**Tempo:** ~10 minutos.

**Referência:** Manual NTSL v4.3 (Nelogica, 10/04/2026) — `~/Downloads/ManualNTSL.pdf`.

---

## Pré-requisitos

- Profit Chart **Pro** ou **Ultra** ativo (Basic não tem editor de estratégias)
- Gráfico do **WIN$** (contínuo) ou vencimento vigente (WINQ26, WINV26, etc.)
- Timeframe **5 minutos** (a estratégia foi adaptada para 5m como base, não 1m)
- Automação de Estratégias liberada na sua licença (se for rodar automatizado; para backtest basta Pro)

---

## Rota A — Editor de Estratégias do Profit

### 1. Abrir o editor
- [ ] Menu superior → **Estratégias** → **Editor de Estratégias**
- [ ] Ou tecla de atalho configurada nas preferências

### 2. Criar nova estratégia
- [ ] Clicar em **Nova Estratégia**
- [ ] Nome: `EixoWIN 5m — Fibo 2º toque + Congruência HTF`
- [ ] Tipo: **Estratégia de Execução** (para backtest + automação)

### 3. Colar o código
- [ ] Abrir `src/strategy.ntsl` deste repo
- [ ] Copiar TODO o conteúdo (Cmd+A, Cmd+C)
- [ ] Colar no editor NTSL
- [ ] Clicar em **Compilar** (F5 ou botão verde)

### 4. Verificar compilação
- [ ] Painel inferior deve mostrar `Código compilado` sem erros
- [ ] Se aparecer erro do tipo `Identificador não declarado`, você provavelmente colou uma versão antiga — o arquivo atual foi validado contra o Manual NTSL v4.3
- [ ] Se aparecer erro na função `DiPDiM` ou `FastStochastic`, sua versão do Profit é anterior a 2020 — precisa atualizar

### 5. Aplicar ao gráfico (modo backtest)
- [ ] Salvar estratégia (Cmd+S / Ctrl+S)
- [ ] Voltar ao gráfico WIN 5min
- [ ] Botão direito no gráfico → **Inserir Estratégia** → escolher `EixoWIN 5m`
- [ ] Aba **Backtest** aparece na barra inferior com performance histórica
- [ ] Setas verdes/vermelhas marcam entradas; **SellToCover** e **BuyToCover** marcam saídas

---

## Parâmetros ajustáveis (input)

Todos acessíveis clicando na engrenagem ⚙️ da estratégia → aba **Parâmetros**:

| Parâmetro | Default | Descrição / Quando mexer |
|---|---|---|
| `TolPct` | 0.05 | Tolerância % pra considerar toque no nível. ↑ pra 0.10 se toques passam despercebidos |
| `GapBars` | 3 | Barras mínimas entre 2 eventos no mesmo nível |
| `MaxGapTouches` | 10 | Barras máximas entre 1º e 2º toque |
| `WaitAfterTouch` | 1 | Janela pós-2º toque pra confirmação |
| `MinExtras` | 1 | Confirmações mínimas (Estoc + TRIX). ↑ pra 2 = mais rigoroso |
| `AdxMin` | 25 | ADX mínimo pra congruência HTF |
| `AdxLenBase` | 8 | ADX base (~5m) |
| `AdxLenH15` | 24 | ADX aprox 15m (3×5m) |
| `AdxLenH30` | 48 | ADX aprox 30m (6×5m) |
| `AdxLenH60` | 96 | ADX aprox 60m (12×5m) |
| `AdxMediaLen` | 9 | Suavização da média do ADX |
| `EstocLen` | 5 | Período do FastStochastic |
| `EstocDLen` | 3 | Período do %D (média do %K) |
| `TrixLen` | 9 | Período das 3 EMAs do TRIX |
| `TrixMALen` | 4 | Média do sinal do TRIX |
| `StopFibPct` | 0.5 | Stop = fração da amplitude Fibo |
| `SessionEndTime` | 1730 | HHMM — fim janela de entrada (17:30) |
| `EodTime` | 1755 | HHMM — EOD forçado (17:55) |
| `QtyBase` | 5 | Contratos base por TF confirmado |
| `QtyCap` | 20 | Cap máximo total de contratos |
| `AntiFaca` | 1 | 1 = bloqueia contra HTF 3/3, 0 = ignora filtro |

---

## Ordem de execução da estratégia

1. **1º candle 5min do dia** → captura High/Low → gera 21 níveis Fibo (U0…U450, L0…L450, UMid)
2. **A cada candle** → conta toques em cada nível (`e` = eventos, `b` = barras desde último toque)
3. **1º toque em suporte** → arma BUY (`BuyFirstAgo := 0`)
4. **2º toque em suporte dentro de `MaxGapTouches`** → confirma gatilho BUY
5. **Filtros extras:** cruzamento Estocástico + TRIX na direção do trade dentro da janela
6. **Anti-faca:** se todos 3 HTF (15/30/60m) estiverem 3/3 contra, bloqueia entrada
7. **Sizing:** `QtyTotal = QtyBase × Cong44BuyScore` (5/10/15/20 contratos), limitado por `QtyCap`
8. **Entrada:** `BuyAtMarket(QtyTotal)` + 3 `SellToCoverLimit` (150/300/450) + 1 `SellToCoverStop`
9. **Saída antecipada:** 2 cruzamentos TRIX contra + toque em qualquer Fibo → `ClosePosition`
10. **EOD:** após `EodTime` (17:55) → `ClosePosition`

---

## Rodar em automação (Ultra)

⚠️ **Antes de habilitar automação real**, rodar backtest por 3 meses no mínimo e revisar:
- Fator de lucro (target > 1.5)
- Número de trades (evitar < 30, estatística fraca)
- Drawdown máximo (compatível com seu risco)

Passos:
- [ ] Menu **Estratégias** → **Gerenciador de Automações**
- [ ] Nova automação → selecionar `EixoWIN 5m` como estratégia
- [ ] Configurar ativo, corretora, conta, quantidade por ordem
- [ ] Aba **Risco**: definir limite de perda diária, número máx. de operações
- [ ] Aba **Horários**: início 09:00, fim 17:30 (bate com `SessionEndTime=1730`)
- [ ] Aba **Segurança**: senha da automação, notificação de execução
- [ ] Ativar

O Raio-X do Gerenciador de Automações mostra o estado interno da estratégia em tempo real (útil para depurar comportamento).

---

## Troubleshooting

### "Erro de compilação: identificador `Estocastico` não declarado"
→ Você colou uma versão antiga. A função correta é `FastStochastic(Periodo)`. Baixe a versão atual do repo.

### "Erro: função `DMIMais` não encontrada"
→ Nomenclatura antiga. Correto: `DiPDiM(Periodo)|0|` (DI+) e `DiPDiM(Periodo)|1|` (DI-).

### "Erro: parâmetros insuficientes em `ADX`"
→ `ADX` no NTSL exige 2 parâmetros: `ADX(Periodo, Media)`. A versão atual usa `AdxMediaLen` como 2º.

### "Estratégia compila mas não abre ordem"
→ Verificar em ordem:
1. Está no gráfico de 5min? (não roda em outros timeframes)
2. É após o 1º candle do dia? (Fibo só existe a partir do 2º candle 5m)
3. `HasBase` está `True`? (adicionar `Plot(FibRange)` temporariamente para conferir)
4. Score de congruência HTF chegou a pelo menos 1?
5. Anti-faca não está bloqueando? (colocar `AntiFaca=0` temporariamente para testar)

### "Ordens de scale-out não estão saindo"
→ `SellToCoverLimit`/`BuyToCoverLimit` só executam se preço atingir o limite. Se o dia não estender até U450/L450, as ordens ficam pendentes até EOD, onde `ClosePosition` cancela tudo e zera posição.

### "Stop-loss não dispara"
→ `SellToCoverStop`/`BuyToCoverStop` são ordens de stop-market. Se o preço romper `StopPrice`, dispara. Se não romper (que é o ideal), a ordem fica pendente e é cancelada no EOD.

### "Muitas entradas por dia"
→ Aumentar `MinExtras` para 2 (exige Estoc **E** TRIX confirmando). Ou aumentar `MaxGapTouches` para 15 (dá mais tempo para o 2º toque validar padrão).

---

## Diferenças vs versão Pine Script

- **Timeframe base:** NTSL roda em 5min (Pine roda em 1min e puxa 5min via `request.security`)
- **HTF congruência:** NTSL aproxima 15/30/60m via ADX com períodos dilatados (3×, 6×, 12× de 5m); Pine usa MTF nativo
- **Scale-out:** NTSL usa 3 alvos (150/300/450); Pine usa 10 alvos (a versão original)
- **Saída antecipada:** ambas usam 2 cruzamentos TRIX + toque em Fibo

Se precisar do comportamento MTF nativo do Pine, migre para MT5 (`EixoWIN.mq5`) que usa `iMACD(_Symbol, PERIOD_H1, ...)` para timeframes reais.
