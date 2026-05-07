//+------------------------------------------------------------------+
//|          Deep Order Flow & CVD Analytics — v2.1                  |
//|          MERGED from: DeepChart_OrderFlow_V13 + DOF_CVD_v1.1     |
//|                                                                  |
//|  FIXED in v2.1:                                                  |
//|  ✅ SendNotification / Alert ทำงานครบทุก signal type            |
//|  ✅ InpNotifyTrap/Sweep/Reload/Fight/FVG ถูกใช้งานจริง         |
//|  ✅ InpUseNotification default เปลี่ยนเป็น false (ชัดเจน)      |
//|  ✅ Cooldown แยกต่างหากสำหรับแต่ละ signal type                 |
//|  ✅ Alert ไม่ส่งซ้ำบน bar เดียวกัน (by bar open time)          |
//|  ✅ FVG confluence alert เชื่อมต่อกับ notification จริง        |
//|  ✅ แก้ static lastT ให้ reset ได้ผ่าน g_LastAlertTime global  |
//+------------------------------------------------------------------+
#property copyright   "DeepChart AI + DOF Analytics"
#property version     "2.10"
#property indicator_chart_window
#property indicator_buffers 15
#property indicator_plots   11

//--- Plots
#property indicator_label1  "Bullish Abs"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrLime
#property indicator_width1  2

#property indicator_label2  "Bearish Abs"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrMagenta
#property indicator_width2  2

#property indicator_label3  "Big Buy"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrSpringGreen
#property indicator_width3  5

#property indicator_label4  "Big Sell"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrRed
#property indicator_width4  5

#property indicator_label5  "Sweep Buy"
#property indicator_type5   DRAW_ARROW
#property indicator_color5  clrDeepSkyBlue
#property indicator_width5  3

#property indicator_label6  "Sweep Sell"
#property indicator_type6   DRAW_ARROW
#property indicator_color6  clrOrange
#property indicator_width6  3

#property indicator_label7  "Reload Buy"
#property indicator_type7   DRAW_ARROW
#property indicator_color7  clrAqua
#property indicator_width7  2

#property indicator_label8  "Reload Sell"
#property indicator_type8   DRAW_ARROW
#property indicator_color8  clrHotPink
#property indicator_width8  2

#property indicator_label9  "Trap Buy"
#property indicator_type9   DRAW_ARROW
#property indicator_color9  clrLimeGreen
#property indicator_width9  1

#property indicator_label10 "Trap Sell"
#property indicator_type10  DRAW_ARROW
#property indicator_color10 clrOrangeRed
#property indicator_width10 1

#property indicator_label11 "Fight Warning"
#property indicator_type11  DRAW_ARROW
#property indicator_color11 clrYellow
#property indicator_width11 1

//============================================================
//  INPUT PARAMETERS
//============================================================
input group "=== 1. Alerts & Notifications ==="
input bool  InpUseNotification  = false;   // Push Notification (ต้องตั้งค่า MetaQuotes ID)
input bool  InpUseAlert         = false;   // Popup Alert
input bool  InpNotifyCombo      = true;    // [FIX] Strategy Combo signals
input bool  InpNotifyTrap       = true;    // [FIX] Trap signals (เชื่อมใช้งานแล้ว)
input bool  InpNotifySweep      = true;    // [FIX] Sweep signals (เชื่อมใช้งานแล้ว)
input bool  InpNotifyReload     = true;    // [FIX] Reload signals (เชื่อมใช้งานแล้ว)
input bool  InpNotifyFight      = true;    // [FIX] Fight signals (เชื่อมใช้งานแล้ว)
input bool  InpNotifyFVG_Setup  = true;    // FVG Confluence alert
input int   InpAlertCooldownBars = 3;      // [FIX] Cooldown bars ระหว่าง alert แต่ละ type

input group "=== 2. Dashboard Settings ==="
input bool  InpShowDashboard    = true;
input int   InpDashX            = 15;
input int   InpDashY            = 25;
input int   InpDashFontSize     = 9;
input color InpDashBgColor      = C'15,15,28';
input color InpDashBorderColor  = C'50,90,170';

input group "=== 3. Core Logic Settings ==="
input int    InpLookBackBars    = 500;
input double InpVolMultiplier   = 1.8;
input double InpBigTradeMult    = 3.0;
input bool   InpUseSweep        = true;
input int    InpSweepLookback   = 20;
input bool   InpUseReload       = true;
input int    InpTrendPeriod     = 50;
input bool   InpUseFight        = true;
input double InpFightVolMult    = 2.5;
input double InpFightBodyRatio  = 0.3;
input int    InpTrapLookback    = 5;

input group "=== 4. FVG Settings ==="
input bool   InpShowFVG         = true;
input int    InpFVGMinPoints    = 30;
input int    InpMaxFVGCount     = 8;
input bool   InpShowCELine      = true;
input bool   InpExtendFVG       = true;
input color  InpColorFreshBull  = C'20,100,40';
input color  InpColorFreshBear  = C'100,20,20';
input color  InpColorMitigated  = C'60,60,60';
input color  InpColorInversion  = clrOrange;

input group "=== 5. Volume Profile (Current TF) ==="
input bool   InpShowVP          = true;
input int    InpVPLookback      = 200;
input int    InpVPBins          = 40;
input double InpVPValueArea     = 0.70;

input group "=== 6. H1 Context Profile ==="
input bool   InpShowH1Profile   = false;
input int    InpH1Lookback      = 48;
input color  InpLVNColor        = clrOrangeRed;
input color  InpVAColor         = clrGray;

input group "=== 7. CVD & Divergence ==="
input int    InpCVDPeriod       = 14;
input bool   InpShowDivLines    = true;
input int    InpDivPeriod       = 20;

input group "=== 8. Strategy Matrix ==="
input bool   InpShowStratOnChart = true;
input int    InpComboLookback    = 8;
input int    InpSignalCooldownBars = 5;

input group "=== 9. Visual Labels ==="
input bool   InpShowLabel_Sweep  = false;
input bool   InpShowLabel_Reload = false;
input bool   InpShowLabel_Fight  = false;
input bool   InpShowLabel_Trap   = false;
input bool   InpShowVolText      = true;
input int    InpTextSize         = 9;
input color  InpBullColor        = clrLime;
input color  InpBearColor        = clrMagenta;

//============================================================
//  BUFFERS
//============================================================
double BufferBullAbs[];
double BufferBearAbs[];
double BufferBigBuy[];
double BufferBigSell[];
double BufferSweepBuy[];
double BufferSweepSell[];
double BufferReloadBuy[];
double BufferReloadSell[];
double BufferTrapBuy[];
double BufferTrapSell[];
double BufferFight[];
double BufferDelta[];
double BufferCVD[];
double BufferVol[];
double BufferMA[];

//============================================================
//  STRUCTS
//============================================================
struct SignalInfo
{
   string name; string icon; string desc; string action; string type; color cl;
};

//============================================================
//  GLOBALS
//============================================================
string DPFX        = "DOF_DASH_";
string PrefixFVG   = "DC_FVG_";
string PrefixAbsBox= "AbsBox_";
string PrefixAbsLine="AbsLine_";
string PrefixLVN   = "DC_LVN_";
string PrefixVA    = "DC_VA_";
string PrefixDiv   = "Div_";
string PrefixVolTxt= "VolTxt_";
string PrefixTrap  = "Trap_";
string PrefixSigTxt= "SigTxt_";
string PrefixStrat = "StratTxt_";
string PrefixVP    = "DOF_VP_";

int    handle_ma;
datetime LastBarTime = 0;

datetime g_LastSignalTime = 0;

datetime g_LastVPBarTime   = 0;
datetime g_LastFVGExtTime  = 0;

string   g_CurStatusName   = "Scanning...";
color    g_CurStatusColor  = (color)C'130,130,130';
string   g_CurStatusAction = "-";
string   g_CurStatusTime   = "-";
string   g_CurBarSignals   = "-";

// [FIX] Global cooldown trackers แยกต่างหากสำหรับแต่ละ signal type
// ใช้ global แทน static เพื่อให้ reset ได้ใน OnInit
datetime g_LastAlertTime_Combo  = 0;
datetime g_LastAlertTime_Sweep  = 0;
datetime g_LastAlertTime_Trap   = 0;
datetime g_LastAlertTime_Reload = 0;
datetime g_LastAlertTime_Fight  = 0;
datetime g_LastAlertTime_FVG    = 0;

double g_POC = 0, g_VAH = 0, g_VAL = 0;
double g_VPBinPrices[];
double g_VPBinVols[];

//============================================================
//  INIT
//============================================================
int OnInit()
{
   SetIndexBuffer(0,  BufferBullAbs,  INDICATOR_DATA);
   SetIndexBuffer(1,  BufferBearAbs,  INDICATOR_DATA);
   SetIndexBuffer(2,  BufferBigBuy,   INDICATOR_DATA);
   SetIndexBuffer(3,  BufferBigSell,  INDICATOR_DATA);
   SetIndexBuffer(4,  BufferSweepBuy, INDICATOR_DATA);
   SetIndexBuffer(5,  BufferSweepSell,INDICATOR_DATA);
   SetIndexBuffer(6,  BufferReloadBuy,INDICATOR_DATA);
   SetIndexBuffer(7,  BufferReloadSell,INDICATOR_DATA);
   SetIndexBuffer(8,  BufferTrapBuy,  INDICATOR_DATA);
   SetIndexBuffer(9,  BufferTrapSell, INDICATOR_DATA);
   SetIndexBuffer(10, BufferFight,    INDICATOR_DATA);
   SetIndexBuffer(11, BufferDelta,    INDICATOR_CALCULATIONS);
   SetIndexBuffer(12, BufferCVD,      INDICATOR_CALCULATIONS);
   SetIndexBuffer(13, BufferVol,      INDICATOR_CALCULATIONS);
   SetIndexBuffer(14, BufferMA,       INDICATOR_CALCULATIONS);

   for(int i = 0; i <= 10; i++)
      PlotIndexSetDouble(i, PLOT_EMPTY_VALUE, EMPTY_VALUE);

   PlotIndexSetInteger(0, PLOT_ARROW, 233);
   PlotIndexSetInteger(1, PLOT_ARROW, 234);
   PlotIndexSetInteger(2, PLOT_ARROW, 159);
   PlotIndexSetInteger(3, PLOT_ARROW, 159);
   PlotIndexSetInteger(4, PLOT_ARROW, 119);
   PlotIndexSetInteger(5, PLOT_ARROW, 119);
   PlotIndexSetInteger(6, PLOT_ARROW, 241);
   PlotIndexSetInteger(7, PLOT_ARROW, 242);
   PlotIndexSetInteger(8, PLOT_ARROW, 168);
   PlotIndexSetInteger(9, PLOT_ARROW, 168);
   PlotIndexSetInteger(10,PLOT_ARROW, 73);

   PlotIndexSetInteger(0, PLOT_ARROW_SHIFT,  8);
   PlotIndexSetInteger(1, PLOT_ARROW_SHIFT, -8);
   PlotIndexSetInteger(4, PLOT_ARROW_SHIFT,  10);
   PlotIndexSetInteger(5, PLOT_ARROW_SHIFT, -10);
   PlotIndexSetInteger(6, PLOT_ARROW_SHIFT,  12);
   PlotIndexSetInteger(7, PLOT_ARROW_SHIFT, -12);

   handle_ma = iMA(_Symbol, _Period, InpTrendPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(handle_ma == INVALID_HANDLE)
   {
      Print("[DOF v2.1] ERROR: iMA handle failed");
      return(INIT_FAILED);
   }

   IndicatorSetString(INDICATOR_SHORTNAME, "DOF & CVD v2.1");
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);

   ArrayResize(g_VPBinPrices, InpVPBins);
   ArrayResize(g_VPBinVols,   InpVPBins);

   // [FIX] Reset cooldown timers ทุกครั้งที่ init
   g_LastAlertTime_Combo  = 0;
   g_LastAlertTime_Sweep  = 0;
   g_LastAlertTime_Trap   = 0;
   g_LastAlertTime_Reload = 0;
   g_LastAlertTime_Fight  = 0;
   g_LastAlertTime_FVG    = 0;

   if(InpShowDashboard) BuildDashboard();

   Print("[DOF v2.1] Init OK | ", _Symbol, " | ", EnumToString(_Period));
   Print("[DOF v2.1] Notification=", InpUseNotification,
         " | Alert=", InpUseAlert,
         " | Combo=", InpNotifyCombo,
         " | Sweep=", InpNotifySweep,
         " | Trap=", InpNotifyTrap,
         " | Reload=", InpNotifyReload,
         " | Fight=", InpNotifyFight);
   return(INIT_SUCCEEDED);
}

//============================================================
//  DEINIT
//============================================================
void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, DPFX);
   ObjectsDeleteAll(0, PrefixFVG);
   ObjectsDeleteAll(0, PrefixAbsBox);
   ObjectsDeleteAll(0, PrefixAbsLine);
   ObjectsDeleteAll(0, PrefixLVN);
   ObjectsDeleteAll(0, PrefixVA);
   ObjectsDeleteAll(0, PrefixDiv);
   ObjectsDeleteAll(0, PrefixVolTxt);
   ObjectsDeleteAll(0, PrefixTrap);
   ObjectsDeleteAll(0, PrefixSigTxt);
   ObjectsDeleteAll(0, PrefixStrat);
   ObjectsDeleteAll(0, PrefixVP);
   if(handle_ma != INVALID_HANDLE) IndicatorRelease(handle_ma);
   ChartRedraw(0);
}

//============================================================
//  MAIN CALCULATE
//============================================================
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double   &open[],
                const double   &high[],
                const double   &low[],
                const double   &close[],
                const long     &tick_volume[],
                const long     &volume[],
                const int      &spread[])
{
   if(rates_total < 30) return(0);

   bool useReal = (volume[rates_total-1] > 0);

   if(CopyBuffer(handle_ma, 0, 0, rates_total, BufferMA) <= 0)
      return(0);

   int start = (prev_calculated == 0)
               ? MathMax(0, rates_total - InpLookBackBars)
               : prev_calculated - 1;

   if(prev_calculated == 0)
   {
      ObjectsDeleteAll(0, PrefixFVG);
      ObjectsDeleteAll(0, PrefixAbsBox);
      ObjectsDeleteAll(0, PrefixAbsLine);
      ObjectsDeleteAll(0, PrefixVolTxt);
      ObjectsDeleteAll(0, PrefixTrap);
      ObjectsDeleteAll(0, PrefixSigTxt);
      ObjectsDeleteAll(0, PrefixStrat);
      ObjectsDeleteAll(0, PrefixDiv);
      ObjectsDeleteAll(0, PrefixVP);
      g_LastSignalTime = 0;
      if(InpShowDashboard) BuildDashboard();
   }

   DashSet("Footprint", StringFormat("Calculating %d bars...", rates_total), InpNeutralColor());

   //----------------------------------------------------------
   // PHASE 1: Delta & CVD
   //----------------------------------------------------------
   for(int i = start; i < rates_total; i++)
   {
      long vol = useReal ? volume[i] : tick_volume[i];
      if(vol <= 0) vol = 1;

      double range = high[i] - low[i];
      double delta = (range > 0)
                     ? (double)vol * ((close[i] - low[i]) - (high[i] - close[i])) / range
                     : 0;

      BufferDelta[i] = delta;
      BufferVol[i]   = (double)vol;

      if(i == 0 || (i == start && prev_calculated == 0))
         BufferCVD[i] = delta;
      else
         BufferCVD[i] = BufferCVD[i-1] + delta;
   }

   DashSet("Footprint", StringFormat("OK (%d bars)", rates_total), clrLime);

   //----------------------------------------------------------
   // PHASE 2: Volume Profile
   //----------------------------------------------------------
   bool isNewBar = (time[rates_total-1] != g_LastVPBarTime);
   if(InpShowVP)
   {
      if(isNewBar || prev_calculated == 0)
      {
         DashSet("VolProfile", "Building...", InpNeutralColor());
         int vpStart = MathMax(0, rates_total - InpVPLookback - 1);
         CalcVolumeProfile(vpStart, rates_total - 1,
                           tick_volume, volume, high, low, useReal);
         DrawVolumeProfileBoxes(rates_total, time);
         g_LastVPBarTime = time[rates_total-1];
         DashSet("VolProfile", StringFormat("POC=%.2f", g_POC), clrLime);
      }
   }

   //----------------------------------------------------------
   // PHASE 3: Per-bar Detection Loop
   //----------------------------------------------------------
   DashSet("Signal", "Scanning...", InpNeutralColor());

   for(int i = start; i < rates_total; i++)
   {
      BufferBullAbs[i]   = EMPTY_VALUE;
      BufferBearAbs[i]   = EMPTY_VALUE;
      BufferBigBuy[i]    = EMPTY_VALUE;
      BufferBigSell[i]   = EMPTY_VALUE;
      BufferSweepBuy[i]  = EMPTY_VALUE;
      BufferSweepSell[i] = EMPTY_VALUE;
      BufferReloadBuy[i] = EMPTY_VALUE;
      BufferReloadSell[i]= EMPTY_VALUE;
      BufferTrapBuy[i]   = EMPTY_VALUE;
      BufferTrapSell[i]  = EMPTY_VALUE;
      BufferFight[i]     = EMPTY_VALUE;

      if(i < 22) continue;

      double avgVol = 0;
      for(int k = 1; k <= 20; k++)
         avgVol += BufferVol[i-k];
      avgVol /= 20.0;
      if(avgVol <= 0) avgVol = 1;

      double vol   = BufferVol[i];
      double delta = BufferDelta[i];
      double range = high[i] - low[i];
      double body  = MathAbs(close[i] - open[i]);

      // ── Absorption ─────────────────────────────────────────
      bool isHighVol = (vol > avgVol * InpVolMultiplier);
      double wickTop = high[i] - MathMax(open[i], close[i]);
      double wickBot = MathMin(open[i], close[i]) - low[i];

      if(isHighVol && delta > 0 && (close[i] < open[i] || (range > 0 && wickTop > range * 0.4)))
      {
         BufferBearAbs[i] = high[i] + _Point * 20;
         DrawAbsorption(high[i], high[i] - wickTop, InpBearColor, time[i], true);
      }
      if(isHighVol && delta < 0 && (close[i] > open[i] || (range > 0 && wickBot > range * 0.4)))
      {
         BufferBullAbs[i] = low[i] - _Point * 20;
         DrawAbsorption(low[i] + wickBot, low[i], InpBullColor, time[i], false);
      }

      // ── Big Trades ─────────────────────────────────────────
      if(vol > avgVol * InpBigTradeMult)
      {
         if(close[i] > open[i])
         {
            BufferBigBuy[i] = close[i];
            DrawBigTradeText(time[i], close[i], (long)vol, clrSpringGreen);
         }
         else
         {
            BufferBigSell[i] = close[i];
            DrawBigTradeText(time[i], close[i], (long)vol, clrRed);
         }
      }

      // ── Sweep Detection ────────────────────────────────────
      if(InpUseSweep && i > InpSweepLookback && range > 0)
      {
         double prevLow = low[i-1], prevHigh = high[i-1];
         for(int k = 2; k <= InpSweepLookback; k++)
         {
            if(low[i-k]  < prevLow)  prevLow  = low[i-k];
            if(high[i-k] > prevHigh) prevHigh = high[i-k];
         }
         if(low[i] < prevLow && close[i] > prevLow
            && (close[i] - low[i]) / range > 0.30 && close[i] > open[i])
         {
            BufferSweepBuy[i] = low[i] - _Point * 100;
            if(InpShowLabel_Sweep)
               DrawSignalText(time[i], BufferSweepBuy[i], "▲ SWEEP", clrDeepSkyBlue, false);
         }
         if(high[i] > prevHigh && close[i] < prevHigh
            && (high[i] - close[i]) / range > 0.30 && close[i] < open[i])
         {
            BufferSweepSell[i] = high[i] + _Point * 100;
            if(InpShowLabel_Sweep)
               DrawSignalText(time[i], BufferSweepSell[i], "▼ SWEEP", clrOrange, true);
         }
      }

      // ── Trap Detection ─────────────────────────────────────
      for(int k = 1; k <= InpTrapLookback && k <= i; k++)
      {
         if(BufferBigSell[i-k] != EMPTY_VALUE
            && BufferBullAbs[i] != EMPTY_VALUE
            && close[i] > BufferBigSell[i-k])
         {
            BufferTrapBuy[i] = low[i];
            DrawTrapSignal(time[i], low[i], true);
         }
         if(BufferBigBuy[i-k] != EMPTY_VALUE
            && BufferBearAbs[i] != EMPTY_VALUE
            && close[i] < BufferBigBuy[i-k])
         {
            BufferTrapSell[i] = high[i];
            DrawTrapSignal(time[i], high[i], false);
         }
      }

      // ── Reload ─────────────────────────────────────────────
      if(InpUseReload)
      {
         if(close[i] > BufferMA[i] && BufferBullAbs[i] != EMPTY_VALUE)
         {
            BufferReloadBuy[i] = low[i] - _Point * 150;
            if(InpShowLabel_Reload)
               DrawSignalText(time[i], BufferReloadBuy[i], "▲ RELOAD", clrAqua, false);
         }
         if(close[i] < BufferMA[i] && BufferBearAbs[i] != EMPTY_VALUE)
         {
            BufferReloadSell[i] = high[i] + _Point * 150;
            if(InpShowLabel_Reload)
               DrawSignalText(time[i], BufferReloadSell[i], "▼ RELOAD", clrHotPink, true);
         }
      }

      // ── Fight Warning ──────────────────────────────────────
      if(InpUseFight && range > 0 && vol > avgVol * InpFightVolMult)
      {
         if(body < range * InpFightBodyRatio)
         {
            BufferFight[i] = high[i];
            if(InpShowLabel_Fight)
               DrawSignalText(time[i], high[i] + _Point * 200, "⚡ FIGHT", clrYellow, true);
         }
      }

      // ── FVG ────────────────────────────────────────────────
      if(InpShowFVG && i >= 2 && i < rates_total - 1)
      {
         ManageAdvancedFVG(i, open, high, low, close, time, rates_total);
      }

      // ── Divergence Lines ───────────────────────────────────
      if(InpShowDivLines && i > InpDivPeriod)
      {
         int hiIdx = i, loIdx = i;
         for(int k = 1; k <= InpDivPeriod; k++)
         {
            if(high[i-k] > high[hiIdx]) hiIdx = i-k;
            if(low[i-k]  < low[loIdx])  loIdx = i-k;
         }
         if(high[i] >= high[hiIdx] && hiIdx != i && BufferCVD[i] < BufferCVD[hiIdx])
            DrawDivLine(time[hiIdx], high[hiIdx], time[i], high[i], InpBearColor, "BearDiv");
         if(low[i] <= low[loIdx] && loIdx != i && BufferCVD[i] > BufferCVD[loIdx])
            DrawDivLine(time[loIdx], low[loIdx], time[i], low[i], InpBullColor, "BullDiv");
      }

      // ── Strategy Matrix (closed bars only) ─────────────────
      if(i < rates_total - 1)
      {
         int comboID = DetectComboStrategy(i);
         if(comboID != -1)
         {
            int barsSince = (g_LastSignalTime > 0)
                            ? (int)((time[i] - g_LastSignalTime) / PeriodSeconds())
                            : 999;
            if(barsSince >= InpSignalCooldownBars)
            {
               bool isBuyStrat = (comboID >= 100 && comboID < 200);
               DrawStrategyText(time[i],
                                isBuyStrat ? low[i] : high[i],
                                comboID, isBuyStrat);
               g_LastSignalTime = time[i];
            }
         }
      }
   }

   //----------------------------------------------------------
   // PHASE 3b: Current Bar Status for Dashboard
   //----------------------------------------------------------
   {
      int cur = rates_total - 1;
      string barSigs = "";

      if(BufferBullAbs[cur]    != EMPTY_VALUE) barSigs += "BullAbs ";
      if(BufferBearAbs[cur]    != EMPTY_VALUE) barSigs += "BearAbs ";
      if(BufferBigBuy[cur]     != EMPTY_VALUE) barSigs += "BigBuy ";
      if(BufferBigSell[cur]    != EMPTY_VALUE) barSigs += "BigSell ";
      if(BufferSweepBuy[cur]   != EMPTY_VALUE) barSigs += "Sweep+ ";
      if(BufferSweepSell[cur]  != EMPTY_VALUE) barSigs += "Sweep- ";
      if(BufferReloadBuy[cur]  != EMPTY_VALUE) barSigs += "Reload+ ";
      if(BufferReloadSell[cur] != EMPTY_VALUE) barSigs += "Reload- ";
      if(BufferTrapBuy[cur]    != EMPTY_VALUE) barSigs += "Trap+ ";
      if(BufferTrapSell[cur]   != EMPTY_VALUE) barSigs += "Trap- ";
      if(BufferFight[cur]      != EMPTY_VALUE) barSigs += "Fight ";
      if(StringLen(barSigs) == 0) barSigs = "None";
      g_CurBarSignals = barSigs;

      int prevBar = rates_total - 2;
      int comboNow = (prevBar >= 0) ? DetectComboStrategy(prevBar) : -1;

      if(comboNow != -1)
      {
         SignalInfo si = GetSignalDetail(comboNow);
         g_CurStatusName   = si.icon + " " + si.name;
         g_CurStatusAction = si.action;
         g_CurStatusColor  = si.cl;
         g_CurStatusTime   = TimeToString(time[prevBar], TIME_MINUTES);
      }
      else
      {
         bool foundRecent = false;
         for(int k = 2; k <= InpComboLookback + 2 && k < rates_total; k++)
         {
            int chkBar = rates_total - k;
            int chkID  = DetectComboStrategy(chkBar);
            if(chkID != -1)
            {
               SignalInfo si = GetSignalDetail(chkID);
               g_CurStatusName   = "(" + IntegerToString(k-1) + " bars) " + si.name;
               g_CurStatusAction = si.action;
               g_CurStatusColor  = (color)C'150,150,100';
               g_CurStatusTime   = TimeToString(time[chkBar], TIME_MINUTES);
               foundRecent       = true;
               break;
            }
         }
         if(!foundRecent)
         {
            g_CurStatusName   = "No Setup";
            g_CurStatusAction = "Wait for signal";
            g_CurStatusColor  = (color)C'130,130,130';
            g_CurStatusTime   = g_LastSignalTime > 0
                                 ? TimeToString(g_LastSignalTime, TIME_MINUTES)
                                 : "-";
         }
      }
   }

   //----------------------------------------------------------
   // PHASE 4: H1 Context
   //----------------------------------------------------------
   if(InpShowH1Profile)
   {
      static datetime lastH1Calc = 0;
      if(TimeCurrent() - lastH1Calc > 60)
      {
         CalculateAndDrawH1Context(time[rates_total-1]);
         lastH1Calc = TimeCurrent();
      }
   }

   //----------------------------------------------------------
   // PHASE 5: Count active FVGs
   //----------------------------------------------------------
   int activeFVG = 0;
   {
      int objTot = ObjectsTotal(0, -1, -1);
      for(int k = 0; k < objTot; k++)
      {
         string nm = ObjectName(0, k);
         if(StringFind(nm, PrefixFVG) >= 0 && StringFind(nm, "_CE") < 0)
            activeFVG++;
      }
   }
   DashSet("FVG", StringFormat("%d zones", activeFVG), activeFVG > 0 ? clrLime : InpNeutralColor());
   ObjectSetString(0, DPFX+"SV_FVG", OBJPROP_TEXT, IntegerToString(activeFVG));

   //----------------------------------------------------------
   // PHASE 6: Dashboard + [FIX] Alert บน closed bar (rates_total-2)
   //----------------------------------------------------------
   UpdateDashboardStats(rates_total, close, tick_volume, volume, time, useReal);

   if(rates_total >= 2)
      CheckAndSendAllAlerts(rates_total-2, time[rates_total-2], close[rates_total-2]);

   ChartRedraw(0);
   return(rates_total);
}

//============================================================
//  [FIX] CheckAndSendAllAlerts — ครอบคลุมทุก signal type
//  เรียกครั้งเดียวต่อ OnCalculate บน closed bar (rates_total-2)
//  แต่ละ type มี cooldown แยกกัน → ไม่ block กันเอง
//============================================================
void CheckAndSendAllAlerts(int i, datetime barTime, double price)
{
   // ถ้าปิด notification และ alert ทั้งคู่ → ออกทันที
   if(!InpUseNotification && !InpUseAlert) return;
   if(i < 0) return;

   string sym = _Symbol;
   string tf  = StringSubstr(EnumToString((ENUM_TIMEFRAMES)Period()), 7);
   int    cooldownSec = InpAlertCooldownBars * (int)PeriodSeconds();

   //----------------------------------------------------------
   // [FIX] 1. Combo Strategy Alert
   //----------------------------------------------------------
   if(InpNotifyCombo)
   {
      int comboID = DetectComboStrategy(i);
      if(comboID != -1)
      {
         bool cooldownOK = (barTime != g_LastAlertTime_Combo) &&
                           ((int)(barTime - g_LastAlertTime_Combo) >= cooldownSec ||
                            g_LastAlertTime_Combo == 0);
         if(cooldownOK)
         {
            SignalInfo si = GetSignalDetail(comboID);
            string msg = StringFormat("[DOF v2.1] %s %s\nSym: %s | TF: %s\nLogic: %s\nAction: %s\nPrice: %s\nTime: %s",
                                      si.icon, si.name, sym, tf,
                                      si.desc, si.action,
                                      DoubleToString(price, _Digits),
                                      TimeToString(barTime, TIME_MINUTES));
            SendAlertMsg(msg);
            g_LastAlertTime_Combo = barTime;
         }
      }
   }

   //----------------------------------------------------------
   // [FIX] 2. Sweep Alert (ใช้ flag จริงแล้ว)
   //----------------------------------------------------------
   if(InpNotifySweep)
   {
      bool hasSweep  = (BufferSweepBuy[i]  != EMPTY_VALUE || BufferSweepSell[i] != EMPTY_VALUE);
      bool cooldownOK = (barTime != g_LastAlertTime_Sweep) &&
                        ((int)(barTime - g_LastAlertTime_Sweep) >= cooldownSec ||
                         g_LastAlertTime_Sweep == 0);
      if(hasSweep && cooldownOK)
      {
         string dir = (BufferSweepBuy[i] != EMPTY_VALUE) ? "BUY ↑" : "SELL ↓";
         string msg = StringFormat("[DOF v2.1] ⚡ SWEEP %s\nSym: %s | TF: %s\nPrice: %s\nTime: %s",
                                   dir, sym, tf,
                                   DoubleToString(price, _Digits),
                                   TimeToString(barTime, TIME_MINUTES));
         SendAlertMsg(msg);
         g_LastAlertTime_Sweep = barTime;
      }
   }

   //----------------------------------------------------------
   // [FIX] 3. Trap Alert (ใช้ flag จริงแล้ว)
   //----------------------------------------------------------
   if(InpNotifyTrap)
   {
      bool hasTrap   = (BufferTrapBuy[i]  != EMPTY_VALUE || BufferTrapSell[i] != EMPTY_VALUE);
      bool cooldownOK = (barTime != g_LastAlertTime_Trap) &&
                        ((int)(barTime - g_LastAlertTime_Trap) >= cooldownSec ||
                         g_LastAlertTime_Trap == 0);
      if(hasTrap && cooldownOK)
      {
         string dir = (BufferTrapBuy[i] != EMPTY_VALUE) ? "BUY ↑ (สวนกับดัก)" : "SELL ↓ (สวนกับดัก)";
         string msg = StringFormat("[DOF v2.1] 🚨 TRAP %s\nSym: %s | TF: %s\nPrice: %s\nTime: %s",
                                   dir, sym, tf,
                                   DoubleToString(price, _Digits),
                                   TimeToString(barTime, TIME_MINUTES));
         SendAlertMsg(msg);
         g_LastAlertTime_Trap = barTime;
      }
   }

   //----------------------------------------------------------
   // [FIX] 4. Reload Alert (ใช้ flag จริงแล้ว)
   //----------------------------------------------------------
   if(InpNotifyReload)
   {
      bool hasReload  = (BufferReloadBuy[i]  != EMPTY_VALUE || BufferReloadSell[i] != EMPTY_VALUE);
      bool cooldownOK  = (barTime != g_LastAlertTime_Reload) &&
                         ((int)(barTime - g_LastAlertTime_Reload) >= cooldownSec ||
                          g_LastAlertTime_Reload == 0);
      if(hasReload && cooldownOK)
      {
         string dir = (BufferReloadBuy[i] != EMPTY_VALUE) ? "BUY ↑ (ตามเทรนด์)" : "SELL ↓ (ตามเทรนด์)";
         string msg = StringFormat("[DOF v2.1] 🌊 RELOAD %s\nSym: %s | TF: %s\nPrice: %s\nTime: %s",
                                   dir, sym, tf,
                                   DoubleToString(price, _Digits),
                                   TimeToString(barTime, TIME_MINUTES));
         SendAlertMsg(msg);
         g_LastAlertTime_Reload = barTime;
      }
   }

   //----------------------------------------------------------
   // [FIX] 5. Fight Alert (ใช้ flag จริงแล้ว)
   //----------------------------------------------------------
   if(InpNotifyFight)
   {
      bool hasFight   = (BufferFight[i] != EMPTY_VALUE);
      bool cooldownOK  = (barTime != g_LastAlertTime_Fight) &&
                         ((int)(barTime - g_LastAlertTime_Fight) >= cooldownSec ||
                          g_LastAlertTime_Fight == 0);
      if(hasFight && cooldownOK)
      {
         string msg = StringFormat("[DOF v2.1] ⚡ FIGHT WARNING\nSym: %s | TF: %s\nBuyer vs Seller ขับเคี่ยวกัน\nPrice: %s\nTime: %s",
                                   sym, tf,
                                   DoubleToString(price, _Digits),
                                   TimeToString(barTime, TIME_MINUTES));
         SendAlertMsg(msg);
         g_LastAlertTime_Fight = barTime;
      }
   }
}

//============================================================
//  [FIX] SendAlertMsg — helper ส่งทั้ง Notification และ Alert
//  แยกออกมาเพื่อไม่ต้องเขียนซ้ำ
//============================================================
void SendAlertMsg(string msg)
{
   if(InpUseNotification)
   {
      if(!SendNotification(msg))
         Print("[DOF v2.1] SendNotification FAILED: ", GetLastError(),
               " — ตรวจสอบ MetaQuotes ID ใน MT5 Options");
   }
   if(InpUseAlert)
      Alert(msg);
}

//============================================================
//  GetBarDelta
//============================================================
double GetBarDelta(long vol, double o, double c, double h, double l)
{
   double range = h - l;
   if(range == 0) return 0;
   return (double)vol * ((c - l) - (h - c)) / range;
}

//============================================================
//  VOLUME PROFILE
//============================================================
void CalcVolumeProfile(int startBar, int endBar,
                       const long &tvol[], const long &rvol[],
                       const double &high[], const double &low[],
                       bool useReal)
{
   double hiMax = high[startBar], loMin = low[startBar];
   for(int i = startBar+1; i <= endBar; i++)
   {
      if(high[i] > hiMax) hiMax = high[i];
      if(low[i]  < loMin) loMin = low[i];
   }
   double fullRange = hiMax - loMin;
   if(fullRange <= 0) return;

   double binSz = fullRange / InpVPBins;

   for(int b = 0; b < InpVPBins; b++)
   {
      g_VPBinPrices[b] = loMin + b * binSz;
      g_VPBinVols[b]   = 0;
   }

   for(int i = startBar; i <= endBar; i++)
   {
      double mid  = (high[i] + low[i]) * 0.5;
      int    bin  = (int)((mid - loMin) / binSz);
      bin = MathMax(0, MathMin(InpVPBins - 1, bin));
      double v = useReal ? (double)rvol[i] : (double)tvol[i];
      g_VPBinVols[bin] += v;
   }

   int pocBin = 0;
   for(int b = 1; b < InpVPBins; b++)
      if(g_VPBinVols[b] > g_VPBinVols[pocBin]) pocBin = b;
   g_POC = g_VPBinPrices[pocBin] + binSz * 0.5;

   double totVol = 0;
   for(int b = 0; b < InpVPBins; b++) totVol += g_VPBinVols[b];
   double target = totVol * InpVPValueArea;
   int hiIdx = pocBin, loIdx = pocBin;
   double va = g_VPBinVols[pocBin];
   while(va < target)
   {
      double up   = (hiIdx+1 < InpVPBins) ? g_VPBinVols[hiIdx+1] : 0;
      double down = (loIdx-1 >= 0)         ? g_VPBinVols[loIdx-1] : 0;
      if(up == 0 && down == 0) break;
      if(up >= down && hiIdx+1 < InpVPBins) { hiIdx++; va += up; }
      else if(loIdx-1 >= 0)                  { loIdx--; va += down; }
      else break;
   }
   g_VAH = g_VPBinPrices[hiIdx] + binSz;
   g_VAL = g_VPBinPrices[loIdx];
}

//============================================================
//  DRAW VP HISTOGRAM
//============================================================
void DrawVolumeProfileBoxes(int ratesTotal, const datetime &time[])
{
   ObjectsDeleteAll(0, PrefixVP);
   if(g_POC <= 0) return;

   double maxVol = 0;
   for(int b = 0; b < InpVPBins; b++)
      if(g_VPBinVols[b] > maxVol) maxVol = g_VPBinVols[b];
   if(maxVol <= 0) return;

   double binSz = (g_VAH - g_VAL + _Point * InpVPBins) / InpVPBins;
   if(binSz <= 0) binSz = _Point * 10;

   datetime tNow = time[ratesTotal-1];
   int barWidth  = 12;

   for(int b = 0; b < InpVPBins; b++)
   {
      if(g_VPBinVols[b] <= 0) continue;
      double binLo = g_VPBinPrices[b];
      double binHi = binLo + binSz;
      int    barsW = MathMax(1, (int)(barWidth * g_VPBinVols[b] / maxVol));

      datetime tL = (datetime)(tNow + PeriodSeconds());
      datetime tR = (datetime)(tNow + PeriodSeconds() * (1 + barsW));

      string rn = PrefixVP + "B" + IntegerToString(b);
      if(ObjectFind(0, rn) < 0)
         ObjectCreate(0, rn, OBJ_RECTANGLE, 0, tL, binHi, tR, binLo);
      ObjectSetInteger(0, rn, OBJPROP_TIME,  0, tL);
      ObjectSetInteger(0, rn, OBJPROP_TIME,  1, tR);
      ObjectSetDouble(0,  rn, OBJPROP_PRICE, 0, binHi);
      ObjectSetDouble(0,  rn, OBJPROP_PRICE, 1, binLo);

      bool isPOC = MathAbs(binLo + binSz*0.5 - g_POC) < binSz * 0.75;
      bool isVA  = (binLo >= g_VAL - binSz*0.1 && binHi <= g_VAH + binSz*0.1);
      color rc   = isPOC ? clrYellow : (isVA ? C'40,70,150' : C'55,55,75');

      ObjectSetInteger(0, rn, OBJPROP_COLOR,      rc);
      ObjectSetInteger(0, rn, OBJPROP_FILL,        true);
      ObjectSetInteger(0, rn, OBJPROP_BACK,        true);
      ObjectSetInteger(0, rn, OBJPROP_SELECTABLE,  false);
      ObjectSetInteger(0, rn, OBJPROP_HIDDEN,      true);
   }

   string pocN = PrefixVP+"POC";
   if(ObjectFind(0, pocN) < 0) ObjectCreate(0, pocN, OBJ_HLINE, 0, 0, g_POC);
   ObjectSetDouble(0,  pocN, OBJPROP_PRICE, g_POC);
   ObjectSetInteger(0, pocN, OBJPROP_COLOR, clrYellow);
   ObjectSetInteger(0, pocN, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, pocN, OBJPROP_SELECTABLE, false);

   string vahN = PrefixVP+"VAH";
   if(ObjectFind(0, vahN) < 0) ObjectCreate(0, vahN, OBJ_HLINE, 0, 0, g_VAH);
   ObjectSetDouble(0,  vahN, OBJPROP_PRICE, g_VAH);
   ObjectSetInteger(0, vahN, OBJPROP_COLOR, C'80,130,210');
   ObjectSetInteger(0, vahN, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, vahN, OBJPROP_SELECTABLE, false);

   string valN = PrefixVP+"VAL";
   if(ObjectFind(0, valN) < 0) ObjectCreate(0, valN, OBJ_HLINE, 0, 0, g_VAL);
   ObjectSetDouble(0,  valN, OBJPROP_PRICE, g_VAL);
   ObjectSetInteger(0, valN, OBJPROP_COLOR, C'80,130,210');
   ObjectSetInteger(0, valN, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, valN, OBJPROP_SELECTABLE, false);
}

//============================================================
//  MANAGE ADVANCED FVG
//  [FIX] FVG Confluence alert เชื่อมกับ SendAlertMsg จริง
//============================================================
void ManageAdvancedFVG(int i, const double &open[], const double &high[],
                       const double &low[], const double &close[],
                       const datetime &time[], int rates_total)
{
   double minGap = InpFVGMinPoints * _Point;

   bool isBullFVG = (close[i-1] > open[i-1] && (low[i] - high[i-2]) > minGap);
   bool isBearFVG = (close[i-1] < open[i-1] && (low[i-2] - high[i]) > minGap);

   if(isBullFVG || isBearFVG)
   {
      string baseName = PrefixFVG + TimeToString(time[i]);
      double top    = isBullFVG ? low[i]   : low[i-2];
      double bottom = isBullFVG ? high[i-2]: high[i];
      double mid    = (top + bottom) * 0.5;
      color  fvgClr = isBullFVG ? InpColorFreshBull : InpColorFreshBear;

      if(ObjectFind(0, baseName) < 0)
      {
         datetime tEnd = InpExtendFVG ? (datetime)(TimeCurrent() + PeriodSeconds()*20) : time[i];
         ObjectCreate(0, baseName, OBJ_RECTANGLE, 0, time[i-1], top, tEnd, bottom);
         ObjectSetInteger(0, baseName, OBJPROP_COLOR, fvgClr);
         ObjectSetInteger(0, baseName, OBJPROP_FILL,  true);
         ObjectSetInteger(0, baseName, OBJPROP_BACK,  true);
         ObjectSetInteger(0, baseName, OBJPROP_WIDTH, 1);
         ObjectSetInteger(0, baseName, OBJPROP_SELECTABLE, false);
         ObjectSetString(0,  baseName, OBJPROP_TEXT, isBullFVG ? "Bull FVG" : "Bear FVG");

         if(InpShowCELine)
         {
            string ceName = baseName + "_CE";
            ObjectCreate(0, ceName, OBJ_TREND, 0, time[i-1], mid, tEnd, mid);
            ObjectSetInteger(0, ceName, OBJPROP_COLOR,     fvgClr);
            ObjectSetInteger(0, ceName, OBJPROP_STYLE,     STYLE_DOT);
            ObjectSetInteger(0, ceName, OBJPROP_RAY_RIGHT, true);
            ObjectSetInteger(0, ceName, OBJPROP_SELECTABLE,false);
         }

         // [FIX] FVG Confluence alert — ใช้ SendAlertMsg แทนการเรียก SendNotification/Alert โดยตรง
         // และตรวจสอบ InpNotifyFVG_Setup + cooldown อย่างถูกต้อง
         if(InpNotifyFVG_Setup && i >= rates_total - 2)
         {
            bool hasSweep = false;
            for(int k = 0; k <= 3 && k <= i; k++)
            {
               if(isBullFVG && BufferSweepBuy[i-k]  != EMPTY_VALUE) hasSweep = true;
               if(isBearFVG && BufferSweepSell[i-k] != EMPTY_VALUE) hasSweep = true;
            }

            string setupMsg = "";
            if(hasSweep)
               setupMsg = "FVG + SWEEP → Reversal Setup";
            if(isBullFVG && i > 0 && BufferBigBuy[i-1]  != EMPTY_VALUE)
               setupMsg = "FVG + WHALE BUY → Support Zone";
            if(isBearFVG && i > 0 && BufferBigSell[i-1] != EMPTY_VALUE)
               setupMsg = "FVG + WHALE SELL → Resistance Zone";

            if(StringLen(setupMsg) > 0)
            {
               // [FIX] ตรวจสอบ cooldown สำหรับ FVG alert แยกต่างหาก
               int cooldownSec = InpAlertCooldownBars * (int)PeriodSeconds();
               bool cooldownOK  = (time[i] != g_LastAlertTime_FVG) &&
                                  ((int)(time[i] - g_LastAlertTime_FVG) >= cooldownSec ||
                                   g_LastAlertTime_FVG == 0);
               if(cooldownOK)
               {
                  string sym = _Symbol;
                  string tf  = StringSubstr(EnumToString((ENUM_TIMEFRAMES)Period()), 7);
                  string msg = StringFormat("[DOF v2.1] 🔥 %s\nSym: %s | TF: %s\nPrice: %s\nTime: %s",
                                            setupMsg, sym, tf,
                                            DoubleToString(close[i], _Digits),
                                            TimeToString(time[i], TIME_MINUTES));
                  SendAlertMsg(msg);
                  g_LastAlertTime_FVG = time[i];
               }
            }
         }
      }
   }

   // State Management: update existing FVG boxes (only on last active bar)
   if(i < rates_total - 2) return;

   int objTotal = ObjectsTotal(0, -1, -1);
   int fvgCount = 0;
   for(int k = objTotal - 1; k >= 0; k--)
   {
      string nm = ObjectName(0, k);
      if(StringFind(nm, PrefixFVG) != 0 || StringFind(nm, "_CE") >= 0) continue;

      fvgCount++;
      if(fvgCount > InpMaxFVGCount)
      {
         ObjectDelete(0, nm);
         ObjectDelete(0, nm + "_CE");
         continue;
      }

      double fTop = ObjectGetDouble(0, nm, OBJPROP_PRICE, 0);
      double fBot = ObjectGetDouble(0, nm, OBJPROP_PRICE, 1);
      double boxTop = MathMax(fTop, fBot);
      double boxBot = MathMin(fTop, fBot);
      string desc   = ObjectGetString(0, nm, OBJPROP_TEXT);
      bool   isBull = (StringFind(desc, "Bull") >= 0);
      string ceName = nm + "_CE";

      bool inverted = (isBull && close[i] < boxBot) || (!isBull && close[i] > boxTop);
      if(inverted)
      {
         ObjectSetInteger(0, nm,     OBJPROP_COLOR, InpColorInversion);
         ObjectSetInteger(0, nm,     OBJPROP_WIDTH, 2);
         ObjectSetInteger(0, ceName, OBJPROP_COLOR, InpColorInversion);
      }
      else
      {
         bool mitigated = (isBull && low[i] <= boxTop) || (!isBull && high[i] >= boxBot);
         if(mitigated)
         {
            ObjectSetInteger(0, nm,     OBJPROP_COLOR, InpColorMitigated);
            ObjectSetInteger(0, nm,     OBJPROP_STYLE, STYLE_DOT);
            ObjectSetInteger(0, ceName, OBJPROP_COLOR, InpColorMitigated);
         }
      }

      if(InpExtendFVG)
      {
         datetime tExt = (datetime)(TimeCurrent() + PeriodSeconds() * 20);
         datetime curRight = (datetime)ObjectGetInteger(0, nm, OBJPROP_TIME, 1);
         if(MathAbs((long)(tExt - curRight)) > PeriodSeconds())
         {
            ObjectSetInteger(0, nm,     OBJPROP_TIME, 1, tExt);
            ObjectSetInteger(0, ceName, OBJPROP_TIME, 1, tExt);
         }
      }
   }
}

//============================================================
//  STRATEGY MATRIX
//============================================================
int DetectComboStrategy(int i)
{
   int lb = InpComboLookback;

   bool foundSweepBuy = false, foundSweepSell = false;
   for(int k = 0; k <= lb; k++)
   {
      if(i-k < 0) break;
      if(BufferSweepBuy[i-k]  != EMPTY_VALUE) foundSweepBuy  = true;
      if(BufferSweepSell[i-k] != EMPTY_VALUE) foundSweepSell = true;
   }
   if(foundSweepBuy  && BufferBullAbs[i] != EMPTY_VALUE) return 101;
   if(foundSweepSell && BufferBearAbs[i] != EMPTY_VALUE) return 201;

   if(BufferTrapBuy[i]  != EMPTY_VALUE) return 102;
   if(BufferTrapSell[i] != EMPTY_VALUE) return 202;

   bool foundAbsBuy = false, foundAbsSell = false;
   for(int k = 1; k <= lb; k++)
   {
      if(i-k < 0) break;
      if(BufferBullAbs[i-k] != EMPTY_VALUE) foundAbsBuy  = true;
      if(BufferBearAbs[i-k] != EMPTY_VALUE) foundAbsSell = true;
   }
   if(foundAbsBuy  && BufferBigBuy[i]  != EMPTY_VALUE) return 103;
   if(foundAbsSell && BufferBigSell[i] != EMPTY_VALUE) return 203;

   bool foundReloadBuy = false, foundReloadSell = false;
   for(int k = 0; k <= lb; k++)
   {
      if(i-k < 0) break;
      if(BufferReloadBuy[i-k]  != EMPTY_VALUE) foundReloadBuy  = true;
      if(BufferReloadSell[i-k] != EMPTY_VALUE) foundReloadSell = true;
   }
   bool bullConf = (BufferBullAbs[i] != EMPTY_VALUE || BufferBigBuy[i]  != EMPTY_VALUE);
   bool bearConf = (BufferBearAbs[i] != EMPTY_VALUE || BufferBigSell[i] != EMPTY_VALUE);
   if(foundReloadBuy  && bullConf) return 104;
   if(foundReloadSell && bearConf) return 204;

   return -1;
}

//============================================================
//  SIGNAL DETAIL
//============================================================
SignalInfo GetSignalDetail(int id)
{
   SignalInfo info;
   switch(id)
   {
      case 101: info.name="REVERSAL BUY";     info.icon="💎"; info.type="STRONG BUY";  info.cl=clrGold;        info.desc="Sweep→Abs";    info.action="BUY ต้นเทรนด์";  break;
      case 102: info.name="WHALE TRAP BUY";   info.icon="🚨"; info.type="STRONG BUY";  info.cl=clrLime;        info.desc="BigSell→Trap"; info.action="BUY สวนกับดัก";  break;
      case 103: info.name="BREAKOUT BUY";     info.icon="🚀"; info.type="STRONG BUY";  info.cl=clrGreenYellow; info.desc="Abs→BigBuy";   info.action="Follow BUY";      break;
      case 104: info.name="TREND FOLLOW BUY"; info.icon="🌊"; info.type="BUY";         info.cl=clrAqua;        info.desc="Reload→Conf";  info.action="BUY ตามน้ำ";     break;
      case 201: info.name="REVERSAL SELL";    info.icon="💎"; info.type="STRONG SELL"; info.cl=clrOrangeRed;   info.desc="Sweep→Abs";    info.action="SELL ต้นเทรนด์"; break;
      case 202: info.name="WHALE TRAP SELL";  info.icon="🚨"; info.type="STRONG SELL"; info.cl=clrRed;         info.desc="BigBuy→Trap";  info.action="SELL สวนกับดัก"; break;
      case 203: info.name="BREAKOUT SELL";    info.icon="☄️"; info.type="STRONG SELL"; info.cl=clrCrimson;     info.desc="Abs→BigSell";  info.action="Follow SELL";     break;
      case 204: info.name="TREND FOLLOW SELL";info.icon="🌊"; info.type="SELL";        info.cl=clrHotPink;     info.desc="Reload→Conf";  info.action="SELL ตามน้ำ";    break;
      default:  info.name=""; break;
   }
   return info;
}

//============================================================
//  H1 CONTEXT PROFILE
//============================================================
void CalculateAndDrawH1Context(datetime currentTime)
{
   if(!InpShowH1Profile) return;
   double h1h[], h1l[]; long h1v[];
   int barsH1 = InpH1Lookback;
   if(CopyHigh(_Symbol, PERIOD_H1, 0, barsH1, h1h) < barsH1) return;
   if(CopyLow (_Symbol, PERIOD_H1, 0, barsH1, h1l) < barsH1) return;
   if(CopyTickVolume(_Symbol, PERIOD_H1, 0, barsH1, h1v) < barsH1) return;

   double maxH = h1h[0], minL = h1l[0];
   for(int i = 1; i < barsH1; i++)
   {
      if(h1h[i] > maxH) maxH = h1h[i];
      if(h1l[i] < minL) minL = h1l[i];
   }
   int    bins = 50;
   double step = (maxH - minL) / bins;
   if(step == 0) return;

   double vp[]; ArrayResize(vp, bins); ArrayInitialize(vp, 0);
   for(int i = 0; i < barsH1; i++)
   {
      int bin = (int)(((h1h[i]+h1l[i])*0.5 - minL) / step);
      if(bin >= 0 && bin < bins) vp[bin] += (double)h1v[i];
   }

   int startS = (int)(bins*0.2), endS = (int)(bins*0.8);
   double maxV = 0, minV = 1e12;
   int pocIdx = -1, lvnIdx = -1;
   for(int k = startS; k <= endS; k++)
      if(vp[k] > maxV) { maxV = vp[k]; pocIdx = k; }
   for(int k = startS; k <= endS; k++)
      if(k != pocIdx && k != pocIdx-1 && k != pocIdx+1 && vp[k] < minV && vp[k] > 0)
         { minV = vp[k]; lvnIdx = k; }

   double vah = minL + step*bins*0.85, val = minL + step*bins*0.15;

   if(lvnIdx != -1)
   {
      string nm = PrefixLVN+"Current";
      double lt = minL+(lvnIdx+1)*step, lb2 = minL+lvnIdx*step;
      if(ObjectFind(0,nm)<0) ObjectCreate(0,nm,OBJ_RECTANGLE,0,currentTime,lt,currentTime+PeriodSeconds()*60,lb2);
      ObjectSetInteger(0,nm,OBJPROP_TIME, 0,currentTime-PeriodSeconds()*300);
      ObjectSetInteger(0,nm,OBJPROP_TIME, 1,currentTime+PeriodSeconds()*900);
      ObjectSetDouble(0, nm,OBJPROP_PRICE,0,lb2); ObjectSetDouble(0,nm,OBJPROP_PRICE,1,lt);
      ObjectSetInteger(0,nm,OBJPROP_COLOR,InpLVNColor); ObjectSetInteger(0,nm,OBJPROP_FILL,true);
      ObjectSetInteger(0,nm,OBJPROP_SELECTABLE,false);
   }
   if(pocIdx != -1)
   {
      string pn = PrefixVA+"POC";
      double pt = minL+(pocIdx+1)*step, pb = minL+pocIdx*step;
      if(ObjectFind(0,pn)<0) ObjectCreate(0,pn,OBJ_RECTANGLE,0,currentTime,pt,currentTime+PeriodSeconds()*60,pb);
      ObjectSetInteger(0,pn,OBJPROP_TIME, 0,currentTime-PeriodSeconds()*300);
      ObjectSetInteger(0,pn,OBJPROP_TIME, 1,currentTime+PeriodSeconds()*900);
      ObjectSetDouble(0, pn,OBJPROP_PRICE,0,pb); ObjectSetDouble(0,pn,OBJPROP_PRICE,1,pt);
      ObjectSetInteger(0,pn,OBJPROP_COLOR,clrGold); ObjectSetInteger(0,pn,OBJPROP_FILL,true);
      ObjectSetInteger(0,pn,OBJPROP_BACK,true); ObjectSetInteger(0,pn,OBJPROP_SELECTABLE,false);
   }
   string vahn=PrefixVA+"VAH", valn=PrefixVA+"VAL";
   if(ObjectFind(0,vahn)<0) ObjectCreate(0,vahn,OBJ_HLINE,0,0,vah);
   ObjectSetDouble(0,vahn,OBJPROP_PRICE,vah); ObjectSetInteger(0,vahn,OBJPROP_COLOR,InpVAColor); ObjectSetInteger(0,vahn,OBJPROP_STYLE,STYLE_DASH);
   if(ObjectFind(0,valn)<0) ObjectCreate(0,valn,OBJ_HLINE,0,0,val);
   ObjectSetDouble(0,valn,OBJPROP_PRICE,val); ObjectSetInteger(0,valn,OBJPROP_COLOR,InpVAColor); ObjectSetInteger(0,valn,OBJPROP_STYLE,STYLE_DASH);
}

//============================================================
//  DRAWING HELPERS
//============================================================
void DrawAbsorption(double top, double bottom, color clr, datetime t, bool isBear)
{
   string boxN = PrefixAbsBox + TimeToString(t);
   if(ObjectFind(0, boxN) < 0)
   {
      ObjectCreate(0, boxN, OBJ_RECTANGLE, 0, t, top, (datetime)(t+PeriodSeconds()), bottom);
      ObjectSetInteger(0, boxN, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, boxN, OBJPROP_FILL,  false);
      ObjectSetInteger(0, boxN, OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, boxN, OBJPROP_BACK,  false);
      ObjectSetInteger(0, boxN, OBJPROP_SELECTABLE, false);
   }
   string lineN = PrefixAbsLine + TimeToString(t);
   if(ObjectFind(0, lineN) < 0)
   {
      double lvl = isBear ? top : bottom;
      ObjectCreate(0, lineN, OBJ_TREND, 0, t, lvl, TimeCurrent(), lvl);
      ObjectSetInteger(0, lineN, OBJPROP_COLOR,     clr);
      ObjectSetInteger(0, lineN, OBJPROP_STYLE,     STYLE_DOT);
      ObjectSetInteger(0, lineN, OBJPROP_WIDTH,     1);
      ObjectSetInteger(0, lineN, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, lineN, OBJPROP_BACK,      true);
      ObjectSetInteger(0, lineN, OBJPROP_SELECTABLE,false);
      ObjectSetString(0,  lineN, OBJPROP_TEXT, isBear ? "Bear" : "Bull");
   }
   else
   {
      datetime curRight = (datetime)ObjectGetInteger(0, lineN, OBJPROP_TIME, 1);
      if(MathAbs((long)(TimeCurrent() - curRight)) > PeriodSeconds())
         ObjectSetInteger(0, lineN, OBJPROP_TIME, 1, TimeCurrent());
   }
}

void DrawBigTradeText(datetime t, double price, long vol, color clr)
{
   if(!InpShowVolText) return;
   string nm = PrefixVolTxt + TimeToString(t);
   if(ObjectFind(0, nm) >= 0) return;
   ObjectCreate(0, nm, OBJ_TEXT, 0, t, price);
   bool isBull = (clr == clrSpringGreen);
   string arrow = isBull ? " ▲ " : " ▼ ";
   ObjectSetString(0,  nm, OBJPROP_TEXT,  arrow + (string)vol);
   ObjectSetInteger(0, nm, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, nm, OBJPROP_FONTSIZE, InpTextSize);
   ObjectSetString(0,  nm, OBJPROP_FONT,  "Arial Bold");
   if(isBull) ObjectSetInteger(0, nm, OBJPROP_ANCHOR, ANCHOR_RIGHT_LOWER);
   else       ObjectSetInteger(0, nm, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
   ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
}

void DrawTrapSignal(datetime t, double price, bool isBull)
{
   if(!InpShowLabel_Trap) return;
   string nm = PrefixTrap + TimeToString(t);
   if(ObjectFind(0, nm) >= 0) return;
   ObjectCreate(0, nm, OBJ_TEXT, 0, t, price);
   ObjectSetString(0,  nm, OBJPROP_TEXT,  isBull ? "▲ TRAP" : "▼ TRAP");
   ObjectSetInteger(0, nm, OBJPROP_FONTSIZE, 10);
   ObjectSetString(0,  nm, OBJPROP_FONT,  "Arial Black");
   ObjectSetInteger(0, nm, OBJPROP_COLOR, isBull ? clrLime : clrRed);
   if(isBull) { ObjectSetInteger(0,nm,OBJPROP_ANCHOR,ANCHOR_TOP);    ObjectSetDouble(0,nm,OBJPROP_PRICE,0,price-_Point*80); }
   else       { ObjectSetInteger(0,nm,OBJPROP_ANCHOR,ANCHOR_BOTTOM); ObjectSetDouble(0,nm,OBJPROP_PRICE,0,price+_Point*80); }
   ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
}

void DrawSignalText(datetime t, double price, string txt, color clr, bool isTop)
{
   string nm = PrefixSigTxt + TimeToString(t) + txt;
   if(ObjectFind(0, nm) >= 0) return;
   ObjectCreate(0, nm, OBJ_TEXT, 0, t, price);
   ObjectSetString(0,  nm, OBJPROP_TEXT,  txt);
   ObjectSetInteger(0, nm, OBJPROP_FONTSIZE, 9);
   ObjectSetString(0,  nm, OBJPROP_FONT,  "Arial Bold");
   ObjectSetInteger(0, nm, OBJPROP_COLOR, clr);
   if(isTop) { ObjectSetInteger(0,nm,OBJPROP_ANCHOR,ANCHOR_BOTTOM); ObjectSetDouble(0,nm,OBJPROP_PRICE,0,price+_Point*50); }
   else      { ObjectSetInteger(0,nm,OBJPROP_ANCHOR,ANCHOR_TOP);    ObjectSetDouble(0,nm,OBJPROP_PRICE,0,price-_Point*50); }
   ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
}

void DrawStrategyText(datetime t, double price, int stratID, bool isBuy)
{
   if(!InpShowStratOnChart) return;
   SignalInfo s = GetSignalDetail(stratID);
   string nm = PrefixStrat + TimeToString(t);
   if(ObjectFind(0, nm) >= 0) return;
   ObjectCreate(0, nm, OBJ_TEXT, 0, t, price);
   ObjectSetString(0,  nm, OBJPROP_TEXT,  (isBuy?"▲ ":"▼ ")+s.name);
   ObjectSetInteger(0, nm, OBJPROP_FONTSIZE, 9);
   ObjectSetString(0,  nm, OBJPROP_FONT,  "Arial Black");
   ObjectSetInteger(0, nm, OBJPROP_COLOR, s.cl);
   double offset = price * 0.005;
   if(isBuy) { ObjectSetInteger(0,nm,OBJPROP_ANCHOR,ANCHOR_TOP);    ObjectSetDouble(0,nm,OBJPROP_PRICE,0,price-offset); }
   else      { ObjectSetInteger(0,nm,OBJPROP_ANCHOR,ANCHOR_BOTTOM); ObjectSetDouble(0,nm,OBJPROP_PRICE,0,price+offset); }
   ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
}

void DrawDivLine(datetime t1, double p1, datetime t2, double p2, color clr, string type)
{
   string nm = PrefixDiv + TimeToString(t2) + "_" + type;
   if(ObjectFind(0, nm) >= 0) return;
   ObjectCreate(0, nm, OBJ_TREND, 0, t1, p1, t2, p2);
   ObjectSetInteger(0, nm, OBJPROP_COLOR,     clr);
   ObjectSetInteger(0, nm, OBJPROP_STYLE,     STYLE_SOLID);
   ObjectSetInteger(0, nm, OBJPROP_WIDTH,     2);
   ObjectSetInteger(0, nm, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, nm, OBJPROP_SELECTABLE,false);
}

//============================================================
//  DASHBOARD
//============================================================
color InpNeutralColor() { return C'130,130,130'; }

void DL(string name, int x, int y, string text, int fs, color clr)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE,  x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE,  y);
   ObjectSetInteger(0, name, OBJPROP_CORNER,     CORNER_LEFT_UPPER);
   ObjectSetString(0,  name, OBJPROP_TEXT,       text);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE,   fs);
   ObjectSetString(0,  name, OBJPROP_FONT,       "Arial");
   ObjectSetInteger(0, name, OBJPROP_COLOR,      clr);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_BACK,       false);
}

void DashSet(string key, string val, color clr)
{
   if(!InpShowDashboard) return;
   string nm = DPFX+"MV_"+key;
   ObjectSetString(0,  nm, OBJPROP_TEXT,  val);
   ObjectSetInteger(0, nm, OBJPROP_COLOR, clr);
}

void BuildDashboard()
{
   ObjectsDeleteAll(0, DPFX);
   int x=InpDashX, y=InpDashY, fs=InpDashFontSize, w=320, h=400;

   string pn = DPFX+"PANEL";
   ObjectCreate(0, pn, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0,pn,OBJPROP_XDISTANCE,  x);
   ObjectSetInteger(0,pn,OBJPROP_YDISTANCE,  y);
   ObjectSetInteger(0,pn,OBJPROP_XSIZE,      w);
   ObjectSetInteger(0,pn,OBJPROP_YSIZE,      h);
   ObjectSetInteger(0,pn,OBJPROP_BGCOLOR,    InpDashBgColor);
   ObjectSetInteger(0,pn,OBJPROP_BORDER_COLOR,InpDashBorderColor);
   ObjectSetInteger(0,pn,OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0,pn,OBJPROP_CORNER,     CORNER_LEFT_UPPER);
   ObjectSetInteger(0,pn,OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0,pn,OBJPROP_BACK,       false);

   int lx=x+10, ly=y+8;
   DL(DPFX+"TITLE",  lx, ly, "◈ DEEP ORDER FLOW & CVD  v2.1", fs+1, clrWhite); ly+=18;
   DL(DPFX+"SEP0",   lx, ly, "═══════════════════════════════", fs-1, InpDashBorderColor); ly+=14;

   // Module Status
   DL(DPFX+"HDR_MOD",lx, ly, "[ MODULE STATUS ]", fs-1, C'80,120,200'); ly+=13;
   string mods[] = {"Footprint","CVD","VolProfile","FVG","Signal"};
   for(int r = 0; r < ArraySize(mods); r++)
   {
      DL(DPFX+"ML_"+mods[r], lx,    ly, mods[r]+":", fs, InpNeutralColor());
      DL(DPFX+"MV_"+mods[r], lx+95, ly, "...", fs, clrWhite);
      ly += 15;
   }
   DL(DPFX+"SEP1",lx,ly,"───────────────────────────────",fs-1,InpDashBorderColor); ly+=12;

   // Analytics
   DL(DPFX+"HDR_ANA",lx,ly,"[ ANALYTICS ]",fs-1,C'80,120,200'); ly+=13;
   string ana[]  = {"Absorption","Bias","Delta","CVDMom"};
   string anaL[] = {"Absorption:","Market Bias:","Last Delta:","CVD Moment:"};
   for(int r = 0; r < ArraySize(ana); r++)
   {
      DL(DPFX+"AL_"+ana[r], lx,    ly, anaL[r], fs, InpNeutralColor());
      DL(DPFX+"AV_"+ana[r], lx+95, ly, "...", fs, clrWhite);
      ly += 15;
   }
   DL(DPFX+"SEP2",lx,ly,"───────────────────────────────",fs-1,InpDashBorderColor); ly+=12;

   // VP Key Levels
   DL(DPFX+"HDR_VP",lx,ly,"[ VP KEY LEVELS ]",fs-1,C'80,120,200'); ly+=13;
   string vpk[]   = {"POC","VAH","VAL"};
   string vpLbl[] = {"POC:","VAH:","VAL:"};
   color  vpClr[] = {clrYellow, C'100,160,230', C'100,160,230'};
   for(int r = 0; r < ArraySize(vpk); r++)
   {
      DL(DPFX+"VL_"+vpk[r], lx,    ly, vpLbl[r], fs, InpNeutralColor());
      DL(DPFX+"VV_"+vpk[r], lx+95, ly, "---", fs, vpClr[r]);
      ly += 15;
   }
   DL(DPFX+"SEP3",lx,ly,"───────────────────────────────",fs-1,InpDashBorderColor); ly+=12;

   // Stats
   DL(DPFX+"HDR_STAT",lx,ly,"[ STATS ]",fs-1,C'80,120,200'); ly+=13;
   DL(DPFX+"SL_FVG", lx,    ly, "Active FVGs:",   fs, InpNeutralColor());
   DL(DPFX+"SV_FVG", lx+95, ly, "0",              fs, clrWhite); ly+=15;
   DL(DPFX+"SL_SIG", lx,    ly, "Strat Signals:", fs, InpNeutralColor());
   DL(DPFX+"SV_SIG", lx+95, ly, "0",              fs, clrWhite); ly+=15;
   DL(DPFX+"SL_VOL", lx,    ly, "Vol Type:",      fs, InpNeutralColor());
   DL(DPFX+"SV_VOL", lx+95, ly, "---",            fs, clrWhite); ly+=15;

   // [FIX] Alert Status row
   DL(DPFX+"SL_ALT", lx,    ly, "Alerts:",        fs, InpNeutralColor());
   DL(DPFX+"SV_ALT", lx+95, ly, "---",            fs, clrWhite); ly+=15;

   DL(DPFX+"SEP4",   lx, ly, "───────────────────────────────", fs-1, InpDashBorderColor); ly+=12;

   // Current Bar Status
   DL(DPFX+"HDR_CUR",lx, ly, "[ CURRENT BAR STATUS ]", fs-1, C'200,160,40'); ly+=13;
   DL(DPFX+"CL_NAME", lx,    ly, "Setup:",      fs, InpNeutralColor());
   DL(DPFX+"CV_NAME", lx+70, ly, "Scanning...", fs, clrWhite); ly+=15;
   DL(DPFX+"CL_ACT",  lx,    ly, "Action:",     fs, InpNeutralColor());
   DL(DPFX+"CV_ACT",  lx+70, ly, "-",           fs, clrWhite); ly+=15;
   DL(DPFX+"CL_SIG",  lx,    ly, "Bar Signals:",fs, InpNeutralColor());
   DL(DPFX+"CV_SIG",  lx+70, ly, "-",           fs, clrWhite); ly+=15;
   DL(DPFX+"CL_TIME", lx,    ly, "Last Signal:",fs, InpNeutralColor());
   DL(DPFX+"CV_TIME", lx+70, ly, "-",           fs, clrWhite); ly+=15;
   DL(DPFX+"CL_POS",  lx,    ly, "Price Zone:", fs, InpNeutralColor());
   DL(DPFX+"CV_POS",  lx+70, ly, "-",           fs, clrWhite); ly+=18;

   DL(DPFX+"FOOTER",  lx, ly, "v2.1 | Alert Fix | DOF & CVD", fs-2, C'60,60,100');

   ObjectSetInteger(0, DPFX+"PANEL", OBJPROP_YSIZE, ly - y + 8);
}

void UpdateDashboardStats(int total, const double &close[], const long &tvol[],
                          const long &rvol[], const datetime &time[], bool useReal)
{
   if(!InpShowDashboard) return;
   int last = total - 1;
   if(last < 1) return;

   double cvdNow  = BufferCVD[last];
   double cvdPrev = (last >= InpCVDPeriod) ? BufferCVD[last-InpCVDPeriod] : 0;
   double cvdMom  = cvdNow - cvdPrev;
   DashSet("CVD", StringFormat("%.1f (%+.1f)", cvdNow, cvdMom),
           cvdMom > 0 ? InpBullColor : InpBearColor);

   double delta = BufferDelta[last];
   double vol   = BufferVol[last];
   double avgV  = 0;
   for(int k = 1; k <= MathMin(20, last); k++) avgV += BufferVol[last-k];
   avgV /= 20.0; if(avgV <= 0) avgV = 1;

   double absScore = 0;
   double range = iHigh(_Symbol,_Period,0) - iLow(_Symbol,_Period,0);
   if(range > 0 && vol > avgV * InpVolMultiplier)
   {
      double priceDir = close[last] - (close[last-1]);
      if((priceDir > 0 && delta < 0) || (priceDir < 0 && delta > 0))
         absScore = MathAbs(delta) / vol * 100.0;
   }
   ObjectSetString(0,  DPFX+"AV_Absorption", OBJPROP_TEXT,  StringFormat("%.1f%%", absScore));
   ObjectSetInteger(0, DPFX+"AV_Absorption", OBJPROP_COLOR, absScore > 50 ? clrYellow : clrWhite);

   bool priceUp = close[last] > close[last-1];
   bool cvdUp   = cvdMom > 0;
   string bias; color biasC;
   if(cvdUp && priceUp)        { bias="BULLISH ↑"; biasC=InpBullColor; }
   else if(!cvdUp && !priceUp) { bias="BEARISH ↓"; biasC=InpBearColor; }
   else                         { bias="NEUTRAL →"; biasC=InpNeutralColor(); }
   ObjectSetString(0,  DPFX+"AV_Bias", OBJPROP_TEXT,  bias);
   ObjectSetInteger(0, DPFX+"AV_Bias", OBJPROP_COLOR, biasC);

   ObjectSetString(0,  DPFX+"AV_Delta",  OBJPROP_TEXT,  StringFormat("%+.1f", delta));
   ObjectSetInteger(0, DPFX+"AV_Delta",  OBJPROP_COLOR, delta>0?InpBullColor:InpBearColor);
   ObjectSetString(0,  DPFX+"AV_CVDMom",OBJPROP_TEXT,  StringFormat("%+.1f", cvdMom));
   ObjectSetInteger(0, DPFX+"AV_CVDMom",OBJPROP_COLOR, cvdMom>0?InpBullColor:InpBearColor);

   ObjectSetString(0,DPFX+"VV_POC",OBJPROP_TEXT, DoubleToString(g_POC,_Digits-1));
   ObjectSetString(0,DPFX+"VV_VAH",OBJPROP_TEXT, DoubleToString(g_VAH,_Digits-1));
   ObjectSetString(0,DPFX+"VV_VAL",OBJPROP_TEXT, DoubleToString(g_VAL,_Digits-1));

   int cnt = 0;
   for(int k = 0; k < ObjectsTotal(0,-1,-1); k++)
   {
      string nm = ObjectName(0,k);
      if(StringFind(nm,PrefixStrat)==0) cnt++;
   }
   ObjectSetString(0, DPFX+"SV_SIG", OBJPROP_TEXT, IntegerToString(cnt));
   ObjectSetString(0, DPFX+"SV_VOL", OBJPROP_TEXT, useReal ? "Real Vol ✓" : "Tick Vol");
   ObjectSetInteger(0,DPFX+"SV_VOL", OBJPROP_COLOR,useReal ? InpBullColor : clrYellow);

   // [FIX] Alert status แสดงใน dashboard
   string altStatus = "";
   color  altClr    = InpNeutralColor();
   if(InpUseNotification && InpUseAlert)        { altStatus = "Push+Popup ON"; altClr = clrLime; }
   else if(InpUseNotification)                  { altStatus = "Push Notif ON";  altClr = clrLime; }
   else if(InpUseAlert)                         { altStatus = "Popup Alert ON"; altClr = clrYellow; }
   else                                          { altStatus = "ALL OFF";        altClr = clrRed; }
   ObjectSetString(0,  DPFX+"SV_ALT", OBJPROP_TEXT,  altStatus);
   ObjectSetInteger(0, DPFX+"SV_ALT", OBJPROP_COLOR, altClr);

   // Current Status
   ObjectSetString(0,  DPFX+"CV_NAME", OBJPROP_TEXT,  g_CurStatusName);
   ObjectSetInteger(0, DPFX+"CV_NAME", OBJPROP_COLOR, g_CurStatusColor);
   ObjectSetString(0,  DPFX+"CV_ACT",  OBJPROP_TEXT,  g_CurStatusAction);
   ObjectSetInteger(0, DPFX+"CV_ACT",  OBJPROP_COLOR, g_CurStatusColor);
   ObjectSetString(0,  DPFX+"CV_SIG",  OBJPROP_TEXT,  g_CurBarSignals);
   ObjectSetInteger(0, DPFX+"CV_SIG",  OBJPROP_COLOR, clrWhite);
   ObjectSetString(0,  DPFX+"CV_TIME", OBJPROP_TEXT,  g_CurStatusTime);
   ObjectSetInteger(0, DPFX+"CV_TIME", OBJPROP_COLOR, C'150,150,150');

   string priceZone = "-";
   color  zoneClr   = C'130,130,130';
   double curPrice  = close[last];
   if(g_POC > 0)
   {
      double proximity = curPrice * 0.002;
      if(MathAbs(curPrice - g_POC) < proximity * 0.5)
         { priceZone = "AT POC";            zoneClr = clrYellow; }
      else if(MathAbs(curPrice - g_VAH) < proximity)
         { priceZone = "AT VAH (Resist)";   zoneClr = InpBearColor; }
      else if(MathAbs(curPrice - g_VAL) < proximity)
         { priceZone = "AT VAL (Support)";  zoneClr = InpBullColor; }
      else if(curPrice > g_VAH)
         { priceZone = "ABOVE VA";          zoneClr = InpBullColor; }
      else if(curPrice < g_VAL)
         { priceZone = "BELOW VA";          zoneClr = InpBearColor; }
      else if(curPrice > g_POC)
         { priceZone = "VA (Above POC)";    zoneClr = C'100,200,100'; }
      else
         { priceZone = "VA (Below POC)";    zoneClr = C'200,100,100'; }
   }
   ObjectSetString(0,  DPFX+"CV_POS",  OBJPROP_TEXT,  priceZone);
   ObjectSetInteger(0, DPFX+"CV_POS",  OBJPROP_COLOR, zoneClr);
}
//+------------------------------------------------------------------+