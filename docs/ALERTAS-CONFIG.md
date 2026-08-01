# Configuração de Alertas — 1 Alerta Free do TradingView

**Contexto:** TradingView plano gratuito tem **limite de 1 alerta ativo por conta**. O indicador foi desenhado pra caber nesse limite: **um único alerta dispara pra COMPRA ou VENDA 4/4**.

---

## Setup em 5 minutos

### 1. Aplicar o indicador
- Seguir `COMO-INSTALAR-BTG.md` primeiro
- Confirmar que `Eixo WIN — Sinais 4/4` está no gráfico

### 2. Criar o alerta
- [ ] Clicar com botão direito no gráfico OU clicar no ícone de **relógio 🕐 / Alertas** na barra direita
- [ ] Clicar em **"+ Criar Alerta"** (ou botão `+` na aba de alertas)

### 3. Configurar condição
- [ ] **Condição:** `Eixo WIN — Sinais 4/4`
- [ ] **Trigger:** escolher a opção **"Eixo WIN — Gatilho 4/4"** (é o `alertcondition` do código)
- [ ] **Opções:** `Once Per Bar Close` — dispara só quando o candle 1min fechar com 4/4 ativo

### 4. Configurar entrega
Escolher **pelo menos 2** canais pra redundância:

- [ ] **Notificação Mobile** (app TradingView instalado no celular)
- [ ] **E-mail** (envia pra o email do cadastro)
- [ ] **Notificação no app do navegador** (popup + som)
- [ ] **Webhook URL** (só Premium — pra automação)

### 5. Mensagem
Deixa o padrão que o Pine já gera:
```
{{ticker}} @ {{close}} | Setup 4/4 disparou | Cong buy={{plot("cong_buy_score")}} sell={{plot("cong_sell_score")}}
```

Se quiser customizar, use variáveis TradingView:
- `{{ticker}}` — símbolo (WINQ26)
- `{{close}}` — preço do candle que disparou
- `{{time}}` — horário
- `{{interval}}` — timeframe (1m)
- `{{exchange}}` — B3
- `{{plot("nome_do_plot")}}` — valores plotados invisíveis (buy_score, sell_score, cong_buy_score, cong_sell_score)

Mensagem enriquecida sugerida:
```
🎯 WIN 4/4 disparou às {{time}}
Preço: {{close}}
Buy score: {{plot("buy_score")}}/4 | Cong: {{plot("cong_buy_score")}}
Sell score: {{plot("sell_score")}}/4 | Cong: {{plot("cong_sell_score")}}
👉 Abrir home broker BTG
```

### 6. Expiração
- **Free:** alertas expiram em ~2 meses. Marca no calendário pra recriar.

### 7. Ativar
- [ ] Clicar **"Criar"** — alerta fica na lista de alertas ativos

---

## Instalar o app TradingView no celular

Pra receber push notification:

- [ ] iOS: https://apps.apple.com/br/app/tradingview/id1205990992
- [ ] Android: https://play.google.com/store/apps/details?id=com.tradingview.tradingviewapp

- [ ] Abrir o app
- [ ] Login com a mesma conta do TradingView.com
- [ ] Permitir notificações no sistema
- [ ] Configurações do app → **Notificações** → habilitar "Alertas"

Após isso, quando o alerta 4/4 disparar no gráfico, o celular vibra com o push.

---

## Se você contratar TradingView Premium depois

Vantagens dos planos pagos:
- **Essential (~US$ 14/mês):** 20 alertas ativos
- **Plus (~US$ 28/mês):** 100 alertas
- **Premium (~US$ 60/mês):** 400 alertas + webhooks

Com múltiplos alertas dá pra separar:
1. Alerta só de COMPRA 4/4
2. Alerta só de VENDA 4/4
3. Alerta quando 3/4 (proximidade)
4. Alerta quando congruência muda pra 4/4 (mesmo sem gatilho)
5. Alerta EOD (15 min antes de fechar posição)

E com **webhook**, dá pra apontar o alerta pra um endpoint HTTP seu — aí você pode:
- Registrar em planilha Google
- Mandar Telegram automático
- Disparar ordem via n8n → API da corretora
- Etc.

---

## Testando o alerta

Não dá pra forçar 4/4 no passado sem esperar, mas dá pra:

- [ ] Rodar backtest com `strategy.pine` — mostra todos os pontos que 4/4 disparou historicamente
- [ ] Escolher um dia com sinal (ex: 10/jul/26 que a estratégia validou) e conferir se aparece a seta verde no gráfico com o `indicator.pine`
- [ ] Aguardar 1-2 pregões operando pra ver o primeiro alerta ao vivo

Se não disparar em 3-5 pregões seguidos:
- Talvez os parâmetros estejam restritivos demais — abrir engrenagem do indicador e testar tolerância maior (0.1%) ou janela maior (5)
- Talvez o mercado esteja em regime lateral hostil (foi o que aconteceu em 2025 no backtest 60m)

---

**Regra de ouro:** o alerta é **aviso**, não é ordem. Você recebe o push, olha o gráfico, confirma o setup visual e decide se opera manualmente. Nunca automatiza execução sem meses de validação em conta demo.
