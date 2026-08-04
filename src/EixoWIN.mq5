//+------------------------------------------------------------------+
//|                                                    EixoWIN.mq5   |
//|                  Eixo Estrategico - WIN Day Trade EA (port Pine) |
//+------------------------------------------------------------------+
//| Portado de strategy.pine (Pine Script v5) para MQL5.             |
//| Multi-timeframe 100% nativo via iADX/iStochastic com PERIOD_*.   |
//| Aplicar no grafico M1 do WIN (mini indice) - qualquer contrato.  |
//+------------------------------------------------------------------+
#property copyright "Eixo Estrategico"
#property link      "https://github.com/geovime1977/pinescript-win-eixo"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>

//=================== INPUTS =========================================
input group "== Toques e Fibonacci =="
input double InpTolPct        = 0.05;   // Tolerancia de toque (%)
input int    InpGapBars       = 3;      // Gap minimo entre eventos (M1)
input int    InpResetGap      = 15;     // Reset contador apos N candles sem tocar
input int    InpMaxGapTouches = 10;     // Max candles entre 1o e 2o toque
input int    InpWaitAfterTouch= 1;      // Janela pos-2o toque

input group "== Confirmacoes e Filtros =="
input int    InpMinExtras     = 1;      // Confirmacoes minimas (Estoc/TRIX)
input double InpAdxMin        = 25.0;   // ADX minimo pra congruencia HTF
input bool   InpAntiFaca      = true;   // Bloqueia contra tendencia 3/3

input group "== Indicadores =="
input int    InpAdxLen        = 8;      // Comprimento ADX/DMI (todos TFs)
input int    InpStochK        = 5;      // Estocastico K
input int    InpStochD        = 3;      // Estocastico D (sma)
input int    InpTrixLen       = 9;      // TRIX comprimento
input int    InpTrixMALen     = 4;      // TRIX MA sinal

input group "== Sizing e Risco =="
input int    InpQtyBase       = 5;      // Contratos por TF confirmado
input int    InpQtyCap        = 20;     // Cap total
input double InpStopFibPct    = 0.5;    // Stop = pct * amplitude Fibo

input group "== Sessao =="
input int    InpSessionEndHour= 17;     // Hora limite pra abrir
input int    InpSessionEndMin = 30;
input int    InpEodHour       = 17;     // Hora fechamento forcado
input int    InpEodMin        = 55;

input group "== Ordem =="
input ulong  InpMagic         = 20260804;
input ulong  InpSlippagePts   = 5;      // Slippage em pontos

input group "== MACD Monitor H1 =="
input bool   InpMacdMonitor   = true;   // Monitorar cruzamentos MACD H1
input int    InpMacdFast      = 12;     // MACD EMA rapida (default)
input int    InpMacdSlow      = 26;     // MACD EMA lenta (default)
input int    InpMacdSignal    = 9;      // MACD sinal SMA (default)
input bool   InpMacdAlertPopup= true;   // Alert popup + som ao cruzar
input bool   InpMacdAlertPush = false;  // Notification push (celular MT5)

//=================== HANDLES ========================================
int hStochM1 = INVALID_HANDLE;
int hAdxM5   = INVALID_HANDLE;
int hAdxM15  = INVALID_HANDLE;
int hAdxM30  = INVALID_HANDLE;
int hAdxH1   = INVALID_HANDLE;

// Estocastico HTF pra score anti-faca
int hStochM15= INVALID_HANDLE;
int hStochM30= INVALID_HANDLE;
int hStochH1 = INVALID_HANDLE;

// MACD H1 (monitor)
int      hMacdH1 = INVALID_HANDLE;
datetime g_lastMacdH1BarTime = 0;
double   g_prevMacdMain = 0, g_prevMacdSignal = 0;
bool     g_macdInit = false;

//=================== ESTADO GLOBAL ==================================
CTrade trade;

datetime g_lastBarTime = 0;
datetime g_currentDay  = 0;

// Fibo do 1o candle M5 do dia
double g_first5High = 0, g_first5Low = 0, g_fibRange = 0;
bool   g_hasBase = false;

// Niveis (ordenados: upper 0..450, mid, lower 0..450) => 21 niveis
#define N_LEVELS 21
double g_levels[N_LEVELS];
// indices:
#define I_U0    0
#define I_U50   1
#define I_U100  2
#define I_U150  3
#define I_U200  4
#define I_U250  5
#define I_U300  6
#define I_U350  7
#define I_U400  8
#define I_U450  9
#define I_UMID  10
#define I_L0    11
#define I_L50   12
#define I_L100  13
#define I_L150  14
#define I_L200  15
#define I_L250  16
#define I_L300  17
#define I_L350  18
#define I_L400  19
#define I_L450  20

int    g_events[N_LEVELS];   // contador de toques (=1 primeiro, =2 segundo)
int    g_barsSince[N_LEVELS]; // -1 = nunca tocou

// Gatilho
int g_buyFirstAgo   = 999999;
int g_buySecondAgo  = 999999;
int g_sellFirstAgo  = 999999;
int g_sellSecondAgo = 999999;

// Rolling EMAs pra TRIX M1 e M5 (mantidos manualmente entre barras)
double g_ema1_M1 = 0, g_ema2_M1 = 0, g_ema3_M1 = 0, g_trix_M1 = 0;
double g_trixMABuf_M1[]; // ultimos N valores pra SMA
double g_prevTrix_M1 = 0, g_prevTrixMA_M1 = 0;
bool   g_trix1mCrossUp = false, g_trix1mCrossDn = false;
int    g_trixBarsUp_M1 = 999999, g_trixBarsDn_M1 = 999999;

double g_ema1_M5 = 0, g_ema2_M5 = 0, g_ema3_M5 = 0, g_trix_M5 = 0;
double g_trixMABuf_M5[];
double g_prevTrix_M5 = 0, g_prevTrixMA_M5 = 0;
int    g_trixBarsUp_M5 = 999999, g_trixBarsDn_M5 = 999999;
datetime g_lastM5BarTime = 0;

// Stoch M1 barssince
int g_stochBarsUp_M1 = 999999, g_stochBarsDn_M1 = 999999;
double g_prevStochK_M1 = 0, g_prevStochD_M1 = 0;

// Saida em 2 fases
int  g_longTrixDnCount  = 0;
int  g_shortTrixUpCount = 0;
bool g_longExitArmed    = false;
bool g_shortExitArmed   = false;

//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(InpSlippagePts);
   trade.SetTypeFillingBySymbol(_Symbol);

   hStochM1 = iStochastic(_Symbol, PERIOD_M1, InpStochK, InpStochD, 3, MODE_SMA, STO_LOWHIGH);
   hAdxM5   = iADX(_Symbol, PERIOD_M5,  InpAdxLen);
   hAdxM15  = iADX(_Symbol, PERIOD_M15, InpAdxLen);
   hAdxM30  = iADX(_Symbol, PERIOD_M30, InpAdxLen);
   hAdxH1   = iADX(_Symbol, PERIOD_H1,  InpAdxLen);

   hStochM15 = iStochastic(_Symbol, PERIOD_M15, InpStochK, InpStochD, 3, MODE_SMA, STO_LOWHIGH);
   hStochM30 = iStochastic(_Symbol, PERIOD_M30, InpStochK, InpStochD, 3, MODE_SMA, STO_LOWHIGH);
   hStochH1  = iStochastic(_Symbol, PERIOD_H1,  InpStochK, InpStochD, 3, MODE_SMA, STO_LOWHIGH);

   // MACD H1 (default 12/26/9 sobre PRICE_CLOSE)
   hMacdH1 = iMACD(_Symbol, PERIOD_H1, InpMacdFast, InpMacdSlow, InpMacdSignal, PRICE_CLOSE);

   if(hStochM1==INVALID_HANDLE || hAdxM5==INVALID_HANDLE || hAdxM15==INVALID_HANDLE ||
      hAdxM30==INVALID_HANDLE  || hAdxH1==INVALID_HANDLE ||
      hStochM15==INVALID_HANDLE|| hStochM30==INVALID_HANDLE || hStochH1==INVALID_HANDLE ||
      hMacdH1==INVALID_HANDLE)
   {
      Print("Falha ao criar handles de indicador");
      return INIT_FAILED;
   }

   ArrayResize(g_trixMABuf_M1, InpTrixMALen);
   ArrayResize(g_trixMABuf_M5, InpTrixMALen);
   ArrayInitialize(g_trixMABuf_M1, 0);
   ArrayInitialize(g_trixMABuf_M5, 0);

   ResetDayState();
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(hStochM1);
   IndicatorRelease(hAdxM5);
   IndicatorRelease(hAdxM15);
   IndicatorRelease(hAdxM30);
   IndicatorRelease(hAdxH1);
   IndicatorRelease(hStochM15);
   IndicatorRelease(hStochM30);
   IndicatorRelease(hStochH1);
   IndicatorRelease(hMacdH1);
}

//+------------------------------------------------------------------+
// Monitor MACD H1: dispara Alert + Print no cruzamento (main x signal)
// Executa uma vez por barra H1 confirmada (nao repete no mesmo candle).
//+------------------------------------------------------------------+
void CheckMacdH1Cross()
{
   if(!InpMacdMonitor) return;

   datetime h1Time = iTime(_Symbol, PERIOD_H1, 1);
   if(h1Time == g_lastMacdH1BarTime) return; // ja processada
   g_lastMacdH1BarTime = h1Time;

   double mainBuf[1], sigBuf[1];
   if(CopyBuffer(hMacdH1, 0, 1, 1, mainBuf) != 1) return; // MAIN
   if(CopyBuffer(hMacdH1, 1, 1, 1, sigBuf)  != 1) return; // SIGNAL

   double macdMain   = mainBuf[0];
   double macdSignal = sigBuf[0];

   if(!g_macdInit)
   {
      g_prevMacdMain   = macdMain;
      g_prevMacdSignal = macdSignal;
      g_macdInit = true;
      return;
   }

   bool crossUp = (g_prevMacdMain <= g_prevMacdSignal) && (macdMain > macdSignal);
   bool crossDn = (g_prevMacdMain >= g_prevMacdSignal) && (macdMain < macdSignal);

   if(crossUp)
   {
      string msg = StringFormat("[MACD H1] %s CRUZAMENTO COMPRA - main=%.2f signal=%.2f (barra %s)",
                                _Symbol, macdMain, macdSignal, TimeToString(h1Time, TIME_DATE|TIME_MINUTES));
      Print(msg);
      if(InpMacdAlertPopup) Alert(msg);
      if(InpMacdAlertPush)  SendNotification(msg);
   }
   else if(crossDn)
   {
      string msg = StringFormat("[MACD H1] %s CRUZAMENTO VENDA - main=%.2f signal=%.2f (barra %s)",
                                _Symbol, macdMain, macdSignal, TimeToString(h1Time, TIME_DATE|TIME_MINUTES));
      Print(msg);
      if(InpMacdAlertPopup) Alert(msg);
      if(InpMacdAlertPush)  SendNotification(msg);
   }

   g_prevMacdMain   = macdMain;
   g_prevMacdSignal = macdSignal;
}

//+------------------------------------------------------------------+
void ResetDayState()
{
   g_first5High = 0;
   g_first5Low  = 0;
   g_fibRange   = 0;
   g_hasBase    = false;
   for(int i=0; i<N_LEVELS; i++) { g_events[i]=0; g_barsSince[i]=-1; }
   g_buyFirstAgo   = 999999;
   g_buySecondAgo  = 999999;
   g_sellFirstAgo  = 999999;
   g_sellSecondAgo = 999999;
   g_longTrixDnCount  = 0;
   g_shortTrixUpCount = 0;
   g_longExitArmed    = false;
   g_shortExitArmed   = false;
}

//+------------------------------------------------------------------+
bool IsNewBarM1()
{
   datetime t = iTime(_Symbol, PERIOD_M1, 0);
   if(t != g_lastBarTime) { g_lastBarTime = t; return true; }
   return false;
}

bool IsNewDay(datetime t)
{
   MqlDateTime mt;
   TimeToStruct(t, mt);
   MqlDateTime prev;
   TimeToStruct(g_currentDay, prev);
   if(mt.year != prev.year || mt.mon != prev.mon || mt.day != prev.day)
   {
      g_currentDay = t;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
void ComputeFibonacci()
{
   double u = g_first5High;
   double l = g_first5Low;
   double r = g_fibRange;
   g_levels[I_U0]   = u + 0.00 * r;
   g_levels[I_U50]  = u + 0.50 * r;
   g_levels[I_U100] = u + 1.00 * r;
   g_levels[I_U150] = u + 1.50 * r;
   g_levels[I_U200] = u + 2.00 * r;
   g_levels[I_U250] = u + 2.50 * r;
   g_levels[I_U300] = u + 3.00 * r;
   g_levels[I_U350] = u + 3.50 * r;
   g_levels[I_U400] = u + 4.00 * r;
   g_levels[I_U450] = u + 4.50 * r;
   g_levels[I_UMID] = (u + l) / 2.0;
   g_levels[I_L0]   = l - 0.00 * r;
   g_levels[I_L50]  = l - 0.50 * r;
   g_levels[I_L100] = l - 1.00 * r;
   g_levels[I_L150] = l - 1.50 * r;
   g_levels[I_L200] = l - 2.00 * r;
   g_levels[I_L250] = l - 2.50 * r;
   g_levels[I_L300] = l - 3.00 * r;
   g_levels[I_L350] = l - 3.50 * r;
   g_levels[I_L400] = l - 4.00 * r;
   g_levels[I_L450] = l - 4.50 * r;
}

//+------------------------------------------------------------------+
// Retorna high/low do 1o candle M5 do dia (usa a barra M5 confirmada
// que engloba as primeiras N ticks do prego). Se ainda nao existe, retorna false.
bool GetFirst5MinBarOfDay(datetime dayStart, double &hi, double &lo)
{
   // Procura o primeiro candle M5 do dia atual (chave: sessao 9:00)
   int shift = 1;
   for(int i=0; i<500; i++)
   {
      datetime bt = iTime(_Symbol, PERIOD_M5, i);
      if(bt == 0) break;
      MqlDateTime mt;
      TimeToStruct(bt, mt);
      if(mt.year==TimeYear(dayStart) && mt.mon==TimeMonth(dayStart) && mt.day==TimeDay(dayStart))
      {
         shift = i; // continua buscando ate achar o mais antigo do dia
      }
      else break;
   }
   if(shift <= 0) return false;
   hi = iHigh(_Symbol, PERIOD_M5, shift);
   lo = iLow(_Symbol, PERIOD_M5, shift);
   return (hi > 0 && lo > 0 && hi > lo);
}

// Helpers de data (MQL5 nao tem TimeYear/TimeMonth/TimeDay padrao — usar struct)
int TimeYear(datetime t)  { MqlDateTime m; TimeToStruct(t, m); return m.year; }
int TimeMonth(datetime t) { MqlDateTime m; TimeToStruct(t, m); return m.mon;  }
int TimeDay(datetime t)   { MqlDateTime m; TimeToStruct(t, m); return m.day;  }
int TimeHour(datetime t)  { MqlDateTime m; TimeToStruct(t, m); return m.hour; }
int TimeMinute(datetime t){ MqlDateTime m; TimeToStruct(t, m); return m.min;  }

//+------------------------------------------------------------------+
void UpdateLevelTouch(int idx, double price, double barHigh, double barLow)
{
   double tol = price * InpTolPct / 100.0;
   bool touching = ((barLow - tol) <= price) && (price <= (barHigh + tol));
   if(touching)
   {
      if(g_barsSince[idx] < 0 || g_barsSince[idx] > InpGapBars)
         g_events[idx]++;
      g_barsSince[idx] = 0;
   }
   else if(g_barsSince[idx] >= 0)
   {
      g_barsSince[idx]++;
      if(g_barsSince[idx] > InpResetGap)
      {
         g_events[idx]  = 0;
         g_barsSince[idx] = -1;
      }
   }
}

//+------------------------------------------------------------------+
// TRIX: EMA(EMA(EMA(close, len), len), len), depois ROC 1 barra
void UpdateTrixM1(double closeM1)
{
   double k = 2.0 / (InpTrixLen + 1.0);
   if(g_ema1_M1 == 0) { g_ema1_M1 = closeM1; g_ema2_M1 = closeM1; g_ema3_M1 = closeM1; }
   g_ema1_M1 = k * closeM1     + (1-k) * g_ema1_M1;
   g_ema2_M1 = k * g_ema1_M1   + (1-k) * g_ema2_M1;
   double prevE3 = g_ema3_M1;
   g_ema3_M1 = k * g_ema2_M1   + (1-k) * g_ema3_M1;
   if(prevE3 > 0)
      g_trix_M1 = (g_ema3_M1 - prevE3) / prevE3 * 100.0;

   // SMA do TRIX (sinal)
   for(int i=InpTrixMALen-1; i>0; i--) g_trixMABuf_M1[i] = g_trixMABuf_M1[i-1];
   g_trixMABuf_M1[0] = g_trix_M1;
   double sum = 0;
   for(int i=0; i<InpTrixMALen; i++) sum += g_trixMABuf_M1[i];
   double trixMA = sum / InpTrixMALen;

   g_trix1mCrossUp = (g_prevTrix_M1 <= g_prevTrixMA_M1) && (g_trix_M1 > trixMA);
   g_trix1mCrossDn = (g_prevTrix_M1 >= g_prevTrixMA_M1) && (g_trix_M1 < trixMA);

   if(g_trix1mCrossUp) g_trixBarsUp_M1 = 0; else g_trixBarsUp_M1++;
   if(g_trix1mCrossDn) g_trixBarsDn_M1 = 0; else g_trixBarsDn_M1++;

   g_prevTrix_M1   = g_trix_M1;
   g_prevTrixMA_M1 = trixMA;
}

void UpdateTrixM5(double closeM5)
{
   double k = 2.0 / (InpTrixLen + 1.0);
   if(g_ema1_M5 == 0) { g_ema1_M5 = closeM5; g_ema2_M5 = closeM5; g_ema3_M5 = closeM5; }
   g_ema1_M5 = k * closeM5     + (1-k) * g_ema1_M5;
   g_ema2_M5 = k * g_ema1_M5   + (1-k) * g_ema2_M5;
   double prevE3 = g_ema3_M5;
   g_ema3_M5 = k * g_ema2_M5   + (1-k) * g_ema3_M5;
   if(prevE3 > 0)
      g_trix_M5 = (g_ema3_M5 - prevE3) / prevE3 * 100.0;

   for(int i=InpTrixMALen-1; i>0; i--) g_trixMABuf_M5[i] = g_trixMABuf_M5[i-1];
   g_trixMABuf_M5[0] = g_trix_M5;
   double sum = 0;
   for(int i=0; i<InpTrixMALen; i++) sum += g_trixMABuf_M5[i];
   double trixMA = sum / InpTrixMALen;

   bool crossUp = (g_prevTrix_M5 <= g_prevTrixMA_M5) && (g_trix_M5 > trixMA);
   bool crossDn = (g_prevTrix_M5 >= g_prevTrixMA_M5) && (g_trix_M5 < trixMA);
   if(crossUp) g_trixBarsUp_M5 = 0; else g_trixBarsUp_M5++;
   if(crossDn) g_trixBarsDn_M5 = 0; else g_trixBarsDn_M5++;

   g_prevTrix_M5   = g_trix_M5;
   g_prevTrixMA_M5 = trixMA;
}

//+------------------------------------------------------------------+
bool ReadADX(int handle, double &adxVal, double &dip, double &dim)
{
   double b0[1], b1[1], b2[1];
   if(CopyBuffer(handle, 0, 1, 1, b0) != 1) return false; // ADX
   if(CopyBuffer(handle, 1, 1, 1, b1) != 1) return false; // +DI
   if(CopyBuffer(handle, 2, 1, 1, b2) != 1) return false; // -DI
   adxVal = b0[0]; dip = b1[0]; dim = b2[0];
   return true;
}

bool ReadStoch(int handle, double &k, double &d)
{
   double b0[1], b1[1];
   if(CopyBuffer(handle, 0, 1, 1, b0) != 1) return false;
   if(CopyBuffer(handle, 1, 1, 1, b1) != 1) return false;
   k = b0[0]; d = b1[0];
   return true;
}

//+------------------------------------------------------------------+
// Score direcional HTF (Stoch + TRIX + DMI). TRIX HTF aproximado pelo
// TRIX M5 (mesmo pra M15/M30/H1 pois nao mantemos EMA chain em cada TF).
int HtfDirectionScore(int stochHandle, int adxHandle, bool isBuy)
{
   double k, d, adxV, dip, dim;
   if(!ReadStoch(stochHandle, k, d)) return 0;
   if(!ReadADX(adxHandle, adxV, dip, dim)) return 0;
   int score = 0;
   if(isBuy) {
      if(k > d)   score++;
      if(g_trix_M5 > g_prevTrixMA_M5) score++;
      if(dip > dim) score++;
   } else {
      if(k < d)   score++;
      if(g_trix_M5 < g_prevTrixMA_M5) score++;
      if(dim > dip) score++;
   }
   return score;
}

//+------------------------------------------------------------------+
double GetPositionVolume()
{
   if(!PositionSelect(_Symbol)) return 0;
   double vol = PositionGetDouble(POSITION_VOLUME);
   long type  = PositionGetInteger(POSITION_TYPE);
   return (type == POSITION_TYPE_BUY) ? vol : -vol;
}

//+------------------------------------------------------------------+
void PlaceScaleOutLong(double totalQty, double stopPrice)
{
   if(!trade.Buy(totalQty, _Symbol, 0, stopPrice)) {
      Print("Falha buy: ", trade.ResultRetcode());
      return;
   }
   // Alvos scale-out em 10 niveis fibo superiores
   double perTgt = MathFloor(totalQty / 10.0);
   if(perTgt < 1) perTgt = 1;
   double remainder = totalQty - perTgt * 9;
   double tgts[10] = { g_levels[I_U0], g_levels[I_U50], g_levels[I_U100], g_levels[I_U150], g_levels[I_U200],
                       g_levels[I_U250], g_levels[I_U300], g_levels[I_U350], g_levels[I_U400], g_levels[I_U450] };
   for(int i=0; i<10; i++)
   {
      double qty = (i==9) ? remainder : perTgt;
      if(qty <= 0) continue;
      // TP como ordem pendente sell limit acima
      trade.SellLimit(qty, tgts[i], _Symbol, stopPrice, 0, ORDER_TIME_DAY);
   }
}

void PlaceScaleOutShort(double totalQty, double stopPrice)
{
   if(!trade.Sell(totalQty, _Symbol, 0, stopPrice)) {
      Print("Falha sell: ", trade.ResultRetcode());
      return;
   }
   double perTgt = MathFloor(totalQty / 10.0);
   if(perTgt < 1) perTgt = 1;
   double remainder = totalQty - perTgt * 9;
   double tgts[10] = { g_levels[I_L0], g_levels[I_L50], g_levels[I_L100], g_levels[I_L150], g_levels[I_L200],
                       g_levels[I_L250], g_levels[I_L300], g_levels[I_L350], g_levels[I_L400], g_levels[I_L450] };
   for(int i=0; i<10; i++)
   {
      double qty = (i==9) ? remainder : perTgt;
      if(qty <= 0) continue;
      trade.BuyLimit(qty, tgts[i], _Symbol, stopPrice, 0, ORDER_TIME_DAY);
   }
}

void CloseAll(const string comment)
{
   if(PositionSelect(_Symbol))
   {
      trade.PositionClose(_Symbol);
      // Cancela ordens pendentes desse simbolo
      for(int i=OrdersTotal()-1; i>=0; i--)
      {
         ulong ticket = OrderGetTicket(i);
         if(OrderSelect(ticket))
            if(OrderGetString(ORDER_SYMBOL) == _Symbol)
               trade.OrderDelete(ticket);
      }
   }
}

//+------------------------------------------------------------------+
void OnTick()
{
   if(!IsNewBarM1()) return;

   // Monitor MACD H1 (independe do resto da logica de trade)
   CheckMacdH1Cross();

   datetime barTime = iTime(_Symbol, PERIOD_M1, 1); // barra fechada
   double closeM1 = iClose(_Symbol, PERIOD_M1, 1);
   double highM1  = iHigh(_Symbol,  PERIOD_M1, 1);
   double lowM1   = iLow(_Symbol,   PERIOD_M1, 1);

   //---- Novo dia
   if(IsNewDay(barTime))
      ResetDayState();

   //---- Captura Fibo do 1o candle M5 do dia (se ainda nao capturado)
   if(!g_hasBase)
   {
      double hi, lo;
      if(GetFirst5MinBarOfDay(barTime, hi, lo))
      {
         g_first5High = hi;
         g_first5Low  = lo;
         g_fibRange   = hi - lo;
         g_hasBase    = (g_fibRange > 0);
         if(g_hasBase) ComputeFibonacci();
      }
   }

   //---- Atualiza TRIX M1 sempre (usa close M1)
   UpdateTrixM1(closeM1);

   //---- Atualiza TRIX M5 quando ha nova barra M5 fechada
   datetime m5Time = iTime(_Symbol, PERIOD_M5, 1);
   if(m5Time != g_lastM5BarTime)
   {
      g_lastM5BarTime = m5Time;
      double closeM5 = iClose(_Symbol, PERIOD_M5, 1);
      UpdateTrixM5(closeM5);
   }

   //---- Estoc M1: le do handle
   double stochK, stochD;
   if(!ReadStoch(hStochM1, stochK, stochD)) return;
   bool stochUp = (g_prevStochK_M1 <= g_prevStochD_M1) && (stochK > stochD);
   bool stochDn = (g_prevStochK_M1 >= g_prevStochD_M1) && (stochK < stochD);
   if(stochUp) g_stochBarsUp_M1 = 0; else g_stochBarsUp_M1++;
   if(stochDn) g_stochBarsDn_M1 = 0; else g_stochBarsDn_M1++;
   g_prevStochK_M1 = stochK;
   g_prevStochD_M1 = stochD;

   //---- ADX/DMI multi-TF (nativo)
   double adx5, dp5, dn5, adx15, dp15, dn15, adx30, dp30, dn30, adx60, dp60, dn60;
   if(!ReadADX(hAdxM5,  adx5,  dp5,  dn5))  return;
   if(!ReadADX(hAdxM15, adx15, dp15, dn15)) return;
   if(!ReadADX(hAdxM30, adx30, dp30, dn30)) return;
   if(!ReadADX(hAdxH1,  adx60, dp60, dn60)) return;

   //---- Se sem Fibo ainda, sai
   if(!g_hasBase) return;

   //---- Atualiza toques em todos os 21 niveis
   for(int i=0; i<N_LEVELS; i++)
      UpdateLevelTouch(i, g_levels[i], highM1, lowM1);

   //---- Detecta 1o e 2o toque em suporte (BUY) e resistencia (SELL)
   // MID conta pra ambos os lados
   bool firstLower = false, firstUpper = false;
   bool secondLower = false, secondUpper = false;

   for(int i=0; i<N_LEVELS; i++)
   {
      if(g_events[i] == 1 && g_barsSince[i] == 0)
      {
         if(i == I_UMID) { firstLower = true; firstUpper = true; }
         else if(i >= I_L0 && i <= I_L450) firstLower = true;
         else if(i >= I_U0 && i <= I_U450) firstUpper = true;
      }
      if(g_events[i] == 2 && g_barsSince[i] == 0)
      {
         if(i == I_UMID) { secondLower = true; secondUpper = true; }
         else if(i >= I_L0 && i <= I_L450) secondLower = true;
         else if(i >= I_U0 && i <= I_U450) secondUpper = true;
      }
   }

   g_buyFirstAgo   += 1;
   g_buySecondAgo  += 1;
   g_sellFirstAgo  += 1;
   g_sellSecondAgo += 1;

   if(firstLower && g_buyFirstAgo > InpMaxGapTouches)  { g_buyFirstAgo  = 0; g_buySecondAgo  = 999999; }
   if(firstUpper && g_sellFirstAgo > InpMaxGapTouches) { g_sellFirstAgo = 0; g_sellSecondAgo = 999999; }
   if(secondLower && g_buyFirstAgo <= InpMaxGapTouches && g_buySecondAgo > InpWaitAfterTouch)
      g_buySecondAgo = 0;
   if(secondUpper && g_sellFirstAgo <= InpMaxGapTouches && g_sellSecondAgo > InpWaitAfterTouch)
      g_sellSecondAgo = 0;

   bool buyTouchOpen  = (g_buySecondAgo  <= InpWaitAfterTouch);
   bool sellTouchOpen = (g_sellSecondAgo <= InpWaitAfterTouch);

   bool buyStochValid  = buyTouchOpen  && (g_stochBarsUp_M1 < g_buyFirstAgo);
   bool buyTrixValid   = buyTouchOpen  && (g_trixBarsUp_M5  < g_buyFirstAgo);
   bool sellStochValid = sellTouchOpen && (g_stochBarsDn_M1 < g_sellFirstAgo);
   bool sellTrixValid  = sellTouchOpen && (g_trixBarsDn_M5  < g_sellFirstAgo);

   int buyExtras  = (buyStochValid ? 1:0) + (buyTrixValid ? 1:0);
   int sellExtras = (sellStochValid? 1:0) + (sellTrixValid? 1:0);

   //---- Congruencia MTF (ADX + direcao DMI)
   bool cong5Buy   = (adx5  > InpAdxMin) && (dp5  > dn5);
   bool cong15Buy  = (adx15 > InpAdxMin) && (dp15 > dn15);
   bool cong30Buy  = (adx30 > InpAdxMin) && (dp30 > dn30);
   bool cong60Buy  = (adx60 > InpAdxMin) && (dp60 > dn60);
   bool cong5Sell  = (adx5  > InpAdxMin) && (dn5  > dp5);
   bool cong15Sell = (adx15 > InpAdxMin) && (dn15 > dp15);
   bool cong30Sell = (adx30 > InpAdxMin) && (dn30 > dp30);
   bool cong60Sell = (adx60 > InpAdxMin) && (dn60 > dp60);

   int cong44BuyScore  = (cong5Buy?1:0)+(cong15Buy?1:0)+(cong30Buy?1:0)+(cong60Buy?1:0);
   int cong44SellScore = (cong5Sell?1:0)+(cong15Sell?1:0)+(cong30Sell?1:0)+(cong60Sell?1:0);

   //---- Anti-faca (score 3/3 na direcao oposta em algum HTF bloqueia)
   int s15Buy  = HtfDirectionScore(hStochM15, hAdxM15, true);
   int s15Sell = HtfDirectionScore(hStochM15, hAdxM15, false);
   int s30Buy  = HtfDirectionScore(hStochM30, hAdxM30, true);
   int s30Sell = HtfDirectionScore(hStochM30, hAdxM30, false);
   int s60Buy  = HtfDirectionScore(hStochH1,  hAdxH1,  true);
   int s60Sell = HtfDirectionScore(hStochH1,  hAdxH1,  false);

   bool antiFacaBuyOk  = !InpAntiFaca || (s15Sell < 3 && s30Sell < 3 && s60Sell < 3);
   bool antiFacaSellOk = !InpAntiFaca || (s15Buy  < 3 && s30Buy  < 3 && s60Buy  < 3);

   bool buySignal  = buyTouchOpen  && (buyExtras  >= InpMinExtras) && antiFacaBuyOk;
   bool sellSignal = sellTouchOpen && (sellExtras >= InpMinExtras) && antiFacaSellOk;

   //---- Janela de sessao
   int h = TimeHour(barTime);
   int m = TimeMinute(barTime);
   bool inEntryWindow = (h < InpSessionEndHour) || (h == InpSessionEndHour && m < InpSessionEndMin);
   bool inEodWindow   = (h > InpEodHour)        || (h == InpEodHour && m >= InpEodMin);

   //---- EOD forcado
   if(inEodWindow && PositionSelect(_Symbol))
   {
      CloseAll("EOD");
      return;
   }

   //---- Saida antecipada 2 fases
   double posVol = GetPositionVolume();
   if(posVol == 0)
   {
      g_longTrixDnCount  = 0;
      g_shortTrixUpCount = 0;
      g_longExitArmed    = false;
      g_shortExitArmed   = false;
   }
   if(posVol > 0 && g_trix1mCrossDn) g_longTrixDnCount++;
   if(posVol < 0 && g_trix1mCrossUp) g_shortTrixUpCount++;
   if(posVol > 0 && g_longTrixDnCount  >= 2) g_longExitArmed  = true;
   if(posVol < 0 && g_shortTrixUpCount >= 2) g_shortExitArmed = true;

   bool anyFiboTouch = false;
   for(int i=0; i<N_LEVELS; i++)
   {
      if(g_barsSince[i] == 0) { anyFiboTouch = true; break; }
   }
   if(g_longExitArmed  && anyFiboTouch) { CloseAll("2xTRIXdn+Fibo"); return; }
   if(g_shortExitArmed && anyFiboTouch) { CloseAll("2xTRIXup+Fibo"); return; }

   //---- Entradas
   if(posVol != 0 || !inEntryWindow) return;

   if(buySignal)
   {
      int qty = InpQtyBase * cong44BuyScore;
      if(qty < InpQtyBase) qty = InpQtyBase;
      if(qty > InpQtyCap)  qty = InpQtyCap;
      double stopPrice = iClose(_Symbol, PERIOD_M1, 0) - g_fibRange * InpStopFibPct;
      PlaceScaleOutLong((double)qty, stopPrice);
   }
   else if(sellSignal)
   {
      int qty = InpQtyBase * cong44SellScore;
      if(qty < InpQtyBase) qty = InpQtyBase;
      if(qty > InpQtyCap)  qty = InpQtyCap;
      double stopPrice = iClose(_Symbol, PERIOD_M1, 0) + g_fibRange * InpStopFibPct;
      PlaceScaleOutShort((double)qty, stopPrice);
   }
}
//+------------------------------------------------------------------+
