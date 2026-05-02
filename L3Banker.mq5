// +------------------------------------------------------------------+
// |   L3_Banker_Fund_Flow_Trend_Oscillator_v6.mq5                    |
// |   v6: Aligned with TV original logic (white/blue candle, levels) |
// +------------------------------------------------------------------+
#property copyright "Blackcat / Fixed by Gemini / v6 patch"
#property version   "6.01"
#property description "L3 Banker Fund Flow v6.01 - TV-aligned, No-Repaint, WSA seed fix"
#property indicator_separate_window
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_buffers 10
#property indicator_plots   1

//--- Plot Settings
#property indicator_type1   DRAW_COLOR_CANDLES
#property indicator_label1  "Banker Flow"
#property indicator_color1  clrYellow, clrLime, clrWhite, clrRed, clrDodgerBlue, clrOrange
#property indicator_width1  2

//--- Indicator Settings
input int    Low_Period      = 27;   // RSI Base Period
input int    WSA_Period      = 5;    // WSA1 Length
input int    WSA_Weight      = 1;    // WSA1 Weight (WSA2 weight is always 1 per original)
input int    WSA2_Period     = 3;    // WSA2 Length
input int    HH_LL_Period    = 34;   // Bull/Bear Period
input int    EMA_Period      = 13;   // Bull/Bear EMA

//--- Signal Filters
input double Sell_Level_Thresh  = 80.0;  // Overbought level
input double Buy_Level_Thresh   = 25.0;  // Oversold level (TV original = 25, not 20)
input bool   Use_Candle_Confirm = true;  // Candle confirmation
input bool   Use_Slope_Filter   = true;  // Slope filter
input double Slope_Threshold    = 0.1;   // Slope threshold
input double Gap_Threshold      = 1.0;   // Gap confirm threshold

//--- Buffers
double PlotOpen[], PlotHigh[], PlotLow[], PlotClose[], PlotColor[];
double Val_RSI[], Val_WSA1[], Val_WSA2[], FundFlowTrend[], BullBearLine[];

// +------------------------------------------------------------------+
int OnInit()
{
   SetIndexBuffer(0, PlotOpen,  INDICATOR_DATA);
   SetIndexBuffer(1, PlotHigh,  INDICATOR_DATA);
   SetIndexBuffer(2, PlotLow,   INDICATOR_DATA);
   SetIndexBuffer(3, PlotClose, INDICATOR_DATA);
   SetIndexBuffer(4, PlotColor, INDICATOR_COLOR_INDEX);

   SetIndexBuffer(5, Val_RSI,       INDICATOR_CALCULATIONS);
   SetIndexBuffer(6, Val_WSA1,      INDICATOR_CALCULATIONS);
   SetIndexBuffer(7, Val_WSA2,      INDICATOR_CALCULATIONS);
   SetIndexBuffer(8, FundFlowTrend, INDICATOR_CALCULATIONS);
   SetIndexBuffer(9, BullBearLine,  INDICATOR_CALCULATIONS);

   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);

   IndicatorSetInteger(INDICATOR_LEVELS, 4);
   IndicatorSetDouble(INDICATOR_LEVELVALUE, 0, Buy_Level_Thresh);
   IndicatorSetDouble(INDICATOR_LEVELVALUE, 1, Sell_Level_Thresh);
   IndicatorSetDouble(INDICATOR_LEVELVALUE, 2, 10);   // weak_threshold (TV original)
   IndicatorSetDouble(INDICATOR_LEVELVALUE, 3, 90);   // strong_threshold

   return(INIT_SUCCEEDED);
}

// +------------------------------------------------------------------+
double GetLowest(const double &arr[], int idx, int len) {
   if(idx < len-1) return arr[idx];
   double val = arr[idx];
   for(int i=1; i<len; i++) val = MathMin(val, arr[idx-i]);
   return val;
}

double GetHighest(const double &arr[], int idx, int len) {
   if(idx < len-1) return arr[idx];
   double val = arr[idx];
   for(int i=1; i<len; i++) val = MathMax(val, arr[idx-i]);
   return val;
}

// +------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   if(rates_total < MathMax(Low_Period, HH_LL_Period) + 3) return 0;

   int start = prev_calculated - 1;
   if(start < 0) start = 0;

   int limit = MathMax(Low_Period, HH_LL_Period);
   if(start < limit)
   {
      start = limit;
      for(int k=0; k<start; k++) {
         PlotOpen[k]  = EMPTY_VALUE; PlotHigh[k]  = EMPTY_VALUE;
         PlotLow[k]   = EMPTY_VALUE; PlotClose[k] = EMPTY_VALUE;
         PlotColor[k] = EMPTY_VALUE;
      }
   }

   for(int i = start; i < rates_total; i++)
   {
      //--- Core Calculation
      double ll27 = GetLowest(low,  i, Low_Period);
      double hh27 = GetHighest(high, i, Low_Period);
      double div  = hh27 - ll27;
      Val_RSI[i] = (div > 0.0) ? (close[i] - ll27) / div * 100.0 : ((i>limit) ? Val_RSI[i-1] : 50.0);

      double prevWSA1 = (i>limit) ? Val_WSA1[i-1] : Val_RSI[i];
      Val_WSA1[i] = (Val_RSI[i] * WSA_Weight + prevWSA1 * (WSA_Period - WSA_Weight)) / WSA_Period;

      // WSA2 weight locked to 1 per TV original: WSA(WSA1, 3, 1)
      double prevWSA2 = (i>limit) ? Val_WSA2[i-1] : Val_WSA1[i];
      Val_WSA2[i] = (Val_WSA1[i] * 1 + prevWSA2 * (WSA2_Period - 1)) / (double)WSA2_Period;

      FundFlowTrend[i] = (3.0*Val_WSA1[i] - 2.0*Val_WSA2[i] - 50.0) * 1.032 + 50.0;

      double typical = (2.0*close[i] + high[i] + low[i] + open[i]) / 5.0;
      double ll34    = GetLowest(low,  i, HH_LL_Period);
      double hh34    = GetHighest(high, i, HH_LL_Period);
      double div34   = hh34 - ll34;
      double rawBullBear = (div34 > 0.0) ? (typical - ll34) / div34 * 100.0 : 50.0;

      double alpha  = 2.0 / (EMA_Period + 1.0);
      double prevBB = (i>limit) ? BullBearLine[i-1] : rawBullBear;
      BullBearLine[i] = rawBullBear * alpha + prevBB * (1.0 - alpha);

      //--- Signal Logic v6: No-Repaint (use confirmed bars i-1 and i-2)
      bool buySignal  = false;
      bool sellSignal = false;

      if(i > 2) {
         bool crossUp   = (FundFlowTrend[i-2] <= BullBearLine[i-2] && FundFlowTrend[i-1] > BullBearLine[i-1]);
         bool crossDown = (FundFlowTrend[i-2] >= BullBearLine[i-2] && FundFlowTrend[i-1] < BullBearLine[i-1]);

         bool inZoneBuy     = (BullBearLine[i-1]  < Buy_Level_Thresh);
         bool inFFTZoneBuy  = (FundFlowTrend[i-1] < Buy_Level_Thresh);
         bool inZoneSell    = (BullBearLine[i-1]  > Sell_Level_Thresh);
         bool inFFTZoneSell = (FundFlowTrend[i-1] > Sell_Level_Thresh);

         bool candleBuy  = (!Use_Candle_Confirm) || (close[i-1] > open[i-1]);
         bool candleSell = (!Use_Candle_Confirm) || (close[i-1] < open[i-1]);

         bool slopeAllowsBuy  = true;
         bool slopeAllowsSell = true;
         if(Use_Slope_Filter) {
            double slope = BullBearLine[i-1] - BullBearLine[i-2];
            if(slope >  Slope_Threshold) slopeAllowsSell = false;
            if(slope < -Slope_Threshold) slopeAllowsBuy  = false;
         }

         bool gapSellConfirm = (BullBearLine[i-1] - FundFlowTrend[i-1]) > Gap_Threshold;
         bool gapBuyConfirm  = (FundFlowTrend[i-1] - BullBearLine[i-1]) > Gap_Threshold;

         buySignal  = (crossUp   && inZoneBuy  && inFFTZoneBuy  && candleBuy  && slopeAllowsBuy  && gapBuyConfirm);
         sellSignal = (crossDown && inZoneSell && inFFTZoneSell && candleSell && slopeAllowsSell && gapSellConfirm);
      }

      //--- Rendering (TV-aligned color logic)
      int    colorIdx = 4;
      double cOpen=0, cClose=0, cHigh=0, cLow=0;

      if(buySignal) {
         // Yellow: banker entry signal
         colorIdx = 0;
         cOpen=0; cClose=50; cLow=0; cHigh=50;
      }
      else if(sellSignal) {
         // Orange: banker exit signal (v4+ addition)
         colorIdx = 5;
         cOpen=100; cClose=50; cLow=50; cHigh=100;
      }
      else {
         double val1 = FundFlowTrend[i];
         double val2 = BullBearLine[i];
         double fftPrev = (i>0) ? FundFlowTrend[i-1] : val1;

         // TV original: white = FFT dropped >5% from previous bar (weakening)
         bool isWeakening = (val1 < fftPrev * 0.95);
         // TV original: blue = FFT < BBL AND FFT > 95% of prev (bearish but rebounding)
         bool isRebound   = (val1 < val2) && (val1 > fftPrev * 0.95);

         if(val1 > val2) {
            colorIdx = isWeakening ? 2 : 1;  // White (weakening) or Lime (strong bull)
         } else {
            colorIdx = isRebound ? 4 : 3;    // Blue (rebound) or Red (bear)
         }
         cOpen  = val1; cClose = val2;
         cHigh  = MathMax(cOpen, cClose);
         cLow   = MathMin(cOpen, cClose);
      }

      PlotOpen[i]  = cOpen;
      PlotHigh[i]  = cHigh;
      PlotLow[i]   = cLow;
      PlotClose[i] = cClose;
      PlotColor[i] = (double)colorIdx;
   }

   return(rates_total);
}