//+------------------------------------------------------------------+
//|                         GoldDXY_Hull_OFA.mq5                    |
//|          LuxAlgo Gold vs DXY Mismatch  v8.11                    |
//|     + Hull Suite Trend Line (Main Chart)                        |
//|     + OFA Order Flow Zigzag (Main Chart)                        |
//|     + Hull & OFA Alerts / Push Notifications                    |
//|                                                                  |
//|  Sub-window  : DXY real price line + DXY Trendlines S1/S2       |
//|  Main window : BUY/SELL arrows + Gold TL + Hull Line + OFA Zig  |
//|  Dashboard   : Step-by-Step Pipeline (Main window top-left)     |
//|                                                                  |
//|  FIXES v8.01:                                                    |
//|  [1] SELL TP คำนวณจาก close_price ไม่ใช่ bh[0]                |
//|  [2] Hull Cleanup ใช้ ObjectsDeleteAll() ตอน full recalc        |
//|  [3] Pre-load Gold/DXY arrays ก่อน loop แทน GetSeries() ใน loop|
//|  [4] OFA incremental update ข้าม full sort บน tick ปกติ        |
//|  [5] Hull Alert ยิงบน Bar[1] confirmed ไม่ใช่ Bar[0] live       |
//|  FIXES v8.02:                                                    |
//|  [6] เพิ่ม input InpShowDashboard (default=false)               |
//|      เปิด/ปิด Dashboard Pipeline ได้จาก Indicator Properties    |
//|  FIXES v8.03:                                                    |
//|  [7] Arrow/Buffer desync: restore buffer จาก arrow ที่มีอยู่   |
//|  [8] last_signal_bar restore จาก arrow objects ใน incremental   |
//|  [9] close_price ใช้ allGold[offset] consistent กับ GoldOkFor   |
//|  FIXES v8.04:                                                    |
//|  [10] Arrow หายเมื่อ reload: start loop ครอบ InpArrowPoints bars|
//|  [11] Arrow restore ใช้ ObjectGetDouble แทน buffer check        |
//|  [12] OFA filter fallback เมื่อ OFA ยังไม่มีข้อมูล (ofaTrend=0)|
//|  FIXES v8.05:                                                    |
//|  [13] เพิ่ม Signal Log: Print รายละเอียด BUY/SELL ใน Journal    |
//|       เปิด/ปิดด้วย InpSignalLog และ InpSignalLogVerbose         |
//|  FIXES v8.07:                                                    |
//|  [17] Incremental merge: copy swing เก่า [0..keepCount-1] เป็น  |
//|       GDX_Fractal แล้ว append fractal ใหม่ ก่อน sort+merge     |
//|       แทนการทิ้ง swing เก่าทั้งหมด (root cause ของ desync)      |
//|  [18] scan_start ขยายจาก fp*2 เป็น fp*3 เพื่อ overlap ปลอดภัย  |
//|  [19] เงื่อนไข early-return ปรับให้ตรงกับ scan_start ใหม่       |
//|  FIXES v8.08: Anti-FalseSignal (End-of-Swing Protection)        |
//|  [20] SwingProgressFilter: ตรวจ % progress ของ live swing       |
//|       ถ้าราคาไปแล้วเกิน InpMaxSwingProgress% (default 75%)      |
//|       ของ magnitude swing ปัจจุบัน → block signal               |
//|       (ป้องกันลูกศรที่เกิดท้าย swing ก่อนกลับตัว)               |
//|  [21] SwingHighLowRange: คำนวณระยะ High-Low ของ swing ปัจจุบัน  |
//|       เทียบกับ swing ก่อนหน้า (Swing Range Ratio)               |
//|       แสดงใน Dashboard: "SwProg", "SwRng", "PrevRng"            |
//|  [22] VolumeMomentumGuard: ตรวจ velocity ratio ของ live swing   |
//|       ถ้าเร็วกว่าเฉลี่ย swing ก่อน > InpMaxVelRatio → อาจ       |
//|       exhaustion → เพิ่มน้ำหนัก warning ใน dashboard           |
//|  FIXES v8.09: Dual-Period OFA (p26 Fast + p50 Slow AND filter)  |
//|  [23] เพิ่ม InpOFA_FractalPeriod2 (default=50, slow OFA)        |
//|       globals แยก: gdx_swings2[], gdx_swingCount2,              |
//|       gdx_LastConfirmedCount2, gdx_LastBarTime2                 |
//|  [24] GdxUpdateOFACore2(): scan/merge แยกจาก p26 อิสระ 100%   |
//|       GdxGetOFATrendAtBar2(): คืนทิศทาง slow OFA ที่ bar ใดก็ได้|
//|  [25] Signal AND filter: ทั้ง fast OFA (p26) และ slow OFA (p50) |
//|       ต้องบอกทิศทางเดียวกัน จึงจะผ่าน                          |
//|       → block signal ที่เป็นแค่ retracement ใน trend ใหญ่       |
//|  [26] Dashboard Step 7 แสดง p26/p50 direction + AND result      |
//|  FIXES v8.11: MACD Momentum Direction Filter                    |
//|  [30] เพิ่มเงื่อนไข MACD Line momentum:                         |
//|       BUY: MACD[0] > MACD[1] (แท่งปัจจุบันสูงกว่าแท่งก่อน)    |
//|       SELL: MACD[0] < MACD[1] (แท่งปัจจุบันต่ำกว่าแท่งก่อน)  |
//|       เพื่อให้ลูกศรแสดงเฉพาะเมื่อ MACD กำลังวิ่งขึ้น/ลง        |
//|       ป้องกันสัญญาณที่ MACD cross แล้ว momentum ชะลอ            |
//|                                                                  |
//|  [27] GdxUpdateLiveSwing2(): p50 มี live tip เลื่อนตาม High/Low  |
//|       ปัจจุบันเหมือน p26 — เรียกทุก tick หลัง confirmed update  |
//|  [28] GdxGetOFATrendAtBar2() ใช้ live tip ของ p50 ในการตัดสิน   |
//|       ทิศทาง → ไม่ block BUY เมื่อราคาทำ new High เกิน p50      |
//|       confirmed swing แล้ว (แก้ปัญหา MISMATCH block signal ดีๆ) |
//|  [29] GdxDrawOFALegs2() อัปเดต live leg แบบ realtime ทุก tick   |
//|       เส้น live = STYLE_DOT (เคลื่อนไหว), confirmed = STYLE_DASH |
//|                                                                  |
//|  Buffer 0 : DXY Price      (Sub-window line)                    |
//|  Buffer 1 : BUY Price      Gold Close @ BUY bar  / EMPTY=none   |
//|  Buffer 2 : SELL Price     Gold Close @ SELL bar / EMPTY=none   |
//|  Buffer 3 : Signal State   1.0=BUY / -1.0=SELL / 0.0=none      |
//|  Buffer 4 : SL Price       ATR-based SL / EMPTY=none            |
//|  Buffer 5 : TP Price       ATR-based TP / EMPTY=none            |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026"
#property version   "8.11"
#property indicator_separate_window   // Sub-window สำหรับ DXY
#property indicator_buffers 6
#property indicator_plots   6

// ── Buffer 0: DXY real price line (Sub-window) ──
#property indicator_label1  "DXY Price"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLime
#property indicator_width1  2
#property indicator_style1  STYLE_SOLID

// ── Buffers 1-5: Data/Signal (DRAW_NONE) ──
#property indicator_label2  "BUY Price"
#property indicator_type2   DRAW_NONE
#property indicator_label3  "SELL Price"
#property indicator_type3   DRAW_NONE
#property indicator_label4  "Signal (1=BUY,-1=SELL)"
#property indicator_type4   DRAW_NONE
#property indicator_label5  "SL Price"
#property indicator_type5   DRAW_NONE
#property indicator_label6  "TP Price"
#property indicator_type6   DRAW_NONE

//+------------------------------------------------------------------+
//| INPUTS                                                           |
//+------------------------------------------------------------------+
//--- Core
input string InpDXY_Symbol    = "DXYm";  // DXY Symbol
input int    InpZPeriod       = 14;
input int    InpMacroBars     = 30;
input int    InpRecentBars    = 10;
input int    InpTriggerBars   = 3;
input int    InpGoldCheckBars = 4;
input double InpGoldZLimit    = 1.5;
input double InpMomentumRatio = 0.6;
input int    InpMinBarGap     = 5;
input int    InpArrowSize     = 3;
input int    InpArrowPoints   = 1500;

//--- Dashboard
input bool   InpShowDashboard = false;   // Show Dashboard (Step-by-Step Pipeline)
input int    InpDashX         = 15;
input int    InpDashY         = 20;

input bool   InpSendAlert     = false;
input bool   InpSendPush      = true;

//--- Signal Log
input group "=== Signal Log Settings ==="
input bool   InpSignalLog          = false;   // เปิด/ปิด Log เมื่อเกิดสัญญาณ BUY/SELL
input bool   InpSignalLogVerbose   = false;   // แสดงรายละเอียด Filter แต่ละ Step

//--- ATR SL/TP
input int    InpATR_Period    = 14;
input double InpATR_SL_Multi  = 1.5;
input double InpATR_TP_Multi  = 3.0;

//--- MACD Filter
input bool   InpUseMACDFilter  = true;
input int    InpMACD_Fast      = 12;
input int    InpMACD_Slow      = 26;
input int    InpMACD_Signal    = 9;
input double InpMACD_MinGap    = 0.0;

//--- Trendlines Step 1
input bool            InpShowTL_Step1    = true;
input color           InpColorTL_S1_Gold = clrGold;
input color           InpColorTL_S1_DXY  = clrAqua;
input int             InpWidthTL_Step1   = 2;
input ENUM_LINE_STYLE InpStyleTL_S1      = STYLE_SOLID;

//--- Trendlines Step 2
input bool            InpShowTL_Step2    = true;
input color           InpColorTL_S2_Gold = clrYellow;
input color           InpColorTL_S2_DXY  = clrSkyBlue;
input int             InpWidthTL_Step2   = 1;
input ENUM_LINE_STYLE InpStyleTL_S2      = STYLE_DOT;

//--- Hull Suite
input group "=== Hull Suite Settings ==="
input int    InpHL_Period          = 50;
input double InpHL_Divisor         = 2.0;
input ENUM_APPLIED_PRICE InpHL_Price = PRICE_CLOSE;
input bool   InpHL_ShowLine        = true;
input color  InpHL_UpColor         = clrMediumSeaGreen;
input color  InpHL_DownColor       = clrOrangeRed;
input int    InpHL_LineWidth        = 2;
//--- Hull Alerts
input bool   InpHL_SendAlert       = false;   // Alert เมื่อ Hull เปลี่ยนทิศ
input bool   InpHL_SendNotify      = false;  // Push เมื่อ Hull เปลี่ยนทิศ

//--- OFA Order Flow
input group "=== OFA Order Flow Settings ==="
input bool   InpOFA_AggressiveFractal   = false;
input int    InpOFA_FractalPeriod       = 26;    // Fast OFA period (entry timing)
input int    InpOFA_FractalPeriod2      = 50;    // Slow OFA period (trend context, 0=off)
input bool   InpOFA_ShowZigzag2         = true;  // แสดง Slow OFA zigzag บนกราฟ
input color  InpOFA_SlowBullColour      = clrDeepSkyBlue;  // Slow OFA Bull leg สี (ต่างจาก p26)
input color  InpOFA_SlowBearColour      = clrTomato;       // Slow OFA Bear leg สี
input int    InpOFA_SlowLineWidth       = 3;     // Slow OFA line width (หนากว่า p26=2)
input bool   InpOFA_DisplayCurrentSwing = false;
input color  InpOFA_BullishColour       = clrDodgerBlue;
input color  InpOFA_BearishColour       = clrOrangeRed;
input bool   InpOFA_ShowZigzag          = false;
input bool   InpOFA_ShowLabels          = false;
input int    InpOFA_MaxBars          = 1000;
//--- OFA Label detail
input bool   InpOFA_IncludeVelMag       = false;
input bool   InpOFA_IncludePriceChange  = false;
input bool   InpOFA_IncludePercentChange= false;
input bool   InpOFA_IncludeBarChange    = false;
input int    InpOFA_LabelFontSize       = 9;
//--- OFA Alerts
input bool   InpOFA_SendNotification = false;   // Push เมื่อ Swing ใหม่
input bool   InpOFA_SendAlert        = false;  // Alert Popup เมื่อ Swing ใหม่
input bool   InpOFA_NotifyBullOnly      = false;
input bool   InpOFA_NotifyBearOnly      = false;
input bool   InpOFA_NotifyOnLiveSwing   = true;
input double InpOFA_NotifyUpdatePts     = 5.0;
input double InpOFA_NotifyUpdatePct     = 50.0;

//--- Session VP Monitor (POC/VAH/VAL)
input group "=== Session VP Monitor (POC/VAH/VAL) ==="
input bool   InpVpSession             = true;    // เปิดใช้ Session VP Monitor
input int    InpVpRowSize             = 100;     // จำนวน rows VP (ยิ่งมาก ยิ่ง precise)
input double InpVpValueArea           = 0.68;    // Value Area % (68% = 1 SD)
input int    InpRetestTolerancePts    = 150;     // tolerance retest ห่าง VAH/VAL (points)
input int    InpBreakoutBufferPts     = 100;     // breakout buffer เหนือ VAH / ใต้ VAL (points)
input int    InpVpConfluenceRange     = 200;     // ระยะ POC confluence Asia vs London (points)
input bool   InpVpNotifyBreakout      = true;    // แจ้งเตือน Breakout signal
input bool   InpVpNotifyRetest        = true;    // แจ้งเตือน Retest signal
input bool   InpVpNotifyConfl         = true;    // แจ้งเตือน POC Confluence signal
input bool   InpExtendNYtoAsia        = true;    // ขยายเส้น NY VP ต่อถึง Asia ถัดไป
input color  InpColorPOC_Asia         = clrDeepPink;    // สี POC Asia
input color  InpColorPOC_London       = clrDarkOrange;  // สี POC London
input color  InpColorPOC_NY           = clrDodgerBlue;  // สี POC NY
input color  InpColorVAH              = clrLime;        // สีเส้น VAH
input color  InpColorVAL              = clrOrangeRed;   // สีเส้น VAL

//--- Session Box
input group "=== Session Box (Asia / London / New York) ==="
input bool   InpShowSessionBox         = false;
input bool   InpSessionBoxAsiaEnable   = true;
input bool   InpSessionBoxLondonEnable = true;
input bool   InpSessionBoxNYEnable     = true;
input int    InpSessionBoxLookbackDays = 3;
input int    InpAsiaStartHr            = 0;
input int    InpAsiaEndHr              = 8;
input int    InpLondonStartHr          = 8;
input int    InpLondonEndHr            = 13;
input int    InpNYStartHr              = 13;
input int    InpNYEndHr                = 21;
input color  InpSessionBoxAsiaColor    = C'30,60,100';
input color  InpSessionBoxLondonColor  = C'30,90,50';
input color  InpSessionBoxNYColor      = C'100,55,20';
input bool   InpSessionBoxBorder       = true;
input int    InpSessionBoxBorderWidth  = 3;
input bool   InpSessionBoxLabel        = true;
input int    InpSessionBoxLabelSize    = 11;
input bool   InpSessionBoxShowHL       = true;
input int    InpSessionBoxHLWidth      = 2;

//+------------------------------------------------------------------+
//| BUFFERS                                                          |
//+------------------------------------------------------------------+
double BufferDXY[];
double BufferBuyPrice[];
double BufferSellPrice[];
double BufferSignal[];
double BufferSL[];
double BufferTP[];

//+------------------------------------------------------------------+
//| GLOBALS                                                          |
//+------------------------------------------------------------------+
int      g_atr_handle    = INVALID_HANDLE;
int      g_macd_handle   = INVALID_HANDLE;
int      last_signal_bar = -9999;
datetime last_alert_time = 0;
string   OBJ_PREFIX      = "GDX8_";
int      g_subwin        = -1;
bool     g_dashboardWasOn = false;   // ติดตามสถานะ dashboard เพื่อลบ label เมื่อ toggle ปิด


//+------------------------------------------------------------------+
//| SESSION VP GLOBALS                                               |
//+------------------------------------------------------------------+
struct SessionVP {
   double poc;
   double vah;
   double val;
   double sessionHigh;
   double sessionLow;
   datetime sessionStart;
   datetime sessionEnd;
   bool   isFormed;
};

enum VP_STATE { VP_WAITING, VP_BROKEN_UP, VP_BROKEN_DN, VP_RETESTING_VAH, VP_RETESTING_VAL, VP_CONFIRMED };

SessionVP VpAsia;
SessionVP VpLondon;
SessionVP VpNY;
SessionVP VpPrevNY;

VP_STATE VpStateAsia   = VP_WAITING;
VP_STATE VpStateLondon = VP_WAITING;
VP_STATE VpStateNY     = VP_WAITING;
VP_STATE VpStatePrevNY = VP_WAITING;

datetime VpLastNotifyAsia   = 0;
datetime VpLastNotifyLondon = 0;
datetime VpLastNotifyNY     = 0;
datetime VpLastNotifyConfl  = 0;
int      VpLastNotifyBar    = -1;

bool VpBreakoutNotifiedAsia      = false;
bool VpBreakoutNotifiedLondon    = false;
bool VpBreakoutNotifiedNY        = false;
bool VpBreakoutNotifiedPrevNY    = false;
bool VpRetestNotifiedAsia        = false;
bool VpRetestNotifiedLondon      = false;
bool VpRetestNotifiedNY          = false;
bool VpRetestNotifiedPrevNY      = false;

string SB_Prefix = "GDX8_SB_";

struct VP_Row {
   double priceByRow;
   double volBuy;
   double volSell;
   double volTotal;
};

string OBJ_DXY_LBL    = "GDX8_DXY_LBL";
string TL_S1_GOLD     = "GDX8_TL_S1_GOLD";
string TL_S1_DXY      = "GDX8_TL_S1_DXY";
string TL_S2_GOLD     = "GDX8_TL_S2_GOLD";
string TL_S2_DXY      = "GDX8_TL_S2_DXY";
string TL_S1_GOLD_LBL = "GDX8_TL_S1_GOLD_LBL";
string TL_S1_DXY_LBL  = "GDX8_TL_S1_DXY_LBL";
string TL_S2_GOLD_LBL = "GDX8_TL_S2_GOLD_LBL";
string TL_S2_DXY_LBL  = "GDX8_TL_S2_DXY_LBL";

//--- Hull Suite globals
double   gdx_HullValue[];   // คำนวณ internally (ไม่ใช่ indicator buffer)
double   gdx_HullTrend[];   // 1=Up, -1=Down
bool     gdx_IsHullInitialized = false;
int      gdx_LastHullTrend = 0;
datetime gdx_LastHullAlertTime = 0;

//--- OFA globals
struct GDX_SwingPoint {
   datetime time;
   double   price;
   int      bar;
   bool     isHigh;
   double   velocity;
   double   magnitude;
   double   magPct;
};
struct GDX_Fractal {
   datetime time;
   double   price;
   int      bar;
   bool     isHigh;
};
GDX_SwingPoint gdx_swings[];
int        gdx_swingCount           = 0;
int        gdx_LastConfirmedCount   = 0;
datetime   gdx_LastBarTime          = 0;
datetime   gdx_LastNotifyBullTime   = 0;
datetime   gdx_LastNotifyBearTime   = 0;
double     gdx_LastNotifyBullMag    = 0;
double     gdx_LastNotifyBearMag    = 0;
int        gdx_LastNotifyBullUpdateN= 0;
int        gdx_LastNotifyBearUpdateN= 0;

//--- Slow OFA globals (Period2 = p50, trend context)
GDX_SwingPoint gdx_swings2[];
int        gdx_swingCount2          = 0;
int        gdx_LastConfirmedCount2  = 0;
datetime   gdx_LastBarTime2         = 0;

//--- v8.12 Perf: global OHLCT arrays (incremental copy — full on new bar, 1-bar update on tick)
double   g_ohlc_open[], g_ohlc_high[], g_ohlc_low[], g_ohlc_close[];
datetime g_ohlc_time[];
int      g_ohlc_size = 0;

//+------------------------------------------------------------------+
//| Hull Suite Class                                                 |
//+------------------------------------------------------------------+
class CGdxHull {
private:
   int    m_fullPeriod, m_halfPeriod, m_sqrtPeriod, m_arraySize;
   double m_weight1, m_weight2, m_weight3;
   struct sHullArrayStruct {
      double value, value3, wsum1, wsum2, wsum3, lsum1, lsum2, lsum3;
   };
   sHullArrayStruct m_array[];
public:
   CGdxHull() : m_fullPeriod(1), m_halfPeriod(1), m_sqrtPeriod(1), m_arraySize(-1) {}
   void init(int period, double divisor) {
      m_fullPeriod  = (period  > 1 ? period  : 1);
      m_halfPeriod  = (int)(m_fullPeriod / (divisor > 1 ? divisor : 1));
      m_sqrtPeriod  = (int)MathSqrt(m_fullPeriod);
      m_arraySize   = -1;
   }
   double calculate(double value, int i, int bars) {
      if(m_arraySize < bars) {
         m_arraySize = ArrayResize(m_array, bars + 500);
         if(m_arraySize < bars) return 0;
      }
      m_array[i].value = value;
      if(i > m_fullPeriod) {
         m_array[i].wsum1 = m_array[i-1].wsum1 + value * m_halfPeriod - m_array[i-1].lsum1;
         m_array[i].lsum1 = m_array[i-1].lsum1 + value - m_array[i - m_halfPeriod].value;
         m_array[i].wsum2 = m_array[i-1].wsum2 + value * m_fullPeriod  - m_array[i-1].lsum2;
         m_array[i].lsum2 = m_array[i-1].lsum2 + value - m_array[i - m_fullPeriod].value;
      } else {
         m_array[i].wsum1 = m_array[i].wsum2 = m_array[i].lsum1 = m_array[i].lsum2 = m_weight1 = m_weight2 = 0;
         for(int k = 0, w1 = m_halfPeriod, w2 = m_fullPeriod; w2 > 0 && i >= k; k++, w1--, w2--) {
            if(w1 > 0) { m_array[i].wsum1 += m_array[i-k].value * w1; m_array[i].lsum1 += m_array[i-k].value; m_weight1 += w1; }
            m_array[i].wsum2 += m_array[i-k].value * w2; m_array[i].lsum2 += m_array[i-k].value; m_weight2 += w2;
         }
      }
      m_array[i].value3 = 2.0 * m_array[i].wsum1 / m_weight1 - m_array[i].wsum2 / m_weight2;
      if(i > m_sqrtPeriod) {
         m_array[i].wsum3 = m_array[i-1].wsum3 + m_array[i].value3 * m_sqrtPeriod - m_array[i-1].lsum3;
         m_array[i].lsum3 = m_array[i-1].lsum3 + m_array[i].value3 - m_array[i - m_sqrtPeriod].value3;
      } else {
         m_array[i].wsum3 = m_array[i].lsum3 = m_weight3 = 0;
         for(int k = 0, w3 = m_sqrtPeriod; w3 > 0 && i >= k; k++, w3--) {
            m_array[i].wsum3 += m_array[i-k].value3 * w3; m_array[i].lsum3 += m_array[i-k].value3; m_weight3 += w3;
         }
      }
      return m_array[i].wsum3 / m_weight3;
   }
};
CGdxHull gdx_HullEngine;

//+------------------------------------------------------------------+
//| OnInit                                                           |
//+------------------------------------------------------------------+
int OnInit()
{
   SetIndexBuffer(0, BufferDXY,       INDICATOR_DATA);
   SetIndexBuffer(1, BufferBuyPrice,  INDICATOR_DATA);
   SetIndexBuffer(2, BufferSellPrice, INDICATOR_DATA);
   SetIndexBuffer(3, BufferSignal,    INDICATOR_DATA);
   SetIndexBuffer(4, BufferSL,        INDICATOR_DATA);
   SetIndexBuffer(5, BufferTP,        INDICATOR_DATA);
   for(int b = 0; b < 6; b++)
      PlotIndexSetDouble(b, PLOT_EMPTY_VALUE, EMPTY_VALUE);

   IndicatorSetString(INDICATOR_SHORTNAME,
      StringFormat("GoldDXY Hull+OFA v8.11 [%s]", InpDXY_Symbol));

   if(!SymbolSelect(InpDXY_Symbol, true)) {
      Print("ERROR: ????? Symbol '", InpDXY_Symbol, "'");
      return INIT_FAILED;
   }
   g_atr_handle = iATR(_Symbol, _Period, InpATR_Period);
   if(g_atr_handle == INVALID_HANDLE) {
      Print("ERROR: Cannot create ATR handle");
      return INIT_FAILED;
   }
   g_macd_handle = iMACD(_Symbol, _Period, InpMACD_Fast, InpMACD_Slow, InpMACD_Signal, PRICE_CLOSE);
   if(g_macd_handle == INVALID_HANDLE) {
      Print("ERROR: Cannot create MACD handle");
      return INIT_FAILED;
   }

   // Allocate Hull internal arrays
   ArrayResize(gdx_HullValue, 0);
   ArrayResize(gdx_HullTrend, 0);

   last_signal_bar    = -9999;
   g_subwin           = -1;
   g_dashboardWasOn   = false;
   gdx_LastHullTrend      = 0;
   gdx_IsHullInitialized  = false;
   gdx_swingCount         = 0;
   gdx_LastConfirmedCount = 0;
   gdx_LastBarTime        = 0;
   gdx_swingCount2        = 0;
   gdx_LastConfirmedCount2= 0;
   gdx_LastBarTime2       = 0;
   g_ohlc_size            = 0;

   // FIX Bug#1: บันทึก arrow positions ก่อน CleanAll() แล้ว restore หลังจากนั้น
   // เพื่อป้องกัน arrow หายเมื่อ reload indicator
   // เก็บ bar index → (time, price, isBuy) ของ arrow ที่มีอยู่ก่อน clean
   // (ใช้ prefix scan ก่อน delete)
   // NOTE: CleanAll() ต้องทำก่อน แต่ arrow จะถูก re-draw ใน OnCalculate
   // ดังนั้นไม่ต้องทำอะไรพิเศษ — แค่อย่าให้ start loop skip bars ที่มี arrow
   CleanAll();
   Print("GoldDXY Hull+OFA v8.11 Init OK");
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   if(g_atr_handle  != INVALID_HANDLE) IndicatorRelease(g_atr_handle);
   if(g_macd_handle != INVALID_HANDLE) IndicatorRelease(g_macd_handle);
   CleanAll();
   ObjectsDeleteAll(0, "GDX8_HULL_");
   ObjectsDeleteAll(0, "GDX8_OFA_");
   ObjectsDeleteAll(0, "GDX8_OFA2_");
}

//+------------------------------------------------------------------+
//| OnCalculate                                                      |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
{
   int need = InpZPeriod + InpMacroBars + InpTriggerBars + InpGoldCheckBars + InpATR_Period + 5;
   if(rates_total < need) return 0;

   // FIX v8.07: เมื่อ reload indicator (prev_calculated<=0) ต้อง recalculate ย้อนหลัง
   // ให้ครอบคลุม InpArrowPoints bars เพื่อให้ลูกศรเก่าถูกวาดกลับมาหลัง CleanAll()
   int start;
   if(prev_calculated <= 0) {
      last_signal_bar = -9999;
      start = rates_total - InpArrowPoints;
      if(start < need) start = need;
   } else {
      // FIX Bug#2: restore last_signal_bar จาก arrow object ที่มีอยู่
      if(last_signal_bar == -9999) {
         for(int s = prev_calculated - 2; s >= 0; s--) {
            string bn = OBJ_PREFIX + "ARW_BUY_"  + IntegerToString(s);
            string sn = OBJ_PREFIX + "ARW_SELL_" + IntegerToString(s);
            if(ObjectFind(0, bn) >= 0 || ObjectFind(0, sn) >= 0) {
               last_signal_bar = s;
               break;
            }
         }
      }
      start = prev_calculated - 1;
   }

   // ── v8.12 Perf: Tick detection — no new bar when prev==rates_total ──
   bool isTick = (prev_calculated > 0 && prev_calculated == rates_total);
   int  smallCount = need + 20;  // minimal copy for tick path

   // ── Pre-load DXY (reduced copy on tick) ──
   double allDXY[];
   ArraySetAsSeries(allDXY, true);
   int dxyCopy  = isTick ? MathMin(rates_total, smallCount) : rates_total;
   int dxy_total = CopyClose(InpDXY_Symbol, _Period, 0, dxyCopy, allDXY);
   if(dxy_total < need) return 0;

   // ── Pre-load OHLCT into globals (full on new bar/recalc, 1-bar update on tick) ──
   if(!isTick || g_ohlc_size < rates_total) {
      ArraySetAsSeries(g_ohlc_open,  false);
      ArraySetAsSeries(g_ohlc_high,  false);
      ArraySetAsSeries(g_ohlc_low,   false);
      ArraySetAsSeries(g_ohlc_close, false);
      ArraySetAsSeries(g_ohlc_time,  false);
      if(CopyOpen (_Symbol, _Period, 0, rates_total, g_ohlc_open)  < rates_total) return 0;
      if(CopyHigh (_Symbol, _Period, 0, rates_total, g_ohlc_high)  < rates_total) return 0;
      if(CopyLow  (_Symbol, _Period, 0, rates_total, g_ohlc_low)   < rates_total) return 0;
      if(CopyClose(_Symbol, _Period, 0, rates_total, g_ohlc_close) < rates_total) return 0;
      if(CopyTime (_Symbol, _Period, 0, rates_total, g_ohlc_time)  < rates_total) return 0;
      g_ohlc_size = rates_total;
   } else {
      // Tick: update only latest bar (chronological index = rates_total-1)
      double t1[1]; datetime tt[1];
      if(CopyOpen (_Symbol,_Period,0,1,t1)<1) return 0; g_ohlc_open [rates_total-1] = t1[0];
      if(CopyHigh (_Symbol,_Period,0,1,t1)<1) return 0; g_ohlc_high [rates_total-1] = t1[0];
      if(CopyLow  (_Symbol,_Period,0,1,t1)<1) return 0; g_ohlc_low  [rates_total-1] = t1[0];
      if(CopyClose(_Symbol,_Period,0,1,t1)<1) return 0; g_ohlc_close[rates_total-1] = t1[0];
      if(CopyTime (_Symbol,_Period,0,1,tt)<1) return 0; g_ohlc_time [rates_total-1] = tt[0];
   }

   // ── Pre-load ATR (reduced copy on tick) ──
   double atr_buf[];
   ArraySetAsSeries(atr_buf, true);
   int atrCopy = isTick ? MathMin(rates_total, smallCount) : rates_total;
   if(CopyBuffer(g_atr_handle, 0, 0, atrCopy, atr_buf) < need) return 0;

   // ── Pre-load MACD (reduced copy on tick) ──
   double macd_main[], macd_signal_buf[];
   ArraySetAsSeries(macd_main,       true);
   ArraySetAsSeries(macd_signal_buf, true);
   bool macd_ready = false;
   if(InpUseMACDFilter) {
      int macdCopy = isTick ? MathMin(rates_total, smallCount) : rates_total;
      macd_ready = (CopyBuffer(g_macd_handle, 0, 0, macdCopy, macd_main)       >= need &&
                    CopyBuffer(g_macd_handle, 1, 0, macdCopy, macd_signal_buf) >= need);
      if(!macd_ready) Print("WARN: MACD data not ready");
   }

   // ── allGold as-series (reduced copy on tick; separate from g_ohlc_close ที่เป็น chronological) ──
   double allGold[];
   ArraySetAsSeries(allGold, true);
   int goldCopy = isTick ? MathMin(rates_total, smallCount) : rates_total;
   if(CopyClose(_Symbol, _Period, 0, goldCopy, allGold) < goldCopy) return 0;

   // ── 1. Hull Suite Calculation (index-based, chronological order) ──
   GdxUpdateHull(rates_total, prev_calculated, g_ohlc_open, g_ohlc_high, g_ohlc_low, g_ohlc_close);
   bool isFullRecalc = (prev_calculated <= 0);
   // ── v8.12 Perf: วาด Hull line เฉพาะ new bar/recalc (ไม่วาดทุก tick) ──
   bool isNewBarForHull = (g_ohlc_time[rates_total - 1] != gdx_LastBarTime) || isFullRecalc;
   if(InpHL_ShowLine && isNewBarForHull) GdxDrawHullLine(rates_total, g_ohlc_time, isFullRecalc);

   // ── Hull Alert: ตรวจสอบการเปลี่ยนทิศ Hull บน Bar[1] ที่ปิดแล้ว (ไม่ใช่ Bar[0] live) ──
   // FIX: ใช้ rates_total-2 (bar ที่ปิดแล้ว) และ rates_total-3 (bar ก่อนหน้า)
   // เพื่อป้องกัน alert ยิงแล้วกลับทิศก่อน bar close
   if(rates_total > 2) {
      int curH  = (int)gdx_HullTrend[rates_total - 2];  // bar ที่ปิดแล้ว
      int prevH = (int)gdx_HullTrend[rates_total - 3];  // bar ก่อนหน้าที่ปิดแล้ว
      if(curH != prevH && curH != 0 && prevH != 0) {
         datetime confirmedTime = g_ohlc_time[rates_total - 2];
         if(confirmedTime > gdx_LastHullAlertTime) {
            GdxSendHullAlert(curH, g_ohlc_close[rates_total - 2], confirmedTime);
            gdx_LastHullAlertTime = confirmedTime;
         }
      }
   }

   // ── 2. OFA Calculation ──
   bool isNewBar = (g_ohlc_time[rates_total - 1] != gdx_LastBarTime);
   if(isNewBar || prev_calculated == 0) {
      // Fast OFA (p26) — entry timing + zigzag display
      GdxUpdateOFACore(rates_total, g_ohlc_time, g_ohlc_high, g_ohlc_low, g_ohlc_close, isFullRecalc);
      gdx_LastBarTime = g_ohlc_time[rates_total - 1];
      GdxDrawOFALegs();
      // Slow OFA (p50) — trend context filter, runs only if Period2 enabled
      if(InpOFA_FractalPeriod2 > InpOFA_FractalPeriod) {
         bool isNewBar2 = (g_ohlc_time[rates_total - 1] != gdx_LastBarTime2);
         if(isNewBar2 || prev_calculated == 0) {
            GdxUpdateOFACore2(rates_total, g_ohlc_time, g_ohlc_high, g_ohlc_low, g_ohlc_close, isFullRecalc);
            gdx_LastBarTime2 = g_ohlc_time[rates_total - 1];
            GdxDrawOFALegs2();   // วาด slow OFA zigzag บนกราฟ
         }
      }
   }
   if(InpOFA_DisplayCurrentSwing && gdx_LastConfirmedCount > 0)
      GdxUpdateLiveSwing(rates_total, g_ohlc_time, g_ohlc_high, g_ohlc_low);

   // Slow OFA (p50) live swing — เลื่อน tip ตาม High/Low ปัจจุบัน ทุก tick (v8.10)
   if(InpOFA_FractalPeriod2 > InpOFA_FractalPeriod && gdx_LastConfirmedCount2 > 0)
      GdxUpdateLiveSwing2(rates_total, g_ohlc_time, g_ohlc_high, g_ohlc_low);

   // ── OFA Notifications ──
   if(prev_calculated > 0 && (InpOFA_SendNotification || InpOFA_SendAlert))
      GdxHandleOFANotifications(rates_total);

   // ── 3. Main Signal Loop ──
   for(int i = start; i < rates_total; i++)
   {
      // ── FIX v8.07: Arrow Restore Logic ──
      // ปัญหา: เมื่อ reload indicator (prev_calculated=0), MT5 reset buffer ทั้งหมดเป็น EMPTY_VALUE
      // ทำให้ check "BufferBuyPrice[i] != EMPTY_VALUE" ไม่ทำงาน
      // แก้: ตรวจ arrow object ก่อน ถ้ามีให้ดึง price จาก OBJPROP_PRICE แล้ว restore buffer
      string buyArrowName  = OBJ_PREFIX + "ARW_BUY_"  + IntegerToString(i);
      string sellArrowName = OBJ_PREFIX + "ARW_SELL_" + IntegerToString(i);
      bool hasBuyArrow  = (ObjectFind(0, buyArrowName)  >= 0);
      bool hasSellArrow = (ObjectFind(0, sellArrowName) >= 0);

      // ถ้า bar นี้มี BUY arrow → restore buffers จาก arrow price แล้วข้ามการคำนวณใหม่
      if(hasBuyArrow)
      {
         int offset_r = rates_total - 1 - i;
         BufferDXY[i] = (offset_r < dxy_total) ? allDXY[offset_r] : EMPTY_VALUE;
         // Restore BuyPrice จาก arrow หรือ allGold ถ้า buffer ว่าง
         if(BufferBuyPrice[i] == EMPTY_VALUE || BufferBuyPrice[i] <= 0) {
            double ap = ObjectGetDouble(0, buyArrowName, OBJPROP_PRICE);
            // แปลง arrow price (low - offset) กลับเป็น close price โดยประมาณ
            // ใช้ allGold[offset_r] ซึ่งเป็น close ของ bar นั้น
            BufferBuyPrice[i] = (offset_r < rates_total && allGold[offset_r] > 0)
                                 ? allGold[offset_r] : ap;
         }
         BufferSignal[i] = (i < rates_total - 2) ? 0.0 : 1.0;
         // Update last_signal_bar
         if(i > last_signal_bar) last_signal_bar = i;
         continue;
      }
      // ถ้า bar นี้มี SELL arrow → restore buffers
      if(hasSellArrow)
      {
         int offset_r = rates_total - 1 - i;
         BufferDXY[i] = (offset_r < dxy_total) ? allDXY[offset_r] : EMPTY_VALUE;
         if(BufferSellPrice[i] == EMPTY_VALUE || BufferSellPrice[i] <= 0) {
            double ap = ObjectGetDouble(0, sellArrowName, OBJPROP_PRICE);
            BufferSellPrice[i] = (offset_r < rates_total && allGold[offset_r] > 0)
                                  ? allGold[offset_r] : ap;
         }
         BufferSignal[i] = (i < rates_total - 2) ? 0.0 : -1.0;
         if(i > last_signal_bar) last_signal_bar = i;
         continue;
      }

      BufferDXY[i]       = EMPTY_VALUE;
      BufferBuyPrice[i]  = EMPTY_VALUE;
      BufferSellPrice[i] = EMPTY_VALUE;
      BufferSignal[i]    = 0.0;
      BufferSL[i]        = EMPTY_VALUE;
      BufferTP[i]        = EMPTY_VALUE;

      int offset = rates_total - 1 - i;
      if(offset >= dxy_total) continue;

      BufferDXY[i] = allDXY[offset];

      double dxy_m[], gold_m[], dxy_r[], gold_r[], dxy_t[], gc[];

      // FIX: ใช้ slice จาก pre-loaded arrays แทนการเรียก CopyClose() ซ้ำใน loop
      // allDXY / allGold เป็น as-series (index 0=latest), offset คือตำแหน่งจาก latest
      ArraySetAsSeries(dxy_m,  true); ArrayResize(dxy_m,  InpMacroBars);
      ArraySetAsSeries(gold_m, true); ArrayResize(gold_m, InpMacroBars);
      ArraySetAsSeries(dxy_r,  true); ArrayResize(dxy_r,  InpRecentBars);
      ArraySetAsSeries(gold_r, true); ArrayResize(gold_r, InpRecentBars);
      ArraySetAsSeries(dxy_t,  true); ArrayResize(dxy_t,  InpTriggerBars+1);
      ArraySetAsSeries(gc,     true); ArrayResize(gc,      InpZPeriod);

      bool sliceOK = true;
      for(int k = 0; k < InpMacroBars && sliceOK; k++) {
         int idx = offset + k;
         if(idx >= dxy_total || idx >= rates_total) { sliceOK = false; break; }
         dxy_m[k]  = allDXY[idx];
         gold_m[k] = allGold[idx];
      }
      for(int k = 0; k < InpRecentBars && sliceOK; k++) {
         int idx = offset + k;
         if(idx >= dxy_total || idx >= rates_total) { sliceOK = false; break; }
         dxy_r[k]  = allDXY[idx];
         gold_r[k] = allGold[idx];
      }
      for(int k = 0; k <= InpTriggerBars && sliceOK; k++) {
         int idx = offset + k;
         if(idx >= dxy_total) { sliceOK = false; break; }
         dxy_t[k] = allDXY[idx];
      }
      for(int k = 0; k < InpZPeriod && sliceOK; k++) {
         int idx = offset + k;
         if(idx >= rates_total) { sliceOK = false; break; }
         gc[k] = allGold[idx];
      }
      if(!sliceOK) continue;

      int md = TrendDir(dxy_m,  InpMacroBars),  mg = TrendDir(gold_m, InpMacroBars);
      int rd = TrendDir(dxy_r,  InpRecentBars), rg = TrendDir(gold_r, InpRecentBars);
      bool buy_zone  = (md == -1 && mg == +1 && rd == -1 && rg == +1);
      bool sell_zone = (md == +1 && mg == -1 && rd == +1 && rg == -1);
      if(!buy_zone && !sell_zone) continue;

      bool pb = (dxy_t[0] < dxy_t[InpTriggerBars]);
      bool rb = (dxy_t[0] > dxy_t[InpTriggerBars]);
      double z_gold = ZScore(gc, InpZPeriod);
      bool far_ok   = (i - last_signal_bar) >= InpMinBarGap;

      double bh[], bl[];
      ArraySetAsSeries(bh, true); ArraySetAsSeries(bl, true);
      if(CopyHigh(_Symbol, _Period, offset, 1, bh) < 1) continue;
      if(CopyLow (_Symbol, _Period, offset, 1, bl) < 1) continue;

      bool gob = GoldOkForBuy(offset);
      bool gos = GoldOkForSell(offset);

      datetime bar_t[]; ArraySetAsSeries(bar_t, true);
      if(CopyTime(_Symbol, _Period, offset, 1, bar_t) < 1) continue;

      double atr_val = (offset < (int)ArraySize(atr_buf)) ? atr_buf[offset] : 0;
      if(atr_val <= 0) continue;

      // MACD Filter
      bool macd_buy_ok  = true;
      bool macd_sell_ok = true;
      if(InpUseMACDFilter && macd_ready && offset < (int)ArraySize(macd_main)) {
         double m_line = macd_main[offset];
         double s_line = macd_signal_buf[offset];
         double gap    = m_line - s_line;
         // เงื่อนไขเดิม: MACD line อยู่เหนือ/ใต้ Signal line
         bool macd_cross_buy  = (gap >  InpMACD_MinGap);
         bool macd_cross_sell = (gap < -InpMACD_MinGap);
         // เงื่อนไขใหม่ v8.11: MACD line momentum — แท่งก่อนหน้าต้องต่ำกว่า (BUY) หรือสูงกว่า (SELL)
         bool macd_mom_buy  = true;
         bool macd_mom_sell = true;
         if(offset + 1 < (int)ArraySize(macd_main)) {
            double m_prev = macd_main[offset + 1];   // แท่งก่อนหน้า (offset+1 = 1 bar เก่ากว่า)
            macd_mom_buy  = (m_line > m_prev);        // MACD ปัจจุบันสูงกว่าก่อนหน้า → momentum ขึ้น
            macd_mom_sell = (m_line < m_prev);        // MACD ปัจจุบันต่ำกว่าก่อนหน้า → momentum ลง
         }
         macd_buy_ok  = macd_cross_buy  && macd_mom_buy;
         macd_sell_ok = macd_cross_sell && macd_mom_sell;
      }

      // ── OFA Trend Filter (Dual-Period v8.10) ──
      // Fast OFA (p26): entry timing
      int ofaTrend = GdxGetOFATrendAtBar(i);
      bool ofa1PassBuy  = (ofaTrend == 1)  || (ofaTrend == 0 && gdx_LastConfirmedCount == 0);
      bool ofa1PassSell = (ofaTrend == -1) || (ofaTrend == 0 && gdx_LastConfirmedCount == 0);

      // Slow OFA (p50): trend context — AND with fast OFA
      bool ofa2PassBuy  = true;
      bool ofa2PassSell = true;
      if(InpOFA_FractalPeriod2 > InpOFA_FractalPeriod) {
         int ofaTrend2 = GdxGetOFATrendAtBar2(i);
         // fallback: เมื่อ slow OFA ยังไม่มีข้อมูล (ofaTrend2==0) → pass ได้
         ofa2PassBuy  = (ofaTrend2 == 1)  || (ofaTrend2 == 0 && gdx_LastConfirmedCount2 == 0);
         ofa2PassSell = (ofaTrend2 == -1) || (ofaTrend2 == 0 && gdx_LastConfirmedCount2 == 0);
      }

      bool ofaPassBuy  = ofa1PassBuy  && ofa2PassBuy;
      bool ofaPassSell = ofa1PassSell && ofa2PassSell;

      // ── BUY: ต้องผ่านทุกเงื่อนไข รวม OFA ขาขึ้น ──
      bool buyOK = (buy_zone && pb && MathAbs(z_gold) < InpGoldZLimit
                    && gob && far_ok && macd_buy_ok && ofaPassBuy);

      // ── SELL: ต้องผ่านทุกเงื่อนไข รวม OFA ขาลง ──
      bool sellOK = (sell_zone && rb && MathAbs(z_gold) < InpGoldZLimit
                     && gos && far_ok && macd_sell_ok && ofaPassSell);

      // ── ราคา close ของแท่งนี้ ──
      // ใช้ allGold[offset] (as-series) แทน arr_close[i] (chronological)
      // เพื่อให้สอดคล้องกับ GoldOkForBuy/Sell ที่ใช้ offset-based CopyClose
      double close_price = allGold[offset];

      if(buyOK)
      {
         BufferBuyPrice[i] = close_price;
         BufferSignal[i]   = 1.0;
         BufferSL[i]       = bl[0] - (atr_val * InpATR_SL_Multi);
         BufferTP[i]       = bl[0] + (atr_val * InpATR_TP_Multi);
         last_signal_bar   = i;
         DrawBuyArrow(i, bar_t[0], bl[0]);
         // Signal Log
         {
            double dv  = allDXY[offset];
            double dvp = (offset+InpTriggerBars < dxy_total) ? allDXY[offset+InpTriggerBars] : dv;
            double ml  = (macd_ready && offset < (int)ArraySize(macd_main))       ? macd_main[offset]       : 0;
            double ms  = (macd_ready && offset < (int)ArraySize(macd_signal_buf)) ? macd_signal_buf[offset] : 0;
            int ht     = (i < (int)ArraySize(gdx_HullTrend)) ? (int)gdx_HullTrend[i] : 0;
            SignalLog("BUY", bar_t[0], close_price, BufferSL[i], BufferTP[i],
                      atr_val, z_gold, Correlation(InpZPeriod),
                      dv, dvp, md, mg, rd, rg, pb, gob, ml, ms,
                      ofaTrend, ht, i - last_signal_bar);
         }
         // FIX: ยิง Alert เฉพาะ bar ที่เพิ่งปิด (rates_total-2) เท่านั้น
         if(i == rates_total - 2) {
            double dv = allDXY[0];
            double ml = (macd_ready && offset < (int)ArraySize(macd_main))       ? macd_main[offset]       : 0;
            double ms = (macd_ready && offset < (int)ArraySize(macd_signal_buf)) ? macd_signal_buf[offset] : 0;
            FireAlert("BUY", close_price, BufferSL[i], dv, z_gold, Correlation(InpZPeriod), bar_t[0], ml, ms);
         }
      }

      if(sellOK)
      {
         BufferSellPrice[i] = close_price;
         BufferSignal[i]    = -1.0;
         BufferSL[i]        = bh[0] + (atr_val * InpATR_SL_Multi);
         BufferTP[i]        = close_price - (atr_val * InpATR_TP_Multi);
         last_signal_bar    = i;
         DrawSellArrow(i, bar_t[0], bh[0]);
         // Signal Log
         {
            double dv  = allDXY[offset];
            double dvp = (offset+InpTriggerBars < dxy_total) ? allDXY[offset+InpTriggerBars] : dv;
            double ml  = (macd_ready && offset < (int)ArraySize(macd_main))       ? macd_main[offset]       : 0;
            double ms  = (macd_ready && offset < (int)ArraySize(macd_signal_buf)) ? macd_signal_buf[offset] : 0;
            int ht     = (i < (int)ArraySize(gdx_HullTrend)) ? (int)gdx_HullTrend[i] : 0;
            SignalLog("SELL", bar_t[0], close_price, BufferSL[i], BufferTP[i],
                      atr_val, z_gold, Correlation(InpZPeriod),
                      dv, dvp, md, mg, rd, rg, rb, gos, ml, ms,
                      ofaTrend, ht, i - last_signal_bar);
         }
         // FIX: ยิง Alert เฉพาะ bar ที่เพิ่งปิด (rates_total-2) เท่านั้น
         if(i == rates_total - 2) {
            double dv = allDXY[0];
            double ml = (macd_ready && offset < (int)ArraySize(macd_main))       ? macd_main[offset]       : 0;
            double ms = (macd_ready && offset < (int)ArraySize(macd_signal_buf)) ? macd_signal_buf[offset] : 0;
            FireAlert("SELL", close_price, BufferSL[i], dv, z_gold, Correlation(InpZPeriod), bar_t[0], ml, ms);
         }
      }
   }

   if(g_subwin < 0) g_subwin = GetSubWin();
   // Dashboard: แสดงเมื่อ InpShowDashboard=true เท่านั้น
   // เมื่อปิด → ลบ label ทั้งหมดทิ้ง (ทำแค่ครั้งแรกที่ปิด หลัง user toggle)
   if(InpShowDashboard) {
      g_dashboardWasOn = true;
      // ── v8.12 Perf: วาด Dashboard เฉพาะ new bar/recalc ──
      if(isNewBar || isFullRecalc) DrawDashboard(rates_total);
   } else {
      if(g_dashboardWasOn) {
         ObjectsDeleteAll(0, OBJ_PREFIX + "T0");
         ObjectsDeleteAll(0, OBJ_PREFIX + "SEP");
         ObjectsDeleteAll(0, OBJ_PREFIX + "S");
         ObjectsDeleteAll(0, OBJ_PREFIX + "RES");
         ObjectsDeleteAll(0, OBJ_PREFIX + "TLH");
         ObjectsDeleteAll(0, OBJ_PREFIX + "TL1");
         ObjectsDeleteAll(0, OBJ_PREFIX + "TL2");
         ObjectsDeleteAll(0, OBJ_PREFIX + "S8");
         g_dashboardWasOn = false;
      }
   }
   // ══ Session VP Monitor ══
   RunSessionVP();

   // ══ Session Box ══
   {
      static int sbLastBar = -1;
      int sbCurBar = Bars(_Symbol, PERIOD_M15);
      if(sbCurBar != sbLastBar) {
         ObjectsDeleteAll(0, SB_Prefix);
         DrawSessionBoxes();
         sbLastBar = sbCurBar;
      }
   }

   UpdateTrendLines(rates_total);
   return rates_total;
}

//+------------------------------------------------------------------+
//| HULL SUITE FUNCTIONS                                             |
//+------------------------------------------------------------------+
double GdxGetHullPrice(ENUM_APPLIED_PRICE type, const double &o[], const double &h[],
                    const double &l[], const double &c[], int i) {
   switch(type) {
      case PRICE_CLOSE:    return c[i];
      case PRICE_OPEN:     return o[i];
      case PRICE_HIGH:     return h[i];
      case PRICE_LOW:      return l[i];
      case PRICE_MEDIAN:   return (h[i] + l[i]) / 2.0;
      case PRICE_TYPICAL:  return (h[i] + l[i] + c[i]) / 3.0;
      case PRICE_WEIGHTED: return (h[i] + l[i] + c[i] + c[i]) / 4.0;
      default:             return c[i];
   }
}

void GdxUpdateHull(int total, int prev,
                const double &o[], const double &h[],
                const double &l[], const double &c[])
{
   if(!gdx_IsHullInitialized) {
      gdx_HullEngine.init(InpHL_Period, InpHL_Divisor);
      gdx_IsHullInitialized = true;
   }
   if(ArraySize(gdx_HullValue) < total) {
      ArrayResize(gdx_HullValue, total + 500);
      ArrayResize(gdx_HullTrend, total + 500);
   }
   int start = (prev > 0) ? prev - 1 : 0;
   for(int i = start; i < total; i++) {
      double p   = GdxGetHullPrice(InpHL_Price, o, h, l, c, i);
      gdx_HullValue[i] = gdx_HullEngine.calculate(p, i, total);
      gdx_HullTrend[i] = (i > 0)
         ? (gdx_HullValue[i] > gdx_HullValue[i-1] ? 1 : (gdx_HullValue[i] < gdx_HullValue[i-1] ? -1 : gdx_HullTrend[i-1]))
         : 0;
   }
}

void GdxDrawHullLine(int total, const datetime &time[], bool isFullRecalc)
{
   // FIX: Full recalc → ลบทุก Hull object ทิ้งก่อนวาดใหม่ ป้องกัน object สะสม
   if(isFullRecalc) {
      ObjectsDeleteAll(0, "GDX8_HULL_");
   }

   int count = 500;
   int seg_start = total - count;
   if(seg_start < 1) seg_start = 1;

   for(int i = seg_start; i < total; i++) {
      string n = "GDX8_HULL_" + IntegerToString(i);
      if(ObjectFind(0, n) < 0) {
         ObjectCreate(0, n, OBJ_TREND, 0, time[i-1], gdx_HullValue[i-1], time[i], gdx_HullValue[i]);
         ObjectSetInteger(0, n, OBJPROP_RAY_RIGHT, false);
         ObjectSetInteger(0, n, OBJPROP_WIDTH,     InpHL_LineWidth);
         ObjectSetInteger(0, n, OBJPROP_SELECTABLE,false);
         ObjectSetInteger(0, n, OBJPROP_BACK,      true);
      }
      ObjectSetInteger(0, n, OBJPROP_COLOR, gdx_HullTrend[i] == 1 ? InpHL_UpColor : InpHL_DownColor);
      // Update endpoints
      ObjectSetInteger(0, n, OBJPROP_TIME,  0, time[i-1]);
      ObjectSetDouble (0, n, OBJPROP_PRICE, 0, gdx_HullValue[i-1]);
      ObjectSetInteger(0, n, OBJPROP_TIME,  1, time[i]);
      ObjectSetDouble (0, n, OBJPROP_PRICE, 1, gdx_HullValue[i]);
   }
}

void GdxSendHullAlert(int trend, double price, datetime t)
{
   string dir = (trend == 1) ? "HULL UP" : "HULL DOWN";
   string sym = _Symbol;
   string tf  = GdxGetTFString();
   int    digs = (_Digits > 3) ? 2 : _Digits;
   string msg  = StringFormat("%s | %s %s @ %."+IntegerToString(digs)+"f | %s",
                              dir, sym, tf, price, TimeToString(t, TIME_DATE|TIME_MINUTES));
   if(InpHL_SendAlert)  Alert(msg);
   if(InpHL_SendNotify) SendNotification(msg);
   Print("Hull Direction Change: ", msg);
}

//+------------------------------------------------------------------+
//| OFA TREND AT BAR                                                 |
//| คืนค่า  1 = OFA ขาขึ้น (Bullish leg)                           |
//|        -1 = OFA ขาลง  (Bearish leg)                            |
//|         0 = ยังไม่มีข้อมูล                                      |
//+------------------------------------------------------------------+
int GdxGetOFATrendAtBar(int bar)
{
   // ── ก่อนอื่น: ถ้า bar อยู่หลัง confirmed swing สุดท้าย → ใช้ live swing
   // live swing คือ gdx_swings[gdx_swingCount-1] เมื่อ gdx_swingCount > gdx_LastConfirmedCount
   if(gdx_swingCount > gdx_LastConfirmedCount && gdx_LastConfirmedCount > 0)
   {
      int lastConfBar = gdx_swings[gdx_LastConfirmedCount-1].bar;
      if(bar > lastConfBar)
         return gdx_swings[gdx_swingCount-1].isHigh ? 1 : -1;
   }

   // ── วิ่งผ่าน confirmed swings ──
   for(int i = 1; i < gdx_LastConfirmedCount; i++)
   {
      if(bar >= gdx_swings[i-1].bar && bar <= gdx_swings[i].bar)
         return gdx_swings[i].isHigh ? 1 : -1;
   }

   // ── fallback: ใช้ confirmed swing ล่าสุด ถ้า bar เลยไปแล้ว ──
   if(gdx_LastConfirmedCount > 0 && bar >= gdx_swings[gdx_LastConfirmedCount-1].bar)
      return gdx_swings[gdx_LastConfirmedCount-1].isHigh ? 1 : -1;

   return 0;
}

//+------------------------------------------------------------------+
//| SLOW OFA TREND AT BAR (Period2 = p50)                            |
//| คืนค่า  1 = Slow OFA ขาขึ้น                                     |
//|        -1 = Slow OFA ขาลง                                       |
//|         0 = ยังไม่มีข้อมูล                                      |
//+------------------------------------------------------------------+
int GdxGetOFATrendAtBar2(int bar)
{
   if(gdx_swingCount2 > gdx_LastConfirmedCount2 && gdx_LastConfirmedCount2 > 0)
   {
      int lastConfBar2 = gdx_swings2[gdx_LastConfirmedCount2-1].bar;
      if(bar > lastConfBar2)
         return gdx_swings2[gdx_swingCount2-1].isHigh ? 1 : -1;
   }

   for(int i = 1; i < gdx_LastConfirmedCount2; i++)
   {
      if(bar >= gdx_swings2[i-1].bar && bar <= gdx_swings2[i].bar)
         return gdx_swings2[i].isHigh ? 1 : -1;
   }

   if(gdx_LastConfirmedCount2 > 0 && bar >= gdx_swings2[gdx_LastConfirmedCount2-1].bar)
      return gdx_swings2[gdx_LastConfirmedCount2-1].isHigh ? 1 : -1;

   return 0;
}

//+------------------------------------------------------------------+
//| SLOW OFA CORE UPDATE (Period2)                                   |
//| เหมือน GdxUpdateOFACore แต่ใช้ InpOFA_FractalPeriod2           |
//| และ gdx_swings2[] / gdx_swingCount2 / gdx_LastConfirmedCount2   |
//+------------------------------------------------------------------+
void GdxUpdateOFACore2(int total, const datetime &time[],
                       const double &high[], const double &low[], const double &close[],
                       bool isFullRecalc)
{
   int fp = InpOFA_FractalPeriod2;
   if(fp <= 0) return;

   int scan_start;
   if(!isFullRecalc && gdx_LastConfirmedCount2 > 1) {
      scan_start = total - (fp * 3 + 1);
      if(scan_start < fp) scan_start = fp;
   } else {
      scan_start = total - InpOFA_MaxBars;
      if(scan_start < fp) scan_start = fp;
   }

   GDX_Fractal fr2[];
   int frCount2 = 0;
   int limit2 = total - 1;

   for(int i = scan_start; i < limit2; i++) {
      bool isFH = true, isFL = true;
      for(int j = 1; j <= fp; j++) {
         int li = i - j, ri = i + j;
         if(li < 0 || ri >= total) { isFH = false; isFL = false; break; }
         if(InpOFA_AggressiveFractal) {
            if(high[i] <= high[li] || high[i] <= high[ri]) isFH = false;
            if(low[i]  >= low[li]  || low[i]  >= low[ri])  isFL = false;
         } else {
            if(close[i] <= close[li] || close[i] <= close[ri]) isFH = false;
            if(close[i] >= close[li] || close[i] >= close[ri]) isFL = false;
         }
         if(!isFH && !isFL) break;
      }
      if(isFH) { ArrayResize(fr2, frCount2+1); fr2[frCount2].time=time[i]; fr2[frCount2].price=high[i];  fr2[frCount2].bar=i; fr2[frCount2].isHigh=true;  frCount2++; }
      if(isFL) { ArrayResize(fr2, frCount2+1); fr2[frCount2].time=time[i]; fr2[frCount2].price=low[i];   fr2[frCount2].bar=i; fr2[frCount2].isHigh=false; frCount2++; }
   }

   // Incremental merge
   if(!isFullRecalc && gdx_LastConfirmedCount2 > 1) {
      int keepCount2 = gdx_LastConfirmedCount2;
      while(keepCount2 > 0 && gdx_swings2[keepCount2-1].bar >= scan_start)
         keepCount2--;

      if(keepCount2 < 1) {
         GdxUpdateOFACore2(total, time, high, low, close, true);
         return;
      }
      if(frCount2 == 0) return;

      int oldCount2  = keepCount2;
      int combined2  = oldCount2 + frCount2;
      GDX_Fractal allFr2[];
      ArrayResize(allFr2, combined2);
      for(int k = 0; k < oldCount2; k++) {
         allFr2[k].time   = gdx_swings2[k].time;
         allFr2[k].price  = gdx_swings2[k].price;
         allFr2[k].bar    = gdx_swings2[k].bar;
         allFr2[k].isHigh = gdx_swings2[k].isHigh;
      }
      for(int k = 0; k < frCount2; k++)
         allFr2[oldCount2 + k] = fr2[k];

      ArrayResize(fr2, combined2);
      for(int k = 0; k < combined2; k++) fr2[k] = allFr2[k];
      frCount2 = combined2;
   }

   if(frCount2 < 2) return;

   // Sort by bar
   for(int i = 1; i < frCount2; i++) {
      GDX_Fractal k2 = fr2[i]; int j = i-1;
      while(j >= 0 && fr2[j].bar > k2.bar) { fr2[j+1] = fr2[j]; j--; }
      fr2[j+1] = k2;
   }
   // Merge consecutive same-type
   bool chg2 = true;
   while(chg2) {
      chg2 = false;
      for(int i = 0; i < frCount2-1; i++) {
         if(fr2[i].isHigh == fr2[i+1].isHigh) {
            int rem = fr2[i].isHigh
               ? (fr2[i].price >= fr2[i+1].price ? i+1 : i)
               : (fr2[i].price <= fr2[i+1].price ? i+1 : i);
            for(int k = rem; k < frCount2-1; k++) fr2[k] = fr2[k+1];
            frCount2--; ArrayResize(fr2, frCount2); chg2 = true; break;
         }
      }
   }

   ArrayResize(gdx_swings2, frCount2); gdx_swingCount2 = frCount2;
   for(int i = 0; i < frCount2; i++) {
      gdx_swings2[i].time    = fr2[i].time;
      gdx_swings2[i].price   = fr2[i].price;
      gdx_swings2[i].bar     = fr2[i].bar;
      gdx_swings2[i].isHigh  = fr2[i].isHigh;
      gdx_swings2[i].velocity  = 0;
      gdx_swings2[i].magnitude = 0;
      gdx_swings2[i].magPct    = 0;
      if(i > 0) {
         gdx_swings2[i].velocity  = MathAbs((double)(gdx_swings2[i].bar - gdx_swings2[i-1].bar));
         gdx_swings2[i].magnitude = MathAbs(gdx_swings2[i].price - gdx_swings2[i-1].price);
         gdx_swings2[i].magPct    = (gdx_swings2[i-1].price != 0)
                                    ? (gdx_swings2[i].magnitude / gdx_swings2[i-1].price) * 100.0 : 0;
      }
   }
   gdx_LastConfirmedCount2 = gdx_swingCount2;
}

//+------------------------------------------------------------------+
//| OFA FUNCTIONS                                                    |
//+------------------------------------------------------------------+
void GdxUpdateOFACore(int total, const datetime &time[],
                   const double &high[], const double &low[], const double &close[],
                   bool isFullRecalc)
{
   int fp = InpOFA_FractalPeriod;

   //--- กำหนด scan window ---
   int scan_start;
   if(!isFullRecalc && gdx_LastConfirmedCount > 1) {
      // ย้อนกลับ fp*3 bars เพื่อครอบคลุม fractal ใหม่และ overlap กับ swing เก่า
      scan_start = total - (fp * 3 + 1);
      if(scan_start < fp) scan_start = fp;
   } else {
      scan_start = total - InpOFA_MaxBars;
      if(scan_start < fp) scan_start = fp;
   }

   //--- Scan หา fractals ใน window ---
   GDX_Fractal fr[];
   int frCount = 0;
   // ใช้ total-1 เป็น limit แล้วตรวจ ri < total ใน loop
   int limit = total - 1;

   for(int i = scan_start; i < limit; i++) {
      bool isFH = true, isFL = true;
      for(int j = 1; j <= fp; j++) {
         int li = i - j, ri = i + j;
         if(li < 0 || ri >= total) { isFH = false; isFL = false; break; }
         if(InpOFA_AggressiveFractal) {
            if(high[i] <= high[li] || high[i] <= high[ri]) isFH = false;
            if(low[i]  >= low[li]  || low[i]  >= low[ri])  isFL = false;
         } else {
            if(close[i] <= close[li] || close[i] <= close[ri]) isFH = false;
            if(close[i] >= close[li] || close[i] >= close[ri]) isFL = false;
         }
         if(!isFH && !isFL) break;
      }
      if(isFH) { ArrayResize(fr, frCount+1); fr[frCount].time=time[i]; fr[frCount].price=high[i]; fr[frCount].bar=i; fr[frCount].isHigh=true;  frCount++; }
      if(isFL) { ArrayResize(fr, frCount+1); fr[frCount].time=time[i]; fr[frCount].price=low[i];  fr[frCount].bar=i; fr[frCount].isHigh=false; frCount++; }
   }

   //--- Incremental: merge swing เก่า + fractal ใหม่ ---
   if(!isFullRecalc && gdx_LastConfirmedCount > 1) {
      // หา keepCount = swings ที่ bar < scan_start (ไม่ต้อง re-scan)
      int keepCount = gdx_LastConfirmedCount;
      while(keepCount > 0 && gdx_swings[keepCount-1].bar >= scan_start)
         keepCount--;

      if(keepCount < 1) {
         // ไม่มี swing เก่าเลย → full recalc
         GdxUpdateOFACore(total, time, high, low, close, true);
         return;
      }

      if(frCount == 0) {
         // ไม่มี fractal ใหม่ในช่วง scan → ไม่มีอะไรเปลี่ยน
         return;
      }

      // สร้าง combined fractal array = แปลง swing เก่า [0..keepCount-1] เป็น GDX_Fractal
      // + fractal ใหม่ที่ scan ได้
      int oldCount = keepCount;
      int combined = oldCount + frCount;
      GDX_Fractal allFr[];
      ArrayResize(allFr, combined);
      // copy swing เก่า
      for(int k = 0; k < oldCount; k++) {
         allFr[k].time   = gdx_swings[k].time;
         allFr[k].price  = gdx_swings[k].price;
         allFr[k].bar    = gdx_swings[k].bar;
         allFr[k].isHigh = gdx_swings[k].isHigh;
      }
      // append fractal ใหม่
      for(int k = 0; k < frCount; k++)
         allFr[oldCount + k] = fr[k];

      // ใช้ allFr แทน fr
      ArrayResize(fr, combined);
      for(int k = 0; k < combined; k++) fr[k] = allFr[k];
      frCount = combined;
   }

   if(frCount < 2) return;

   // Sort by bar index (insertion sort — O(n²) แต่ frCount เล็กมากในโหมด incremental)
   for(int i = 1; i < frCount; i++) {
      GDX_Fractal k = fr[i]; int j = i-1;
      while(j >= 0 && fr[j].bar > k.bar) { fr[j+1] = fr[j]; j--; }
      fr[j+1] = k;
   }
   // Merge same-type consecutive
   bool chg = true;
   while(chg) {
      chg = false;
      for(int i = 0; i < frCount-1; i++) {
         if(fr[i].isHigh == fr[i+1].isHigh) {
            int rem = fr[i].isHigh
               ? (fr[i].price >= fr[i+1].price ? i+1 : i)
               : (fr[i].price <= fr[i+1].price ? i+1 : i);
            for(int k = rem; k < frCount-1; k++) fr[k] = fr[k+1];
            frCount--; ArrayResize(fr, frCount); chg = true; break;
         }
      }
   }
   ArrayResize(gdx_swings, frCount); gdx_swingCount = frCount;
   for(int i = 0; i < frCount; i++) {
      gdx_swings[i].time=fr[i].time; gdx_swings[i].price=fr[i].price;
      gdx_swings[i].bar=fr[i].bar;   gdx_swings[i].isHigh=fr[i].isHigh;
      gdx_swings[i].velocity=0; gdx_swings[i].magnitude=0; gdx_swings[i].magPct=0;
      if(i > 0) {
         gdx_swings[i].velocity  = MathAbs((double)(gdx_swings[i].bar - gdx_swings[i-1].bar));
         gdx_swings[i].magnitude = MathAbs(gdx_swings[i].price - gdx_swings[i-1].price);
         gdx_swings[i].magPct    = (gdx_swings[i-1].price != 0) ? (gdx_swings[i].magnitude / gdx_swings[i-1].price) * 100.0 : 0;
      }
   }
   gdx_LastConfirmedCount = gdx_swingCount;
}

void GdxUpdateLiveSwing(int total, const datetime &time[],
                     const double &high[], const double &low[])
{
   gdx_swingCount = gdx_LastConfirmedCount;
   ArrayResize(gdx_swings, gdx_swingCount);
   int lastB = total - 1;
   GDX_SwingPoint last = gdx_swings[gdx_swingCount-1];
   GDX_SwingPoint cur;
   if(last.isHigh) {
      double cL = low[last.bar]; int cB = last.bar;
      for(int b = last.bar+1; b <= lastB; b++) if(low[b] < cL) { cL = low[b]; cB = b; }
      cur.isHigh = false; cur.price = cL; cur.bar = cB; cur.time = time[cB];
   } else {
      double cH = high[last.bar]; int cB = last.bar;
      for(int b = last.bar+1; b <= lastB; b++) if(high[b] > cH) { cH = high[b]; cB = b; }
      cur.isHigh = true; cur.price = cH; cur.bar = cB; cur.time = time[cB];
   }
   cur.velocity  = MathAbs((double)(cur.bar - last.bar));
   cur.magnitude = MathAbs(cur.price - last.price);
   cur.magPct    = (last.price != 0) ? (cur.magnitude / last.price) * 100.0 : 0;
   ArrayResize(gdx_swings, gdx_swingCount+1); gdx_swings[gdx_swingCount] = cur; gdx_swingCount++;
   GdxUpdateLiveLegDraw();
}

//+------------------------------------------------------------------+
//| SLOW OFA LIVE SWING UPDATE (v8.10)                               |
//| เหมือน GdxUpdateLiveSwing แต่ทำงานกับ gdx_swings2[]             |
//| เรียกทุก tick เพื่อให้ live tip ของ p50 เลื่อนตาม High/Low       |
//| ปัจจุบันเสมอ → ป้องกัน MISMATCH block signal เมื่อราคาทำ new High|
//+------------------------------------------------------------------+
void GdxUpdateLiveSwing2(int total, const datetime &time[],
                          const double &high[], const double &low[])
{
   if(InpOFA_FractalPeriod2 <= InpOFA_FractalPeriod) return;
   if(gdx_LastConfirmedCount2 < 1) return;

   // Reset live portion — เหลือแค่ confirmed swings
   gdx_swingCount2 = gdx_LastConfirmedCount2;
   ArrayResize(gdx_swings2, gdx_swingCount2);

   int lastB = total - 1;
   GDX_SwingPoint last2 = gdx_swings2[gdx_swingCount2 - 1];
   GDX_SwingPoint cur2;

   // หา extreme สุดของ bar ที่เลยจาก confirmed swing ล่าสุด
   if(last2.isHigh) {
      // confirmed High → live tip คือ Low ต่ำสุดหลังจุดนั้น
      double cL = low[last2.bar]; int cB = last2.bar;
      for(int b = last2.bar + 1; b <= lastB; b++)
         if(low[b] < cL) { cL = low[b]; cB = b; }
      cur2.isHigh = false; cur2.price = cL; cur2.bar = cB; cur2.time = time[cB];
   } else {
      // confirmed Low → live tip คือ High สูงสุดหลังจุดนั้น
      double cH = high[last2.bar]; int cB = last2.bar;
      for(int b = last2.bar + 1; b <= lastB; b++)
         if(high[b] > cH) { cH = high[b]; cB = b; }
      cur2.isHigh = true; cur2.price = cH; cur2.bar = cB; cur2.time = time[cB];
   }
   cur2.velocity  = MathAbs((double)(cur2.bar - last2.bar));
   cur2.magnitude = MathAbs(cur2.price - last2.price);
   cur2.magPct    = (last2.price != 0) ? (cur2.magnitude / last2.price) * 100.0 : 0;

   // Append live tip
   ArrayResize(gdx_swings2, gdx_swingCount2 + 1);
   gdx_swings2[gdx_swingCount2] = cur2;
   gdx_swingCount2++;

   // อัปเดตเส้น live leg บนกราฟ
   if(InpOFA_ShowZigzag2) {
      string nLive2 = "GDX8_OFA2_LIVE";
      color cLive2  = cur2.isHigh ? InpOFA_SlowBullColour : InpOFA_SlowBearColour;
      if(ObjectFind(0, nLive2) < 0)
         ObjectCreate(0, nLive2, OBJ_TREND, 0, last2.time, last2.price, cur2.time, cur2.price);
      ObjectSetInteger(0, nLive2, OBJPROP_TIME,  0, last2.time);
      ObjectSetDouble (0, nLive2, OBJPROP_PRICE, 0, last2.price);
      ObjectSetInteger(0, nLive2, OBJPROP_TIME,  1, cur2.time);
      ObjectSetDouble (0, nLive2, OBJPROP_PRICE, 1, cur2.price);
      ObjectSetInteger(0, nLive2, OBJPROP_COLOR,     cLive2);
      ObjectSetInteger(0, nLive2, OBJPROP_WIDTH,     InpOFA_SlowLineWidth);
      ObjectSetInteger(0, nLive2, OBJPROP_STYLE,     STYLE_DOT);
      ObjectSetInteger(0, nLive2, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, nLive2, OBJPROP_BACK,      true);
      ObjectSetInteger(0, nLive2, OBJPROP_SELECTABLE,false);
   }
}

void GdxDrawOFALegs()
{
   // FIX v8.07: เดิมใช้ static lastDrawnCount ทำให้ไม่ redraw เมื่อ count เท่าเดิมแต่ swing ขยับ
   // แก้: redraw ทุกครั้งที่เรียก (GdxDrawOFALegs ถูกเรียกเฉพาะตอน new bar อยู่แล้ว)
   ObjectsDeleteAll(0, "GDX8_OFA_L");
   ObjectsDeleteAll(0, "GDX8_OFA_T");

   // วาดจาก confirmed swings: i=0..gdx_LastConfirmedCount-2 (leg ระหว่าง i และ i+1)
   int draw_start = gdx_LastConfirmedCount - 100;
   if(draw_start < 1) draw_start = 1;
   for(int i = draw_start - 1; i < gdx_LastConfirmedCount - 1; i++) {
      string n = "GDX8_OFA_L" + IntegerToString(i);
      color  c = gdx_swings[i+1].isHigh ? InpOFA_BullishColour : InpOFA_BearishColour;
      if(InpOFA_ShowZigzag) {
         ObjectCreate(0, n, OBJ_TREND, 0, gdx_swings[i].time, gdx_swings[i].price, gdx_swings[i+1].time, gdx_swings[i+1].price);
         ObjectSetInteger(0, n, OBJPROP_COLOR,     c);
         ObjectSetInteger(0, n, OBJPROP_WIDTH,     2);
         ObjectSetInteger(0, n, OBJPROP_RAY_RIGHT, false);
         ObjectSetInteger(0, n, OBJPROP_SELECTABLE,false);
         ObjectSetInteger(0, n, OBJPROP_BACK,      true);
      }
      string tn = "GDX8_OFA_T" + IntegerToString(i+1);
      string txt = GdxBuildLabelText(i+1);
      if(txt != "" && InpOFA_ShowLabels) {
         ObjectCreate(0, tn, OBJ_TEXT, 0, gdx_swings[i+1].time, gdx_swings[i+1].price);
         ObjectSetString (0, tn, OBJPROP_TEXT,   txt);
         ObjectSetInteger(0, tn, OBJPROP_COLOR,  c);
         ObjectSetInteger(0, tn, OBJPROP_FONTSIZE,InpOFA_LabelFontSize);
         ObjectSetInteger(0, tn, OBJPROP_ANCHOR, gdx_swings[i+1].isHigh ? ANCHOR_LEFT_LOWER : ANCHOR_LEFT_UPPER);
      }
   }
}

void GdxUpdateLiveLegDraw()
{
   if(gdx_swingCount < 2) return;
   string n = "GDX8_OFA_LIVE", tn = "GDX8_OFA_LIVET";
   GDX_SwingPoint s1 = gdx_swings[gdx_swingCount-2], s2 = gdx_swings[gdx_swingCount-1];
   color c = s2.isHigh ? clrAqua : clrOrange;
   if(InpOFA_ShowZigzag) {
      if(ObjectFind(0, n) < 0) ObjectCreate(0, n, OBJ_TREND, 0, s1.time, s1.price, s2.time, s2.price);
      ObjectSetInteger(0, n, OBJPROP_TIME,  0, s1.time);  ObjectSetDouble(0, n, OBJPROP_PRICE, 0, s1.price);
      ObjectSetInteger(0, n, OBJPROP_TIME,  1, s2.time);  ObjectSetDouble(0, n, OBJPROP_PRICE, 1, s2.price);
      ObjectSetInteger(0, n, OBJPROP_COLOR, c); ObjectSetInteger(0, n, OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, n, OBJPROP_RAY_RIGHT, false); ObjectSetInteger(0, n, OBJPROP_BACK, true);
   }
   string txt = GdxBuildLabelText(gdx_swingCount-1);
   if(txt != "" && InpOFA_ShowLabels) {
      if(ObjectFind(0, tn) < 0) ObjectCreate(0, tn, OBJ_TEXT, 0, s2.time, s2.price);
      ObjectSetInteger(0, tn, OBJPROP_TIME,  0, s2.time); ObjectSetDouble(0, tn, OBJPROP_PRICE, 0, s2.price);
      ObjectSetString (0, tn, OBJPROP_TEXT,  txt);
      ObjectSetInteger(0, tn, OBJPROP_COLOR, c); ObjectSetInteger(0, tn, OBJPROP_FONTSIZE, InpOFA_LabelFontSize);
      ObjectSetInteger(0, tn, OBJPROP_ANCHOR, s2.isHigh ? ANCHOR_LEFT_LOWER : ANCHOR_LEFT_UPPER);
   }
}

//+------------------------------------------------------------------+
//| SLOW OFA DRAW (Period2 zigzag on chart)                          |
//| ใช้ prefix GDX8_OFA2_ เพื่อแยกจาก fast OFA (GDX8_OFA_)         |
//| เส้นหนากว่า (InpOFA_SlowLineWidth) และสีต่างกัน                  |
//+------------------------------------------------------------------+
void GdxDrawOFALegs2()
{
   if(!InpOFA_ShowZigzag2) return;
   if(InpOFA_FractalPeriod2 <= InpOFA_FractalPeriod) return;
   if(gdx_LastConfirmedCount2 < 2) return;

   ObjectsDeleteAll(0, "GDX8_OFA2_L");
   ObjectsDeleteAll(0, "GDX8_OFA2_T");

   int draw_start2 = gdx_LastConfirmedCount2 - 60;
   if(draw_start2 < 1) draw_start2 = 1;

   for(int i = draw_start2 - 1; i < gdx_LastConfirmedCount2 - 1; i++) {
      string n2 = "GDX8_OFA2_L" + IntegerToString(i);
      color  c2 = gdx_swings2[i+1].isHigh ? InpOFA_SlowBullColour : InpOFA_SlowBearColour;

      ObjectCreate(0, n2, OBJ_TREND, 0,
                   gdx_swings2[i].time,   gdx_swings2[i].price,
                   gdx_swings2[i+1].time, gdx_swings2[i+1].price);
      ObjectSetInteger(0, n2, OBJPROP_COLOR,     c2);
      ObjectSetInteger(0, n2, OBJPROP_WIDTH,     InpOFA_SlowLineWidth);
      ObjectSetInteger(0, n2, OBJPROP_STYLE,     STYLE_DASH);  // เส้นปะทั้งหมด ต่างจาก p26 (solid)
      ObjectSetInteger(0, n2, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, n2, OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0, n2, OBJPROP_BACK,      true);

      // Label: ฝั่งตรงข้ามกับ p26 เพื่อไม่ทับ
      // p26 ใช้ ANCHOR_LEFT_LOWER (High) / ANCHOR_LEFT_UPPER (Low)
      // p50 ใช้ ANCHOR_RIGHT_LOWER (High) / ANCHOR_RIGHT_UPPER (Low) → label อยู่ซ้ายของ swing point
      if(InpOFA_ShowLabels) {
         string tn2  = "GDX8_OFA2_T" + IntegerToString(i+1);
         int    digs = (_Digits > 3) ? 2 : _Digits;
         bool   isH2 = gdx_swings2[i+1].isHigh;
         string lbl2 = StringFormat("[p50] %s%."+IntegerToString(digs)+"f",
                        isH2 ? "+" : "-",
                        gdx_swings2[i+1].magnitude);
         ObjectCreate(0, tn2, OBJ_TEXT, 0, gdx_swings2[i+1].time, gdx_swings2[i+1].price);
         ObjectSetString (0, tn2, OBJPROP_TEXT,      lbl2);
         ObjectSetInteger(0, tn2, OBJPROP_COLOR,     c2);
         ObjectSetInteger(0, tn2, OBJPROP_FONTSIZE,  InpOFA_LabelFontSize);
         // High → anchor ขวา-ล่าง (label อยู่ซ้าย-บน swing high) ไม่ทับ p26 ที่อยู่ขวา-ล่าง
         // Low  → anchor ขวา-บน  (label อยู่ซ้าย-ล่าง swing low)
         ObjectSetInteger(0, tn2, OBJPROP_ANCHOR,    isH2 ? ANCHOR_RIGHT_LOWER : ANCHOR_RIGHT_UPPER);
         ObjectSetInteger(0, tn2, OBJPROP_SELECTABLE,false);
      }
   }

   // Live leg วาดโดย GdxUpdateLiveSwing2() ซึ่งถูกเรียกทุก tick — ไม่ต้องวาดซ้ำที่นี่
}

string GdxBuildLabelText(int idx)
{
   if(idx < 1) return "";
   GDX_SwingPoint s2 = gdx_swings[idx], s1 = gdx_swings[idx-1];
   bool isBull = s2.isHigh;
   double pV = 0, pM = 0;
   for(int j = idx-2; j >= 0; j--)
      if(gdx_swings[j].isHigh == s2.isHigh && gdx_swings[j].velocity > 0) { pV = gdx_swings[j].velocity; pM = gdx_swings[j].magnitude; break; }
   string txt = "";
   if(InpOFA_IncludeVelMag) txt += GdxGetVMStatus(isBull, s2.velocity, s2.magnitude, pV, pM) + "\n";
   string sign = isBull ? "+" : "-";
   if(InpOFA_IncludePriceChange)  txt += sign + DoubleToString(s2.magnitude, (_Digits > 3 ? 2 : _Digits));
   if(InpOFA_IncludePercentChange) txt += "\n" + sign + DoubleToString(s2.magPct, 2) + "%";
   if(InpOFA_IncludeBarChange)    txt += "\n" + DoubleToString(s2.velocity, 0) + " bars";
   return txt;
}

//+------------------------------------------------------------------+
//| OFA NOTIFICATIONS                                                |
//+------------------------------------------------------------------+
void GdxHandleOFANotifications(int total)
{
   string tf = GdxGetTFString(); string sym = _Symbol;
   datetime lastConfirmedTime  = 0; bool lastConfirmedIsHigh = false; double lastConfirmedPrice = 0;
   if(gdx_LastConfirmedCount > 0) {
      lastConfirmedTime   = gdx_swings[gdx_LastConfirmedCount-1].time;
      lastConfirmedPrice  = gdx_swings[gdx_LastConfirmedCount-1].price;
      lastConfirmedIsHigh = gdx_swings[gdx_LastConfirmedCount-1].isHigh;
   }
   double livePrice = 0; datetime liveTime = 0; double liveVel = 0; double liveMag = 0;
   if(InpOFA_DisplayCurrentSwing && gdx_swingCount > gdx_LastConfirmedCount && gdx_swingCount > 0) {
      livePrice = gdx_swings[gdx_swingCount-1].price; liveTime = gdx_swings[gdx_swingCount-1].time;
      liveVel = MathAbs((double)(gdx_swings[gdx_swingCount-1].bar - gdx_swings[gdx_LastConfirmedCount-1].bar));
      liveMag = MathAbs(gdx_swings[gdx_swingCount-1].price - gdx_swings[gdx_LastConfirmedCount-1].price);
   }
   bool liveLegIsBull = !lastConfirmedIsHigh;
   double prevVel = 0, prevMag = 0; int sameCount = 0;
   for(int si = gdx_LastConfirmedCount - 2; si >= 0; si--) {
      if(gdx_swings[si].isHigh == liveLegIsBull) { sameCount++; if(sameCount == 1) { prevVel = gdx_swings[si].velocity; prevMag = gdx_swings[si].magnitude; break; } }
   }
   string liveTag = InpOFA_NotifyOnLiveSwing ? "⚡" : "✅";

   // ── p50 tag ไม่ใส่ใน notification แล้ว (ลบออกตาม request) ──

   if(InpOFA_NotifyOnLiveSwing && lastConfirmedTime > 0) {
      if(liveLegIsBull && !InpOFA_NotifyBearOnly) {
         bool isNew = (lastConfirmedTime != gdx_LastNotifyBullTime);
         int updateN = (!isNew) ? GdxShouldSendOFAUpdate(liveMag, gdx_LastNotifyBullMag, gdx_LastNotifyBullUpdateN) : 0;
         if(isNew || updateN > 0) {
            string tag = isNew ? liveTag : (liveTag + "↑" + IntegerToString(updateN));
            string msg = GdxBuildOFANotifyMsg(sym, tf, true,  livePrice > 0 ? livePrice : lastConfirmedPrice, liveMag, liveVel, prevVel, prevMag, lastConfirmedTime, tag);
            if(InpOFA_SendNotification) SendNotification(msg); if(InpOFA_SendAlert) Alert(msg);
            gdx_LastNotifyBullTime = lastConfirmedTime; gdx_LastNotifyBullMag = liveMag; gdx_LastNotifyBullUpdateN = isNew ? 0 : updateN;
         }
      } else if(!liveLegIsBull && !InpOFA_NotifyBullOnly) {
         bool isNew = (lastConfirmedTime != gdx_LastNotifyBearTime);
         int updateN = (!isNew) ? GdxShouldSendOFAUpdate(liveMag, gdx_LastNotifyBearMag, gdx_LastNotifyBearUpdateN) : 0;
         if(isNew || updateN > 0) {
            string tag = isNew ? liveTag : (liveTag + "↓" + IntegerToString(updateN));
            string msg = GdxBuildOFANotifyMsg(sym, tf, false, livePrice > 0 ? livePrice : lastConfirmedPrice, liveMag, liveVel, prevVel, prevMag, lastConfirmedTime, tag);
            if(InpOFA_SendNotification) SendNotification(msg); if(InpOFA_SendAlert) Alert(msg);
            gdx_LastNotifyBearTime = lastConfirmedTime; gdx_LastNotifyBearMag = liveMag; gdx_LastNotifyBearUpdateN = isNew ? 0 : updateN;
         }
      }
   } else if(!InpOFA_NotifyOnLiveSwing && lastConfirmedTime > 0) {
      double cVel = (gdx_LastConfirmedCount > 0) ? gdx_swings[gdx_LastConfirmedCount-1].velocity  : 0;
      double cMag = (gdx_LastConfirmedCount > 0) ? gdx_swings[gdx_LastConfirmedCount-1].magnitude : 0;
      if(lastConfirmedIsHigh && !InpOFA_NotifyBearOnly && lastConfirmedTime != gdx_LastNotifyBullTime) {
         string msg = GdxBuildOFANotifyMsg(sym, tf, true,  lastConfirmedPrice, cMag, cVel, prevVel, prevMag, lastConfirmedTime, liveTag);
         if(InpOFA_SendNotification) SendNotification(msg); if(InpOFA_SendAlert) Alert(msg);
         gdx_LastNotifyBullTime = lastConfirmedTime;
      } else if(!lastConfirmedIsHigh && !InpOFA_NotifyBullOnly && lastConfirmedTime != gdx_LastNotifyBearTime) {
         string msg = GdxBuildOFANotifyMsg(sym, tf, false, lastConfirmedPrice, cMag, cVel, prevVel, prevMag, lastConfirmedTime, liveTag);
         if(InpOFA_SendNotification) SendNotification(msg); if(InpOFA_SendAlert) Alert(msg);
         gdx_LastNotifyBearTime = lastConfirmedTime;
      }
   }
}

string GdxBuildOFANotifyMsg(string sym, string tf, bool bull, double p, double m, double v, double pV, double pM, datetime t, string tag) {
   int digs = (_Digits > 3) ? 2 : _Digits;
   string sign = bull ? "+" : "-"; string emo = bull ? "🔵" : "🟠"; string dir = bull ? "BULL" : "BEAR";
   string vS = (pV > 0 && pM > 0) ? GdxGetVMStatus(bull, v, m, pV, pM) : (bull ? "v+ m+" : "v- m-");
   return emo + " " + dir + tag + " " + sym + " " + tf + " | " +
          DoubleToString(p, digs) + " | " + vS + " | " + sign + DoubleToString(m, digs) +
          "pts | " + DoubleToString(v, 0) + "bars | " + TimeToString(t, TIME_MINUTES);
}

int GdxShouldSendOFAUpdate(double curM, double lastM, int lastN) {
   if(curM <= 0 || lastM <= 0 || (InpOFA_NotifyUpdatePts <= 0 && InpOFA_NotifyUpdatePct <= 0)) return 0;
   double g = curM - lastM; double gP = (g / lastM) * 100.0;
   if((InpOFA_NotifyUpdatePts > 0 && g >= InpOFA_NotifyUpdatePts) || (InpOFA_NotifyUpdatePct > 0 && gP >= InpOFA_NotifyUpdatePct)) return lastN + 1;
   return 0;
}

string GdxGetVMStatus(bool isBull, double vel, double mag, double pVel, double pMag) {
   if(pVel <= 0 || pMag <= 0) return isBull ? "v+ m+" : "v- m-";
   string vS = (vel/pVel >= 1.5) ? "v++" : (vel/pVel > 1.0) ? "v+" : (vel/pVel <= 0.67) ? "v--" : (vel/pVel < 1.0) ? "v-" : "v=";
   string mS = (mag/pMag >= 1.5) ? "m++" : (mag/pMag > 1.0) ? "m+" : (mag/pMag <= 0.5)  ? "m--" : (mag/pMag < 1.0) ? "m-" : "m=";
   return vS + " " + mS;
}

string GdxGetTFString() {
   switch(Period()) {
      case PERIOD_M1:  return "M1";  case PERIOD_M5:  return "M5";
      case PERIOD_M15: return "M15"; case PERIOD_M30: return "M30";
      case PERIOD_H1:  return "H1";  case PERIOD_H4:  return "H4";
      case PERIOD_D1:  return "D1";  case PERIOD_W1:  return "W1";
      case PERIOD_MN1: return "MN";
      default: return EnumToString((ENUM_TIMEFRAMES)Period());
   }
}

//+------------------------------------------------------------------+
//| CORE HELPERS (DXY / Gold)                                        |
//+------------------------------------------------------------------+
bool GetSeries(string sym, int offset, int count, double &arr[])
{
   ArraySetAsSeries(arr, true);
   return CopyClose(sym, _Period, offset, count, arr) == count;
}

int TrendDir(const double &arr[], int bars)
{
   double d = arr[0] - arr[bars-1];
   if(d >  0.000001) return  1;
   if(d < -0.000001) return -1;
   return 0;
}

double ZScore(const double &arr[], int period)
{
   if(period < 2) return 0;
   double sum = 0;
   for(int j = 0; j < period; j++) sum += arr[j];
   double mean = sum / period, sq = 0;
   for(int j = 0; j < period; j++) sq += MathPow(arr[j]-mean, 2);
   double sd = MathSqrt(sq / (period-1));
   return (sd < 1e-10) ? 0 : (arr[0]-mean) / sd;
}

double Correlation(int period)
{
   double g[], d[];
   ArraySetAsSeries(g, true); ArraySetAsSeries(d, true);
   if(CopyClose(_Symbol,      _Period, 0, period, g) < period) return 0;
   if(CopyClose(InpDXY_Symbol,_Period, 0, period, d) < period) return 0;
   double sg=0,sd=0,sgd=0,sg2=0,sd2=0;
   for(int j=0;j<period;j++){sg+=g[j];sd+=d[j];sgd+=g[j]*d[j];sg2+=g[j]*g[j];sd2+=d[j]*d[j];}
   double den=MathSqrt(((period*sg2)-(sg*sg))*((period*sd2)-(sd*sd)));
   return (den<1e-10)?0:((period*sgd)-(sg*sd))/den;
}

bool GoldOkForBuy(int offset)
{
   double gc[];
   if(!GetSeries(_Symbol, offset, InpGoldCheckBars+1, gc)) return false;
   double op[],cl[],hi[],lo[];
   ArraySetAsSeries(op,true);ArraySetAsSeries(cl,true);ArraySetAsSeries(hi,true);ArraySetAsSeries(lo,true);
   if(CopyOpen (_Symbol,_Period,offset,InpGoldCheckBars,op)<InpGoldCheckBars) return false;
   if(CopyClose(_Symbol,_Period,offset,InpGoldCheckBars,cl)<InpGoldCheckBars) return false;
   if(CopyHigh (_Symbol,_Period,offset,1,hi)<1) return false;
   if(CopyLow  (_Symbol,_Period,offset,1,lo)<1) return false;
   int bear=0;
   for(int j=0;j<InpGoldCheckBars;j++) if(cl[j]<op[j]) bear++;
   if(bear>InpGoldCheckBars/2) return false;
   double body=MathAbs(cl[0]-op[0]),range=hi[0]-lo[0];
   if(range>0&&(body/range)>InpMomentumRatio&&cl[0]<op[0]) return false;
   int cdn=0;
   for(int j=0;j<InpGoldCheckBars-1;j++) if(gc[j]<gc[j+1]) cdn++;
   if(cdn>=InpGoldCheckBars-1) return false;
   return true;
}

bool GoldOkForSell(int offset)
{
   double gc[];
   if(!GetSeries(_Symbol, offset, InpGoldCheckBars+1, gc)) return false;
   double op[],cl[],hi[],lo[];
   ArraySetAsSeries(op,true);ArraySetAsSeries(cl,true);ArraySetAsSeries(hi,true);ArraySetAsSeries(lo,true);
   if(CopyOpen (_Symbol,_Period,offset,InpGoldCheckBars,op)<InpGoldCheckBars) return false;
   if(CopyClose(_Symbol,_Period,offset,InpGoldCheckBars,cl)<InpGoldCheckBars) return false;
   if(CopyHigh (_Symbol,_Period,offset,1,hi)<1) return false;
   if(CopyLow  (_Symbol,_Period,offset,1,lo)<1) return false;
   int bull=0;
   for(int j=0;j<InpGoldCheckBars;j++) if(cl[j]>op[j]) bull++;
   if(bull>InpGoldCheckBars/2) return false;
   double body=MathAbs(cl[0]-op[0]),range=hi[0]-lo[0];
   if(range>0&&(body/range)>InpMomentumRatio&&cl[0]>op[0]) return false;
   int cup=0;
   for(int j=0;j<InpGoldCheckBars-1;j++) if(gc[j]>gc[j+1]) cup++;
   if(cup>=InpGoldCheckBars-1) return false;
   return true;
}

//+------------------------------------------------------------------+
//| SUB-WINDOW HELPERS                                               |
//+------------------------------------------------------------------+
int GetSubWin()
{
   string sn = StringFormat("GoldDXY Hull+OFA v8.11 [%s]", InpDXY_Symbol);
   int total = (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL);
   for(int w = 0; w < total; w++) {
      int cnt = ChartIndicatorsTotal(0, w);
      for(int k = 0; k < cnt; k++)
         if(ChartIndicatorName(0, w, k) == sn) return w;
   }
   return 1;
}

//+------------------------------------------------------------------+
//| ARROW DRAWING                                                    |
//+------------------------------------------------------------------+
void DrawBuyArrow(int bar_idx, datetime bar_time, double low_price)
{
   string name = OBJ_PREFIX + "ARW_BUY_" + IntegerToString(bar_idx);
   if(ObjectFind(0, name) >= 0) return;
   double y_pos = low_price - InpArrowPoints * _Point;
   ObjectCreate(0, name, OBJ_ARROW, 0, bar_time, y_pos);
   ObjectSetInteger(0, name, OBJPROP_ARROWCODE,  233);
   ObjectSetInteger(0, name, OBJPROP_COLOR,      clrLime);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,      InpArrowSize);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_BACK,       false);
}

void DrawSellArrow(int bar_idx, datetime bar_time, double high_price)
{
   string name = OBJ_PREFIX + "ARW_SELL_" + IntegerToString(bar_idx);
   if(ObjectFind(0, name) >= 0) return;
   double y_pos = high_price + InpArrowPoints * _Point;
   ObjectCreate(0, name, OBJ_ARROW, 0, bar_time, y_pos);
   ObjectSetInteger(0, name, OBJPROP_ARROWCODE,  234);
   ObjectSetInteger(0, name, OBJPROP_COLOR,      clrRed);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,      InpArrowSize);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_BACK,       false);
}

//+------------------------------------------------------------------+
//| TRENDLINES                                                       |
//+------------------------------------------------------------------+
void DrawTL(string name, int win,
            datetime t1, double p1, datetime t2, double p2,
            color clr, int w, ENUM_LINE_STYLE sty,
            string lbl_name, string lbl_txt)
{
   if(ObjectFind(0, name) >= 0) ObjectDelete(0, name);
   if(lbl_name != "" && ObjectFind(0, lbl_name) >= 0) ObjectDelete(0, lbl_name);
   ObjectCreate(0, name, OBJ_TREND, win, t1, p1, t2, p2);
   ObjectSetInteger(0, name, OBJPROP_COLOR,      clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,      w);
   ObjectSetInteger(0, name, OBJPROP_STYLE,      sty);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT,  false);
   ObjectSetInteger(0, name, OBJPROP_RAY_LEFT,   false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_BACK,       true);
   if(lbl_name != "") {
      ObjectCreate(0, lbl_name, OBJ_TEXT, win, t1, p1);
      ObjectSetString (0, lbl_name, OBJPROP_TEXT,     lbl_txt);
      ObjectSetString (0, lbl_name, OBJPROP_FONT,     "Courier New");
      ObjectSetInteger(0, lbl_name, OBJPROP_FONTSIZE, 7);
      ObjectSetInteger(0, lbl_name, OBJPROP_COLOR,    clr);
      ObjectSetInteger(0, lbl_name, OBJPROP_ANCHOR,   ANCHOR_RIGHT_LOWER);
      ObjectSetInteger(0, lbl_name, OBJPROP_SELECTABLE,false);
   }
}

void DelObj(string n) { if(ObjectFind(0, n) >= 0) ObjectDelete(0, n); }

void DeleteTrendLines()
{
   DelObj(TL_S1_GOLD); DelObj(TL_S1_DXY); DelObj(TL_S2_GOLD); DelObj(TL_S2_DXY);
   DelObj(TL_S1_GOLD_LBL); DelObj(TL_S1_DXY_LBL); DelObj(TL_S2_GOLD_LBL); DelObj(TL_S2_DXY_LBL);
   DelObj(OBJ_DXY_LBL);
}

void UpdateTrendLines(int rates_total)
{
   if(!InpShowTL_Step1 && !InpShowTL_Step2) { DeleteTrendLines(); return; }
   if(rates_total < MathMax(InpMacroBars, InpRecentBars) + 5) return;
   if(g_subwin < 0) g_subwin = GetSubWin();

   datetime t_now[]; ArraySetAsSeries(t_now, true); if(CopyTime(_Symbol,_Period,0,1,t_now)<1) return;
   datetime t_s1[];  ArraySetAsSeries(t_s1,  true); if(CopyTime(_Symbol,_Period,InpMacroBars-1,1,t_s1)<1) return;
   datetime t_s2[];  ArraySetAsSeries(t_s2,  true); if(CopyTime(_Symbol,_Period,InpRecentBars-1,1,t_s2)<1) return;
   double g_now[]; ArraySetAsSeries(g_now,true); if(CopyClose(_Symbol,_Period,0,1,g_now)<1) return;
   double g_s1[];  ArraySetAsSeries(g_s1, true); if(CopyClose(_Symbol,_Period,InpMacroBars-1,1,g_s1)<1) return;
   double g_s2[];  ArraySetAsSeries(g_s2, true); if(CopyClose(_Symbol,_Period,InpRecentBars-1,1,g_s2)<1) return;
   double d_now[]; ArraySetAsSeries(d_now,true); if(CopyClose(InpDXY_Symbol,_Period,0,1,d_now)<1) return;
   double d_s1[];  ArraySetAsSeries(d_s1, true); if(CopyClose(InpDXY_Symbol,_Period,InpMacroBars-1,1,d_s1)<1) return;
   double d_s2[];  ArraySetAsSeries(d_s2, true); if(CopyClose(InpDXY_Symbol,_Period,InpRecentBars-1,1,d_s2)<1) return;

   int wm = 0, ws = g_subwin;
   if(InpShowTL_Step1) {
      DrawTL(TL_S1_GOLD, wm, t_s1[0],g_s1[0], t_now[0],g_now[0], InpColorTL_S1_Gold, InpWidthTL_Step1, InpStyleTL_S1, TL_S1_GOLD_LBL, StringFormat("S1 Gold(%d)",InpMacroBars));
      DrawTL(TL_S1_DXY,  ws, t_s1[0],d_s1[0], t_now[0],d_now[0], InpColorTL_S1_DXY,  InpWidthTL_Step1, InpStyleTL_S1, TL_S1_DXY_LBL,  StringFormat("S1 DXY(%d)", InpMacroBars));
   } else { DelObj(TL_S1_GOLD); DelObj(TL_S1_DXY); DelObj(TL_S1_GOLD_LBL); DelObj(TL_S1_DXY_LBL); }
   if(InpShowTL_Step2) {
      DrawTL(TL_S2_GOLD, wm, t_s2[0],g_s2[0], t_now[0],g_now[0], InpColorTL_S2_Gold, InpWidthTL_Step2, InpStyleTL_S2, TL_S2_GOLD_LBL, StringFormat("S2 Gold(%d)",InpRecentBars));
      DrawTL(TL_S2_DXY,  ws, t_s2[0],d_s2[0], t_now[0],d_now[0], InpColorTL_S2_DXY,  InpWidthTL_Step2, InpStyleTL_S2, TL_S2_DXY_LBL,  StringFormat("S2 DXY(%d)", InpRecentBars));
   } else { DelObj(TL_S2_GOLD); DelObj(TL_S2_DXY); DelObj(TL_S2_GOLD_LBL); DelObj(TL_S2_DXY_LBL); }

   DelObj(OBJ_DXY_LBL);
   ObjectCreate(0, OBJ_DXY_LBL, OBJ_TEXT, ws, t_now[0], d_now[0]);
   ObjectSetString (0, OBJ_DXY_LBL, OBJPROP_TEXT,    StringFormat(" %.3f", d_now[0]));
   ObjectSetString (0, OBJ_DXY_LBL, OBJPROP_FONT,    "Courier New");
   ObjectSetInteger(0, OBJ_DXY_LBL, OBJPROP_FONTSIZE,9);
   ObjectSetInteger(0, OBJ_DXY_LBL, OBJPROP_COLOR,   clrLime);
   ObjectSetInteger(0, OBJ_DXY_LBL, OBJPROP_ANCHOR,  ANCHOR_LEFT);
   ObjectSetInteger(0, OBJ_DXY_LBL, OBJPROP_SELECTABLE,false);
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| DASHBOARD                                                        |
//+------------------------------------------------------------------+
void DrawDashboard(int rates_total)
{
   int need = InpMacroBars + InpZPeriod + 5;
   if(rates_total < need) return;

   double dxy_m[],gold_m[],dxy_r[],gold_r[],dxy_t[],gc[];
   if(!GetSeries(InpDXY_Symbol,0,InpMacroBars,     dxy_m))  return;
   if(!GetSeries(_Symbol,      0,InpMacroBars,     gold_m)) return;
   if(!GetSeries(InpDXY_Symbol,0,InpRecentBars,    dxy_r))  return;
   if(!GetSeries(_Symbol,      0,InpRecentBars,    gold_r)) return;
   if(!GetSeries(InpDXY_Symbol,0,InpTriggerBars+1, dxy_t))  return;
   if(!GetSeries(_Symbol,      0,InpZPeriod,       gc))     return;

   int md=TrendDir(dxy_m,InpMacroBars), mg=TrendDir(gold_m,InpMacroBars);
   int rd=TrendDir(dxy_r,InpRecentBars), rg=TrendDir(gold_r,InpRecentBars);
   bool bz=(md==-1&&mg==+1&&rd==-1&&rg==+1);
   bool sz=(md==+1&&mg==-1&&rd==+1&&rg==-1);
   bool pb=(dxy_t[0]<dxy_t[InpTriggerBars]);
   bool rb=(dxy_t[0]>dxy_t[InpTriggerBars]);
   double zg=ZScore(gc,InpZPeriod); double corr=Correlation(InpZPeriod);
   bool gob=GoldOkForBuy(0), gos=GoldOkForSell(0);
   bool mom_ok=bz?gob:(sz?gos:false);
   bool z_ok=MathAbs(zg)<InpGoldZLimit;

   // Hull status for dashboard
   int hullNow = (ArraySize(gdx_HullTrend) > 0) ? (int)gdx_HullTrend[ArraySize(gdx_HullTrend)-1] : 0;
   string hullStr = (hullNow == 1) ? "[UP]" : (hullNow == -1 ? "[DOWN]" : "- N/A");
   color  hullClr = (hullNow == 1) ? InpHL_UpColor : (hullNow == -1 ? InpHL_DownColor : clrGray);

   // MACD dashboard
   double dash_macd_line=0, dash_macd_sig=0, dash_macd_gap=0, dash_macd_prev=0;
   bool   macd_dash_ok=true, macd_dash_ready=false;
   bool   macd_mom_buy_dash=true, macd_mom_sell_dash=true;
   if(InpUseMACDFilter) {
      double dm[], ds[]; ArraySetAsSeries(dm,true); ArraySetAsSeries(ds,true);
      if(CopyBuffer(g_macd_handle,0,0,2,dm)>=2 && CopyBuffer(g_macd_handle,1,0,1,ds)>=1) {
         dash_macd_line=dm[0]; dash_macd_prev=dm[1]; dash_macd_sig=ds[0];
         dash_macd_gap=dm[0]-ds[0]; macd_dash_ready=true;
         macd_mom_buy_dash  = (dash_macd_line > dash_macd_prev);
         macd_mom_sell_dash = (dash_macd_line < dash_macd_prev);
         bool cross_ok = bz ? (dash_macd_gap>InpMACD_MinGap) : (sz ? (dash_macd_gap<-InpMACD_MinGap) : true);
         bool mom_ok_dash = bz ? macd_mom_buy_dash : (sz ? macd_mom_sell_dash : true);
         if(bz) macd_dash_ok = (dash_macd_gap>InpMACD_MinGap) && macd_mom_buy_dash;
         else if(sz) macd_dash_ok = (dash_macd_gap<-InpMACD_MinGap) && macd_mom_sell_dash;
      }
   }

   string dir = bz?"[BUY MODE]":(sz?"[SELL MODE]":"[SCANNING]");
   color  tc  = bz?clrLime:(sz?clrRed:clrGold);
   Lbl("T0", StringFormat("== GoldDXY Hull+OFA v8.11 %s ==", dir), InpDashX, InpDashY, 10, tc);

   int y=InpDashY+18, dy=14;
   Lbl("SEP0","----------------------------------",InpDashX,y,8,clrDimGray); y+=dy-2;

   // STEP 1
   bool s1=(bz?(md==-1&&mg==+1):(sz?(md==+1&&mg==-1):false));
   Lbl("S1H",StringFormat("%s STEP 1: Macro Trend (%d bars)%s",s1?"OK":"XX",InpMacroBars,InpShowTL_Step1?" [TL]":" [--]"),InpDashX,y,9,s1?clrLime:clrOrangeRed); y+=dy;
   string dm2=md>0?"UP":md<0?"DOWN":"FLAT"; bool dm_ok=bz?(md==-1):(md==+1);
   Lbl("S1D",StringFormat("    DXY  Macro : %s  %s",dm2,dm_ok?"OK":StringFormat("Need: %s",bz?"DOWN":"UP")),InpDashX,y,8,dm_ok?clrSilver:clrOrangeRed); y+=dy;
   string gm2=mg>0?"UP":mg<0?"DOWN":"FLAT"; bool gm_ok=bz?(mg==+1):(mg==-1);
   Lbl("S1G",StringFormat("    Gold Macro : %s  %s",gm2,gm_ok?"OK":StringFormat("Need: %s",bz?"UP":"DOWN")),InpDashX,y,8,gm_ok?clrSilver:clrOrangeRed); y+=dy;
   Lbl("SEP1","----------------------------------",InpDashX,y,8,clrDimGray); y+=dy-2;

   // STEP 2
   bool s2=(bz?(rd==-1&&rg==+1):(sz?(rd==+1&&rg==-1):false));
   string s2ic=!s1?"--":(s2?"OK":"..."); color s2cl=!s1?clrDimGray:(s2?clrLime:clrOrangeRed);
   Lbl("S2H",StringFormat("%s STEP 2: Recent Trend (%d bars)%s",s2ic,InpRecentBars,InpShowTL_Step2?" [TL]":" [--]"),InpDashX,y,9,s2cl); y+=dy;
   string dr=rd>0?"UP":rd<0?"DOWN":"FLAT"; bool dr_ok=bz?(rd==-1):(rd==+1);
   Lbl("S2D",StringFormat("    DXY  Recent: %s  %s",dr,dr_ok?"OK":(bz?"Need DOWN":"Need UP")),InpDashX,y,8,!s1?clrDimGray:(dr_ok?clrSilver:clrOrangeRed)); y+=dy;
   string gr=rg>0?"UP":rg<0?"DOWN":"FLAT"; bool gr_ok=bz?(rg==+1):(rg==-1);
   Lbl("S2G",StringFormat("    Gold Recent: %s  %s",gr,gr_ok?"OK":(bz?"Need UP":"Need DOWN")),InpDashX,y,8,!s1?clrDimGray:(gr_ok?clrSilver:clrOrangeRed)); y+=dy;
   Lbl("SEP2","----------------------------------",InpDashX,y,8,clrDimGray); y+=dy-2;

   // STEP 3
   bool s3=(bz&&pb)||(sz&&rb); bool s3a=s1&&s2;
   Lbl("S3H",StringFormat("%s STEP 3: DXY Entry Trigger (%d bars)",!s3a?"--":(s3?"OK":"..."),InpTriggerBars),InpDashX,y,9,!s3a?clrDimGray:(s3?clrLime:clrYellow)); y+=dy;
   Lbl("S3V",StringFormat("    DXY now:%.4f  prev:%.4f  %s",dxy_t[0],dxy_t[InpTriggerBars],s3?"Triggered!":StringFormat("Waiting: %s",bz?"DXY pullback":"DXY bounce")),InpDashX,y,8,!s3a?clrDimGray:(s3?clrLime:clrYellow)); y+=dy;
   Lbl("SEP3","----------------------------------",InpDashX,y,8,clrDimGray); y+=dy-2;

   // STEP 4
   bool s4a=s1&&s2&&s3; string s4ic=!s4a?"--":(z_ok&&mom_ok?"OK":"XX"); color s4cl=!s4a?clrDimGray:(z_ok&&mom_ok?clrLime:clrOrangeRed);
   Lbl("S4H",StringFormat("%s STEP 4: Gold Filters",s4ic),InpDashX,y,9,s4cl); y+=dy;
   Lbl("S4Z",StringFormat("    Z-Score  : %s",z_ok?StringFormat("OK Z=%.2f (+-%.1f)",zg,InpGoldZLimit):StringFormat("XX Z=%.2f (over +-%.1f)",zg,InpGoldZLimit)),InpDashX,y,8,!s4a?clrDimGray:(z_ok?clrSilver:clrOrangeRed)); y+=dy;
   Lbl("S4M",StringFormat("    Momentum : %s",mom_ok?"OK Momentum":(bz?"XX Bearish Momentum":"XX Bullish Momentum")),InpDashX,y,8,!s4a?clrDimGray:(mom_ok?clrSilver:clrOrangeRed)); y+=dy;
   Lbl("S4C",StringFormat("    Corr(Gold/DXY): %.3f%s",corr,(corr>0.3)?"  !! Corr positive!":""),InpDashX,y,8,corr>0.3?clrOrange:clrDimGray); y+=dy;
   Lbl("SEP4","==================================",InpDashX,y,8,clrDimGray); y+=dy-2;

   // STEP 5: MACD
   bool s5a=s1&&s2&&s3&&z_ok&&mom_ok;
   string s5ic,s5_detail,s5_mom; color s5cl;
   if(!InpUseMACDFilter) { s5ic="--"; s5cl=clrDimGray; s5_detail="    MACD Filter: OFF"; s5_mom=""; }
   else if(!macd_dash_ready) { s5ic="?"; s5cl=clrYellow; s5_detail="    MACD: Waiting..."; s5_mom=""; }
   else {
      bool ok=macd_dash_ok; s5ic=!s5a?"--":(ok?"OK":"XX"); s5cl=!s5a?clrDimGray:(ok?clrLime:clrOrangeRed);
      string dir_req=bz?"MACD>Sig (Bullish)":"MACD<Sig (Bearish)";
      s5_detail=StringFormat("    MACD:%.5f  Sig:%.5f  %s",dash_macd_line,dash_macd_sig,ok?StringFormat("OK %s",dir_req):StringFormat("Need: %s",dir_req));
      // Momentum line v8.11
      string mom_arrow = (dash_macd_line > dash_macd_prev) ? "▲ Rising" : (dash_macd_line < dash_macd_prev ? "▼ Falling" : "= Flat");
      bool mom_pass = bz ? macd_mom_buy_dash : (sz ? macd_mom_sell_dash : true);
      string mom_need = bz ? "Need: ▲ Rising" : "Need: ▼ Falling";
      s5_mom = StringFormat("    MACDmom: prev:%.5f  now:%.5f  %s  [%s]",
                             dash_macd_prev, dash_macd_line, mom_arrow,
                             mom_pass ? "OK" : mom_need);
   }
   Lbl("S5H",StringFormat("%s STEP 5: MACD Filter (%d/%d/%d)",s5ic,InpMACD_Fast,InpMACD_Slow,InpMACD_Signal),InpDashX,y,9,s5cl); y+=dy;
   Lbl("S5D",s5_detail,InpDashX,y,8,!InpUseMACDFilter?clrDimGray:(!macd_dash_ready?clrYellow:(!s5a?clrDimGray:(macd_dash_ok?clrSilver:clrOrangeRed)))); y+=dy;
   if(InpUseMACDFilter && macd_dash_ready) {
      bool mom_pass2 = bz ? macd_mom_buy_dash : (sz ? macd_mom_sell_dash : true);
      Lbl("S5M",s5_mom,InpDashX,y,8,!s5a?clrDimGray:(mom_pass2?clrSilver:clrOrangeRed)); y+=dy;
   }
   Lbl("SEP5","==================================",InpDashX,y,8,clrDimGray); y+=dy-2;

   // STEP 6: Hull Suite
   Lbl("S6H", StringFormat("[HULL] Suite (Period=%d):", InpHL_Period), InpDashX, y, 9, clrWhite); y+=dy;
   Lbl("S6V", StringFormat("    Trend : %s", hullStr), InpDashX, y, 9, hullClr); y+=dy;
   Lbl("SEP6","----------------------------------",InpDashX,y,8,clrDimGray); y+=dy-2;

   // STEP 7: OFA Filter (Dual-Period v8.10)
   bool ofaBull  = (gdx_LastConfirmedCount  > 0) ? !gdx_swings[gdx_LastConfirmedCount-1].isHigh  : false;
   bool ofaBull2 = (gdx_LastConfirmedCount2 > 0) ? !gdx_swings2[gdx_LastConfirmedCount2-1].isHigh : false;
   string ofaStr  = (gdx_LastConfirmedCount  > 0) ? (ofaBull  ? "[BULL Leg]" : "[BEAR Leg]") : "- Calculating";
   string ofaStr2 = (InpOFA_FractalPeriod2 > InpOFA_FractalPeriod)
                    ? ((gdx_LastConfirmedCount2 > 0) ? (ofaBull2 ? "[BULL Leg]" : "[BEAR Leg]") : "- Calculating")
                    : "[OFF]";
   color ofaClr   = (gdx_LastConfirmedCount  > 0) ? (ofaBull  ? InpOFA_BullishColour : InpOFA_BearishColour) : clrGray;
   color ofaClr2  = (InpOFA_FractalPeriod2 > InpOFA_FractalPeriod)
                    ? ((gdx_LastConfirmedCount2 > 0) ? (ofaBull2 ? InpOFA_BullishColour : InpOFA_BearishColour) : clrGray)
                    : clrDimGray;

   // AND result
   bool dualOFAMatch = true;
   string dualResult = "---";
   color  dualClr    = clrGray;
   if(InpOFA_FractalPeriod2 > InpOFA_FractalPeriod && gdx_LastConfirmedCount2 > 0 && gdx_LastConfirmedCount > 0) {
      dualOFAMatch = (ofaBull == ofaBull2);
      dualResult   = dualOFAMatch ? "ALIGNED - Signal OK" : "MISMATCH - Block signal";
      dualClr      = dualOFAMatch ? clrLime : clrOrangeRed;
   }

   Lbl("S7H",  "[OFA] Order Flow Filter (Dual-Period v8.10):", InpDashX, y, 9, clrWhite); y+=dy;
   Lbl("S7V1", StringFormat("    p%-3d (Fast): %s", InpOFA_FractalPeriod,  ofaStr),  InpDashX, y, 8, ofaClr);  y+=dy;
   Lbl("S7V2", StringFormat("    p%-3d (Slow): %s", InpOFA_FractalPeriod2, ofaStr2), InpDashX, y, 8, ofaClr2); y+=dy;
   Lbl("S7AND",StringFormat("    AND result : %s", dualResult),                       InpDashX, y, 8, dualClr); y+=dy;
   string ofaAllowStr; color ofaAllowClr;
   if(gdx_LastConfirmedCount > 0) {
      if(ofaBull) { ofaAllowStr = "    [OK] Allow BUY  | [--] Block SELL"; ofaAllowClr = InpOFA_BullishColour; }
      else        { ofaAllowStr = "    [--] Block BUY  | [OK] Allow SELL"; ofaAllowClr = InpOFA_BearishColour; }
   } else          { ofaAllowStr = "    --- Calculating OFA..."; ofaAllowClr = clrGray; }
   Lbl("S7F", ofaAllowStr, InpDashX, y, 8, dualOFAMatch ? ofaAllowClr : clrDimGray); y+=dy;
   Lbl("SEP7","==================================",InpDashX,y,8,clrDimGray); y+=dy-2;

   // RESULT
   bool macd_pass=(!InpUseMACDFilter||!macd_dash_ready||macd_dash_ok);
   bool all=s1&&s2&&s3&&z_ok&&mom_ok&&macd_pass&&dualOFAMatch;
   string rt; color rc;
   if(!bz&&!sz)   { rt="[..] SCANNING - Wait Macro Trend"; rc=clrGold; }
   else if(all)   { rt=bz?"[BUY]  SIGNAL READY - BUY Gold Mismatch":"[SELL] SIGNAL READY - SELL Gold Mismatch"; rc=bz?clrLime:clrRed; }
   else if(s1&&s2&&s3&&z_ok&&mom_ok&&macd_pass&&!dualOFAMatch) { rt="[XX] BLOCKED - OFA p26/p50 Mismatch (Step 7)"; rc=clrOrangeRed; }
   else if(s1&&s2&&s3&&z_ok&&mom_ok&&!macd_pass) { rt=bz?"[XX] BLOCKED - MACD Bearish (Step 5)":"[XX] BLOCKED - MACD Bullish (Step 5)"; rc=clrOrangeRed; }
   else if(s1&&s2&&!s3) { rt=bz?"[..] SETUP OK - Wait DXY pullback (Step 3)":"[..] SETUP OK - Wait DXY bounce (Step 3)"; rc=clrYellow; }
   else if(s1&&!s2)     { rt="[..] MACRO OK - Wait Recent Trend (Step 2)"; rc=clrYellow; }
   else                 { rt="[XX] No condition - Wait new Trend Setup"; rc=clrGray; }
   Lbl("RES", rt, InpDashX, y, 10, rc); y+=dy+2;

   // TL Legend
   Lbl("SEP9","----------------------------------",InpDashX,y,8,clrDimGray); y+=dy-2;
   Lbl("TLH","[TL] Trendlines Main=Gold | Sub=DXY",InpDashX,y,8,clrWhite); y+=dy;
   Lbl("TL1G",StringFormat("  -- S1 Gold(%d): %s",InpMacroBars,InpShowTL_Step1?"ON":"OFF"),InpDashX,y,8,InpShowTL_Step1?InpColorTL_S1_Gold:clrDimGray); y+=dy;
   Lbl("TL1D",StringFormat("  -- S1 DXY (%d): %s",InpMacroBars,InpShowTL_Step1?"ON":"OFF"),InpDashX,y,8,InpShowTL_Step1?InpColorTL_S1_DXY:clrDimGray); y+=dy;
   Lbl("TL2G",StringFormat("  .. S2 Gold(%d): %s",InpRecentBars,InpShowTL_Step2?"ON":"OFF"),InpDashX,y,8,InpShowTL_Step2?InpColorTL_S2_Gold:clrDimGray); y+=dy;
   Lbl("TL2D",StringFormat("  .. S2 DXY (%d): %s",InpRecentBars,InpShowTL_Step2?"ON":"OFF"),InpDashX,y,8,InpShowTL_Step2?InpColorTL_S2_DXY:clrDimGray);
}

//+------------------------------------------------------------------+
//| LABEL HELPER                                                     |
//+------------------------------------------------------------------+
void Lbl(string id, string txt, int x, int y, int fs, color clr)
{
   string name = OBJ_PREFIX + id;
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetString (0, name, OBJPROP_TEXT,      txt);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE,  fs);
   ObjectSetString (0, name, OBJPROP_FONT,      "Courier New");
   ObjectSetInteger(0, name, OBJPROP_COLOR,     clr);
   ObjectSetInteger(0, name, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
}

void CleanAll()
{
   ObjectsDeleteAll(0, OBJ_PREFIX);
   DeleteTrendLines();
   ObjectsDeleteAll(0, "GDX8_HULL_");
   ObjectsDeleteAll(0, "GDX8_OFA_");
   ObjectsDeleteAll(0, "GDX8_OFA2_");   // Slow OFA objects
   ObjectsDeleteAll(0, SB_Prefix);
   ObjectsDeleteAll(0, "GDX8_SVP");
}

//+------------------------------------------------------------------+
//| SIGNAL LOG                                                       |
//| Print รายละเอียดสัญญาณ BUY/SELL ใน Journal/Experts tab          |
//| เปิด/ปิดได้ด้วย InpSignalLog                                    |
//+------------------------------------------------------------------+
void SignalLog(string dir,
               datetime bar_time,
               double   entry,
               double   sl,
               double   tp,
               double   atr,
               double   z_gold,
               double   corr,
               double   dxy_now,
               double   dxy_prev,
               int      md, int mg,   // Macro trend DXY/Gold
               int      rd, int rg,   // Recent trend DXY/Gold
               bool     pb_rb,        // DXY pullback(BUY) or bounce(SELL)
               bool     gok,          // GoldOkForBuy / GoldOkForSell
               double   macd_line,
               double   macd_sig,
               int      ofa_trend,
               int      hull_trend,
               int      bar_gap)
{
   if(!InpSignalLog) return;

   string arrow  = (dir == "BUY") ? "▲" : "▼";
   string sep    = "════════════════════════════════════════";
   string sep2   = "────────────────────────────────────────";
   double rr     = InpATR_TP_Multi / InpATR_SL_Multi;
   double sl_pts = MathAbs(entry - sl) / _Point;
   double tp_pts = MathAbs(tp   - entry) / _Point;

   // ── Header ──
   Print(sep);
   Print(StringFormat("[SIGNAL] %s %s  @ %s  |  Bar: %s",
         arrow, dir, _Symbol,
         TimeToString(bar_time, TIME_DATE|TIME_MINUTES|TIME_SECONDS)));
   Print(sep2);

   // ── Price ──
   Print(StringFormat("  Entry  : %.3f",  entry));
   Print(StringFormat("  SL     : %.3f  (%.0f pts  ATR×%.1f  ATR=%.3f)",
         sl, sl_pts, InpATR_SL_Multi, atr));
   Print(StringFormat("  TP     : %.3f  (%.0f pts  ATR×%.1f  R:R=1:%.1f)",
         tp, tp_pts, InpATR_TP_Multi, rr));

   if(InpSignalLogVerbose)
   {
      Print(sep2);
      // ── Step 1: Macro Trend ──
      string md_s = (md==1)?"UP":(md==-1)?"DOWN":"FLAT";
      string mg_s = (mg==1)?"UP":(mg==-1)?"DOWN":"FLAT";
      bool s1 = (dir=="BUY") ? (md==-1 && mg==1) : (md==1 && mg==-1);
      Print(StringFormat("  STEP1  Macro(%d bars)  DXY:%s  Gold:%s  [%s]",
            InpMacroBars, md_s, mg_s, s1?"OK":"FAIL"));

      // ── Step 2: Recent Trend ──
      string rd_s = (rd==1)?"UP":(rd==-1)?"DOWN":"FLAT";
      string rg_s = (rg==1)?"UP":(rg==-1)?"DOWN":"FLAT";
      bool s2 = (dir=="BUY") ? (rd==-1 && rg==1) : (rd==1 && rg==-1);
      Print(StringFormat("  STEP2  Recent(%d bars)  DXY:%s  Gold:%s  [%s]",
            InpRecentBars, rd_s, rg_s, s2?"OK":"FAIL"));

      // ── Step 3: DXY Trigger ──
      string trig_s = (dir=="BUY") ? "DXY pullback" : "DXY bounce";
      Print(StringFormat("  STEP3  DXY Trigger(%d bars)  now:%.4f  prev:%.4f  %s  [%s]",
            InpTriggerBars, dxy_now, dxy_prev, trig_s, pb_rb?"OK":"FAIL"));

      // ── Step 4: Gold Filters ──
      bool z_ok = MathAbs(z_gold) < InpGoldZLimit;
      Print(StringFormat("  STEP4a Z-Score  : %.3f  (limit ±%.1f)  [%s]",
            z_gold, InpGoldZLimit, z_ok?"OK":"FAIL"));
      Print(StringFormat("  STEP4b Momentum : GoldOk=%s  [%s]",
            gok?"true":"false", gok?"OK":"FAIL"));
      Print(StringFormat("  STEP4c BarGap   : %d bars (min %d)  [%s]",
            bar_gap, InpMinBarGap, (bar_gap>=InpMinBarGap)?"OK":"FAIL"));
      string corr_warn = (corr > 0.3) ? "  !! CORR POSITIVE WARNING" : "";
      Print(StringFormat("  STEP4d Corr(Gold/DXY): %.3f%s", corr, corr_warn));

      // ── Step 5: MACD ──
      if(InpUseMACDFilter) {
         double gap = macd_line - macd_sig;
         bool cross_ok = (dir=="BUY") ? (gap > InpMACD_MinGap) : (gap < -InpMACD_MinGap);
         bool mok = cross_ok;
         string mom_str = "";
         // ดึง MACD 2 bars ล่าสุดจาก handle โดยตรง (ไม่ต้องใช้ offset/rates_total)
         double macd_log_arr[];
         ArraySetAsSeries(macd_log_arr, true);
         if(CopyBuffer(g_macd_handle, 0, 0, 2, macd_log_arr) >= 2) {
            double m_prev = macd_log_arr[1];
            bool mom_ok = (dir=="BUY") ? (macd_line > m_prev) : (macd_line < m_prev);
            mok = cross_ok && mom_ok;
            mom_str = StringFormat("  MACDmom: prev:%.5f  now:%.5f  [%s]",
                                   m_prev, macd_line, mom_ok ? "Rising OK" : "Need other dir");
         } else {
            mom_str = "  MACDmom: prev N/A";
         }
         Print(StringFormat("  STEP5  MACD(%d/%d/%d)  Line:%.5f  Sig:%.5f  Gap:%.5f  [%s]",
               InpMACD_Fast, InpMACD_Slow, InpMACD_Signal,
               macd_line, macd_sig, gap, mok?"OK":"FAIL"));
         Print(mom_str);
      } else {
         Print("  STEP5  MACD Filter: OFF");
      }

      // ── Step 6: Hull ──
      string hull_s = (hull_trend==1)?"UP":(hull_trend==-1)?"DOWN":"N/A";
      bool hok = (dir=="BUY") ? (hull_trend==1) : (hull_trend==-1);
      Print(StringFormat("  STEP6  Hull(Period=%d)  Trend:%s  [%s]",
            InpHL_Period, hull_s, hok?"OK":"INFO"));

      // ── Step 7: OFA (Dual-Period v8.10) ──
      string ofa1_s = (ofa_trend==1)?"BULL":(ofa_trend==-1)?"BEAR":"N/A";
      bool   ofa1ok = (dir=="BUY") ? (ofa_trend==1) : (ofa_trend==-1);
      int    ot2    = GdxGetOFATrendAtBar2(0);
      string ofa2_s = (ot2==1)?"BULL":(ot2==-1)?"BEAR":"N/A";
      bool   ofa2ok = (dir=="BUY") ? (ot2==1) : (ot2==-1);
      bool   andOK  = ofa1ok && (InpOFA_FractalPeriod2<=InpOFA_FractalPeriod || ofa2ok || ot2==0);
      Print(StringFormat("  STEP7a OFA p%-3d (Fast) Trend:%s  [%s]", InpOFA_FractalPeriod,  ofa1_s, ofa1ok?"OK":"INFO"));
      Print(StringFormat("  STEP7b OFA p%-3d (Slow) Trend:%s  [%s]", InpOFA_FractalPeriod2, ofa2_s, ofa2ok?"OK":(ot2==0?"FALLBACK":"MISMATCH")));
      Print(StringFormat("  STEP7  AND result: [%s]", andOK?"ALIGNED":"BLOCKED - OFA mismatch"));
   }

   Print(sep);
}

//+------------------------------------------------------------------+
//| FIRE ALERT (GoldDXY Signal)                                      |
//+------------------------------------------------------------------+
void FireAlert(string dir, double entry, double sl,
               double dxy, double z, double corr, datetime bt,
               double macd_line=0, double macd_sig=0)
{
   // FIX: ใช้ bar_time (bt) เป็น dedup key แทน TimeCurrent()+60
   // ป้องกัน alert ยิงซ้ำทุก tick บน bar เดิม
   if(bt <= last_alert_time) return;
   string em=(dir=="BUY")?"\xE2\x96\xB2 BUY":"\xE2\x96\xBC SELL";
   string cw=(corr>0.3)?"  !! CORR WARNING":"";
   double sl_dist = MathAbs(entry - sl);
   double tp = (dir=="BUY") ? entry + sl_dist*(InpATR_TP_Multi/InpATR_SL_Multi)
                             : entry - sl_dist*(InpATR_TP_Multi/InpATR_SL_Multi);
   string macd_str = InpUseMACDFilter
      ? StringFormat("MACD   : %.5f  Sig:%.5f  Gap:%.5f [%s]\n",
                     macd_line, macd_sig, macd_line-macd_sig,
                     (dir=="BUY")?"Bullish[OK]":"Bearish[OK]")
      : "MACD   : Filter OFF\n";
   string msg=StringFormat(
      "== GoldDXY MISMATCH SIGNAL ==\n"
      "%s  %s %s  @ %s\n"
      "Entry  : %.3f\n"
      "SL     : %.3f  (ATR x %.1f)\n"
      "TP     : %.3f  (ATR x %.1f  R:R=1:%.1f)\n"
      "DXY (%s) : %.4f\nZ-Gold : %.3f (+-%.1f)\n"
      "%s"
      "Corr   : %.3f%s\n"
      "Filters: Macro[OK] Recent[OK] Trigger[OK] Momentum[OK] Z[OK] MACD[OK]\n"
      "==============================",
      em,_Symbol,EnumToString(_Period),TimeToString(bt,TIME_DATE|TIME_MINUTES),
      entry,
      sl,InpATR_SL_Multi,
      tp,InpATR_TP_Multi,(InpATR_TP_Multi/InpATR_SL_Multi),
      InpDXY_Symbol,dxy,z,InpGoldZLimit,
      macd_str,
      corr,cw);
   if(InpSendAlert) Alert(msg);
   if(InpSendPush)  SendNotification(StringFormat(
      "%s %s E:%.3f SL:%.3f TP:%.3f DXY:%.4f Z:%.2f MACD_Gap:%.5f",
      em,_Symbol,entry,sl,tp,dxy,z,macd_line-macd_sig));
   last_alert_time=bt;   // FIX: record bar_time ไม่ใช่ TimeCurrent()
   Print("SIGNAL:",dir," E:",entry," SL:",sl," TP:",tp," DXY:",dxy,
         " Z:",z," Corr:",corr," MACD_Gap:",macd_line-macd_sig);
}

//+------------------------------------------------------------------+
//| SESSION VP — VP_Row struct already declared above                |
//+------------------------------------------------------------------+

bool CalcSessionVP(ENUM_TIMEFRAMES tf, datetime sessionStart, datetime sessionEnd, SessionVP &vp)
{
   MqlRates rates[];
   ArraySetAsSeries(rates, false);
   int copied = CopyRates(_Symbol, tf, sessionStart, sessionEnd, rates);
   if(copied < 3) return false;

   double maxH = -DBL_MAX, minL = DBL_MAX;
   for(int i = 0; i < copied; i++) {
      if(rates[i].high > maxH) maxH = rates[i].high;
      if(rates[i].low  < minL) minL = rates[i].low;
   }
   if(maxH <= minL) return false;

   double rangeV = maxH - minL;
   double step   = rangeV / InpVpRowSize;
   if(step <= 0) return false;

   VP_Row rows[];
   if(ArrayResize(rows, InpVpRowSize) != InpVpRowSize) return false;

   for(int k = 0; k < InpVpRowSize; k++) {
      rows[k].priceByRow = minL + k * step;
      rows[k].volBuy = 0; rows[k].volSell = 0; rows[k].volTotal = 0;
   }

   for(int i = 0; i < copied; i++) {
      double avgP = (rates[i].high + rates[i].low) / 2.0;
      int idx = (int)((avgP - minL) / step);
      if(idx >= InpVpRowSize) idx = InpVpRowSize - 1;
      if(idx < 0) idx = 0;
      long vol = rates[i].tick_volume;
      bool isBull = (rates[i].close >= rates[i].open);
      if(isBull) rows[idx].volBuy  += (double)vol;
      else       rows[idx].volSell += (double)vol;
      rows[idx].volTotal += (double)vol;
   }

   double maxVol = 0, totalVol = 0;
   int pocIdx = 0;
   for(int k = 0; k < InpVpRowSize; k++) {
      if(rows[k].volTotal > maxVol) { maxVol = rows[k].volTotal; pocIdx = k; }
      totalVol += rows[k].volTotal;
   }

   double targetVA = totalVol * InpVpValueArea;
   double curVA    = rows[pocIdx].volTotal;
   int upIdx = pocIdx, dnIdx = pocIdx;
   while(curVA < targetVA) {
      if(upIdx >= InpVpRowSize-1 && dnIdx <= 0) break;
      double nextUp = (upIdx < InpVpRowSize-1) ? rows[upIdx+1].volTotal : 0;
      double nextDn = (dnIdx > 0)              ? rows[dnIdx-1].volTotal : 0;
      if(nextUp >= nextDn && upIdx < InpVpRowSize-1) { upIdx++; curVA += nextUp; }
      else if(dnIdx > 0)                             { dnIdx--; curVA += nextDn; }
      else if(upIdx < InpVpRowSize-1)                { upIdx++; curVA += nextUp; }
      else break;
   }

   vp.poc          = rows[pocIdx].priceByRow + (step / 2.0);
   vp.vah          = rows[upIdx].priceByRow  + step;
   vp.val          = rows[dnIdx].priceByRow;
   vp.sessionHigh  = maxH;
   vp.sessionLow   = minL;
   vp.sessionStart = sessionStart;
   vp.sessionEnd   = sessionEnd;
   vp.isFormed     = true;
   return true;
}

void DrawVPLines(string prefix, SessionVP &vp, color clrPOC, color clrVAH, color clrVAL)
{
   if(!vp.isFormed) return;

   datetime t2;
   if(InpExtendNYtoAsia && StringFind(prefix, "GDX8_SVPN_") == 0) {
      MqlDateTime nyEndDt;
      TimeToStruct(vp.sessionEnd, nyEndDt);
      datetime nextMidnight = (datetime)(vp.sessionEnd
                               - (nyEndDt.hour * 3600 + nyEndDt.min * 60 + nyEndDt.sec)
                               + 86400);
      t2 = nextMidnight + InpAsiaEndHr * 3600;
   } else {
      t2 = (datetime)(vp.sessionEnd + PeriodSeconds(PERIOD_H1) * 8);
   }

   string nPOC = prefix + "POC", nVAH = prefix + "VAH", nVAL = prefix + "VAL";

   ObjectDelete(0, nPOC);
   ObjectCreate(0, nPOC, OBJ_TREND, 0, vp.sessionStart, vp.poc, t2, vp.poc);
   ObjectSetInteger(0, nPOC, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, nPOC, OBJPROP_TIME,  0, vp.sessionStart);
   ObjectSetDouble (0, nPOC, OBJPROP_PRICE, 0, vp.poc);
   ObjectSetInteger(0, nPOC, OBJPROP_TIME,  1, t2);
   ObjectSetDouble (0, nPOC, OBJPROP_PRICE, 1, vp.poc);
   ObjectSetInteger(0, nPOC, OBJPROP_COLOR, clrPOC);
   ObjectSetInteger(0, nPOC, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, nPOC, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, nPOC, OBJPROP_BACK,  true);
   ObjectSetString (0, nPOC, OBJPROP_TOOLTIP, prefix + " POC: " + DoubleToString(vp.poc, _Digits));

   ObjectDelete(0, nVAH);
   ObjectCreate(0, nVAH, OBJ_TREND, 0, vp.sessionStart, vp.vah, t2, vp.vah);
   ObjectSetInteger(0, nVAH, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, nVAH, OBJPROP_TIME,  0, vp.sessionStart);
   ObjectSetDouble (0, nVAH, OBJPROP_PRICE, 0, vp.vah);
   ObjectSetInteger(0, nVAH, OBJPROP_TIME,  1, t2);
   ObjectSetDouble (0, nVAH, OBJPROP_PRICE, 1, vp.vah);
   ObjectSetInteger(0, nVAH, OBJPROP_COLOR, clrVAH);
   ObjectSetInteger(0, nVAH, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, nVAH, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, nVAH, OBJPROP_BACK,  true);
   ObjectSetString (0, nVAH, OBJPROP_TOOLTIP, prefix + " VAH: " + DoubleToString(vp.vah, _Digits));

   ObjectDelete(0, nVAL);
   ObjectCreate(0, nVAL, OBJ_TREND, 0, vp.sessionStart, vp.val, t2, vp.val);
   ObjectSetInteger(0, nVAL, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, nVAL, OBJPROP_TIME,  0, vp.sessionStart);
   ObjectSetDouble (0, nVAL, OBJPROP_PRICE, 0, vp.val);
   ObjectSetInteger(0, nVAL, OBJPROP_TIME,  1, t2);
   ObjectSetDouble (0, nVAL, OBJPROP_PRICE, 1, vp.val);
   ObjectSetInteger(0, nVAL, OBJPROP_COLOR, clrVAL);
   ObjectSetInteger(0, nVAL, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, nVAL, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, nVAL, OBJPROP_BACK,  true);
   ObjectSetString (0, nVAL, OBJPROP_TOOLTIP, prefix + " VAL: " + DoubleToString(vp.val, _Digits));
   ChartRedraw();
}

void ResetVPState(VP_STATE &state) { state = VP_WAITING; }

void CheckVPSignal(string sessionName, SessionVP &vp, VP_STATE &state, datetime &lastNotify,
                   color clrPOC, bool &breakoutNotified, bool &retestNotified)
{
   if(!vp.isFormed) return;

   MqlTick tick;
   SymbolInfoTick(_Symbol, tick);
   double ask = tick.ask;
   double bid = tick.bid;
   double retestTol = InpRetestTolerancePts * _Point;
   double boBuf     = InpBreakoutBufferPts  * _Point;

   if(state == VP_WAITING) {
      if(ask > vp.vah + boBuf)      { state = VP_BROKEN_UP; breakoutNotified = false; retestNotified = false; }
      else if(bid < vp.val - boBuf) { state = VP_BROKEN_DN; breakoutNotified = false; retestNotified = false; }
   }

   if(ask > vp.vah + boBuf) {
      if(state == VP_BROKEN_DN || state == VP_RETESTING_VAL) {
         state = VP_BROKEN_UP; breakoutNotified = false; retestNotified = false;
      }
   } else if(bid < vp.val - boBuf) {
      if(state == VP_BROKEN_UP || state == VP_RETESTING_VAH) {
         state = VP_BROKEN_DN; breakoutNotified = false; retestNotified = false;
      }
   }

   if(state == VP_BROKEN_UP && bid <= vp.vah + retestTol && bid >= vp.vah - retestTol) {
      state = VP_RETESTING_VAH; retestNotified = false;
   }
   if(state == VP_BROKEN_DN && ask >= vp.val - retestTol && ask <= vp.val + retestTol) {
      state = VP_RETESTING_VAL; retestNotified = false;
   }

   if(state == VP_RETESTING_VAH && bid < vp.val - boBuf) {
      state = VP_BROKEN_DN; breakoutNotified = false; retestNotified = false;
      Print("[VP-", sessionName, "] False Breakout UP -> DN | VAH=", DoubleToString(vp.vah, _Digits));
   }
   if(state == VP_RETESTING_VAL && ask > vp.vah + boBuf) {
      state = VP_BROKEN_UP; breakoutNotified = false; retestNotified = false;
      Print("[VP-", sessionName, "] False Breakout DN -> UP | VAL=", DoubleToString(vp.val, _Digits));
   }

   if(lastNotify == TimeCurrent()) return;
   bool notified = false;

   if(InpVpNotifyBreakout) {
      if(state == VP_BROKEN_UP && !breakoutNotified && ask > vp.vah) {
         string msg = StringFormat("BREAKOUT UP [VP-%s] VAH=%.5f POC=%.5f VAL=%.5f Ask=%.5f +%.0f pts",
            sessionName, vp.vah, vp.poc, vp.val, ask, (ask - vp.vah) / _Point);
         Print(msg); if(InpSendPush) SendNotification(msg);
         breakoutNotified = true; notified = true;
      } else if(state == VP_BROKEN_DN && !breakoutNotified && bid < vp.val) {
         string msg = StringFormat("BREAKOUT DN [VP-%s] VAH=%.5f POC=%.5f VAL=%.5f Bid=%.5f %.0f pts",
            sessionName, vp.vah, vp.poc, vp.val, bid, (vp.val - bid) / _Point);
         Print(msg); if(InpSendPush) SendNotification(msg);
         breakoutNotified = true; notified = true;
      }
   }

   if(InpVpNotifyRetest) {
      if(state == VP_RETESTING_VAH && !retestNotified && bid <= vp.vah) {
         string msg = StringFormat("RETEST VAH [VP-%s] BUY Setup | VAH=%.5f POC=%.5f VAL=%.5f Bid=%.5f",
            sessionName, vp.vah, vp.poc, vp.val, bid);
         Print(msg); if(InpSendPush) SendNotification(msg);
         retestNotified = true; notified = true;
      } else if(state == VP_RETESTING_VAL && !retestNotified && ask >= vp.val) {
         string msg = StringFormat("RETEST VAL [VP-%s] SELL Setup | VAH=%.5f POC=%.5f VAL=%.5f Ask=%.5f",
            sessionName, vp.vah, vp.poc, vp.val, ask);
         Print(msg); if(InpSendPush) SendNotification(msg);
         retestNotified = true; notified = true;
      }
   }

   if(notified) lastNotify = TimeCurrent();
}

void RunSessionVP()
{
   if(!InpVpSession) return;

   MqlDateTime dt;
   TimeCurrent(dt);
   int hr = dt.hour;
   datetime today     = (datetime)(TimeCurrent() - (hr * 3600 + dt.min * 60 + dt.sec));
   datetime yesterday = today - 86400;

   datetime asiaStart   = today + InpAsiaStartHr   * 3600;
   datetime asiaEnd     = today + InpAsiaEndHr      * 3600;
   datetime londonStart = today + InpLondonStartHr  * 3600;
   datetime londonEnd   = today + InpLondonEndHr    * 3600;
   datetime nyStart     = today + InpNYStartHr      * 3600;
   datetime nyEnd       = today + InpNYEndHr        * 3600;
   datetime prevNyStart = yesterday + InpNYStartHr  * 3600;
   datetime prevNyEnd   = yesterday + InpNYEndHr    * 3600;

   bool inAsia   = (hr >= InpAsiaStartHr   && hr < InpAsiaEndHr);
   bool inLondon = (hr >= InpLondonStartHr && hr < InpLondonEndHr);
   bool inNY     = (hr >= InpNYStartHr     && hr < InpNYEndHr);

   static int  lastBarAsia = -1, lastBarLondon = -1, lastBarNY = -1;
   static datetime lastDay = 0;
   int curBar = Bars(_Symbol, PERIOD_M1);

   datetime todayDate = (datetime)(TimeCurrent() - (hr * 3600 + dt.min * 60 + dt.sec));
   if(todayDate != lastDay) {
      lastDay = todayDate;
      lastBarAsia = -1; lastBarLondon = -1; lastBarNY = -1;
      VpAsia.isFormed   = false;
      VpLondon.isFormed = false;
      VpNY.isFormed     = false;
      VpBreakoutNotifiedAsia   = false; VpBreakoutNotifiedLondon = false; VpBreakoutNotifiedNY = false;
      VpRetestNotifiedAsia     = false; VpRetestNotifiedLondon   = false; VpRetestNotifiedNY   = false;

      if(InpExtendNYtoAsia && inAsia) {
         if(CalcSessionVP(PERIOD_M1, prevNyStart, prevNyEnd, VpPrevNY)) {
            ResetVPState(VpStatePrevNY);
            VpBreakoutNotifiedPrevNY = false;
            VpRetestNotifiedPrevNY   = false;
            DrawVPLines("GDX8_SVPN_", VpPrevNY, InpColorPOC_NY, InpColorVAH, InpColorVAL);
         }
      }
   }

   // ── Asia VP ──
   static bool VpAsiaFrozen = false;
   if(inAsia) {
      VpAsiaFrozen = false;
   } else if(VpAsia.isFormed && !VpAsiaFrozen) {
      VpAsiaFrozen = true;
      if(InpExtendNYtoAsia && VpPrevNY.isFormed) {
         VpPrevNY.isFormed = false;
         ResetVPState(VpStatePrevNY);
         ObjectDelete(0, "GDX8_SVPN_POC");
         ObjectDelete(0, "GDX8_SVPN_VAH");
         ObjectDelete(0, "GDX8_SVPN_VAL");
      }
   }
   if(!VpAsiaFrozen && (inAsia || hr >= InpAsiaEndHr) && curBar != lastBarAsia) {
      datetime calcEnd = inAsia ? TimeCurrent() : asiaEnd;
      if(CalcSessionVP(PERIOD_M1, asiaStart, calcEnd, VpAsia)) {
         DrawVPLines("GDX8_SVPA_", VpAsia, InpColorPOC_Asia, InpColorVAH, InpColorVAL);
         if(inAsia && lastBarAsia == -1) { ResetVPState(VpStateAsia); VpBreakoutNotifiedAsia = false; VpRetestNotifiedAsia = false; }
      }
      lastBarAsia = curBar;
   }

   // ── London VP ──
   bool londonVpFrozen = (!inLondon && VpLondon.isFormed);
   if(!londonVpFrozen && (inLondon || hr >= InpLondonEndHr) && curBar != lastBarLondon) {
      datetime calcEnd = inLondon ? TimeCurrent() : londonEnd;
      if(CalcSessionVP(PERIOD_M1, londonStart, calcEnd, VpLondon)) {
         DrawVPLines("GDX8_SVPL_", VpLondon, InpColorPOC_London, InpColorVAH, InpColorVAL);
         if(inLondon && lastBarLondon == -1) { ResetVPState(VpStateLondon); VpBreakoutNotifiedLondon = false; VpRetestNotifiedLondon = false; }
      }
      lastBarLondon = curBar;
   }

   // ── NY VP ──
   bool nyVpFrozen = (!inNY && VpNY.isFormed);
   if(!nyVpFrozen && (inNY || hr >= InpNYEndHr) && curBar != lastBarNY) {
      datetime calcEnd = inNY ? TimeCurrent() : nyEnd;
      if(CalcSessionVP(PERIOD_M1, nyStart, calcEnd, VpNY)) {
         DrawVPLines("GDX8_SVPN_", VpNY, InpColorPOC_NY, InpColorVAH, InpColorVAL);
         if(inNY && lastBarNY == -1) { ResetVPState(VpStateNY); VpBreakoutNotifiedNY = false; VpRetestNotifiedNY = false; }
      }
      lastBarNY = curBar;
   }

   // ── ตรวจ Signal ทุก tick ──
   if(VpAsia.isFormed)   CheckVPSignal("Asia",   VpAsia,   VpStateAsia,   VpLastNotifyAsia,   InpColorPOC_Asia,   VpBreakoutNotifiedAsia,   VpRetestNotifiedAsia);
   if(VpLondon.isFormed) CheckVPSignal("London", VpLondon, VpStateLondon, VpLastNotifyLondon, InpColorPOC_London, VpBreakoutNotifiedLondon, VpRetestNotifiedLondon);
   if(VpNY.isFormed)     CheckVPSignal("NY",     VpNY,     VpStateNY,     VpLastNotifyNY,     InpColorPOC_NY,     VpBreakoutNotifiedNY,     VpRetestNotifiedNY);

   // ── PrevNY extend ──
   if(InpExtendNYtoAsia && VpPrevNY.isFormed && inAsia) {
      static int lastBarPrevNY = -1;
      if(curBar != lastBarPrevNY) {
         DrawVPLines("GDX8_SVPN_", VpPrevNY, InpColorPOC_NY, InpColorVAH, InpColorVAL);
         lastBarPrevNY = curBar;
      }
      static datetime prevNyLastNotify = 0;
      CheckVPSignal("NY(prev)", VpPrevNY, VpStatePrevNY, prevNyLastNotify, InpColorPOC_NY, VpBreakoutNotifiedPrevNY, VpRetestNotifiedPrevNY);
   }

   // ── POC Confluence: Asia vs London ──
   if(InpVpNotifyConfl && VpAsia.isFormed && VpLondon.isFormed) {
      double diff = MathAbs(VpAsia.poc - VpLondon.poc);
      if(diff <= InpVpConfluenceRange * _Point) {
         int curBarC = Bars(_Symbol, PERIOD_M1);
         if(curBarC != VpLastNotifyBar) {
            string msg = StringFormat(
               "POC Confluence Asia~London | Asia POC=%.5f VAH=%.5f VAL=%.5f | London POC=%.5f VAH=%.5f VAL=%.5f | gap=%.0f pts",
               VpAsia.poc, VpAsia.vah, VpAsia.val,
               VpLondon.poc, VpLondon.vah, VpLondon.val,
               diff / _Point);
            Print(msg);
            if(InpSendPush) SendNotification(msg);
            VpLastNotifyBar = curBarC;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| SESSION BOX FUNCTIONS                                            |
//+------------------------------------------------------------------+
void DrawOneSessionBox(string tag, datetime tStart, datetime tEnd,
                       double hi, double lo, color clrBox,
                       string label, bool showBorder, int borderW,
                       bool showLabel, int lblSize, bool showHL, int hlW)
{
   string bgName  = SB_Prefix + tag + "_BG";
   string brdName = SB_Prefix + tag + "_BRD";
   string txtName = SB_Prefix + tag + "_LBL";
   string hiName  = SB_Prefix + tag + "_HI";
   string loName  = SB_Prefix + tag + "_LO";

   int r = (int)((clrBox >> 16) & 0xFF);
   int g = (int)((clrBox >> 8)  & 0xFF);
   int b = (int)( clrBox        & 0xFF);
   int rb = MathMin(255, (int)(r * 1.6 + 40));
   int gb = MathMin(255, (int)(g * 1.6 + 40));
   int bb = MathMin(255, (int)(b * 1.6 + 40));
   color clrBright = (color)((rb << 16) | (gb << 8) | bb);

   if(ObjectFind(0, bgName) < 0)
      ObjectCreate(0, bgName, OBJ_RECTANGLE, 0, tStart, hi, tEnd, lo);
   ObjectSetInteger(0, bgName, OBJPROP_TIME,  0, tStart);
   ObjectSetDouble (0, bgName, OBJPROP_PRICE, 0, hi);
   ObjectSetInteger(0, bgName, OBJPROP_TIME,  1, tEnd);
   ObjectSetDouble (0, bgName, OBJPROP_PRICE, 1, lo);
   ObjectSetInteger(0, bgName, OBJPROP_COLOR,    clrBox);
   ObjectSetInteger(0, bgName, OBJPROP_BACK,     true);
   ObjectSetInteger(0, bgName, OBJPROP_FILL,     true);
   ObjectSetInteger(0, bgName, OBJPROP_WIDTH,    0);
   ObjectSetInteger(0, bgName, OBJPROP_STYLE,    STYLE_SOLID);
   ObjectSetInteger(0, bgName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, bgName, OBJPROP_HIDDEN,   true);

   if(showBorder) {
      if(ObjectFind(0, brdName) < 0)
         ObjectCreate(0, brdName, OBJ_RECTANGLE, 0, tStart, hi, tEnd, lo);
      ObjectSetInteger(0, brdName, OBJPROP_TIME,  0, tStart);
      ObjectSetDouble (0, brdName, OBJPROP_PRICE, 0, hi);
      ObjectSetInteger(0, brdName, OBJPROP_TIME,  1, tEnd);
      ObjectSetDouble (0, brdName, OBJPROP_PRICE, 1, lo);
      ObjectSetInteger(0, brdName, OBJPROP_COLOR,   clrBright);
      ObjectSetInteger(0, brdName, OBJPROP_BACK,    false);
      ObjectSetInteger(0, brdName, OBJPROP_FILL,    false);
      ObjectSetInteger(0, brdName, OBJPROP_WIDTH,   borderW);
      ObjectSetInteger(0, brdName, OBJPROP_STYLE,   STYLE_SOLID);
      ObjectSetInteger(0, brdName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, brdName, OBJPROP_HIDDEN,  true);
   }

   if(showLabel) {
      if(ObjectFind(0, txtName) < 0)
         ObjectCreate(0, txtName, OBJ_TEXT, 0, tStart, hi);
      ObjectSetInteger(0, txtName, OBJPROP_TIME,  tStart);
      ObjectSetDouble (0, txtName, OBJPROP_PRICE, hi);
      ObjectSetString (0, txtName, OBJPROP_TEXT,  label);
      ObjectSetInteger(0, txtName, OBJPROP_COLOR, clrBright);
      ObjectSetInteger(0, txtName, OBJPROP_FONTSIZE, lblSize);
      ObjectSetString (0, txtName, OBJPROP_FONT,  "Arial Bold");
      ObjectSetInteger(0, txtName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
      ObjectSetInteger(0, txtName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, txtName, OBJPROP_HIDDEN, true);
   }

   if(showHL) {
      if(ObjectFind(0, hiName) < 0)
         ObjectCreate(0, hiName, OBJ_TREND, 0, tStart, hi, tEnd, hi);
      ObjectSetInteger(0, hiName, OBJPROP_TIME,  0, tStart);
      ObjectSetDouble (0, hiName, OBJPROP_PRICE, 0, hi);
      ObjectSetInteger(0, hiName, OBJPROP_TIME,  1, tEnd);
      ObjectSetDouble (0, hiName, OBJPROP_PRICE, 1, hi);
      ObjectSetInteger(0, hiName, OBJPROP_COLOR,  clrBright);
      ObjectSetInteger(0, hiName, OBJPROP_WIDTH,  hlW);
      ObjectSetInteger(0, hiName, OBJPROP_STYLE,  STYLE_DASH);
      ObjectSetInteger(0, hiName, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, hiName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, hiName, OBJPROP_HIDDEN, true);
      if(ObjectFind(0, loName) < 0)
         ObjectCreate(0, loName, OBJ_TREND, 0, tStart, lo, tEnd, lo);
      ObjectSetInteger(0, loName, OBJPROP_TIME,  0, tStart);
      ObjectSetDouble (0, loName, OBJPROP_PRICE, 0, lo);
      ObjectSetInteger(0, loName, OBJPROP_TIME,  1, tEnd);
      ObjectSetDouble (0, loName, OBJPROP_PRICE, 1, lo);
      ObjectSetInteger(0, loName, OBJPROP_COLOR,  clrBright);
      ObjectSetInteger(0, loName, OBJPROP_WIDTH,  hlW);
      ObjectSetInteger(0, loName, OBJPROP_STYLE,  STYLE_DASH);
      ObjectSetInteger(0, loName, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, loName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, loName, OBJPROP_HIDDEN, true);
   }
}

void DrawSessionBoxes()
{
   if(!InpShowSessionBox) return;
   int lookback = MathMax(1, MathMin(7, InpSessionBoxLookbackDays));

   for(int dayOffset = 0; dayOffset < lookback; dayOffset++)
   {
      datetime baseTime = TimeCurrent() - dayOffset * 86400;
      MqlDateTime dtBase;
      TimeToStruct(baseTime, dtBase);
      dtBase.hour = 0; dtBase.min = 0; dtBase.sec = 0;
      datetime dayStart = StructToTime(dtBase);

      string daySuffix = TimeToString(dayStart, TIME_DATE);
      StringReplace(daySuffix, ".", "");
      StringReplace(daySuffix, "-", "");
      StringReplace(daySuffix, " ", "");

      if(InpSessionBoxAsiaEnable)
      {
         datetime aS = dayStart + InpAsiaStartHr * 3600;
         datetime aE = dayStart + InpAsiaEndHr   * 3600;
         if(aE > aS) {
            int s1 = iBarShift(_Symbol, PERIOD_M1, aS, false);
            int s2 = iBarShift(_Symbol, PERIOD_M1, aE, false);
            if(s1 >= s2 && s2 >= 0) {
               double hi = -DBL_MAX, lo = DBL_MAX;
               for(int bx = s2; bx <= s1; bx++) {
                  hi = MathMax(hi, iHigh(_Symbol, PERIOD_M1, bx));
                  lo = MathMin(lo, iLow (_Symbol, PERIOD_M1, bx));
               }
               if(hi > lo && hi > 0)
                  DrawOneSessionBox("ASIA_" + daySuffix, aS, aE, hi, lo,
                     InpSessionBoxAsiaColor, "Asia",
                     InpSessionBoxBorder, InpSessionBoxBorderWidth,
                     InpSessionBoxLabel,  InpSessionBoxLabelSize,
                     InpSessionBoxShowHL, InpSessionBoxHLWidth);
            }
         }
      }

      if(InpSessionBoxLondonEnable)
      {
         datetime lS = dayStart + InpLondonStartHr * 3600;
         datetime lE = dayStart + InpLondonEndHr   * 3600;
         if(lE > lS) {
            int s1 = iBarShift(_Symbol, PERIOD_M1, lS, false);
            int s2 = iBarShift(_Symbol, PERIOD_M1, lE, false);
            if(s1 >= s2 && s2 >= 0) {
               double hi = -DBL_MAX, lo = DBL_MAX;
               for(int bx = s2; bx <= s1; bx++) {
                  hi = MathMax(hi, iHigh(_Symbol, PERIOD_M1, bx));
                  lo = MathMin(lo, iLow (_Symbol, PERIOD_M1, bx));
               }
               if(hi > lo && hi > 0)
                  DrawOneSessionBox("LDN_" + daySuffix, lS, lE, hi, lo,
                     InpSessionBoxLondonColor, "London",
                     InpSessionBoxBorder, InpSessionBoxBorderWidth,
                     InpSessionBoxLabel,  InpSessionBoxLabelSize,
                     InpSessionBoxShowHL, InpSessionBoxHLWidth);
            }
         }
      }

      if(InpSessionBoxNYEnable)
      {
         datetime nS = dayStart + InpNYStartHr * 3600;
         datetime nE = dayStart + InpNYEndHr   * 3600;
         if(nE > nS) {
            int s1 = iBarShift(_Symbol, PERIOD_M1, nS, false);
            int s2 = iBarShift(_Symbol, PERIOD_M1, nE, false);
            if(s1 >= s2 && s2 >= 0) {
               double hi = -DBL_MAX, lo = DBL_MAX;
               for(int bx = s2; bx <= s1; bx++) {
                  hi = MathMax(hi, iHigh(_Symbol, PERIOD_M1, bx));
                  lo = MathMin(lo, iLow (_Symbol, PERIOD_M1, bx));
               }
               if(hi > lo && hi > 0)
                  DrawOneSessionBox("NY_" + daySuffix, nS, nE, hi, lo,
                     InpSessionBoxNYColor, "New York",
                     InpSessionBoxBorder, InpSessionBoxBorderWidth,
                     InpSessionBoxLabel,  InpSessionBoxLabelSize,
                     InpSessionBoxShowHL, InpSessionBoxHLWidth);
            }
         }
      }
   }
   ChartRedraw();
}