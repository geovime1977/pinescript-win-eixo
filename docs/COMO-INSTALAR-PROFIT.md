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

## Ordem de execução da estratégia v14

1. **1º candle 5min do dia** → captura High/Low → gera 21 níveis Fibo (U0…U450, L0…L450, UMid)
2. **A cada candle 5min** → conta toques em cada nível (`e` = eventos, `b` = barras desde último toque)
3. **Indicadores no 5m:** Estocástico Lento (8,3), TRIX (9, MMA 3), DI+/DI- (8,8), ADX (8,8)
4. **Score X/3 5m:** Estoc + TRIX + DI± alinhados na direção. Se 3/3 → TF 5m conta como alinhado
5. **Congruência 15/30/60m:** proxies via ADX com períodos dilatados (24 / 48 / 96) — se ADX > 25 + DI direcionando, TF conta como alinhado
6. **Sizing:** `QtyBase × NTfsAlinhados` (5/10/15/20 contratos), limitado por `QtyCap`
7. **Gate v14:** 2ª batida em nível Fibo (`_e = 2`) E candle fecha `Close > nivel` (compra) ou `Close < nivel` (venda) → arma
8. **Entrada:** no candle SEGUINTE ao armed (via `BuySignalV14 := BuyGateArmed[1]`) → `BuyAtMarket(QtyTotal)` + 2 `SellToCoverLimit` (U150/U300) + 1 `SellToCoverStop`
9. **EOD:** após `EodTime` (17:55) → `ClosePosition`

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
4. Já teve 2ª batida em algum Fibo hoje? (o gate v14 exige `_e = 2` em algum nível)
5. Candle da 2ª batida fechou na direção correta? (compra: `Close > nivel`; venda: `Close < nivel`)
6. `NTfsBuy` ou `NTfsSell` ≥ 1? (mesmo com mínimo 5, sizing depende dos TFs)

### "Ordens de scale-out não estão saindo"
→ `SellToCoverLimit`/`BuyToCoverLimit` só executam se preço atingir o limite. Se o dia não estender até U450/L450, as ordens ficam pendentes até EOD, onde `ClosePosition` cancela tudo e zera posição.

### "Stop-loss não dispara"
→ `SellToCoverStop`/`BuyToCoverStop` são ordens de stop-market. Se o preço romper `StopPrice`, dispara. Se não romper (que é o ideal), a ordem fica pendente e é cancelada no EOD.

### "Muitas entradas por dia"
→ Aumentar `MaxGapTouches` para 15 (dá mais tempo pro 2º toque). Ou reduzir `TolPct` pra 0.03 (toque mais estrito). Se ainda assim muito, considerar rodar só 1 direção (comentar bloco de venda ou de compra).

### "Muitas entradas de baixa qualidade"
→ O sizing mínimo é 5 mesmo com 0 TFs alinhados. Se quiser bloquear entradas sem congruência mínima, editar a condição da entrada para exigir `NTfsBuy >= 1` (idem venda).

---

## Diferenças vs versão Pine Script v14

- **Timeframe base:** NTSL roda em 5min (Pine roda em 1min e puxa 5m/15m/30m/60m via `request.security`)
- **HTF congruência:** NTSL aproxima 15/30/60m via ADX com períodos dilatados (24, 48, 96); Pine usa MTF nativo com Estoc + TRIX + DI+ADX por TF
- **Scale-out:** NTSL usa 2 alvos (U150/U300 na compra, L150/L300 na venda); Pine usa scale-out por flip de TF
- **Gate v14:** ambos usam a mesma regra — 2ª batida em Fibo + candle fecha na direção → entra na abertura do seguinte

Se precisar do comportamento MTF nativo do Pine, migre para MT5 (`EixoWIN.mq5`) que usa `iCustom(_Symbol, PERIOD_H1, ...)` para timeframes reais.
