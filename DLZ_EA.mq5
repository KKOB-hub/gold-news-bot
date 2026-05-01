//+------------------------------------------------------------------+
//|                               DLZ_EA.mq5                         |
//|  EA based on Dynamic Liquidity Zones Indicator                   |
//|  Signal: EQL→BUY, EQH(streak>=3)→SELL                           |
//+------------------------------------------------------------------+
#property copyright   "DLZ EA"
#property version     "2.02"
#property description "DLZ EA -- Auto trading on EQH/EQL zones"
//+------------------------------------------------------------------+
//|  RELEASE NOTES                                                   |
//+------------------------------------------------------------------+
// v2.00 | 2026-05-01 | NR Mode4: remove Hull M15 filter — follow Hull M1 only (BUY+SELL hard check M1 only)
// v1.99 | 2026-05-01 | SmartNR: fix RankTight→sliding pairs (match Pine), remove Setup Timeout, fix line extend forward, buffer 2000→5000
// v1.97 | 2026-04-30 | Fibo filter: block if max(p26,fx) > fiboMaxPct for both BUY and SELL (fix conflicting Fibo source bypass)
// v1.96 | 2026-04-30 | NR Mode4: Hull M1 hard check always active (fix $30 loss) + Fibo fx hard cap >150% for SELL always active (fix $54 loss)
// v1.95 | 2026-04-30 | SNR Arrow: add Hull M15 filter (blocks BUY/SELL if M15 not aligned), active even in DirectEntry mode
// v1.94 | 2026-04-30 | Setup Timeout: cancel nr_pend if price doesn't break within InpNR_ExtendFwd bars
// v1.93 | 2026-04-30 | Fix SNR stop detecting after long run: detect sliding window shift each tick, adjust all stored bar indices (leftBar/trigBar/endBar/pend/expBar) + shift nr_wasSetup array
// v1.92 | 2026-04-29 | NR SNR lines: extend by endBar instead of exited flag — lines visible for full ExtendFwd window even if pattern exits early
// v1.91 | 2026-04-29 | SafeSendNotification: retry queue (1 slot, +5s delay) เมื่อ MT5 push socket fail
// v1.90 | 2026-04-29 | Fix SNR lines disappear after long run: extend hiL_/loL_ each tick + recalc MA 400 bars on new bar
// v1.89 | 2026-04-29 | NR Mode4 Reversal: หลัง trigger ยิง เฝ้าดู breakout ทิศตรงข้ามภายใน ExtendFwd (SELL→BUY / BUY→SELL), arrow สี DodgerBlue
// v1.88 | 2026-04-29 | NR Mode4: เปลี่ยน once-per-bar guard จาก static local → global g_lastNROrderBar (ไม่ reset เมื่อ EA reload)
// v1.87 | 2026-04-29 | M15CV_PROG label: สี clrYellow, font size 7
// v1.86 | 2026-04-29 | M15 Candle Visual: แสดง progress bar count "5/15" กลางแท่งปัจจุบัน
// v1.85 | 2026-04-29 | NR MA: Slope Lookback + Threshold anti-flip (InpNR_MaSlopeLB / InpNR_MaSlopeThresh)
// v1.84 | 2026-04-29 | SmartNR cold-start: remove !wasColdStart from shouldDraw — draw within MaxKeep window on initial load
// v1.83 | 2026-04-28 | SafeSendNotification: rate-limit push to >=5s apart (prevent MT5 send failed spam)
// v1.82 | 2026-04-28 | Disable NR MA flip close positions (NR_ARROW_SELL/BUY CLOSE_ALL removed)
// v1.81 | 2026-04-28 | SmartNR overlap: align to Pine Script — check last pattern only, bar overlap only (remove Layer1/2/3)
// v1.80 | 2026-04-28 | SmartNR cold-start: suppress box drawing via !wasColdStart in shouldDraw (no ObjectsDeleteAll)
// v1.79 | 2026-04-28 | SmartNR cold-start: delete all NR chart objects after reload (overlap memory preserved)
// v1.78 | 2026-04-28 | SmartNR Density Filter: bar buffer 5 bars + midpoint price buffer 50pts + strict price overlap
// v1.77 | 2026-04-28 | NR MA flip DN→UP ปิด NR_ARROW_SELL; UP→DN ปิด NR_ARROW_BUY (magic+symbol+comment filter)
// v1.76 | 2026-04-28 | SmartNR: วาด box/arrow เฉพาะ MaxKeep bars ล่าสุด; cold-start เก็บ active overlap memory
// v1.75 | 2026-04-28 | SmartNR Mode4: both Round1+Round2 fire orders; Round1=gray arrow, Round2=white arrow
// v1.74 | 2026-04-28 | SmartNR Mode4: 2-round confirmation — Round1=arrow only (gray), Round2=order+white arrow
// v1.73 | 2026-04-28 | SmartNR Mode4: clear nr_patCnt after cold-start so historical patterns don't block live overlap check
// v1.72 | 2026-04-28 | SmartNR NR_RankTight: fix rank logic (compare each hist bar vs fixed current, not sliding pairs)
// v1.71 | 2026-04-28 | SmartNR NR_RankTight: initial fix attempt (partial)
// v1.70 | 2026-04-27 | SmartNR notify: suppress historical patterns after EA reload (wasColdStart)
// v1.69 | 2026-04-27 | Revert p50 Extension guard (v1.67) — ลบ [C] block BUY >100%
// v1.68 | 2026-04-27 | SmartNR notify: fix rangeUSD × InpLot (was 100× inflated)
// v1.67 | 2026-04-27 | DXY_AUTO BUY: block p50 Fibo > 100% (Extension zone guard)
// v1.66 | 2026-04-27 | Raise BE defaults: TriggerUSD 1.0→3.0, BufferUSD 0.5→1.5
// v1.65 | 2026-04-27 | Embed SmartNR_IB as NR_Calculate() sub-module (InpNR_Enable toggle)
// v1.63 | 2026-04-24 | Live swing scan lastB total-2 (skip forming bar) → Real/Demo consistent
// v1.62 | 2026-04-24 | EMA dist → USD (tickVal*tickSize*Lot)
// v1.61 | 2026-04-24
//   - Dashboard: เพิ่มแถว EMA_STATUS (BULL/BEAR/SIDE | slope | dist | E200 | action)
//     ใต้ TITLE ใน Market Context panel — ใช้ g_emaHandle ที่มีอยู่แล้ว
//
// v1.57 | 2026-04-23
//   - EMA: เปลี่ยนจาก OBJ_TREND เป็น ChartIndicatorAdd (ไม่กระพริบ, เร็วขึ้น)
//
// v1.56 | 2026-04-23
//   - EMA Overlay: เพิ่มเส้น EMA 2 เส้น (200/720) พร้อม input เปิด/ปิด
//
// v1.55 | 2026-04-23
//   - Strategic What's Next: แยกเป็น 3 ชั้น Bias/Setup/Entry
//   - GetBiasScore: p50+M15+DXY (hard block ถ้า p50 ขัด)
//   - GetSetupScore: sweep decay, zone distance, R:R, M1
//   - GetEntryBlockReason: ตรวจ hard filters จริงทุกตัว
//   - Sweep Decay: 0-3 bars=+30, 4-8 bars=+15, >8=0
//   - Confidence bar = Bias*60% + Setup*40%
//
// v1.54 | 2026-04-23
//   - Hull Trail SL: เพิ่ม threshold กำไร $1 USD ก่อนเริ่มเลื่อน SL
//     (เดิมเลื่อนทันทีตั้งแต่แท่งแรก แม้ยังไม่มีกำไร)
//
// v1.52 | prior
//   - Hull Trail SL + Dynamic TP (candle-close based)
//   - Fibo 261.8% SL Mode, DXY Market Monitor, Session Filter
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>

//--- Object name prefix (used for bulk cleanup)
#define OBJ_PREFIX "DLZ_"
#define DASH_PREFIX "DLZ_DASH_" // สำหรับ Dashboard

//+------------------------------------------------------------------+
//|  INPUTS                                                          |
//+------------------------------------------------------------------+
input group           "=== EA General ==="
input bool   InpEA_Enable      = true;    // Enable Auto Trading (Master Switch)
input int    InpMagicNumber    = 20260403;// Magic Number
input double InpLot            = 0.01;    // Lot Size
input double InpTP_USD         = 3.0;     // Take Profit (USD)
input double InpSL_USD         = 30.0;    // Stop Loss (USD) — used as min floor in Mode 1
input int    InpSL_Mode        = 1;       // SL Mode: 0=USD Fixed, 1=Fibo 261.8% Extension (P26/M1)
input double InpSL_FiboBuffer  = 2.0;    // [Mode 1] Extra buffer beyond 261.8% level (USD)
input int    InpMaxBuy         = 2;       // Max Buy Orders
input int    InpMaxSell        = 2;       // Max Sell Orders
input double InpCloseAllProfit = 10.0;    // Close All when Total Profit >= USD (0=disabled)
input double InpBE_TriggerUSD  = 3.0;    // Move SL to Break Even when profit >= USD (0=off)
input double InpBE_BufferUSD   = 1.5;    // Buffer above entry for BE SL (USD)

input group           "=== Hull Trail SL + Dynamic TP ==="
input bool   InpHullTrailEnable  = true;   // Enable Hull Trail SL (on candle close)
input bool   InpHullDynTPEnable  = true;   // Enable Dynamic TP → next EQH/EQL (requires Trail)
input int    InpHullTrailBars    = 3;      // Hull lookback bars for SL (default=3, noise buffer)
input double InpHullDynTP_Mult   = 2.0;   // Fallback TP multiplier if no EQH/EQL found

input group           "=== DXY Market Monitor ==="
input string InpDXY_Symbol      = "DXYm";  // DXY Symbol Name (DXY, USDX, DXYm)
input int    InpDXY_Lookback    = 30;       // Bars to calculate trend
input bool   InpDXY_AutoTrade   = true;    // Enable DXY Auto Trade (Buy/Sell on trend change)
input bool   InpFlatClose_Enable    = true;  // Close orders when DXY is FLAT
input double InpFlatClose_MinProfit = 1.0;    // Min profit (USD) required to close on FLAT
input int    InpFlatClose_DelaySec  = 180;    // Seconds DXY must stay FLAT before closing (0=instant)
input bool   InpFlatClose_HullFilter = true;   // Hold on DXY FLAT — wait Hull M1 flip before closing
input int    InpFlatClose_TimeoutSec = 600;    // Force close if Hull doesn't flip within N seconds
input double InpFlatClose_SlopeThreshold = 0.10; // Hull M1 slope decel threshold (0=off, USD/bar e.g. 0.10)

input group           "=== DXY Max Distance Filter ==="
input int    InpMaxHullDistM1   = 750;    // Max Distance from Hull M1 (Points) — 0=disabled
input bool   InpUseDynamicATR   = true;   // Use ATR-based Dynamic Limit instead of fixed
input double InpATRMultiplier   = 2.5;    // ATR Multiplier (only when Dynamic ATR = true)

input group           "=== Liquidity Detection ==="
input int    InpLeftLen       = 10;          // Pivot Left Length
input int    InpRightLen      = 2;           // Pivot Right Length
input double InpThresholdPct  = 0.03;        // Equality Threshold (%)
input int    InpMaxZones      = 60;          // Max Active Zones
input bool   InpMinGapFilter  = true;        // [Filter] Min Gap between same-type zones
input double InpMinZoneGapUSD = 2.0;         // [Filter] Min Gap (USD) — block zone if too close to existing

input group           "=== Visuals ==="
input color  InpBullColor     = C'8,153,129';    // Bullish Zone Color  (#089981)
input color  InpBearColor     = C'242,54,69';    // Bearish Zone Color  (#F23645)
input int    InpZoneTransp    = 85;          // Zone Transparency (0=opaque 100=clear)
input bool   InpShowMidline   = false;       // Show Midline
input color  InpMidlineColor  = C'120,123,134';  // Midline Color       (#787B86)
input bool   InpShowVolume    = true;        // Show Volume
input bool   InpDeleteOnSweep = true;        // Delete on Sweep

//--- เพิ่ม enum และ input เพื่อเลือกประเภท Volume
enum ENUM_VOL_TYPE { Vol_Tick, Vol_Real };

input group           "=== Liquidity Detection ==="
input ENUM_VOL_TYPE InpVolType = Vol_Tick; // Volume Type (Forex/Gold use Tick)
input int    InpRVolPeriod     = 50;   // RVol: Avg period (bars)
input double InpRVolCreateMult = 1.5;  // RVol: CreateZone threshold multiplier
input double InpRVolOrderMult  = 0;  // RVol: Order entry threshold multiplier

//--- [NEW] DASHBOARD INPUTS ---
input group           "=== Dashboard Settings ==="
input bool   InpShowDash      = true;        // Show Status Dashboard
input int    InpDashX         = 20;          // Offset X (จากมุมขวา)
input int    InpDashY         = 30;          // Offset Y
input color  InpDashTxtColor  = clrWhite;    // Dashboard Text Color

input bool   InpOFA_AggressiveFractal   = true;
input int    InpOFA_FractalPeriod       = 26;            // Fast fractal period (p26)
input int    InpOFA_FractalPeriod2      = 40;            // Slow fractal period (p50)
input bool   InpOFA_ShowZigzag          = true;          // Show p26 Zigzag lines
input bool   InpOFA_ShowZigzag2         = true;          // Show p50 Zigzag lines
input color  InpOFA_BullishColour       = clrDodgerBlue;
input color  InpOFA_BearishColour       = clrOrangeRed;
input color  InpOFA_SlowBullColour      = clrDeepSkyBlue;
input color  InpOFA_SlowBearColour      = clrTomato;
input int    InpOFA_SlowLineWidth       = 3;
input bool   InpOFA_ShowLabels          = true;
input bool   InpOFA_IncludeVelMag       = true;
input bool   InpOFA_IncludePriceChange  = true;
input bool   InpOFA_IncludePercentChange= false;
input bool   InpOFA_IncludeBarChange    = false;
input bool   InpOFA_ShowFibLabel        = true;
input int    InpOFA_LabelFontSize       = 9;
input int    InpOFA_MaxBars             = 1000;

input group           "=== EMA Overlay ==="
input bool   InpShowEMA        = false;         // Show EMA Lines (200/720)

input group           "=== TP/SL Box Visual ==="
input bool   InpRR_DrawEnable = true;     // Draw TP/SL Rectangle on chart
input color  InpRR_TPColor    = clrLime;  // TP Box color
input color  InpRR_SLColor    = clrCrimson; // SL Box color
input bool   InpRR_ShowText   = true;     // Show USD label on boxes

input group           "=== Alerts ==="
input bool   InpAlertPopup   = false;     // Show Popup Alert
input bool   InpAlertPush    = true;      // Send Mobile Notification
input bool   InpNotifyOrder  = true;      // [Notify] Order events (Open/Close/BE/CloseAll)
input bool   InpNotifySignal = false;      // [Notify] Signal events (Zone/Sweep/Retest)
input double InpRetestPips   = 3.0;       // Retest tolerance (pips)

input group           "=== OFA Fibo Notification ==="
input bool   InpNotifyFibo618  = true;    // Notify when price hits P50 Fibo 61.8%
input double InpFibTolerance   = 0.5;     // Tolerance % around 61.8 line



input group           "=== Entry Mode 1: Zone Entry ==="
input bool   InpZoneEntry      = true;   // Enable Zone Entry (EQL→BUY / EQH streak→SELL)
input int    InpEQH_Streak     = 2;       // EQH Streak required before SELL
input int    InpEQL_Streak3rd  = 3;       // EQL Streak for 3rd BUY
input bool   InpHullFilter     = true;   // [Filter] Hull Direction (M15+M1 must align)
input bool   InpPriceFilter    = false;   // [Filter] Price Position (BUY below SELL / SELL above BUY)
input double InpPriceBuffer    = 1.0;    // [Filter] Price Buffer (USD)
input bool   InpGapFilter      = true;   // [Filter] Gap to opposite zone max
input double InpMaxGapUSD      = 20.0;   // [Filter] Max Gap (USD)
input bool   InpStreakFilter    = true;   // [Filter] Streak Max
input int    InpMaxEQLStreak   = 4;      // [Filter] Max EQL streak for BUY
input int    InpMaxEQHStreak   = 4;      // [Filter] Max EQH streak for SELL
input bool   InpMinGapEntryFilter = true;   // [Filter] Min Gap to opposite zone (block if too close)
input double InpMinEntryGapUSD    = 3.0;    // [Filter] Min Gap (USD) — BUY block near EQH / SELL block near EQL
input int    InpEQL_ConfirmMaxBars = 3;     // EQL Candle Confirm: max bars to wait for reject candle (0=instant)
input int    InpEQH_ConfirmMaxBars = 3;     // EQH Candle Confirm: max bars to wait for reject candle (0=instant)

input group           "=== DXY Auto Trade — Fibo Zone Filter ==="
input bool   InpDXY_FiboFilter  = true;   // [DXY_AUTO] เปิด/ปิด Fibo filter
input double InpDXY_FiboMinPct  = 38.2;   // [DXY_AUTO] Min Fibo% (block ถ้า < ค่านี้ = ใกล้ swing extreme)

input group           "=== Entry Mode 2: Hull Follow Entry ==="
input bool   InpHullFollowEntry  = true;  // Enable Hull Follow Entry (M1 turns to match M15)
input int    InpZoneProximityPts = 300000;  // Zone Proximity (points) — must be near EQL/EQH zone
input bool   InpFiboFilter       = true;  // [Filter] Fibo Extension — block entry if overextended
input double InpFiboMaxPct       = 85.0;  // [Filter] Max Fibo % allowed (block if > this value)

input group           "=== Entry Mode 3: Cluster Zone Fast Reversal ==="
input bool   InpClusterEntry     = true;   // Enable Cluster Fast Reversal (2x EQL/EQH)
input int    InpClusterMinCount  = 2;      // Min zones in cluster to trigger
input double InpClusterRangePts  = 200.0;  // Cluster grouping range (points)

input group           "=== Session Profile ==="
input bool   InpUseSessionProfile   = true;   // Enable Session Profile (override inputs per session)
// --- Asian Session ---
input int    InpAsian_Start         = 0;      // Asian GMT Start hour
input int    InpAsian_End           = 7;      // Asian GMT End hour
input int    InpAsian_EQH_Streak    = 1;      // Asian EQH streak required
input int    InpAsian_EQL_Streak    = 1;      // Asian EQL streak (3rd BUY threshold)
input double InpAsian_FiboMaxPct    = 70.0;   // Asian Max Fibo % allowed
input int    InpAsian_ProximityPts  = 300000;    // Asian Zone proximity (pts)
input double InpAsian_MaxSpreadUSD  = 2.00;   // Asian Max Spread (USD)
// --- London Session ---
input int    InpLondon_Start        = 7;      // London GMT Start hour
input int    InpLondon_End          = 16;     // London GMT End hour
input int    InpLondon_EQH_Streak   = 1;      // London EQH streak required
input int    InpLondon_EQL_Streak   = 1;      // London EQL streak (3rd BUY threshold)
input double InpLondon_FiboMaxPct   = 85.0;   // London Max Fibo % allowed
input int    InpLondon_ProximityPts = 500000;   // London Zone proximity (pts)
input double InpLondon_MaxSpreadUSD = 2.00;   // London Max Spread (USD)
// --- New York Session ---
input int    InpNY_Start            = 13;     // NY GMT Start hour
input int    InpNY_End              = 21;     // NY GMT End hour
input int    InpNY_EQH_Streak       = 1;      // NY EQH streak required
input int    InpNY_EQL_Streak       = 1;      // NY EQL streak (3rd BUY threshold)
input double InpNY_FiboMaxPct       = 85.0;   // NY Max Fibo % allowed
input int    InpNY_ProximityPts     = 500000;   // NY Zone proximity (pts)
input double InpNY_MaxSpreadUSD     = 2.00;   // NY Max Spread (USD)

input group           "=== Auto Pending Order ==="
input bool   InpAutoPending       = false;   // Enable Auto Pending Order (BuyLimit/SellLimit)
input double InpPendingDriftPts   = 200.0;  // POI drift threshold ก่อน re-place (points)
input double InpPendingSL_USD     = 20.0;   // SL สำหรับ Pending Order (USD)
input int    InpMinOrderDistancePts = 1000; // [Filter] Min distance from existing orders/positions (pts)

input group           "=== Spread Filter ==="
input bool   InpUseSpreadFilter     = true;   // Enable Spread Filter (used when Session Profile is off)
input double InpMaxSpreadUSD        = 0.50;   // Max Spread USD (fallback when Session Profile off)

input group           "=== News & Session Filter ==="
input bool   InpUseNewsFilter     = true;        // Enable News Filter
input bool   InpHighImpact        = true;        // Block on High Impact (3 Stars)
input bool   InpMediumImpact      = false;       // Block on Medium Impact (2 Stars)
input int    InpNewsBefore        = 30;          // Stop trading X mins BEFORE news
input int    InpNewsAfter         = 30;          // Wait Y mins AFTER news
input bool   InpIncludeUSD        = true;        // Always check USD news
input bool   InpDailyExit         = true;        // Enable Daily Session Exit
input int    InpDailyExitHour     = 22;          // GMT Hour to stop trading daily (0-23)
input bool   InpFridayExit        = true;        // Close all on Friday (No carry over)
input int    InpFridayExitHour    = 21;          // Hour to close all on Friday

input group           "=== Smart NR / Inside Bar ==="
input bool   InpNR_Enable        = true;      // Enable Smart NR/IB Overlay
input bool   InpNR_UseInsideBar  = false;      // Enable Inside Bar detection
input bool   InpNR_UseTrendFilter= true;       // Enable Trend Filter (MA)
input bool   InpNR_ShowTrendMA   = true;      // Show Trend MA line
input string InpNR_TrendMode     = "Static";   // Trend MA Mode: Static / NR-Adaptive
input string InpNR_TrendMaType   = "EMA";      // MA Type: EMA / RMA
input double InpNR_TrendMul      = 2.0;        // NR-Adaptive MA Multiplier
input int    InpNR_TrendMaLen    = 200;        // Static MA Length
input int    InpNR_MaSlopeLB     = 3;          // NR MA Slope lookback bars (anti-flip, 1=raw)
input double InpNR_MaSlopeThresh = 5.0;        // NR MA Slope threshold pts (0=off)
input color  InpNR_MaColUp       = clrBlue;    // MA Up Color
input color  InpNR_MaColDn       = clrRed;     // MA Down Color
input string InpNR_LbMode        = "Static";   // Look Back Mode: Static / ADX Adaptive
input int    InpNR_AdxLen        = 14;         // ADX Length
input double InpNR_AdxLo         = 10.0;       // ADX Low threshold
input double InpNR_AdxHi         = 35.0;       // ADX High threshold
input int    InpNR_LbMin         = 20;         // Look Back Min
input int    InpNR_LbMax         = 120;        // Look Back Max
input bool   InpNR_ShowExitX     = true;       // Show Exit Markers (TP/SL/T labels)
input bool   InpNR_UseCondTP     = true;       // Condition Based TP
input bool   InpNR_UseTimeExit   = false;      // Time Based Exit
input bool   InpNR_UseSL         = true;       // Stop Loss exit marker
input double InpNR_ExitR         = 2.0;        // Target R (Risk:Reward)
input int    InpNR_ExitBars      = 50;         // Time Exit Bars
input color  InpNR_TpExitCol     = clrLime;    // TP Label Color
input color  InpNR_SlExitCol     = clrRed;     // SL Label Color
input color  InpNR_TimeExitCol   = clrBlue;    // Time Exit Label Color
input int    InpNR_ExtendFwd     = 50;         // Extend Levels (bars)
input color  InpNR_BullCol       = clrBlue;    // Bull Color
input color  InpNR_BearCol       = clrRed;     // Bear Color
input int    InpNR_BoxFillAlpha  = 86;         // Box Fill Transparency 0-100
input int    InpNR_BoxEdgeAlpha  = 35;         // Box Border Transparency 0-100
input int    InpNR_LvlW          = 2;          // Level Line Width
input string InpNR_LvlStyleStr   = "Dotted";   // Level Style: Solid / Dashed / Dotted
input bool   InpNR_ShowTrigIcon  = true;       // Show Trigger Icon
input int    InpNR_MaxKeep       = 120;        // Max Patterns Kept
input bool   InpNR_Notify        = true;       // [SmartNR] Send push notify on BUY/SELL signal
input bool   InpNR_ShowBreakArrow= true;       // Show breakout arrow at NR trigger bar
input bool   InpNR_ArrowEntry   = true;       // [Mode 4] Open order on NR breakout arrow
input bool   InpNR_DirectEntry  = true;      // [Mode 4] Direct entry — skip all filters except max orders

//+------------------------------------------------------------------+
//|  [NEW] MTF (Higher Timeframe) INPUTS                             |
//+------------------------------------------------------------------+
input group           "=== Higher Timeframe Liquidity ==="
input bool            InpEnableHTF    = true;            // Enable HTF Zones
input ENUM_TIMEFRAMES InpHTF          = PERIOD_M15;      // Select HTF (e.g., M15)
input color           InpHTFBullColor = C'20, 80, 200';  // HTF EQL Color (Deep Blue)
input color           InpHTFBearColor = C'200, 80, 20';  // HTF EQH Color (Deep Orange)
input int             InpHTFTransp    = 60;              // HTF Transparency (ทึบกว่า M1)

input group           "=== M15 Candle Visual ==="
input bool   InpM15CV_Show   = true;         // Show M15 Candles on chart
input int    InpM15CV_Count  = 3;            // Number of M15 candles to display
input color  InpM15CV_Bull   = C'0,100,0';   // M15 Bull candle color
input color  InpM15CV_Bear   = C'120,0,0';   // M15 Bear candle color
input int    InpM15CV_Width  = 1;            // Candle body width (bars)
input int    InpM15CV_Offset = 5;            // Offset right from current bar (bars)

//+------------------------------------------------------------------+
//|  HULL SUITE INPUTS (M1 + M15)                                    |
//+------------------------------------------------------------------+
input group           "=== Hull Suite M1 ==="
input bool   InpHullM1_Enable   = true;          // Enable Hull Suite M1
input int    InpHullM1_Period   = 50;             // Hull M1 Period ★
input double InpHullM1_Divisor  = 2.0;            // Hull M1 Divisor
input color  InpHullM1_UpColor  = clrLime;        // M1 Hull Up Color
input color  InpHullM1_DnColor  = clrRed;         // M1 Hull Down Color
input int    InpHullM1_Width    = 2;              // M1 Hull Line Width
input double InpHullM1_Threshold = 100.0;         // Hull flip threshold (points) — filters noise
input int    InpHullM1_SlopeLB   = 3;             // M1 slope lookback bars (1=fast, 3-5=smooth)

input group           "=== Hull Suite M15 (Synthetic — M1 Period×15) ==="
input bool   InpHullM15_Enable    = true;           // Enable Synthetic M15 Hull (real-time)
input int    InpHullM15_Period    = 40;              // Synthetic M15 Period (actual M1 bars = Period×15) ★
input double InpHullM15_Divisor   = 2.0;             // Hull M15 Divisor
input color  InpHullM15_UpColor   = C'0,200,255';   // M15 Hull Up Color
input color  InpHullM15_DnColor   = C'255,120,0';   // M15 Hull Down Color
input int    InpHullM15_Width     = 3;              // M15 Hull Line Width
input double InpHullM15_Threshold = 50.0;           // SynM15 flip threshold (pts) — กรอง noise flip สั้น
input int    InpHullM15_SlopeLB   = 3;              // SynM15 slope lookback bars (2-5)

input group           "=== ATR Previous Day Levels ==="
input bool   InpATRLevelsEnable        = true;
input int    InpATRLevelsPeriod        = 14;
input bool   InpATRShow25              = true;
input bool   InpATRShow50              = true;
input bool   InpATRShow75              = true;
input bool   InpATRShow100             = true;
input bool   InpATRShow150             = true;
input bool   InpATRShow200             = true;
input bool   InpATRShow250             = false;
input bool   InpATRShow300             = false;
input bool   InpATRShowClose           = true;
input int    InpATRLineWidth           = 2;
input int    InpATRLabelSize           = 8;
input color  InpATRColorPlus25         = clrSandyBrown;
input color  InpATRColorPlus50         = clrTomato;
input color  InpATRColorPlus75         = clrCrimson;
input color  InpATRColorPlus100        = clrOrange;
input color  InpATRColorPlus150        = clrOrangeRed;
input color  InpATRColorPlus200        = clrRed;
input color  InpATRColorPlus250        = clrDarkRed;
input color  InpATRColorPlus300        = clrMaroon;
input color  InpATRColorClose          = clrWhite;
input color  InpATRColorMinus25        = clrAqua;
input color  InpATRColorMinus50        = clrTurquoise;
input color  InpATRColorMinus75        = clrMediumTurquoise;
input color  InpATRColorMinus100       = clrDeepSkyBlue;
input color  InpATRColorMinus150       = clrViolet;
input color  InpATRColorMinus200       = clrMagenta;
input color  InpATRColorMinus250       = clrDarkViolet;
input color  InpATRColorMinus300       = clrPurple;

//+------------------------------------------------------------------+
//|  STRUCTS                                                         |
//+------------------------------------------------------------------+
struct SessionProfile
{
   int    eqhStreak;
   int    eqlStreak;
   double fiboMaxPct;
   int    zoneProximityPts;
   double maxSpreadUSD;   // 0 = no spread check
};

SessionProfile GetActiveProfile()
{
   SessionProfile p;
   if(!InpUseSessionProfile) {
      p.eqhStreak        = InpEQH_Streak;
      p.eqlStreak        = InpEQL_Streak3rd;
      p.fiboMaxPct       = InpFiboMaxPct;
      p.zoneProximityPts = InpZoneProximityPts;
      p.maxSpreadUSD     = InpUseSpreadFilter ? InpMaxSpreadUSD : 0.0;
      return p;
   }
   MqlDateTime t; TimeToStruct(TimeCurrent(), t);
   int h = t.hour;
   bool isAsian  = (h >= InpAsian_Start  && h < InpAsian_End);
   bool isLondon = (h >= InpLondon_Start && h < InpLondon_End);
   bool isNY     = (h >= InpNY_Start     && h < InpNY_End);
   if(isLondon) {
      p.eqhStreak = InpLondon_EQH_Streak; p.eqlStreak = InpLondon_EQL_Streak;
      p.fiboMaxPct = InpLondon_FiboMaxPct; p.zoneProximityPts = InpLondon_ProximityPts;
      p.maxSpreadUSD = InpLondon_MaxSpreadUSD;
   } else if(isNY) {
      p.eqhStreak = InpNY_EQH_Streak; p.eqlStreak = InpNY_EQL_Streak;
      p.fiboMaxPct = InpNY_FiboMaxPct; p.zoneProximityPts = InpNY_ProximityPts;
      p.maxSpreadUSD = InpNY_MaxSpreadUSD;
   } else {
      // Asian or off-session (use Asian — most conservative)
      p.eqhStreak = InpAsian_EQH_Streak; p.eqlStreak = InpAsian_EQL_Streak;
      p.fiboMaxPct = InpAsian_FiboMaxPct; p.zoneProximityPts = InpAsian_ProximityPts;
      p.maxSpreadUSD = InpAsian_MaxSpreadUSD;
   }
   return p;
}

// bool IsSpreadAllowed(double maxSpreadUSD)
// {
//    if(maxSpreadUSD <= 0) return true;
//    double spread    = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point;
//    double tickVal   = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
//    double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
//    if(tickSize <= 0) return true;
//    double spreadUSD = spread / tickSize * tickVal;
//    if(spreadUSD > maxSpreadUSD) {
//       Print("[DLZ Order] Blocked — spread $", DoubleToString(spreadUSD,3), " > max $", DoubleToString(maxSpreadUSD,2));
//       return false;
//    }
//    return true;
// }

// double GetSpreadUSD()
// {
//    double spread   = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point;
//    double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
//    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
//    if(tickSize <= 0) return 0;
//    return spread / tickSize * tickVal;
// }
bool IsSpreadAllowed(double maxSpreadUSD)
{
   if(maxSpreadUSD <= 0) return true;
   double spread    = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point;
   double tickVal   = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickSize <= 0) return true;
   
   // แก้ไขบรรทัดนี้: คูณด้วย InpLot เพื่อให้ได้ค่า USD ตามขนาดไม้จริง
   double spreadUSD = (spread / tickSize * tickVal) * InpLot; 
   
   if(spreadUSD > maxSpreadUSD) {
      // พิมพ์ Log ให้เห็นชัดขึ้นว่าคำนวณจาก Lot อะไร
      Print("[DLZ Order] Blocked — spread $", DoubleToString(spreadUSD,3), " (at ", InpLot, " lot) > max $", DoubleToString(maxSpreadUSD,2));
      return false;
   }
   return true;
}

double GetSpreadUSD()
{
   double spread   = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point;
   double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickSize <= 0) return 0;
   
   // แก้ไขบรรทัดนี้ด้วยเช่นกัน
   return (spread / tickSize * tickVal) * InpLot; 
}

double GetATR()
{
   if(g_atrHandle == INVALID_HANDLE) return 0;
   double buf[1];
   if(CopyBuffer(g_atrHandle, 0, 0, 1, buf) < 1) return 0;
   double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickSize <= 0) return 0;
   return buf[0] / tickSize * tickVal; // ATR in USD per lot
}

struct PivotPoint
{
   double   price;
   datetime barTime;   // time of the actual pivot bar (not confirming bar)
   double   vol;
};

struct LiquidityZone
{
   string   boxName;
   string   midName;
   string   lblName;
   string   b1Name;
   string   b2Name;
   string   v1Name;
   string   v2Name;
   double   sweepLevel;     // top for EQH, bottom for EQL
   double   totalVol;
   int      createdBarNS;   // non-series index of confirming bar (for sweep delay)
   bool     isHigh;
   bool     isSwept;
   bool     retestNotified; // ป้องกัน notify retest ซ้ำ
   double   topPrice;
   double   bottomPrice;
   double   midPrice;
};

//+------------------------------------------------------------------+
//|  GLOBAL STATE                                                    |
//+------------------------------------------------------------------+
LiquidityZone g_zones[];
PivotPoint    g_histHighs[];
PivotPoint    g_histLows[];
int           g_objCounter     = 0;
datetime      g_lastBarTimeProcessed = 0; // เวลาแท่งสุดท้ายที่ประมวลผลแล้ว

bool          g_isLive         = false;
datetime      g_eaStartTime    = 0;    // เวลาที่ EA เริ่มต้น — ใช้กรอง Notification Flood

//--- EA globals
CTrade        g_trade;

//--- Cockpit Control Logic
class C_Commander;
C_Commander* g_commander = NULL;
int           g_eql_streak     = 0;
int           g_eqh_streak     = 0;
datetime      g_lastBarTimeEA  = 0;   // ป้องกัน OnTick ประมวลผลซ้ำ
datetime      g_lastNROrderBar = 0;   // NR Mode4: once-per-bar guard (global, ไม่ reset ตาม static)
int           g_lastFibNotifiedSwing = 0;  // index Swing ล่าสุดที่แจ้งเตือน Fibo 61.8 ไปแล้ว
datetime      g_lastFibNotifyTime    = 0;  // ป้องกันส่งซ้ำใกล้กัน
int           g_lastDXYTrend        = 0;  // เก็บสถานะเทรนด์ DXY ล่าสุด

// --- [DXY Pending Signal] Delayed entry after Hull/Candle block ---
struct DXY_PendingSignal
{
   bool     isPending;     // มี pending อยู่หรือไม่
   int      direction;     // 1=BUY, -1=SELL
   double   signalClose;   // close ของแท่งที่ block
   datetime signalTime;    // time ของแท่งที่ block
   int      barsWaited;    // จำนวนแท่งที่รอไปแล้ว
};
DXY_PendingSignal g_dxyPending = {false, 0, 0.0, 0, 0};

// Forward declarations
void CheckAndOpenOrder(const LiquidityZone &z);
void CheckHullFollowEntry();
void CheckClusterZoneFastEntry();
void CheckOFAFibNotification();
void UpdateEADashboard();
void CloseAllIfProfitTarget();
void CheckBreakEven();
void UpdateMaxDrawdown();
void CheckFlatCloseOrders();
void CheckEQLConfirmation();
void CheckEQHConfirmation();
void LogTradeOpen(ulong ticket, string reason, double reqPrice);
void ManageSLExpansion();
void ManageAutoPending();
void NotifyOrderClose(ulong ticket, string closeReason, string openReason, double pnl, int durMin, double maxDD);
void UpdateWhatNextDashboard();

struct TradeTrack {
   ulong    ticket;
   double   maxDD_USD;
   double   entryPrice;
   datetime openTime;
   string   reason;
   double   reqPrice;
   bool     beTriggered;
   int      slExpandCount;
};
TradeTrack g_trackList[];
int        g_trackCount = 0;

// Push notification retry queue (1 pending slot)
string     g_retryMsg   = "";
datetime   g_retryAfter = 0;

struct EQLPendingConfirm {
   double   topPrice;
   double   bottomPrice;
   datetime createdTime;
   bool     touched;
   int      barsWaited;
};
EQLPendingConfirm g_eqlPendingList[];
int               g_eqlPendingCount = 0;

struct EQHPendingConfirm {
   double   topPrice;
   double   bottomPrice;
   datetime createdTime;
   bool     touched;
   int      barsWaited;
};
EQHPendingConfirm g_eqhPendingList[];
int               g_eqhPendingCount = 0;
datetime      g_lastClusterBarTime = 0;  // ติดตาม bar close สำหรับ Cluster Dashboard
string        g_lastSweptMsg    = "-";   // ข้อความ Sweep ล่าสุดสำหรับ Dashboard
datetime      g_lastSweptTime   = 0;    // เวลา Sweep ล่าสุด (สำหรับ decay คะแนน)
string        g_TradingStatus   = "READY"; // สถานะการเทรดปัจจุบัน
color         g_StatusColor     = clrLime; // สีแสดงสถานะ
int           g_atr_d1_handle   = INVALID_HANDLE; // ATR D1 handle
ENUM_TIMEFRAMES g_lastTF        = PERIOD_CURRENT; // ติดตามการเปลี่ยน TF

//--- Auto Pending Order globals
ulong         g_pendingTicket   = 0;     // ticket ของ pending order ที่วางอยู่
double        g_pendingPOI      = 0.0;   // ราคา POI ที่ใช้วาง pending ครั้งล่าสุด
bool          g_pendingIsBull   = false; // ทิศทางของ pending ที่วางอยู่
//--- Shared state จาก UpdateDashboard → ManageAutoPending
double        g_poiPrice        = 0.0;
double        g_targetPrice     = 0.0;
bool          g_isBullStructure = false;

//+------------------------------------------------------------------+
//|  SMART NR/IB GLOBALS                                            |
//+------------------------------------------------------------------+
#define NR_OBJ_PFX  "NR_"
#define NR_LOOKBACK 20

struct NR_PatData {
   int    leftBar;
   int    trigBar;
   int    endBar;
   int    dir;       // +1 bull / -1 bear
   double entry, stop, tgt;
   bool   exited;
   bool   notified;
   string id;
};

NR_PatData nr_pats[];
int        nr_patCnt   = 0;
bool       nr_pend     = false;
int        nr_pendLeft = 0, nr_pendRight = 0;
double     nr_pendHi   = 0.0, nr_pendLo = 0.0;
string     nr_pendName = "";

// Mode 4 — 2-Round confirmation state
int      nr_r1_dir    = 0;     // 1=BUY pending, -1=SELL pending, 0=none
double   nr_r1_hi     = 0.0;
double   nr_r1_lo     = 0.0;
datetime nr_r1_time   = 0;
int      nr_r1_expBar = 0;     // bar index when round 1 expires

// Mode 4 — Reversal watch state (after trigger fires, watch opposite breakout)
bool     nr_rev_active = false;
int      nr_rev_dir    = 0;    // +1=watch for BUY, -1=watch for SELL
double   nr_rev_hi     = 0.0;
double   nr_rev_lo     = 0.0;
int      nr_rev_expBar = 0;

double     nr_trendMA[];
double     nr_atrRma[], nr_plusRma[], nr_minusRma[], nr_adxRma[];
bool       nr_wasSetup[];
int        nr_prevCalc = 0;
int        g_nrMADir   = 0;  // 1=UP, -1=DN, 0=unknown
datetime   nr_windowStartTime = 0; // time[0] ของ call ก่อน — ใช้ detect window slide

//--- Global Variables สำหรับ HTF ---
LiquidityZone g_zones_htf[];
PivotPoint    g_histHighs_htf[];
PivotPoint    g_histLows_htf[];
datetime      g_lastHTFBarTime = 0;
bool          g_htfInitialized = false;

//+------------------------------------------------------------------+
//|  OFA STRUCTS & GLOBALS                                           |
//+------------------------------------------------------------------+
struct GDX_SwingPoint {
   datetime time;
   double   price;
   int      bar;
   bool     isHigh;
   double   velocity;
   double   magnitude;
   double   magPct;
   long     volume;
   double   open;
   double   high;
   double   low;
   double   close;
};

struct GDX_Fractal {
   datetime time;
   double   price;
   int      bar;
   bool     isHigh;
};

// OFA p26 (fast) globals
GDX_SwingPoint gdx_swings[];
int      gdx_swingCount          = 0;
int      gdx_LastConfirmedCount  = 0;
datetime gdx_LastBarTime         = 0;

// OFA p50 (slow) globals
GDX_SwingPoint gdx_swings2[];
int      gdx_swingCount2         = 0;
int      gdx_LastConfirmedCount2 = 0;
datetime gdx_LastBarTime2        = 0;

//+------------------------------------------------------------------+
//| HULL ENGINE — CGdxHull (identical to GoldDXY indicator)          |
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

// Hull M1 globals
CGdxHull  g_hullEngineM1;
double    g_hullValM1[];
double    g_hullTrdM1[];
bool      g_hullInitM1   = false;
datetime  g_hullBarM1    = 0;
int       g_hullDirM1    = 0;   // 1=UP, -1=DN, 0=unknown
int       g_prevHullDirM1 = 0; // Hull M1 direction previous tick

// Hull M15 globals
CGdxHull  g_hullEngineM15;
double    g_hullValM15[];
double    g_hullTrdM15[];
bool      g_hullInitM15  = false;
datetime  g_hullBarM15   = 0;
int       g_hullDirM15   = 0;
int       g_prevHullDirM15 = 0;
double    g_hullSlopeM15   = 0.0;  // slope ล่าสุดของ Synthetic M15 (สำหรับ Dashboard)
double    g_hullSlopeDummy = 0.0;  // dummy สำหรับ M1 call (ไม่ใช้ค่า)
double    g_hullLastM15    = 0.0;  // Hull M15 value ล่าสุด (สำหรับ Instant Flip check)
double    g_p50LastLow     = 0.0;  // p50 Swing Low ล่าสุด (สำหรับ Structure Break check)
double    g_hullValueM1_Curr = 0.0; // Hull M1 value ล่าสุด (สำหรับ DXY AutoTrade filter)
double    g_hullValueM1_Prev = 0.0; // Hull M1 value แท่งก่อนหน้า

// ATR handle for logging
int       g_atrHandle    = INVALID_HANDLE;

// EMA handles + last-bar tracker (for OBJ_TREND draw pattern)
int       g_emaHandle[4]  = {INVALID_HANDLE, INVALID_HANDLE, INVALID_HANDLE, INVALID_HANDLE};
datetime  g_emaLastBar    = 0;
datetime  g_nrMALastBar   = 0;

//+------------------------------------------------------------------+
//|  HELPER: unique object name                                      |
//+------------------------------------------------------------------+
string ObjName(const string prefix)
{
   return OBJ_PREFIX + prefix + IntegerToString(g_objCounter++);
}

//+------------------------------------------------------------------+
//|  HELPER: color with transparency (mirrors Pine color.new)        |
//|  transpPct: 0=fully opaque, 100=fully transparent                |
//+------------------------------------------------------------------+
long AlphaColor(color clr, int transpPct)
{
   uchar alpha = (uchar)(255.0 * (100 - transpPct) / 100.0 + 0.5);
   return (long)ColorToARGB(clr, alpha);
}

//+------------------------------------------------------------------+
//|  HELPER: chart foreground color with transparency                |
//+------------------------------------------------------------------+
long FgColor(int transpPct)
{
   color fg = (color)ChartGetInteger(0, CHART_COLOR_FOREGROUND);
   return AlphaColor(fg, transpPct);
}

//+------------------------------------------------------------------+
//|  HELPER: volume formatter (mirrors f_formatVol in Pine)          |
//+------------------------------------------------------------------+
string FormatVol(double v)
{
   if(v >= 1000000.0) return StringFormat("%.1fM", v / 1000000.0);
   if(v >= 1000.0)    return StringFormat("%.1fK", v / 1000.0);
   return IntegerToString((int)MathRound(v));
}

//+------------------------------------------------------------------+
//|  HELPER: pivot high check (non-series arrays, 0=oldest)          |
//|  pivotBar = the candidate pivot bar index                         |
//+------------------------------------------------------------------+
bool IsPivotHigh(const double &h[], int pivotBar, int leftLen, int rightLen, int total)
{
   if(pivotBar < leftLen || pivotBar + rightLen >= total) return false;
   double ph = h[pivotBar];
   for(int k = 1; k <= leftLen;  k++) if(h[pivotBar - k] >= ph) return false;
   for(int k = 1; k <= rightLen; k++) if(h[pivotBar + k] >= ph) return false;
   return true;
}

//+------------------------------------------------------------------+
//|  HELPER: pivot low check (non-series arrays, 0=oldest)           |
//+------------------------------------------------------------------+
bool IsPivotLow(const double &l[], int pivotBar, int leftLen, int rightLen, int total)
{
   if(pivotBar < leftLen || pivotBar + rightLen >= total) return false;
   double pl = l[pivotBar];
   for(int k = 1; k <= leftLen;  k++) if(l[pivotBar - k] <= pl) return false;
   for(int k = 1; k <= rightLen; k++) if(l[pivotBar + k] <= pl) return false;
   return true;
}

//+------------------------------------------------------------------+
//|  HELPER: prepend pivot to history array, cap at maxSize          |
//+------------------------------------------------------------------+
void PrependPivot(PivotPoint &arr[], double price, datetime t, double vol, int maxSize)
{
   int sz = ArraySize(arr);
   int newSz = MathMin(sz + 1, maxSize);
   ArrayResize(arr, newSz);
   // Shift existing elements towards end (drop last if at maxSize)
   int copyEnd = (sz < maxSize) ? sz : maxSize - 1;
   for(int i = copyEnd; i > 0; i--)
      arr[i] = arr[i - 1];
   arr[0].price   = price;
   arr[0].barTime = t;
   arr[0].vol     = vol;
}

//+------------------------------------------------------------------+
//| [REPLACE] UPDATED FUNCTION TO SUPPORT FONT SIZE & BOLD           |
//+------------------------------------------------------------------+
//void CreateDashLabel(string name, int y_offset, string text, color clr, int fontSize=9, bool isBold=false)
//{
//   if(!InpShowDash) return;
//   
//   // ถ้ายังไม่มี Object ให้สร้างใหม่
//   if(ObjectFind(0, name) < 0) 
//      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
//      
//   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
//   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, InpDashX);
//   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y_offset);
//   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
//   
//   // ส่วนที่เพิ่มเข้ามาเพื่อรองรับ Parameter ตัวที่ 5 และ 6
//   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
//   ObjectSetString(0, name, OBJPROP_FONT, isBold ? "Segoe UI Bold" : "Segoe UI Semibold");
//   
//   ObjectSetString(0, name, OBJPROP_TEXT, text);
//   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
//}
void CreateDashLabel(string name, int y_offset, string text, color clr, int fontSize=9, bool isBold=false)
{
   if(!InpShowDash) return;
   
   if(ObjectFind(0, name) < 0) ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, InpDashX + 15); // ขยับออกจากขอบกล่องนิดนึง
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y_offset);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetString(0, name, OBJPROP_FONT, isBold ? "Segoe UI Bold" : "Segoe UI Semibold");
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_BACK, false); // บังคับให้ลอยอยู่หน้าสุด
}

//+------------------------------------------------------------------+
//| [NEW] FUNCTION: วาดวงกลมเป้าหมาย และ จุดเข้า บนกราฟขวาสุด         |
//+------------------------------------------------------------------+
void DrawTradeMarkers(double poi, double tgt, bool isBull)
{
   string poiName = DASH_PREFIX+"POI_DOT";
   string poiTxt  = DASH_PREFIX+"POI_TXT";
   string tgtName = DASH_PREFIX+"TGT_DOT";
   string tgtTxt  = DASH_PREFIX+"TGT_TXT";

   // กำหนดเวลาขวาสุด (ขยับไปในอนาคต 5 แท่งเพื่อให้เห็นชัดในพื้นที่ว่าง)
   datetime rightTime = iTime(_Symbol, _Period, 0) + (PeriodSeconds(_Period) * 10);

   // --- 1. วาดจุด ENTRY POI ---
   if(poi > 0) {
      if(ObjectFind(0, poiName) < 0) ObjectCreate(0, poiName, OBJ_ARROW, 0, 0, 0);
      ObjectSetInteger(0, poiName, OBJPROP_ARROWCODE, 159); // วงกลมทึบขนาดใหญ่
      ObjectSetInteger(0, poiName, OBJPROP_TIME, 0, rightTime);
      ObjectSetDouble(0, poiName, OBJPROP_PRICE, 0, poi);
      ObjectSetInteger(0, poiName, OBJPROP_COLOR, isBull ? clrSpringGreen : clrDeepPink);
      ObjectSetInteger(0, poiName, OBJPROP_WIDTH, 4);
      ObjectSetInteger(0, poiName, OBJPROP_BACK, false);

      ObjectDelete(0, poiTxt);
   } else {
      ObjectDelete(0, poiName); ObjectDelete(0, poiTxt);
   }

   // --- 2. วาดจุด NEXT TARGET ---
   if(tgt > 0) {
      if(ObjectFind(0, tgtName) < 0) ObjectCreate(0, tgtName, OBJ_ARROW, 0, 0, 0);
      ObjectSetInteger(0, tgtName, OBJPROP_ARROWCODE, 164); // รูปเป้าเล็ง (Target)
      ObjectSetInteger(0, tgtName, OBJPROP_TIME, 0, rightTime);
      ObjectSetDouble(0, tgtName, OBJPROP_PRICE, 0, tgt);
      ObjectSetInteger(0, tgtName, OBJPROP_COLOR, clrAqua);
      ObjectSetInteger(0, tgtName, OBJPROP_WIDTH, 4);
      ObjectSetInteger(0, tgtName, OBJPROP_BACK, false);

      ObjectDelete(0, tgtTxt);
   } else {
      ObjectDelete(0, tgtName); ObjectDelete(0, tgtTxt);
   }
}

//+------------------------------------------------------------------+
//| CLUSTER DASHBOARD — เรียกเฉพาะ Bar Close                          |
//+------------------------------------------------------------------+
void UpdateClusterDashboard()
{
   if(!InpShowDash) return;

   double curPrice  = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double rangePts  = 150.0 * _Point * 10; // 150 pips radius (Gold: 150 pts)

   // --- นับ Cluster และหา Volume ของ zone แรก/ล่าสุดในกลุ่ม ---
   int    clusterH = 0, clusterL = 0;
   double firstVolH = 0, lastVolH = 0;
   double firstVolL = 0, lastVolL = 0;
   double clusterHigh_lo = 0, clusterHigh_hi = 0;
   double clusterLow_lo  = 0, clusterLow_hi  = 0;

   for(int i = 0; i < ArraySize(g_zones); i++)
   {
      if(g_zones[i].isSwept) continue;
      double dist = MathAbs(g_zones[i].sweepLevel - curPrice);
      if(dist > rangePts) continue;

      if(g_zones[i].isHigh)
      {
         if(clusterH == 0) { firstVolH = g_zones[i].totalVol; clusterHigh_lo = g_zones[i].sweepLevel; clusterHigh_hi = g_zones[i].sweepLevel; }
         clusterH++;
         lastVolH = g_zones[i].totalVol;
         if(g_zones[i].sweepLevel < clusterHigh_lo) clusterHigh_lo = g_zones[i].sweepLevel;
         if(g_zones[i].sweepLevel > clusterHigh_hi) clusterHigh_hi = g_zones[i].sweepLevel;
      }
      else
      {
         if(clusterL == 0) { firstVolL = g_zones[i].totalVol; clusterLow_lo = g_zones[i].sweepLevel; clusterLow_hi = g_zones[i].sweepLevel; }
         clusterL++;
         lastVolL = g_zones[i].totalVol;
         if(g_zones[i].sweepLevel < clusterLow_lo)  clusterLow_lo  = g_zones[i].sweepLevel;
         if(g_zones[i].sweepLevel > clusterLow_hi)  clusterLow_hi  = g_zones[i].sweepLevel;
      }
   }

   // --- CLUSTER + TRAP (รวมบรรทัดเดียว) ---
   bool   trapH   = (clusterH >= 3 && firstVolH > 0 && lastVolH > firstVolH * 1.5);
   bool   trapL   = (clusterL >= 3 && firstVolL > 0 && lastVolL > firstVolL * 1.5);
   string trapPart = (trapH && trapL) ? " TRAP H+L" : trapH ? " TRAP H" : trapL ? " TRAP L" : "";
   string clusterTxt;
   color  clusterClr = clrSilver;
   if(clusterH >= 3 && clusterL >= 3)
   {
      clusterTxt = StringFormat("H x%d | L x%d%s", clusterH, clusterL, trapPart);
      clusterClr = clrOrangeRed;
   }
   else if(clusterH >= 3)
   {
      clusterTxt = StringFormat("H x%d | L %d%s", clusterH, clusterL, trapPart);
      clusterClr = clrOrangeRed;
   }
   else if(clusterL >= 3)
   {
      clusterTxt = StringFormat("H %d | L x%d%s", clusterH, clusterL, trapPart);
      clusterClr = clrDodgerBlue;
   }
   else
   {
      clusterTxt = StringFormat("H %d | L %d  normal", clusterH, clusterL);
      clusterClr = clrSilver;
   }
   if(trapPart != "") clusterClr = clrYellow;
   ObjectSetString (0, DASH_PREFIX+"CLUSTER", OBJPROP_TEXT,  clusterTxt);
   ObjectSetInteger(0, DASH_PREFIX+"CLUSTER", OBJPROP_COLOR, clusterClr);

   // --- SWEPT row ---
   ObjectSetString (0, DASH_PREFIX+"SWEPT", OBJPROP_TEXT,  "Swept: " + g_lastSweptMsg);
   ObjectSetInteger(0, DASH_PREFIX+"SWEPT", OBJPROP_COLOR, (g_lastSweptMsg == "-") ? clrSilver : clrOrangeRed);

   // --- OFA Bias (P26 + P50) ---
   bool p26Up = (gdx_swingCount  > 0 && gdx_swings [gdx_swingCount -1].isHigh);
   bool p50Up = (gdx_swingCount2 > 0 && gdx_swings2[gdx_swingCount2-1].isHigh);
   bool ofaAlign = (gdx_swingCount > 0 && gdx_swingCount2 > 0);
   bool ofaBull  = (ofaAlign && p26Up && p50Up);
   bool ofaBear  = (ofaAlign && !p26Up && !p50Up);

   // หา EQL/EQH ใกล้สุดที่ยังไม่ sweep สำหรับ entry zone
   double nearEQL = 0, nearEQH = 0;
   for(int i = 0; i < ArraySize(g_zones); i++)
   {
      if(g_zones[i].isSwept) continue;
      if(!g_zones[i].isHigh && g_zones[i].sweepLevel < curPrice) // EQL ด้านล่าง
      {
         if(nearEQL == 0 || g_zones[i].sweepLevel > nearEQL) nearEQL = g_zones[i].sweepLevel;
      }
      else if(g_zones[i].isHigh && g_zones[i].sweepLevel > curPrice) // EQH ด้านบน
      {
         if(nearEQH == 0 || g_zones[i].sweepLevel < nearEQH) nearEQH = g_zones[i].sweepLevel;
      }
   }

   // --- DECISION row ---
   string decTxt = "o SCANNING";
   color  decClr = clrSilver;
   bool   swept  = (g_lastSweptMsg != "-");

   if(ofaBull)
   {
      if(nearEQL > 0) { decTxt = StringFormat("o BUY  EQL %.2f", nearEQL); decClr = clrLime; }
      else            { decTxt = "o BUY BIAS  no EQL";                      decClr = clrDodgerBlue; }
   }
   else if(ofaBear)
   {
      if(nearEQH > 0) { decTxt = StringFormat("o SELL  EQH %.2f", nearEQH); decClr = clrTomato; }
      else            { decTxt = "o SELL BIAS  no EQH";                      decClr = clrOrangeRed; }
   }
   else if(ofaAlign)
   {
      decTxt = StringFormat("o WAIT  p26%s p50%s conflict", p26Up ? "UP" : "DN", p50Up ? "UP" : "DN");
      decClr = clrYellow;
   }
   else if((clusterH >= 3 || clusterL >= 3) && !swept)
   {
      decTxt = "o WAIT  cluster no sweep";
      decClr = clrYellow;
   }
   else if((trapH || trapL) && !swept)
   {
      decTxt = "o TRAP  sweep imminent";
      decClr = clrOrange;
   }
   else if(swept)
   {
      decTxt = "o WATCH  wait retest";
      decClr = clrAqua;
   }

   ObjectSetString (0, DASH_PREFIX+"DECISION", OBJPROP_TEXT,  decTxt);
   ObjectSetInteger(0, DASH_PREFIX+"DECISION", OBJPROP_COLOR, decClr);
}

//+------------------------------------------------------------------+
//| DrawEMALines — OBJ_TREND pattern (no flicker, correct color/width)|
//+------------------------------------------------------------------+
void DrawEMALines()
{
   if(!InpShowEMA) return;

   int    emaPeriods[2] = {200, 720};
   color  emaColors[2]  = {clrPink, clrBlue};
   int    emaWidths[2]  = {3, 4};

   int drawBars = 302;
   datetime times[];
   ArraySetAsSeries(times, false);
   if(CopyTime(_Symbol, PERIOD_M1, 0, drawBars, times) <= 0) return;
   int seg = ArraySize(times);
   if(seg < 2) return;

   datetime curBarTime = times[seg - 1];
   bool isNewBar = (curBarTime != g_emaLastBar);

   for(int ei = 0; ei < 4; ei++)
   {
      if(g_emaHandle[ei] == INVALID_HANDLE) continue;

      double vals[];
      ArraySetAsSeries(vals, false);
      if(CopyBuffer(g_emaHandle[ei], 0, 0, seg, vals) <= 0) continue;

      string pfx = "DLZ_EMA" + IntegerToString(emaPeriods[ei]) + "_";

      // --- Bar-close: redraw history ---
      if(isNewBar)
      {
         ObjectsDeleteAll(0, pfx + "H");
         for(int b = 1; b < seg - 1; b++)
         {
            if(vals[b] == 0 || vals[b-1] == 0) continue;
            string n = pfx + "H" + IntegerToString(b);
            ObjectCreate(0, n, OBJ_TREND, 0, times[b-1], vals[b-1], times[b], vals[b]);
            ObjectSetInteger(0, n, OBJPROP_RAY_RIGHT,  false);
            ObjectSetInteger(0, n, OBJPROP_WIDTH,       emaWidths[ei]);
            ObjectSetInteger(0, n, OBJPROP_COLOR,       emaColors[ei]);
            ObjectSetInteger(0, n, OBJPROP_SELECTABLE,  false);
            ObjectSetInteger(0, n, OBJPROP_BACK,        true);
         }
      }

      // --- Every tick: update live segment ---
      string live = pfx + "LIVE";
      if(ObjectFind(0, live) < 0)
      {
         ObjectCreate(0, live, OBJ_TREND, 0, times[seg-2], vals[seg-2], times[seg-1], vals[seg-1]);
         ObjectSetInteger(0, live, OBJPROP_RAY_RIGHT,  false);
         ObjectSetInteger(0, live, OBJPROP_WIDTH,       emaWidths[ei]);
         ObjectSetInteger(0, live, OBJPROP_COLOR,       emaColors[ei]);
         ObjectSetInteger(0, live, OBJPROP_SELECTABLE,  false);
         ObjectSetInteger(0, live, OBJPROP_BACK,        true);
      }
      else
      {
         ObjectMove(0, live, 0, times[seg-2], vals[seg-2]);
         ObjectMove(0, live, 1, times[seg-1], vals[seg-1]);
      }
   }

   if(isNewBar) g_emaLastBar = curBarTime;
}

//+------------------------------------------------------------------+
void DrawNRTrendMA()
{
   if(!InpNR_ShowTrendMA || !InpNR_Enable) return;

   int drawBars = 302;
   datetime times[];
   ArraySetAsSeries(times, false);
   if(CopyTime(_Symbol, _Period, 0, drawBars, times) <= 0) return;
   int seg = ArraySize(times);
   if(seg < 2) return;

   int rtTotal = nr_prevCalc;
   if(rtTotal < seg) return;

   datetime curBarTime = times[seg - 1];
   bool isNewBar = (curBarTime != g_nrMALastBar);

   string pfx    = "DLZ_NRMA_";
   int    lineWidth = 2;
   int    offset = rtTotal - seg;

   if(isNewBar)
   {
      ObjectsDeleteAll(0, pfx + "H");
      int    _lb    = (InpNR_MaSlopeLB < 1) ? 1 : InpNR_MaSlopeLB;
      double _thr   = InpNR_MaSlopeThresh * _Point;
      color  _prevC = InpNR_MaColUp;
      for(int b = 1; b < seg - 1; b++)
      {
         int idx = offset + b;
         if(nr_trendMA[idx] == 0 || nr_trendMA[idx-1] == 0) continue;
         color c;
         if(idx >= _lb && nr_trendMA[idx - _lb] != 0) {
            double _sl = nr_trendMA[idx] - nr_trendMA[idx - _lb];
            if(_sl >  _thr) c = InpNR_MaColUp;
            else if(_sl < -_thr) c = InpNR_MaColDn;
            else c = _prevC;
         } else c = _prevC;
         _prevC = c;
         string n = pfx + "H" + IntegerToString(b);
         ObjectCreate(0, n, OBJ_TREND, 0, times[b-1], nr_trendMA[idx-1], times[b], nr_trendMA[idx]);
         ObjectSetInteger(0, n, OBJPROP_RAY_RIGHT,  false);
         ObjectSetInteger(0, n, OBJPROP_WIDTH,       lineWidth);
         ObjectSetInteger(0, n, OBJPROP_COLOR,       c);
         ObjectSetInteger(0, n, OBJPROP_SELECTABLE,  false);
         ObjectSetInteger(0, n, OBJPROP_BACK,        true);
      }
      g_nrMALastBar = curBarTime;
   }

   // live segment — อัปเดตทุก tick + เปลี่ยนสีตาม slope
   string live  = pfx + "LIVE";
   int    idxL  = offset + seg - 1;
   int    idxL1 = idxL - 1;
   if(idxL < 1 || nr_trendMA[idxL] == 0 || nr_trendMA[idxL1] == 0) return;
   int    _lbL  = (InpNR_MaSlopeLB < 1) ? 1 : InpNR_MaSlopeLB;
   double _thrL = InpNR_MaSlopeThresh * _Point;
   color  liveCol;
   {
      double _slL = (idxL >= _lbL && nr_trendMA[idxL - _lbL] != 0)
                    ? nr_trendMA[idxL] - nr_trendMA[idxL - _lbL] : 0;
      if(_slL >  _thrL)      liveCol = InpNR_MaColUp;
      else if(_slL < -_thrL) liveCol = InpNR_MaColDn;
      else liveCol = (g_nrMADir == 1) ? InpNR_MaColUp : (g_nrMADir == -1) ? InpNR_MaColDn : InpNR_MaColUp;
   }
   if(ObjectFind(0, live) < 0)
      ObjectCreate(0, live, OBJ_TREND, 0, times[seg-2], nr_trendMA[idxL1], times[seg-1], nr_trendMA[idxL]);
   else
   {
      ObjectSetInteger(0, live, OBJPROP_TIME,  0, times[seg-2]);
      ObjectSetDouble (0, live, OBJPROP_PRICE, 0, nr_trendMA[idxL1]);
      ObjectSetInteger(0, live, OBJPROP_TIME,  1, times[seg-1]);
      ObjectSetDouble (0, live, OBJPROP_PRICE, 1, nr_trendMA[idxL]);
   }
   ObjectSetInteger(0, live, OBJPROP_RAY_RIGHT,  false);
   ObjectSetInteger(0, live, OBJPROP_WIDTH,       lineWidth);
   ObjectSetInteger(0, live, OBJPROP_COLOR,       liveCol);
   ObjectSetInteger(0, live, OBJPROP_SELECTABLE,  false);
   ObjectSetInteger(0, live, OBJPROP_BACK,        true);
}

//+------------------------------------------------------------------+
//| [REPLACE] ADVANCED DASHBOARD UPDATE LOGIC (CTF + HTF Support)    |
//+------------------------------------------------------------------+
void UpdateDashboard()
{
   if(!InpShowDash) return;
   
   double curPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   // อัปเดตเมื่อเวลาผ่าน 1 วินาที หรือราคาวิ่งเกิน 20 Points
   static double   lastDashPrice = 0;
   static datetime lastDashTime  = 0;
   datetime now = TimeCurrent();
   if(now - lastDashTime < 1 && MathAbs(curPrice - lastDashPrice) < 20 * _Point) return;
   lastDashTime  = now;
   lastDashPrice = curPrice;
   
   int countH_CTF=0, countL_CTF=0;
   int countH_HTF=0, countL_HTF=0;
   double nearH=0, nearL=0;
   
   // 1. คำนวณหา Liquidity Zones ของกรอบเวลาปัจจุบัน (CTF)
   for(int i=0; i<ArraySize(g_zones); i++) {
      if(g_zones[i].isSwept) continue;
      if(g_zones[i].isHigh) { 
         countH_CTF++; 
         if(nearH==0 || g_zones[i].sweepLevel < nearH) nearH = g_zones[i].sweepLevel; 
      } else { 
         countL_CTF++; 
         if(nearL==0 || g_zones[i].sweepLevel > nearL) nearL = g_zones[i].sweepLevel; 
      }
   }

   // 1.1 คำนวณหา Liquidity Zones ของกรอบเวลาใหญ่ (HTF)
   if(InpEnableHTF) {
      for(int i=0; i<ArraySize(g_zones_htf); i++) {
         if(g_zones_htf[i].isSwept) continue;
         if(g_zones_htf[i].isHigh) { 
            countH_HTF++; 
            // เช็คว่าโซน HTF ใกล้กว่า CTF หรือไม่
            if(nearH==0 || g_zones_htf[i].sweepLevel < nearH) nearH = g_zones_htf[i].sweepLevel; 
         } else { 
            countL_HTF++; 
            if(nearL==0 || g_zones_htf[i].sweepLevel > nearL) nearL = g_zones_htf[i].sweepLevel; 
         }
      }
   }

   // 2. แสดงหัวข้อ Symbol & Price
   string tf = StringSubstr(EnumToString(Period()), 7);
   ObjectSetString(0, DASH_PREFIX+"TITLE", OBJPROP_TEXT, StringFormat("%s [%s]  Price: %s", _Symbol, tf, DoubleToString(curPrice, _Digits)));

   // 2b. EMA Status Row
   {
      double ema200 = 0, ema200_prev = 0, ema720 = 0;
      double _ebuf[6];
      if(g_emaHandle[0] != INVALID_HANDLE && CopyBuffer(g_emaHandle[0], 0, 0, 6, _ebuf) == 6)
         { ema200 = _ebuf[5]; ema200_prev = _ebuf[0]; }
      double _ebuf2[2];
      if(g_emaHandle[1] != INVALID_HANDLE && CopyBuffer(g_emaHandle[1], 0, 0, 2, _ebuf2) == 2)
         ema720 = _ebuf2[1];

      string emaStatusTxt = "EMA: --";
      color  emaStatusClr = clrSilver;
      if(ema200 > 0 && ema720 > 0) {
         bool isBull  = (curPrice > ema200 && ema200 > ema720);
         bool isBear  = (curPrice < ema200 && ema200 < ema720);
         string estat = isBull ? "BULL" : isBear ? "BEAR" : "SIDE";
         string eslop = (ema200 > ema200_prev) ? "↗" : "↘";
         double _tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
         double _tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
         double edist = (_tickSize > 0) ? (curPrice - ema200) / _tickSize * _tickVal * InpLot : 0;
         string eact  = isBull ? "BUY" : isBear ? "SELL" : "WAIT";
         emaStatusClr = isBull ? clrSpringGreen : isBear ? clrTomato : clrSilver;
         emaStatusTxt = StringFormat("%s | %s | D:$%.2f | E200:%.1f | %s",
                                     estat, eslop, edist, ema200, eact);
      }
      ObjectSetString (0, DASH_PREFIX+"EMA_STATUS", OBJPROP_TEXT,  emaStatusTxt);
      ObjectSetInteger(0, DASH_PREFIX+"EMA_STATUS", OBJPROP_COLOR, emaStatusClr);
   }

   // 3. Structure + P26 (รวมบรรทัดเดียว)
   string structTxt = "Struct  - . p26 -";
   color structClr = clrSilver;
   if(gdx_swingCount2 > 1 && gdx_swingCount > 0) {
      bool p50Up = gdx_swings2[gdx_swingCount2-1].isHigh;
      bool p26Up = gdx_swings[gdx_swingCount-1].isHigh;
      structTxt  = StringFormat("Struct  p50%s · p26%s", p50Up ? "▲" : "▼", p26Up ? "▲" : "▼");
      structClr  = (p50Up && p26Up) ? clrLime : (!p50Up && !p26Up) ? clrTomato : clrGold;
   } else if(gdx_swingCount2 > 1) {
      bool p50Up = gdx_swings2[gdx_swingCount2-1].isHigh;
      structTxt = StringFormat("Struct  p50%s · p26 ─", p50Up ? "▲" : "▼");
      structClr = p50Up ? clrDeepSkyBlue : clrTomato;
   }
   ObjectSetString (0, DASH_PREFIX+"STRUCT", OBJPROP_TEXT,  structTxt);
   ObjectSetInteger(0, DASH_PREFIX+"STRUCT", OBJPROP_COLOR, structClr);

   // 4. วิเคราะห์ Momentum & Fibo Insight จาก OFA p26 (Fast Fractal)
   string momentumText = "Momentum: Calculating..."; 
   string insightText = "Advice: Scanning...";
   
   if(gdx_swingCount > 1) {
      GDX_SwingPoint s1 = gdx_swings[gdx_swingCount-2]; // จุดเริ่มต้นของขาปัจจุบัน
      GDX_SwingPoint s2 = gdx_swings[gdx_swingCount-1]; // จุดสิ้นสุด (High/Low ล่าสุด)
      
      double range = MathAbs(s1.price - s2.price);
      double retrace = 0;
      if(range > 0) retrace = (MathAbs(curPrice - s2.price) / range) * 100.0;
      
      momentumText = StringFormat("Momentum: %s (Retrace: %.1f%%)", (s2.isHigh ? "Bullish" : "Bearish"), retrace);
      insightText = "Advice: " + GetFiboMeaning(retrace);
   }
   ObjectSetString(0, DASH_PREFIX+"MOMENTUM", OBJPROP_TEXT, momentumText);
   ObjectSetString(0, DASH_PREFIX+"INSIGHT",  OBJPROP_TEXT, insightText);

   // 5. Liquidity Radar (รวมบรรทัดเดียว)
   double distH = (nearH > 0) ? (nearH - curPrice) / _Point : 0;
   double distL = (nearL > 0) ? (curPrice - nearL) / _Point : 0;
   string strRadar = StringFormat("EQH x%d +%.0fpt  |  EQL x%d -%.0fpt",
                                  countH_CTF + countH_HTF, distH,
                                  countL_CTF + countL_HTF, distL);
   ObjectSetString(0, DASH_PREFIX+"RADAR_H", OBJPROP_TEXT, strRadar);

   // 6. สถานะแจ้งเตือนพิเศษ
   string status = "STATUS: MONITORING"; color statClr = clrSilver;
   if((distH > 0 && distH < 400) || (distL > 0 && distL < 400)) { status = "STATUS: ⚠️ NEAR LIQUIDITY ZONE"; statClr = clrYellow; }
   
   ObjectSetString(0, DASH_PREFIX+"STATUS", OBJPROP_TEXT, status);
   ObjectSetInteger(0, DASH_PREFIX+"STATUS", OBJPROP_COLOR, statClr);
   
   // --- [ADD] Smart Trade Plan Calculation Logic ---
   g_targetPrice     = 0;
   g_poiPrice        = 0;
   g_isBullStructure = (gdx_swingCount2 > 1 && gdx_swings2[gdx_swingCount2-1].isHigh);
   string tradeAction = "WAITING...";
   color actionClr = clrWhite;

   // --- อัปเดต p50 Swing Low ล่าสุด (สำหรับ Structure Break check) ---
   g_p50LastLow = 0.0;
   for(int i = gdx_swingCount2 - 1; i >= 0; i--) {
      if(!gdx_swings2[i].isHigh) { g_p50LastLow = gdx_swings2[i].price; break; }
   }

   // 2. ค้นหา Next Target (จาก HTF EQH/EQL ที่ยังไม่ถูกกวาด)
   if(InpEnableHTF) {
      for(int i=0; i<ArraySize(g_zones_htf); i++) {
         if(g_zones_htf[i].isSwept) continue;
         if(g_isBullStructure && g_zones_htf[i].isHigh && g_zones_htf[i].sweepLevel > curPrice) {
            if(g_targetPrice == 0 || g_zones_htf[i].sweepLevel < g_targetPrice) g_targetPrice = g_zones_htf[i].sweepLevel;
         }
         else if(!g_isBullStructure && !g_zones_htf[i].isHigh && g_zones_htf[i].sweepLevel < curPrice) {
            if(g_targetPrice == 0 || g_zones_htf[i].sweepLevel > g_targetPrice) g_targetPrice = g_zones_htf[i].sweepLevel;
         }
      }
   }

   // 3. ค้นหา POI (Entry จุดที่ราคาควรจะ Pullback ลงมาทดสอบ - M1 Unswept Liquidity)
   for(int i=0; i<ArraySize(g_zones); i++) {
      if(g_zones[i].isSwept) continue;
      if(g_isBullStructure && !g_zones[i].isHigh && g_zones[i].sweepLevel < curPrice) {
         if(g_poiPrice == 0 || g_zones[i].sweepLevel > g_poiPrice) g_poiPrice = g_zones[i].sweepLevel;
      }
      else if(!g_isBullStructure && g_zones[i].isHigh && g_zones[i].sweepLevel > curPrice) {
         if(g_poiPrice == 0 || g_zones[i].sweepLevel < g_poiPrice) g_poiPrice = g_zones[i].sweepLevel;
      }
   }
   // sync local aliases สำหรับโค้ดด้านล่าง
   double poiPrice        = g_poiPrice;
   double targetPrice     = g_targetPrice;
   bool   isBullStructure = g_isBullStructure;

   // 4. สรุป Trade Action
   if(isBullStructure) {
      tradeAction = "🔵 BUY ON DIP (Long Focus)";
      actionClr = clrDeepSkyBlue;
   } else {
      tradeAction = "🔴 SELL ON RALLY (Short Focus)";
      actionClr = clrTomato;
   }

   // 5. Action + POI + Target (รวมบรรทัดเดียว)
   string poiStr = (poiPrice > 0) ? DoubleToString(poiPrice, _Digits) : "---";
   string tgtStr = (targetPrice > 0) ? DoubleToString(targetPrice, _Digits) : "---";
   string actionSym = isBullStructure ? "BUY" : "SELL";
   ObjectSetString (0, DASH_PREFIX+"ACTION", OBJPROP_TEXT,
                    StringFormat("%s  POI %s -> TGT %s", actionSym, poiStr, tgtStr));
   ObjectSetInteger(0, DASH_PREFIX+"ACTION", OBJPROP_COLOR, actionClr);

   // Confluence
   bool m1MomentumUp = (gdx_swingCount > 0 && gdx_swings[gdx_swingCount-1].isHigh);
   string confluence = (m1MomentumUp == isBullStructure) ? "Conf: **** Aligned" : "Conf: ** Wait Rejection";
   ObjectSetString(0, DASH_PREFIX+"CONF", OBJPROP_TEXT, confluence);

   // --- Hull M1 + M15 (รวมบรรทัดเดียว) ---
   string hullTxt = "Hull";
   color  hullClr = clrSilver;
   if(InpHullM1_Enable) {
      if(g_hullDirM1 == 1)       { hullTxt += "  M1UP";  hullClr = InpHullM1_UpColor; }
      else if(g_hullDirM1 == -1) { hullTxt += "  M1DN";  hullClr = InpHullM1_DnColor; }
      else                        { hullTxt += "  M1--"; }
   }
   if(InpHullM15_Enable) {
      if(g_hullDirM15 == 1)       { hullTxt += "  M15UP";  if(hullClr==clrSilver) hullClr = InpHullM15_UpColor; }
      else if(g_hullDirM15 == -1) { hullTxt += "  M15DN";  if(hullClr==clrSilver) hullClr = InpHullM15_DnColor; }
      else                         { hullTxt += "  M15--"; }
   }
   ObjectSetString (0, DASH_PREFIX+"HULL_M1", OBJPROP_TEXT,  hullTxt);
   ObjectSetInteger(0, DASH_PREFIX+"HULL_M1", OBJPROP_COLOR, hullClr);

   // --- [ADD] เรียกใช้การวาดวงกลม GPS Markers ต่อท้าย UpdateDashboard ---
   DrawTradeMarkers(poiPrice, targetPrice, isBullStructure);
}
//+------------------------------------------------------------------+
//|  DELETE all chart objects belonging to a zone                    |
//+------------------------------------------------------------------+
void DeleteZoneObjects(const LiquidityZone &z)
{
   ObjectDelete(0, z.boxName);
   ObjectDelete(0, z.midName);
   ObjectDelete(0, z.lblName);
   ObjectDelete(0, z.b1Name);
   ObjectDelete(0, z.b2Name);
   ObjectDelete(0, z.v1Name);
   ObjectDelete(0, z.v2Name);
}

//+------------------------------------------------------------------+
//|  REMOVE element from g_zones at index i                          |
//+------------------------------------------------------------------+
void RemoveZone(int idx)
{
   int sz = ArraySize(g_zones);
   for(int i = idx; i < sz - 1; i++)
      g_zones[i] = g_zones[i + 1];
   ArrayResize(g_zones, sz - 1);
}

//+------------------------------------------------------------------+
//|  CREATE ZONE -- mirrors zone creation logic in Pine               |
//|  leftTime   : time of previous pivot bar (box left edge)          |
//|  b1Time/b1Price : previous pivot (circle)                         |
//|  b2Time/b2Price : current pivot  (circle)                         |
//|  confirmBarNS   : non-series index of the confirming bar          |
//+------------------------------------------------------------------+
void CreateZone(
   bool     isHigh,
   double   topPrice,
   double   bottomPrice,
   datetime leftTime,
   datetime b1Time,   double b1Price,
   datetime b2Time,   double b2Price,
   double   b1Vol,    double b2Vol,
   int      confirmBarNS,
   datetime rightTime
)
{
   // MinGap filter — block zone if too close to existing same-type unswept zone
   if(InpMinGapFilter && InpMinZoneGapUSD > 0)
   {
      double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double newLevel = isHigh ? topPrice : bottomPrice;
      if(tickSize > 0 && tickVal > 0)
      {
         double minGapPts = (InpMinZoneGapUSD / tickVal) * tickSize / _Point;
         for(int _i = 0; _i < ArraySize(g_zones); _i++)
         {
            if(g_zones[_i].isSwept) continue;
            if(g_zones[_i].isHigh != isHigh) continue;
            if(MathAbs(g_zones[_i].sweepLevel - newLevel) / _Point < minGapPts)
            {
               // Print("[DLZ Signal] Zone skipped — too close to existing ", isHigh?"EQH":"EQL",
               //       " at ", DoubleToString(g_zones[_i].sweepLevel, _Digits),
               //       " gap < $", DoubleToString(InpMinZoneGapUSD, 2));
               return;
            }
         }
      }
   }

   // RVol filter — block low-liquidity zones
   if(InpRVolCreateMult > 0)
   {
      double avgVol = GetAvgVolume(InpRVolPeriod);
      double totVolCheck = b1Vol + b2Vol;
      if(avgVol > 0 && totVolCheck < avgVol * InpRVolCreateMult) return;
   }

   // Enforce MaxZones -- remove oldest if over limit
   while(ArraySize(g_zones) >= InpMaxZones)
   {
      DeleteZoneObjects(g_zones[0]);
      RemoveZone(0);
   }

   color  zClr    = isHigh ? InpBearColor : InpBullColor;
   double mid     = (topPrice + bottomPrice) * 0.5;
   double totVol  = b1Vol + b2Vol;

   LiquidityZone z;
   z.boxName       = ObjName("BOX_");
   z.midName       = ObjName("MID_");
   z.lblName       = ObjName("LBL_");
   z.b1Name        = ObjName("B1_");
   z.b2Name        = ObjName("B2_");
   z.v1Name        = ObjName("V1_");
   z.v2Name        = ObjName("V2_");
   z.sweepLevel    = isHigh ? topPrice : bottomPrice;
   z.totalVol      = totVol;
   z.createdBarNS  = confirmBarNS;
   z.isHigh        = isHigh;
   z.isSwept       = false;
   z.topPrice      = topPrice;
   z.bottomPrice   = bottomPrice;
   z.midPrice      = mid;

   //--- Box (OBJ_RECTANGLE)
   ObjectCreate(0, z.boxName, OBJ_RECTANGLE, 0, leftTime, topPrice, rightTime, bottomPrice);
   ObjectSetInteger(0, z.boxName, OBJPROP_FILL,        true);
   ObjectSetInteger(0, z.boxName, OBJPROP_BGCOLOR,     AlphaColor(zClr, InpZoneTransp));
   ObjectSetInteger(0, z.boxName, OBJPROP_COLOR,       zClr);
   ObjectSetInteger(0, z.boxName, OBJPROP_WIDTH,       1);
   ObjectSetInteger(0, z.boxName, OBJPROP_BACK,        true);
   ObjectSetInteger(0, z.boxName, OBJPROP_SELECTABLE,  false);
   ObjectSetInteger(0, z.boxName, OBJPROP_HIDDEN,      true);

   //--- Midline (OBJ_TREND, dashed) -- optional
   if(InpShowMidline)
   {
      ObjectCreate(0, z.midName, OBJ_TREND, 0, leftTime, mid, rightTime, mid);
      ObjectSetInteger(0, z.midName, OBJPROP_COLOR,      InpMidlineColor);
      ObjectSetInteger(0, z.midName, OBJPROP_STYLE,      STYLE_DASH);
      ObjectSetInteger(0, z.midName, OBJPROP_RAY_RIGHT,  false);
      ObjectSetInteger(0, z.midName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, z.midName, OBJPROP_HIDDEN,     true);
   }

   //--- Text label at right edge (extends with zone)
   ObjectCreate(0, z.lblName, OBJ_TEXT, 0, rightTime, mid);
   ObjectSetInteger(0, z.lblName, OBJPROP_COLOR,     zClr);
   ObjectSetInteger(0, z.lblName, OBJPROP_FONTSIZE,  8);
   ObjectSetInteger(0, z.lblName, OBJPROP_ANCHOR,    ANCHOR_LEFT);
   ObjectSetString (0, z.lblName, OBJPROP_TEXT,      " ");
   ObjectSetInteger(0, z.lblName, OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0, z.lblName, OBJPROP_HIDDEN,    true);

   //--- Pivot circles (OBJ_ARROW, bullet code 108 = o)
   ObjectCreate(0, z.b1Name, OBJ_ARROW, 0, b1Time, b1Price);
   ObjectSetInteger(0, z.b1Name, OBJPROP_ARROWCODE,  108);
   ObjectSetInteger(0, z.b1Name, OBJPROP_COLOR,      zClr);
   ObjectSetInteger(0, z.b1Name, OBJPROP_WIDTH,      2);
   ObjectSetInteger(0, z.b1Name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, z.b1Name, OBJPROP_HIDDEN,     true);

   ObjectCreate(0, z.b2Name, OBJ_ARROW, 0, b2Time, b2Price);
   ObjectSetInteger(0, z.b2Name, OBJPROP_ARROWCODE,  108);
   ObjectSetInteger(0, z.b2Name, OBJPROP_COLOR,      zClr);
   ObjectSetInteger(0, z.b2Name, OBJPROP_WIDTH,      2);
   ObjectSetInteger(0, z.b2Name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, z.b2Name, OBJPROP_HIDDEN,     true);

   //--- Volume labels (Pine: label_down=above for EQH, label_up=below for EQL)
   if(InpShowVolume)
   {
      ENUM_ANCHOR_POINT vAnchor = isHigh ? ANCHOR_LOWER : ANCHOR_UPPER;

      ObjectCreate(0, z.v1Name, OBJ_TEXT, 0, b1Time, b1Price);
      ObjectSetInteger(0, z.v1Name, OBJPROP_COLOR,      zClr);
      ObjectSetInteger(0, z.v1Name, OBJPROP_FONTSIZE,   7);
      ObjectSetInteger(0, z.v1Name, OBJPROP_ANCHOR,     vAnchor);
      ObjectSetString (0, z.v1Name, OBJPROP_TEXT,       FormatVol(b1Vol));
      ObjectSetInteger(0, z.v1Name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, z.v1Name, OBJPROP_HIDDEN,     true);

      ObjectCreate(0, z.v2Name, OBJ_TEXT, 0, b2Time, b2Price);
      ObjectSetInteger(0, z.v2Name, OBJPROP_COLOR,      zClr);
      ObjectSetInteger(0, z.v2Name, OBJPROP_FONTSIZE,   7);
      ObjectSetInteger(0, z.v2Name, OBJPROP_ANCHOR,     vAnchor);
      ObjectSetString (0, z.v2Name, OBJPROP_TEXT,       FormatVol(b2Vol));
      ObjectSetInteger(0, z.v2Name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, z.v2Name, OBJPROP_HIDDEN,     true);
   }

   // Append to active zones array
   int sz = ArraySize(g_zones);
   ArrayResize(g_zones, sz + 1);
   g_zones[sz] = z;
   
   // --- [NEW] เรียกใช้งานฟังก์ชันแจ้งเตือนตรงนี้ ---
   NotifyNewZone(z, b2Time);
   // --- EA: ตรวจสอบและเปิด Order ---
   if(InpEA_Enable && InpZoneEntry && g_isLive) CheckAndOpenOrder(z);
}

//+------------------------------------------------------------------+
//|  UPDATE ZONES -- extend right edge and check for sweeps           |
//|  Called every tick with non-series arrays                        |
//+------------------------------------------------------------------+
void ApplySweepVisuals(int idx)
{
   string typeStr = g_zones[idx].isHigh ? "EQH" : "EQL";
   string volStr  = "";
   if(InpShowVolume)
      volStr = StringFormat(" (%s)", FormatVol(g_zones[idx].totalVol));

   // กำหนดสีเทาเข้ม (DarkGray)
   color clrSwept = clrDarkGray; 

   // 1. ปรับพื้นหลังกล่อง (Box Fill) ให้เป็นเทาอ่อนและโปร่งใสมาก (92%)
   ObjectSetInteger(0, g_zones[idx].boxName, OBJPROP_BGCOLOR, AlphaColor(clrSwept, 92));
   
   // 2. ปรับขอบกล่อง (Box Border)
   ObjectSetInteger(0, g_zones[idx].boxName, OBJPROP_COLOR,   AlphaColor(clrSwept, 80));
   
   // 3. ปรับเส้นกลาง (ถ้าเปิดใช้งาน)
   if(InpShowMidline && g_zones[idx].midName != "")
      ObjectSetInteger(0, g_zones[idx].midName, OBJPROP_COLOR, AlphaColor(clrSwept, 80));
   
   // 4. ปรับสีตัวอักษร Label ให้เป็นสีเทาอ่อน
   ObjectSetInteger(0, g_zones[idx].lblName,  OBJPROP_COLOR,  clrSwept);
   ObjectSetString (0, g_zones[idx].lblName,  OBJPROP_TEXT,   "Swept " + typeStr + volStr);
   
   // 5. ปรับสีจุด Pivot Circles (จุดกลมๆ)
   ObjectSetInteger(0, g_zones[idx].b1Name,   OBJPROP_COLOR,  AlphaColor(clrSwept, 85));
   ObjectSetInteger(0, g_zones[idx].b2Name,   OBJPROP_COLOR,  AlphaColor(clrSwept, 85));
   
   // 6. ลบ Label Volume รายจุดทิ้ง (เพื่อไม่ให้รก)
   ObjectDelete(0, g_zones[idx].v1Name);
   ObjectDelete(0, g_zones[idx].v2Name);

   // --- บันทึก Sweep ล่าสุดสำหรับ Dashboard + Notification ---
   if(g_isLive && TimeCurrent() > g_eaStartTime + 5)
   {
      string tf      = StringSubstr(EnumToString(Period()), 7);
      string priceStr = DoubleToString(g_zones[idx].sweepLevel, _Digits);
      string timeStr  = TimeToString(TimeCurrent(), TIME_MINUTES);
      string icon    = g_zones[idx].isHigh ? "🔴" : "🟢";

      g_lastSweptMsg  = StringFormat("%s %s %s at %s @ %s", icon, typeStr, priceStr, timeStr, tf);
      g_lastSweptTime = TimeCurrent();

      string msg = StringFormat("[DLZ Signal] %s %s: 💥 %s SWEPT at %s | Liquidity Grabbed — Watch for Reversal",
                                _Symbol, tf, typeStr, priceStr);
      Print(msg);
      if(InpNotifySignal) {
         if(InpAlertPopup) Alert(msg);
         //if(InpAlertPush)  SendNotification(msg);
      }
   }
}

void UpdateZones(
   const double   &high[],
   const double   &low[],
   const datetime &time[],
   int   ratesTotal,
   int   currentBarNS
)
{
   // All function-level declarations first (C89 compliance)
   datetime rightTime;
   double   curHigh;
   double   curLow;

   rightTime = time[currentBarNS] + (datetime)PeriodSeconds(Period());
   curHigh   = high[currentBarNS];
   curLow    = low[currentBarNS];

   // ตรวจสอบ retest ครั้งเดียวต่อ tick (ไม่อยู่ใน loop)
   CheckRetestZones(curHigh, curLow);

   for(int idx = ArraySize(g_zones) - 1; idx >= 0; idx--)
   {
      // All loop-body declarations at TOP before any statements (C89 compliance)
      bool   zIsHigh;
      double zSweepLv;
      bool   swept;

      zIsHigh  = g_zones[idx].isHigh;
      zSweepLv = g_zones[idx].sweepLevel;
      swept    = false;

      if(g_zones[idx].isSwept) continue;

      //--- Extend box & label right edge to current bar
      ObjectSetInteger(0, g_zones[idx].boxName, OBJPROP_TIME, 1, rightTime);
      ObjectSetInteger(0, g_zones[idx].lblName, OBJPROP_TIME, 0, rightTime);
      if(InpShowMidline && g_zones[idx].midName != "")
         ObjectSetInteger(0, g_zones[idx].midName, OBJPROP_TIME, 1, rightTime);

      //--- Sweep check starts the bar AFTER confirmation (mirrors Pine: bar_index > zone.createdIdx)
      if(currentBarNS <= g_zones[idx].createdBarNS) continue;

      //--- Check sweep condition
      swept = zIsHigh ? (curHigh > zSweepLv) : (curLow < zSweepLv);
      if(!swept) continue;

      g_zones[idx].isSwept = true;

      if(InpDeleteOnSweep)
      {
         DeleteZoneObjects(g_zones[idx]);
         RemoveZone(idx);
      }
      else
      {
         ApplySweepVisuals(idx);
         RemoveZone(idx);
      }
   }
}

//+------------------------------------------------------------------+
//|  CONSOLIDATE LABELS -- group nearby zones into "2x EQH" etc.     |
//|  Mirrors f_consolidateLabels() in Pine                           |
//+------------------------------------------------------------------+
void ConsolidateLabels()
{
   int sz = ArraySize(g_zones);
   if(sz == 0) return;

   //--- Clear all live zone labels first
   for(int i = 0; i < sz; i++)
      if(!g_zones[i].isSwept)
         ObjectSetString(0, g_zones[i].lblName, OBJPROP_TEXT, " ");

   bool processed[];
   ArrayResize(processed, sz);
   ArrayInitialize(processed, false);

   for(int i = 0; i < sz; i++)
   {
      if(processed[i] || g_zones[i].isSwept) continue;
      processed[i] = true;

      double clusterVol   = g_zones[i].totalVol;
      int    clusterCount = 1;

      for(int j = i + 1; j < sz; j++)
      {
         if(processed[j] || g_zones[j].isSwept) continue;
         if(g_zones[i].isHigh != g_zones[j].isHigh) continue;

         // Cluster threshold = InpThresholdPct * 3 (same as Pine)
         double diff = MathAbs(g_zones[i].sweepLevel - g_zones[j].sweepLevel)
                     / g_zones[i].sweepLevel * 100.0;
         if(diff <= InpThresholdPct * 3.0)
         {
            clusterVol  += g_zones[j].totalVol;
            clusterCount++;
            processed[j] = true;
         }
      }

      string typeStr  = g_zones[i].isHigh ? "EQH" : "EQL";
      string countStr = (clusterCount > 1) ? StringFormat("%dx ", clusterCount) : "";
      string volStr   = InpShowVolume ? StringFormat(" (%s)", FormatVol(clusterVol)) : "";
      ObjectSetString(0, g_zones[i].lblName, OBJPROP_TEXT, countStr + typeStr + volStr);
   }

}

//+------------------------------------------------------------------+
//|  PROCESS ONE CONFIRMING BAR (non-series index)                  |
//|  Called for every bar from historical to most recent             |
//+------------------------------------------------------------------+
void ProcessConfirmBar(
   const double   &high[],
   const double   &low[],
   const datetime &time[],
   const long     &volume[],
   int   confirmBarNS,
   int   ratesTotal
)
{
   int pivotBarNS = confirmBarNS - InpRightLen;

   // ---- EQH (Equal Highs) ----
   if(IsPivotHigh(high, pivotBarNS, InpLeftLen, InpRightLen, ratesTotal))
   {
      double   pH         = high[pivotBarNS];
      datetime pivotTime  = time[pivotBarNS];
      double   pivotVol   = (double)volume[pivotBarNS];

      // Compare with stored historical highs
      int histSz = ArraySize(g_histHighs);
      for(int i = 0; i < histSz; i++)
      {
         double diff = MathAbs(pH - g_histHighs[i].price) / g_histHighs[i].price * 100.0;
         if(diff <= InpThresholdPct)
         {
            double   top       = MathMax(pH, g_histHighs[i].price);
            double   bottom    = MathMin(pH, g_histHighs[i].price);
            datetime rightTime = time[confirmBarNS] + (datetime)PeriodSeconds(Period());

            CreateZone(
               true, top, bottom,
               g_histHighs[i].barTime,            // box left = prev pivot time
               g_histHighs[i].barTime, g_histHighs[i].price,  // b1
               pivotTime,             pH,                      // b2
               g_histHighs[i].vol,    pivotVol,
               confirmBarNS,
               rightTime
            );
            break;  // only match first (closest) historical pivot
         }
      }

      // Prepend current pivot to history (max 50 entries, mirrors Pine)
      PrependPivot(g_histHighs, pH, pivotTime, pivotVol, 50);
   }

   // ---- EQL (Equal Lows) ----
   if(IsPivotLow(low, pivotBarNS, InpLeftLen, InpRightLen, ratesTotal))
   {
      double   pL         = low[pivotBarNS];
      datetime pivotTime  = time[pivotBarNS];
      double   pivotVol   = (double)volume[pivotBarNS];

      int histSz = ArraySize(g_histLows);
      for(int i = 0; i < histSz; i++)
      {
         double diff = MathAbs(pL - g_histLows[i].price) / g_histLows[i].price * 100.0;
         if(diff <= InpThresholdPct)
         {
            double   top       = MathMax(pL, g_histLows[i].price);
            double   bottom    = MathMin(pL, g_histLows[i].price);
            datetime rightTime = time[confirmBarNS] + (datetime)PeriodSeconds(Period());

            CreateZone(
               false, top, bottom,
               g_histLows[i].barTime,
               g_histLows[i].barTime, g_histLows[i].price,
               pivotTime,             pL,
               g_histLows[i].vol,     pivotVol,
               confirmBarNS,
               rightTime
            );
            break;
         }
      }

      PrependPivot(g_histLows, pL, pivotTime, pivotVol, 50);
   }
}

//+------------------------------------------------------------------+
//|  OFA HELPER FUNCTIONS                                            |
//+------------------------------------------------------------------+
string GdxGetVMStatus(bool isBull, double vel, double mag, double pVel, double pMag)
{
   if(pVel <= 0 || pMag <= 0) return isBull ? "v+ m+" : "v- m-";
   string vS = (vel/pVel >= 1.5) ? "v++" : (vel/pVel > 1.0) ? "v+" : (vel/pVel <= 0.67) ? "v--" : "v-";
   string mS = (mag/pMag >= 1.5) ? "m++" : (mag/pMag > 1.0) ? "m+" : (mag/pMag <= 0.5)  ? "m--" : "m-";
   return vS + " " + mS;
}

string GdxGetFibLevelStr(double hi, double lo, double curPrice)
{
   double range = hi - lo;
   if(range < 0.5) return "";
   double ret = (hi - curPrice) / range;
   double fibs[]     = {0.0, 0.236, 0.382, 0.500, 0.618, 0.786, 0.887, 1.000};
   string fibNames[] = {"0%","23.6%","38.2%","50%","61.8%","78.6%","88.7%","100%"};
   if(ret < -0.05) return StringFormat("Fibo +%.1f%%", -ret * 100);
   if(ret >  1.05) return StringFormat("Fibo +%.1f%%",  ret * 100);
   int nearest = 0;
   double minDiff = MathAbs(ret - fibs[0]);
   for(int k = 1; k < 8; k++) {
      double diff = MathAbs(ret - fibs[k]);
      if(diff < minDiff) { minDiff = diff; nearest = k; }
   }
   return "Fibo " + fibNames[nearest];
}

string GdxBuildLabelText(int idx)
{
   if(idx < 1 || idx >= gdx_swingCount) return "";
   GDX_SwingPoint s2 = gdx_swings[idx];
   bool isBull = s2.isHigh;
   double pV = 0, pM = 0;
   for(int j = idx-2; j >= 0; j--)
      if(gdx_swings[j].isHigh == s2.isHigh && gdx_swings[j].velocity > 0)
         { pV = gdx_swings[j].velocity; pM = gdx_swings[j].magnitude; break; }
   string txt = "";
   if(InpOFA_IncludeVelMag) txt += GdxGetVMStatus(isBull, s2.velocity, s2.magnitude, pV, pM) + "\n";
   string sign = isBull ? "+" : "-";
   if(InpOFA_IncludePriceChange)   txt += sign + DoubleToString(s2.magnitude, (_Digits > 3 ? 2 : _Digits));
   if(InpOFA_IncludePercentChange) txt += "\n" + sign + DoubleToString(s2.magPct, 2) + "%";
   if(InpOFA_IncludeBarChange)     txt += "\n" + DoubleToString(s2.velocity, 0) + " bars";
   if(InpOFA_ShowFibLabel && idx >= 2) {
      GDX_SwingPoint s1 = gdx_swings[idx - 1];
      GDX_SwingPoint s0 = gdx_swings[idx - 2];
      double hi = s1.isHigh ? s1.price : s0.price;
      double lo = s1.isHigh ? s0.price : s1.price;
      txt += "\n" + GdxGetFibLevelStr(hi, lo, s2.price);
   }
   return txt;
}

void GdxUpdateOFACore(int total, const datetime &time[],
                   const double &high[], const double &low[], const double &close[],
                   bool isFullRecalc,
                   const double &open[],
                   const long   &tickvol[])
{
   int fp = InpOFA_FractalPeriod;
   int scan_start;
   if(!isFullRecalc && gdx_LastConfirmedCount > 1) {
      scan_start = total - (fp * 3 + 1);
      if(scan_start < fp) scan_start = fp;
   } else {
      scan_start = total - InpOFA_MaxBars;
      if(scan_start < fp) scan_start = fp;
   }
   GDX_Fractal fr[];
   int frCount = 0;
   int limit = total - 1;
   for(int i = scan_start; i < limit; i++) {
      bool isFH = true, isFL = true;
      for(int j = 1; j <= fp; j++) {
         int li = i-j, ri = i+j;
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
      if(isFH) { ArrayResize(fr,frCount+1); fr[frCount].time=time[i]; fr[frCount].price=high[i]; fr[frCount].bar=i; fr[frCount].isHigh=true;  frCount++; }
      if(isFL) { ArrayResize(fr,frCount+1); fr[frCount].time=time[i]; fr[frCount].price=low[i];  fr[frCount].bar=i; fr[frCount].isHigh=false; frCount++; }
   }
   if(!isFullRecalc && gdx_LastConfirmedCount > 1) {
      int keepCount = gdx_LastConfirmedCount;
      while(keepCount > 0 && gdx_swings[keepCount-1].bar >= scan_start) keepCount--;
      if(keepCount < gdx_LastConfirmedCount - 3) keepCount = gdx_LastConfirmedCount - 3;
      if(keepCount < 1) { GdxUpdateOFACore(total,time,high,low,close,true,open,tickvol); return; }
      if(frCount == 0) return;
      int combined = keepCount + frCount;
      GDX_Fractal allFr[];
      ArrayResize(allFr, combined);
      for(int k=0;k<keepCount;k++) { allFr[k].time=gdx_swings[k].time; allFr[k].price=gdx_swings[k].price; allFr[k].bar=gdx_swings[k].bar; allFr[k].isHigh=gdx_swings[k].isHigh; }
      for(int k=0;k<frCount;k++) allFr[keepCount+k]=fr[k];
      ArrayResize(fr,combined);
      for(int k=0;k<combined;k++) fr[k]=allFr[k];
      frCount=combined;
   }
   if(frCount < 2) return;
   for(int i=1;i<frCount;i++) { GDX_Fractal kk=fr[i]; int j=i-1; while(j>=0&&fr[j].bar>kk.bar){fr[j+1]=fr[j];j--;} fr[j+1]=kk; }
   bool chg=true;
   while(chg) {
      chg=false;
      for(int i=0;i<frCount-1;i++) {
         if(fr[i].isHigh==fr[i+1].isHigh) {
            int rem=fr[i].isHigh?(fr[i].price>=fr[i+1].price?i+1:i):(fr[i].price<=fr[i+1].price?i+1:i);
            for(int k=rem;k<frCount-1;k++) fr[k]=fr[k+1];
            frCount--; ArrayResize(fr,frCount); chg=true; break;
         }
      }
   }
   ArrayResize(gdx_swings,frCount); gdx_swingCount=frCount;
   for(int i=0;i<frCount;i++) {
      gdx_swings[i].time=fr[i].time; gdx_swings[i].price=fr[i].price;
      gdx_swings[i].bar=fr[i].bar;   gdx_swings[i].isHigh=fr[i].isHigh;
      gdx_swings[i].velocity=0; gdx_swings[i].magnitude=0; gdx_swings[i].magPct=0;
      int b = fr[i].bar;
      gdx_swings[i].volume = (ArraySize(tickvol) > b && b >= 0) ? tickvol[b] : 0;
      gdx_swings[i].open   = (ArraySize(open)    > b && b >= 0) ? open[b]    : 0;
      gdx_swings[i].high   = (b >= 0 && b < total) ? high[b]   : 0;
      gdx_swings[i].low    = (b >= 0 && b < total) ? low[b]    : 0;
      gdx_swings[i].close  = (b >= 0 && b < total) ? close[b]  : 0;
      if(i>0) {
         gdx_swings[i].velocity =MathAbs((double)(gdx_swings[i].bar-gdx_swings[i-1].bar));
         gdx_swings[i].magnitude=MathAbs(gdx_swings[i].price-gdx_swings[i-1].price);
         gdx_swings[i].magPct   =(gdx_swings[i-1].price!=0)?(gdx_swings[i].magnitude/gdx_swings[i-1].price)*100.0:0;
      }
   }
   gdx_LastConfirmedCount=gdx_swingCount;
}

void GdxUpdateOFACore2(int total, const datetime &time[],
                       const double &high[], const double &low[], const double &close[],
                       bool isFullRecalc)
{
   int fp=InpOFA_FractalPeriod2;
   if(fp<=0) return;
   int scan_start;
   if(!isFullRecalc && gdx_LastConfirmedCount2>1) { scan_start=total-(fp*3+1); if(scan_start<fp) scan_start=fp; }
   else { scan_start=total-InpOFA_MaxBars; if(scan_start<fp) scan_start=fp; }
   GDX_Fractal fr2[]; int frCount2=0; int limit2=total-1;
   for(int i=scan_start;i<limit2;i++) {
      bool isFH=true,isFL=true;
      for(int j=1;j<=fp;j++) {
         int li=i-j,ri=i+j;
         if(li<0||ri>=total){isFH=false;isFL=false;break;}
         if(InpOFA_AggressiveFractal){if(high[i]<=high[li]||high[i]<=high[ri])isFH=false;if(low[i]>=low[li]||low[i]>=low[ri])isFL=false;}
         else{if(close[i]<=close[li]||close[i]<=close[ri])isFH=false;if(close[i]>=close[li]||close[i]>=close[ri])isFL=false;}
         if(!isFH&&!isFL) break;
      }
      if(isFH){ArrayResize(fr2,frCount2+1);fr2[frCount2].time=time[i];fr2[frCount2].price=high[i];fr2[frCount2].bar=i;fr2[frCount2].isHigh=true;frCount2++;}
      if(isFL){ArrayResize(fr2,frCount2+1);fr2[frCount2].time=time[i];fr2[frCount2].price=low[i]; fr2[frCount2].bar=i;fr2[frCount2].isHigh=false;frCount2++;}
   }
   if(!isFullRecalc&&gdx_LastConfirmedCount2>1){
      int kc2=gdx_LastConfirmedCount2;
      while(kc2>0&&gdx_swings2[kc2-1].bar>=scan_start) kc2--;
      if(kc2<1){GdxUpdateOFACore2(total,time,high,low,close,true);return;}
      if(frCount2==0) return;
      int c2=kc2+frCount2; GDX_Fractal aF2[]; ArrayResize(aF2,c2);
      for(int k=0;k<kc2;k++){aF2[k].time=gdx_swings2[k].time;aF2[k].price=gdx_swings2[k].price;aF2[k].bar=gdx_swings2[k].bar;aF2[k].isHigh=gdx_swings2[k].isHigh;}
      for(int k=0;k<frCount2;k++) aF2[kc2+k]=fr2[k];
      ArrayResize(fr2,c2); for(int k=0;k<c2;k++) fr2[k]=aF2[k]; frCount2=c2;
   }
   if(frCount2<2) return;
   for(int i=1;i<frCount2;i++){GDX_Fractal k2=fr2[i];int j=i-1;while(j>=0&&fr2[j].bar>k2.bar){fr2[j+1]=fr2[j];j--;}fr2[j+1]=k2;}
   bool chg2=true;
   while(chg2){chg2=false;for(int i=0;i<frCount2-1;i++){if(fr2[i].isHigh==fr2[i+1].isHigh){int rem=fr2[i].isHigh?(fr2[i].price>=fr2[i+1].price?i+1:i):(fr2[i].price<=fr2[i+1].price?i+1:i);for(int k=rem;k<frCount2-1;k++)fr2[k]=fr2[k+1];frCount2--;ArrayResize(fr2,frCount2);chg2=true;break;}}}
   ArrayResize(gdx_swings2,frCount2); gdx_swingCount2=frCount2;
   for(int i=0;i<frCount2;i++){
      gdx_swings2[i].time=fr2[i].time; gdx_swings2[i].price=fr2[i].price;
      gdx_swings2[i].bar=fr2[i].bar;   gdx_swings2[i].isHigh=fr2[i].isHigh;
      gdx_swings2[i].velocity=0; gdx_swings2[i].magnitude=0; gdx_swings2[i].magPct=0;
      if(i>0){gdx_swings2[i].velocity=MathAbs((double)(gdx_swings2[i].bar-gdx_swings2[i-1].bar));gdx_swings2[i].magnitude=MathAbs(gdx_swings2[i].price-gdx_swings2[i-1].price);gdx_swings2[i].magPct=(gdx_swings2[i-1].price!=0)?(gdx_swings2[i].magnitude/gdx_swings2[i-1].price)*100.0:0;}
   }
   gdx_LastConfirmedCount2=gdx_swingCount2;
}

void GdxUpdateLiveLegDraw()
{
   if(gdx_swingCount<2) return;
   string n="GDEA_OFA_LIVE", tn="GDEA_OFA_LIVET";
   GDX_SwingPoint s1=gdx_swings[gdx_swingCount-2], s2=gdx_swings[gdx_swingCount-1];
   color c=s2.isHigh?clrAqua:clrOrange;
   if(InpOFA_ShowZigzag) {
      if(ObjectFind(0,n)<0) ObjectCreate(0,n,OBJ_TREND,0,s1.time,s1.price,s2.time,s2.price);
      ObjectSetInteger(0,n,OBJPROP_TIME,0,s1.time);   ObjectSetDouble(0,n,OBJPROP_PRICE,0,s1.price);
      ObjectSetInteger(0,n,OBJPROP_TIME,1,s2.time);   ObjectSetDouble(0,n,OBJPROP_PRICE,1,s2.price);
      ObjectSetInteger(0,n,OBJPROP_COLOR,c); ObjectSetInteger(0,n,OBJPROP_WIDTH,2);
      ObjectSetInteger(0,n,OBJPROP_RAY_RIGHT,false); ObjectSetInteger(0,n,OBJPROP_BACK,true);
      ObjectSetInteger(0,n,OBJPROP_SELECTABLE,false);
   }
   string txt=GdxBuildLabelText(gdx_swingCount-1);
   if(txt!=""&&InpOFA_ShowLabels) {
      if(ObjectFind(0,tn)<0) ObjectCreate(0,tn,OBJ_TEXT,0,s2.time,s2.price);
      ObjectSetInteger(0,tn,OBJPROP_TIME,0,s2.time); ObjectSetDouble(0,tn,OBJPROP_PRICE,0,s2.price);
      ObjectSetString(0,tn,OBJPROP_TEXT,txt); ObjectSetInteger(0,tn,OBJPROP_COLOR,c);
      ObjectSetInteger(0,tn,OBJPROP_FONTSIZE,InpOFA_LabelFontSize);
      ObjectSetInteger(0,tn,OBJPROP_ANCHOR,s2.isHigh?ANCHOR_LEFT_LOWER:ANCHOR_LEFT_UPPER);
      ObjectSetInteger(0,tn,OBJPROP_SELECTABLE,false);
   }
}

void GdxUpdateLiveSwing(int total, const datetime &time[],
                     const double &high[], const double &low[])
{
   if(gdx_LastConfirmedCount < 1) return;
   gdx_swingCount=gdx_LastConfirmedCount;
   ArrayResize(gdx_swings,gdx_swingCount);
   int lastB=total-2;
   GDX_SwingPoint last=gdx_swings[gdx_swingCount-1], cur;
   if(last.bar < 0 || last.bar >= total) return;
   if(last.isHigh) {
      double cL=low[last.bar]; int cB=last.bar;
      for(int b=last.bar+1;b<=lastB;b++) if(low[b]<cL){cL=low[b];cB=b;}
      cur.isHigh=false; cur.price=cL; cur.bar=cB; cur.time=time[cB];
   } else {
      double cH=high[last.bar]; int cB=last.bar;
      for(int b=last.bar+1;b<=lastB;b++) if(high[b]>cH){cH=high[b];cB=b;}
      cur.isHigh=true; cur.price=cH; cur.bar=cB; cur.time=time[cB];
   }
   cur.velocity=MathAbs((double)(cur.bar-last.bar));
   cur.magnitude=MathAbs(cur.price-last.price);
   cur.magPct=(last.price!=0)?(cur.magnitude/last.price)*100.0:0;
   cur.volume=0; cur.open=0; cur.high=0; cur.low=0; cur.close=0;
   ArrayResize(gdx_swings,gdx_swingCount+1); gdx_swings[gdx_swingCount]=cur; gdx_swingCount++;
   GdxUpdateLiveLegDraw();
}

void GdxUpdateLiveSwing2(int total, const datetime &time[],
                          const double &high[], const double &low[])
{
   if(InpOFA_FractalPeriod2<=InpOFA_FractalPeriod) return;
   if(gdx_LastConfirmedCount2<1) return;
   gdx_swingCount2=gdx_LastConfirmedCount2;
   ArrayResize(gdx_swings2,gdx_swingCount2);
   int lastB=total-2;
   GDX_SwingPoint last2=gdx_swings2[gdx_swingCount2-1], cur2;
   if(last2.bar < 0 || last2.bar >= total) return;
   if(last2.isHigh) {
      double cL=low[last2.bar]; int cB=last2.bar;
      for(int b=last2.bar+1;b<=lastB;b++) if(low[b]<cL){cL=low[b];cB=b;}
      cur2.isHigh=false; cur2.price=cL; cur2.bar=cB; cur2.time=time[cB];
   } else {
      double cH=high[last2.bar]; int cB=last2.bar;
      for(int b=last2.bar+1;b<=lastB;b++) if(high[b]>cH){cH=high[b];cB=b;}
      cur2.isHigh=true; cur2.price=cH; cur2.bar=cB; cur2.time=time[cB];
   }
   cur2.velocity=MathAbs((double)(cur2.bar-last2.bar));
   cur2.magnitude=MathAbs(cur2.price-last2.price);
   cur2.magPct=(last2.price!=0)?(cur2.magnitude/last2.price)*100.0:0;
   cur2.volume=0; cur2.open=0; cur2.high=0; cur2.low=0; cur2.close=0;
   ArrayResize(gdx_swings2,gdx_swingCount2+1); gdx_swings2[gdx_swingCount2]=cur2; gdx_swingCount2++;
   if(InpOFA_ShowZigzag2) {
      string nL2="GDEA_OFA2_LIVE"; color cL2=cur2.isHigh?InpOFA_SlowBullColour:InpOFA_SlowBearColour;
      if(ObjectFind(0,nL2)<0) ObjectCreate(0,nL2,OBJ_TREND,0,last2.time,last2.price,cur2.time,cur2.price);
      ObjectSetInteger(0,nL2,OBJPROP_TIME,0,last2.time); ObjectSetDouble(0,nL2,OBJPROP_PRICE,0,last2.price);
      ObjectSetInteger(0,nL2,OBJPROP_TIME,1,cur2.time);  ObjectSetDouble(0,nL2,OBJPROP_PRICE,1,cur2.price);
      ObjectSetInteger(0,nL2,OBJPROP_COLOR,cL2); ObjectSetInteger(0,nL2,OBJPROP_WIDTH,InpOFA_SlowLineWidth);
      ObjectSetInteger(0,nL2,OBJPROP_STYLE,STYLE_DOT); ObjectSetInteger(0,nL2,OBJPROP_RAY_RIGHT,false);
      ObjectSetInteger(0,nL2,OBJPROP_BACK,true); ObjectSetInteger(0,nL2,OBJPROP_SELECTABLE,false);
   }
   if(InpOFA_ShowLabels) {
      string tn2="GDEA_OFA2_LIVET"; color cL2=cur2.isHigh?InpOFA_SlowBullColour:InpOFA_SlowBearColour;
      string lbl2=StringFormat("[p50] %s%.2f",cur2.isHigh?"+":"-",cur2.magnitude);
      if(InpOFA_ShowFibLabel && gdx_swingCount2>=3) {
         GDX_SwingPoint prev2=gdx_swings2[gdx_swingCount2-3];
         double hi2=last2.isHigh?last2.price:prev2.price;
         double lo2=last2.isHigh?prev2.price:last2.price;
         lbl2+="\n"+GdxGetFibLevelStr(hi2,lo2,cur2.price);
      }
      if(ObjectFind(0,tn2)<0) ObjectCreate(0,tn2,OBJ_TEXT,0,cur2.time,cur2.price);
      ObjectSetInteger(0,tn2,OBJPROP_TIME,0,cur2.time);  ObjectSetDouble(0,tn2,OBJPROP_PRICE,0,cur2.price);
      ObjectSetString(0,tn2,OBJPROP_TEXT,lbl2);          ObjectSetInteger(0,tn2,OBJPROP_COLOR,cL2);
      ObjectSetInteger(0,tn2,OBJPROP_FONTSIZE,InpOFA_LabelFontSize);
      ObjectSetInteger(0,tn2,OBJPROP_ANCHOR,cur2.isHigh?ANCHOR_RIGHT_LOWER:ANCHOR_RIGHT_UPPER);
      ObjectSetInteger(0,tn2,OBJPROP_SELECTABLE,false);  ObjectSetInteger(0,tn2,OBJPROP_HIDDEN,true);
   }
}

void GdxDrawOFALegs()
{
   ObjectsDeleteAll(0,"GDEA_OFA_L"); ObjectsDeleteAll(0,"GDEA_OFA_T");
   int draw_start=gdx_LastConfirmedCount-100; if(draw_start<1) draw_start=1;
   for(int i=draw_start-1;i<gdx_LastConfirmedCount-1;i++) {
      string n="GDEA_OFA_L"+IntegerToString(i);
      color c=gdx_swings[i+1].isHigh?InpOFA_BullishColour:InpOFA_BearishColour;
      if(InpOFA_ShowZigzag) {
         ObjectCreate(0,n,OBJ_TREND,0,gdx_swings[i].time,gdx_swings[i].price,gdx_swings[i+1].time,gdx_swings[i+1].price);
         ObjectSetInteger(0,n,OBJPROP_COLOR,c); ObjectSetInteger(0,n,OBJPROP_WIDTH,2);
         ObjectSetInteger(0,n,OBJPROP_RAY_RIGHT,false); ObjectSetInteger(0,n,OBJPROP_SELECTABLE,false);
         ObjectSetInteger(0,n,OBJPROP_BACK,true);
      }
      string tn="GDEA_OFA_T"+IntegerToString(i+1);
      string txt=GdxBuildLabelText(i+1);
      if(txt!=""&&InpOFA_ShowLabels) {
         ObjectCreate(0,tn,OBJ_TEXT,0,gdx_swings[i+1].time,gdx_swings[i+1].price);
         ObjectSetString(0,tn,OBJPROP_TEXT,txt); ObjectSetInteger(0,tn,OBJPROP_COLOR,c);
         ObjectSetInteger(0,tn,OBJPROP_FONTSIZE,InpOFA_LabelFontSize);
         ObjectSetInteger(0,tn,OBJPROP_ANCHOR,gdx_swings[i+1].isHigh?ANCHOR_LEFT_LOWER:ANCHOR_LEFT_UPPER);
         ObjectSetInteger(0,tn,OBJPROP_SELECTABLE,false);
      }
   }
}

void GdxDrawOFALegs2()
{
   if(!InpOFA_ShowZigzag2) return;
   if(InpOFA_FractalPeriod2<=InpOFA_FractalPeriod) return;
   if(gdx_LastConfirmedCount2<2) return;
   ObjectsDeleteAll(0,"GDEA_OFA2_L"); ObjectsDeleteAll(0,"GDEA_OFA2_T");
   int ds2=gdx_LastConfirmedCount2-60; if(ds2<1) ds2=1;
   for(int i=ds2-1;i<gdx_LastConfirmedCount2-1;i++) {
      string n2="GDEA_OFA2_L"+IntegerToString(i);
      color c2=gdx_swings2[i+1].isHigh?InpOFA_SlowBullColour:InpOFA_SlowBearColour;
      ObjectCreate(0,n2,OBJ_TREND,0,gdx_swings2[i].time,gdx_swings2[i].price,gdx_swings2[i+1].time,gdx_swings2[i+1].price);
      ObjectSetInteger(0,n2,OBJPROP_COLOR,c2); ObjectSetInteger(0,n2,OBJPROP_WIDTH,InpOFA_SlowLineWidth);
      ObjectSetInteger(0,n2,OBJPROP_STYLE,STYLE_DASH); ObjectSetInteger(0,n2,OBJPROP_RAY_RIGHT,false);
      ObjectSetInteger(0,n2,OBJPROP_SELECTABLE,false); ObjectSetInteger(0,n2,OBJPROP_BACK,true);
      if(InpOFA_ShowLabels) {
         string tn2="GDEA_OFA2_T"+IntegerToString(i+1);
         bool isH2=gdx_swings2[i+1].isHigh;
         string lbl2=StringFormat("[p50] %s%.2f",isH2?"+":"-",gdx_swings2[i+1].magnitude);
         if(InpOFA_ShowFibLabel && i >= 1) {
            bool prevIsH2 = gdx_swings2[i].isHigh;
            double hi2 = prevIsH2 ? gdx_swings2[i].price : gdx_swings2[i-1].price;
            double lo2 = prevIsH2 ? gdx_swings2[i-1].price : gdx_swings2[i].price;
            lbl2 += "\n" + GdxGetFibLevelStr(hi2, lo2, gdx_swings2[i+1].price);
         }
         ObjectCreate(0,tn2,OBJ_TEXT,0,gdx_swings2[i+1].time,gdx_swings2[i+1].price);
         ObjectSetString(0,tn2,OBJPROP_TEXT,lbl2); ObjectSetInteger(0,tn2,OBJPROP_COLOR,c2);
         ObjectSetInteger(0,tn2,OBJPROP_FONTSIZE,InpOFA_LabelFontSize);
         ObjectSetInteger(0,tn2,OBJPROP_ANCHOR,isH2?ANCHOR_RIGHT_LOWER:ANCHOR_RIGHT_UPPER);
         ObjectSetInteger(0,tn2,OBJPROP_SELECTABLE,false);
      }
   }
}

void RunOFAUpdate(const int total, 
                  const datetime &arr_time[],
                  const double &arr_open[], 
                  const double &arr_high[], 
                  const double &arr_low[], 
                  const double &arr_close[],
                  const long &arr_volume[])
{
   int need = InpOFA_FractalPeriod * 2 + 2;
   if(total < need) return;

   // สังเกตว่าเราลบพวก double arr_high[]; และ CopyHigh ออกไปหมดแล้ว 
   // เพราะเราใช้ข้อมูลที่ส่งต่อมาจาก OnCalculate โดยตรง (ช่วยลดการทำงานของ CPU ได้มหาศาล)

   bool isNewBar  = (arr_time[total-1] != gdx_LastBarTime);
   bool isNewBar2 = (arr_time[total-1] != gdx_LastBarTime2);

   if(isNewBar) {
      GdxUpdateOFACore(total, arr_time, arr_high, arr_low, arr_close,
                       true, arr_open, arr_volume); // always full recalc — incremental merge causes swing drift
      GdxDrawOFALegs();
      gdx_LastBarTime = arr_time[total-1];
   }
   GdxUpdateLiveSwing(total, arr_time, arr_high, arr_low);

   if(InpOFA_FractalPeriod2 > InpOFA_FractalPeriod) {
      if(isNewBar2) {
         GdxUpdateOFACore2(total, arr_time, arr_high, arr_low, arr_close,
                           true); // always full recalc
         GdxDrawOFALegs2();
         gdx_LastBarTime2 = arr_time[total-1];
      }
      GdxUpdateLiveSwing2(total, arr_time, arr_high, arr_low);
   }
}

//+------------------------------------------------------------------+
//| [NEW] FIBO MEANING & STAR RATING LOGIC                           |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| [REPLACE] FIBO ZONE LEVEL MEANING (Range-based Logic)            |
//+------------------------------------------------------------------+
string GetFiboMeaning(double pct)
{
   double absPct = MathAbs(pct); // ใช้ค่าบวกในการเช็คโซน

   //--- Retracement Zones (0 - 110%) ---
   if(absPct < 44.0)                   return "⭐⭐ Shallow retrace | Trend strong (38.2% Zone)";
   if(absPct >= 44.0 && absPct < 56.0)  return "⭐⭐ Decision zone | Bull/Bear battle (50.0% Zone)";
   if(absPct >= 56.0 && absPct < 70.0)  return "⭐⭐⭐ Golden Ratio | Reversal zone (61.8% Zone)";
   if(absPct >= 70.0 && absPct < 90.0)  return "⭐⭐⭐ Deep retrace | Last chance (78.6% Zone)";
   if(absPct >= 90.0 && absPct < 110.0) return "⭐⭐ Full retrace | Double top/bot (100.0% Zone)";

   //--- Extension Zones (110%+) ---
   // เช็คโซน 127.2% (ครอบคลุม 112.7% จากในรูป)
   if(absPct >= 110.0 && absPct < 145.0) 
   {
      if(pct > 0) return "⭐⭐⭐ Extension | Breakout confirm (127.2% Zone)";
      else        return "⭐⭐⭐ Extension DN | Breakout confirm (-127.2% Zone)";
   }
   
   // เช็คโซน 161.8%
   if(absPct >= 145.0 && absPct < 210.0)
   {
      if(pct > 0) return "⭐⭐⭐ Golden Extension | Target (161.8% Zone)";
      else        return "⭐⭐⭐ Golden Extension DN | Target (-161.8% Zone)";
   }

   // เช็คโซน 261.8% ขึ้นไป
   if(absPct >= 210.0)
   {
      if(pct > 0) return "⭐⭐ Extended run | Momentum extreme (261.8% Zone)";
      else        return "⭐⭐ Extended run DN | Momentum extreme (-261.8% Zone)";
   }

   return "Scanning for key levels...";
}


//+------------------------------------------------------------------+
//| HULL MTF — ฉบับแก้ไขเพิ่ม Slope Smoothing (ลดสัญญาณหลอก)            |
//+------------------------------------------------------------------+
void RunHullMTF(CGdxHull &eng, bool &isInit, double &hv[], double &ht[],
                datetime &lastBar, int &dir,
                ENUM_TIMEFRAMES tf, int period, double divisor,
                color upClr, color dnClr, int lw, const string prefix,
                double threshold, int slopeLB, double &outSlope, double &outLastVal)
{
   int total = Bars(_Symbol, tf);
   if(total < period * 2 + 2) return;
   int limit = MathMin(total, 500);

   datetime bt[];
   ArraySetAsSeries(bt, false);
   if(CopyTime(_Symbol, tf, 0, limit, bt) <= 0) return;
   int seg = ArraySize(bt);
   if(seg < 2) return;

   bool newBar = (bt[seg - 1] != lastBar);
   if(!newBar && isInit) return;

   if(!isInit) { eng.init(period, divisor); isInit = true; }

   double hc[];
   ArraySetAsSeries(hc, false);
   if(CopyClose(_Symbol, tf, 0, seg, hc) <= 0) return;

   if(ArraySize(hv) < seg) { ArrayResize(hv, seg + 100); ArrayResize(ht, seg + 100); }

   double thr = threshold * _Point;
   int    lb  = (slopeLB < 1) ? 1 : slopeLB;  // lookback bars สำหรับ slope

   for(int i = 0; i < seg; i++) {
      hv[i] = eng.calculate(hc[i], i, seg);

      if(i >= lb) {
         // slope เฉลี่ย lb bars — เห็น "หักหัว" ได้ชัดกว่า tick-to-tick
         double slope = (hv[i] - hv[i - lb]) / lb;
         // บันทึก slope M1 ล่าสุดสำหรับ DXY AutoTrade filter (เฉพาะแท่งสุดท้ายเท่านั้น)
         if(prefix == "DLZ_HULLM1_" && i == seg - 1) {
            g_hullValueM1_Prev = hv[seg-2];
            g_hullValueM1_Curr = hv[seg-1];
         }
         if(slope > thr)
            ht[i] = 1.0;   // Bullish
         else if(slope < -thr)
            ht[i] = -1.0;  // Bearish
         else
            ht[i] = ht[i - 1]; // sideway — ใช้สีเดิม
      }
      else if(i > 0) ht[i] = ht[i - 1];
      else           ht[i] = 0.0;
   }

   dir = (int)ht[seg - 1];

   // store slope ล่าสุด (raw, ไม่ * _Point — แสดงเป็น price per bar)
   if(seg > lb) outSlope = (hv[seg - 1] - hv[seg - 1 - lb]) / lb;

   // --- New Bar: redraw history segments (ds → seg-2), delete old objects first
   if(newBar || !isInit) {
      ObjectsDeleteAll(0, prefix + "H");
      int ds = seg - 300; if(ds < 1) ds = 1;
      for(int i = ds; i < seg - 1; i++) {
         if(hv[i] == 0 || hv[i - 1] == 0) continue;
         string n = prefix + "H" + IntegerToString(i);
         ObjectCreate(0, n, OBJ_TREND, 0, bt[i-1], hv[i-1], bt[i], hv[i]);
         ObjectSetInteger(0, n, OBJPROP_RAY_RIGHT,  false);
         ObjectSetInteger(0, n, OBJPROP_WIDTH,       lw);
         ObjectSetInteger(0, n, OBJPROP_SELECTABLE,  false);
         ObjectSetInteger(0, n, OBJPROP_BACK,        true);
         color hclr = (ht[i] == 1.0) ? upClr : dnClr;
         ObjectSetInteger(0, n, OBJPROP_COLOR,  hclr);
         ObjectSetDouble (0, n, OBJPROP_PRICE, 0, hv[i-1]);
         ObjectSetDouble (0, n, OBJPROP_PRICE, 1, hv[i]);
      }
   }

   // --- Every tick: update live segment (last bar only) using ObjectMove
   string liveName = prefix + "LIVE";
   color liveClr = (ht[seg-1] == 1.0) ? upClr : dnClr;
   if(ObjectFind(0, liveName) < 0) {
      ObjectCreate(0, liveName, OBJ_TREND, 0, bt[seg-2], hv[seg-2], bt[seg-1], hv[seg-1]);
      ObjectSetInteger(0, liveName, OBJPROP_RAY_RIGHT,  false);
      ObjectSetInteger(0, liveName, OBJPROP_WIDTH,       lw);
      ObjectSetInteger(0, liveName, OBJPROP_SELECTABLE,  false);
      ObjectSetInteger(0, liveName, OBJPROP_BACK,        true);
   } else {
      ObjectMove(0, liveName, 0, bt[seg-2], hv[seg-2]);
      ObjectMove(0, liveName, 1, bt[seg-1], hv[seg-1]);
   }
   ObjectSetInteger(0, liveName, OBJPROP_COLOR, liveClr);

   // --- Hull Gap Label (ปลายเส้น live) ---
   if(prefix == "DLZ_HULLM1_" || prefix == "DLZ_HULLM15_")
   {
      string lblName = (prefix == "DLZ_HULLM1_") ? "DLZ_HULLM1_LABEL" : "DLZ_HULLM15_LABEL";
      double curPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double gap      = hv[seg - 1] - curPrice;
      string gapTxt   = StringFormat("%s$%.2f", (gap >= 0 ? "+" : ""), gap);
      datetime lblTime = bt[seg-1] + (datetime)(PeriodSeconds(PERIOD_M1) * 5);
      if(ObjectFind(0, lblName) < 0)
         ObjectCreate(0, lblName, OBJ_TEXT, 0, lblTime, hv[seg-1]);
      ObjectSetInteger(0, lblName, OBJPROP_TIME,   0, lblTime);
      ObjectSetDouble (0, lblName, OBJPROP_PRICE,  0, hv[seg-1]);
      ObjectSetString (0, lblName, OBJPROP_TEXT,   gapTxt);
      ObjectSetInteger(0, lblName, OBJPROP_COLOR,  liveClr);
      ObjectSetInteger(0, lblName, OBJPROP_FONTSIZE, 8);
      ObjectSetString (0, lblName, OBJPROP_FONT,   "Arial Bold");
      ObjectSetInteger(0, lblName, OBJPROP_ANCHOR, ANCHOR_LEFT);
      ObjectSetInteger(0, lblName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, lblName, OBJPROP_HIDDEN, true);
   }

   outLastVal = hv[seg - 1];
   lastBar = bt[seg - 1];
}
//+------------------------------------------------------------------+
//| Gold Trend Direction: 1=UP, -1=DN, 0=FLAT (30-bar Close)        |
//+------------------------------------------------------------------+
int GetGoldTrendDirection()
{
   double gold_close[];
   ArraySetAsSeries(gold_close, true);
   int lookback = 30;
   if(CopyClose(_Symbol, PERIOD_CURRENT, 0, lookback, gold_close) < lookback) return 0;
   double diff      = gold_close[0] - gold_close[lookback - 1];
   double threshold = (_Digits >= 3) ? 0.2 : 1.0;  // XAUUSDm: 1.0 USD/30bar = real trend
   if(diff >  threshold) return  1;
   if(diff < -threshold) return -1;
   return 0;
}

//+------------------------------------------------------------------+
//| DXY Trend Direction: 1=UP(USD Strong), -1=DN(USD Weak), 0=Flat  |
//+------------------------------------------------------------------+
int GetDXYTrendDirection()
{
   if(StringLen(InpDXY_Symbol) == 0) return 0;
   double dxy_close[];
   ArraySetAsSeries(dxy_close, true);
   if(CopyClose(InpDXY_Symbol, PERIOD_CURRENT, 0, InpDXY_Lookback, dxy_close) < InpDXY_Lookback)
      return 0;
   double diff = dxy_close[0] - dxy_close[InpDXY_Lookback - 1];
   if(diff >  0.02) return  1;
   if(diff < -0.02) return -1;
   return 0;
}

//+------------------------------------------------------------------+
//|  NEWS & SESSION FILTER FUNCTIONS                                 |
//+------------------------------------------------------------------+
bool IsNewsTime()
{
   if(!InpUseNewsFilter) return false;
   static datetime lastNewsCheck = 0;
   static bool     lastNewsResult = false;
   if(TimeCurrent() - lastNewsCheck < 30) return lastNewsResult;
   lastNewsCheck = TimeCurrent();

   datetime gmtNow = TimeGMT();
   datetime tStart = gmtNow - (InpNewsAfter  * 60);
   datetime tEnd   = gmtNow + (InpNewsBefore * 60);
   string curBase  = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_BASE);
   string curProf  = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT);
   string toCheck[];
   if(InpIncludeUSD && curBase != "USD" && curProf != "USD") {
      ArrayResize(toCheck, 3); toCheck[0]=curBase; toCheck[1]=curProf; toCheck[2]="USD";
   } else {
      ArrayResize(toCheck, 2); toCheck[0]=curBase; toCheck[1]=curProf;
   }

   MqlCalendarValue vals[];
   for(int i = 0; i < ArraySize(toCheck); i++) {
      if(CalendarValueHistory(vals, tStart, tEnd, NULL, toCheck[i])) {
         for(int j = 0; j < ArraySize(vals); j++) {
            MqlCalendarEvent ev;
            if(CalendarEventById(vals[j].event_id, ev)) {
               if((InpHighImpact   && ev.importance == CALENDAR_IMPORTANCE_HIGH) ||
                  (InpMediumImpact && ev.importance == CALENDAR_IMPORTANCE_MODERATE)) {
                  g_TradingStatus = "PAUSED BY NEWS"; g_StatusColor = clrOrange;
                  lastNewsResult = true; return true;
               }
            }
         }
      }
   }
   if(g_TradingStatus == "PAUSED BY NEWS") {
      g_TradingStatus = "READY";
      g_StatusColor   = clrLime;
   }
   lastNewsResult = false; return false;
}

void CloseAllPositions(string reason, bool onlyProfit = false)
{
   for(int i = PositionsTotal()-1; i >= 0; i--) {
      ulong t = PositionGetTicket(i);
      if(PositionSelectByTicket(t) && PositionGetInteger(POSITION_MAGIC) == InpMagicNumber) {
         double netProfit = PositionGetDouble(POSITION_PROFIT)
                          + PositionGetDouble(POSITION_SWAP);
         if(onlyProfit && netProfit <= 0) continue;
         g_trade.PositionClose(t);
      }
   }
   if(!onlyProfit) {
      for(int i = OrdersTotal()-1; i >= 0; i--) {
         ulong t = OrderGetTicket(i);
         if(OrderSelect(t) && OrderGetInteger(ORDER_MAGIC) == InpMagicNumber)
            g_trade.OrderDelete(t);
      }
   }
   Print("[DLZ EA] Status: ", reason, (onlyProfit ? " (Closed only winners)" : ""));
}

bool CheckSessionAndExit()
{
   MqlDateTime dt; TimeCurrent(dt);
   if(InpFridayExit && dt.day_of_week == 5 && dt.hour >= InpFridayExitHour) {
      if(PositionsTotal() > 0) CloseAllPositions("WEEKEND EXIT", true);
      g_TradingStatus = "WEEKEND CLOSED"; g_StatusColor = clrRed;
      return false;
   }
   if(InpDailyExit && dt.hour >= InpDailyExitHour) {
      if(PositionsTotal() > 0) CloseAllPositions("DAILY EXIT", true);
      g_TradingStatus = "SESSION CLOSED"; g_StatusColor = clrRed;
      return false;
   }
   if(g_TradingStatus == "SESSION CLOSED" || g_TradingStatus == "WEEKEND CLOSED") {
      g_TradingStatus = "READY"; g_StatusColor = clrLime;
   }
   return true;
}

//+------------------------------------------------------------------+
//| MODULE: FULL COCKPIT CONTROL PANEL FOR DLZ EA                    |
//+------------------------------------------------------------------+
class C_Commander {
private:
   bool   m_isLocked;
   string m_prefix;
   string m_info_prefix;

public:
   C_Commander() { m_isLocked = true; m_prefix = "DLZ_BTN_"; m_info_prefix = "DLZ_INFO_"; }

   void DrawPanel() {
      int startX = 150, startY = 30, btnW = 69, btnH = 25, gap = 2;

      // แถว 0: LOCK (กว้างเต็ม)
      string lockTxt = m_isLocked ? "LOCK" : "UNLOCK";
      color  lockBg  = m_isLocked ? clrDimGray : clrForestGreen;
      CreateBtn("LOCK", lockTxt, startX, startY, (btnW*2)+gap, btnH, lockBg);

      string btns[] = {"BUY","SELL","X_BUY","X_SELL","X_PR","X_LS","CLOSE","HALF","BE"};
      if(m_isLocked) {
         for(int i=0; i<ArraySize(btns); i++) ObjectDelete(0, m_prefix+btns[i]);
         DeleteAccountBox();
      } else {
         int r1=startY+btnH+gap, r2=r1+btnH+gap, r3=r2+btnH+gap, r4=r3+btnH+gap, r5=r4+btnH+gap;
         // แถว 1: BUY / SELL
         CreateBtn("BUY",    "BUY",      startX+btnW+gap-71, r1, btnW, btnH, clrSeaGreen);
         CreateBtn("SELL",   "SELL",     startX-71,          r1, btnW, btnH, clrCrimson);
         // แถว 2: ปิดฝั่ง
         CreateBtn("X_BUY",  "X BUYs",  startX+btnW+gap-71, r2, btnW, btnH, clrTeal);
         CreateBtn("X_SELL", "X SELLs", startX-71,          r2, btnW, btnH, clrFireBrick);
         // แถว 3: ปิดตามผลลัพธ์
         CreateBtn("X_PR",   "X PROFIT",startX+btnW+gap-71, r3, btnW, btnH, clrLimeGreen);
         CreateBtn("X_LS",   "X LOSS",  startX-71,          r3, btnW, btnH, clrOrangeRed);
         // แถว 4: ปิดทั้งหมด / ครึ่ง
         CreateBtn("CLOSE",  "CLOSE ALL",startX+btnW+gap-71, r4, btnW, btnH, clrRed);
         CreateBtn("HALF",   "1/2 CLOSE",startX-71,          r4, btnW, btnH, clrDarkOrange);
         // แถว 5: AUTO BE (กว้างเต็ม)
         CreateBtn("BE",     "AUTO BE",  startX, r5, (btnW*2)+gap, btnH, clrCornflowerBlue);
         UpdateAccountInfo();
      }
      ChartRedraw();
   }

   void UpdateAccountInfo() {
      if(m_isLocked) return;
      int startX = 150, startY = 30, btnW = 69, btnH = 25, gap = 2;
      int boxY  = startY + (btnH + gap) * 6;
      int boxW  = (btnW * 2) + gap;   // 140
      int txtX  = startX -140 ;         // anchor ชิดขวาภายในกล่อง (ANCHOR_RIGHT)

      CreateLabelBox("BG", startX, boxY, boxW, 145, C'15,15,15');

      double bal = AccountInfoDouble(ACCOUNT_BALANCE);
      double equ = AccountInfoDouble(ACCOUNT_EQUITY);
      double pro = AccountInfoDouble(ACCOUNT_PROFIT);
      double mar = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
      double dd  = (bal > 0) ? (bal - equ) / bal * 100.0 : 0.0;
      if(dd < 0) dd = 0;
      color plClr = (pro >= 0) ? clrLime : clrRed;

      CreateTxt("T1", "Time: "+TimeToString(TimeCurrent(),TIME_SECONDS), txtX, boxY+8,  clrSilver,    8);
      CreateTxt("T2", "Balance :  $"+DoubleToString(bal,2),              txtX, boxY+28, clrWhite,     9);
      CreateTxt("T3", "Equity  :  $"+DoubleToString(equ,2),              txtX, boxY+48, clrWhite,     9);
      CreateTxt("T4", "P/L Total: "+DoubleToString(pro,2),               txtX, boxY+70, plClr,       10);
      CreateTxt("T5", StringFormat("Drawdown: %.2f%%", dd),              txtX, boxY+90, (dd>5?clrRed:clrSilver), 9);
      CreateTxt("T6", StringFormat("Margin  : %.0f%%", mar),             txtX, boxY+110,(mar<200?clrRed:clrLime),9);
      CreateTxt("T7", "Next Lot: "+DoubleToString(InpLot,2),             txtX, boxY+130,clrCyan,      9);
   }

   void ProcessClick(string name) {
      if(name == m_prefix+"LOCK") { m_isLocked = !m_isLocked; DrawPanel(); return; }
      if(m_isLocked) return;

      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double tpG = USDtoPriceGap(InpTP_USD);

      if(name == m_prefix+"BUY") {
         double slG = CalcSLGap(ask, true);
         double sl=ask-slG, tp=ask+tpG;
         if(g_trade.Buy(InpLot,_Symbol,ask,sl,tp,"Manual"))
            LogTradeOpen(g_trade.ResultOrder(),"MANUAL_BUY",ask);
      }
      if(name == m_prefix+"SELL") {
         double slG = CalcSLGap(bid, false);
         double sl=bid+slG, tp=bid-tpG;
         if(g_trade.Sell(InpLot,_Symbol,bid,sl,tp,"Manual"))
            LogTradeOpen(g_trade.ResultOrder(),"MANUAL_SELL",bid);
      }
      if(name == m_prefix+"X_BUY")  CloseByDir(POSITION_TYPE_BUY);
      if(name == m_prefix+"X_SELL") CloseByDir(POSITION_TYPE_SELL);
      if(name == m_prefix+"X_PR")   CloseByPerf(true);
      if(name == m_prefix+"X_LS")   CloseByPerf(false);
      if(name == m_prefix+"CLOSE")  CloseAllPositions("MANUAL_ALL");
      if(name == m_prefix+"HALF")   CloseHalfAll();
      if(name == m_prefix+"BE")     CheckBreakEven();
   }

private:
   void CreateBtn(string id, string txt, int x, int y, int w, int h, color bg) {
      string n = m_prefix+id;
      if(ObjectFind(0,n) < 0) ObjectCreate(0,n,OBJ_BUTTON,0,0,0);
      ObjectSetInteger(0,n,OBJPROP_CORNER,    CORNER_RIGHT_UPPER);
      ObjectSetInteger(0,n,OBJPROP_XDISTANCE, x); ObjectSetInteger(0,n,OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0,n,OBJPROP_XSIZE,     w); ObjectSetInteger(0,n,OBJPROP_YSIZE,     h);
      ObjectSetInteger(0,n,OBJPROP_BGCOLOR,   bg); ObjectSetString( 0,n,OBJPROP_TEXT,     txt);
      ObjectSetInteger(0,n,OBJPROP_COLOR,     clrWhite);
      ObjectSetInteger(0,n,OBJPROP_FONTSIZE,  8);
      ObjectSetInteger(0,n,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,n,OBJPROP_STATE,     false);
   }

   void CreateLabelBox(string id, int x, int y, int w, int h, color bg) {
      string n = m_info_prefix+id;
      if(ObjectFind(0,n) < 0) ObjectCreate(0,n,OBJ_RECTANGLE_LABEL,0,0,0);
      ObjectSetInteger(0,n,OBJPROP_CORNER,    CORNER_RIGHT_UPPER);
      ObjectSetInteger(0,n,OBJPROP_XDISTANCE, x); ObjectSetInteger(0,n,OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0,n,OBJPROP_XSIZE,     w); ObjectSetInteger(0,n,OBJPROP_YSIZE,     h);
      ObjectSetInteger(0,n,OBJPROP_BGCOLOR,   bg);
      ObjectSetInteger(0,n,OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0,n,OBJPROP_COLOR,     C'50,50,50');
      ObjectSetInteger(0,n,OBJPROP_BACK,      false);
      ObjectSetInteger(0,n,OBJPROP_SELECTABLE,false);
   }

   void CreateTxt(string id, string txt, int x, int y, color clr, int fs) {
      string n = m_info_prefix+id;
      if(ObjectFind(0,n) < 0) ObjectCreate(0,n,OBJ_LABEL,0,0,0);
      ObjectSetInteger(0,n,OBJPROP_CORNER,    CORNER_RIGHT_UPPER);
      ObjectSetInteger(0,n,OBJPROP_ANCHOR,    ANCHOR_RIGHT_UPPER);
      ObjectSetInteger(0,n,OBJPROP_XDISTANCE, x); ObjectSetInteger(0,n,OBJPROP_YDISTANCE, y);
      ObjectSetString( 0,n,OBJPROP_TEXT,      txt);
      ObjectSetInteger(0,n,OBJPROP_COLOR,     clr);
      ObjectSetString( 0,n,OBJPROP_FONT,      "Consolas");
      ObjectSetInteger(0,n,OBJPROP_FONTSIZE,  fs);
      ObjectSetInteger(0,n,OBJPROP_SELECTABLE,false);
   }

   void DeleteAccountBox() {
      ObjectsDeleteAll(0, m_info_prefix);
   }

   void CloseByDir(ENUM_POSITION_TYPE type) {
      for(int i=PositionsTotal()-1; i>=0; i--) {
         ulong t=PositionGetTicket(i);
         if(PositionSelectByTicket(t) &&
            PositionGetInteger(POSITION_MAGIC)==InpMagicNumber &&
            PositionGetString(POSITION_SYMBOL)==_Symbol &&
            (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==type)
            g_trade.PositionClose(t);
      }
   }

   void CloseByPerf(bool profitOnly) {
      for(int i=PositionsTotal()-1; i>=0; i--) {
         ulong t=PositionGetTicket(i);
         if(PositionSelectByTicket(t) &&
            PositionGetInteger(POSITION_MAGIC)==InpMagicNumber &&
            PositionGetString(POSITION_SYMBOL)==_Symbol) {
            double pnl=PositionGetDouble(POSITION_PROFIT);
            if((profitOnly && pnl>0) || (!profitOnly && pnl<0))
               g_trade.PositionClose(t);
         }
      }
   }

   void CloseHalfAll() {
      for(int i=PositionsTotal()-1; i>=0; i--) {
         ulong t=PositionGetTicket(i);
         if(PositionSelectByTicket(t) &&
            PositionGetInteger(POSITION_MAGIC)==InpMagicNumber &&
            PositionGetString(POSITION_SYMBOL)==_Symbol) {
            double vol  = PositionGetDouble(POSITION_VOLUME);
            double minV = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
            double half = NormalizeDouble(vol/2.0,2);
            if(half>=minV) g_trade.PositionClosePartial(t,half);
         }
      }
   }
};

C_Commander Commander;

//+------------------------------------------------------------------+
//|  M15 Candle Visual                                               |
//+------------------------------------------------------------------+
#define M15CV_PREFIX "M15CV_"

class CM15Candle {
public:
   string obj_body, obj_wu, obj_wl, obj_tro, obj_fibo;
   void Create(int idx) {
      string base = M15CV_PREFIX + IntegerToString(idx);
      obj_body = base+"_b"; obj_wu = base+"_wu";
      obj_wl   = base+"_wl"; obj_tro = base+"_tro";
      obj_fibo = base+"_f";
   }
   void Draw(datetime t1, int width_sec, double o, double h, double l, double c, bool is_latest) {
      datetime t2   = t1 + width_sec;
      datetime tmid = t1 + (width_sec / 2);
      color bcol = (c >= o) ? InpM15CV_Bull : InpM15CV_Bear;
      // body
      ObjectCreate(0, obj_body, OBJ_RECTANGLE, 0, t1, o, t2, c);
      ObjectSetInteger(0, obj_body, OBJPROP_COLOR,      (long)bcol);
      ObjectSetInteger(0, obj_body, OBJPROP_FILL,       true);
      ObjectSetInteger(0, obj_body, OBJPROP_WIDTH,      1);
      ObjectSetInteger(0, obj_body, OBJPROP_SELECTABLE, false);
      // wicks
      double bh = MathMax(o,c), bl = MathMin(o,c);
      ObjectCreate(0, obj_wu, OBJ_TREND, 0, tmid, h, tmid, bh);
      ObjectSetInteger(0, obj_wu, OBJPROP_COLOR, clrGray);
      ObjectCreate(0, obj_wl, OBJ_TREND, 0, tmid, l, tmid, bl);
      ObjectSetInteger(0, obj_wl, OBJPROP_COLOR, clrGray);
      // open trace line on latest bar
      if(is_latest) {
         ObjectCreate(0, obj_tro, OBJ_TREND, 0, TimeCurrent(), o, t1, o);
         ObjectSetInteger(0, obj_tro, OBJPROP_COLOR,    clrDimGray);
         ObjectSetInteger(0, obj_tro, OBJPROP_STYLE,    STYLE_DOT);
         ObjectSetInteger(0, obj_tro, OBJPROP_RAY_LEFT, true);
      } else ObjectDelete(0, obj_tro);
   }
   void DrawFibo(datetime t1, int width_sec, double h, double l, bool bearish) {
      datetime t2 = t1 + width_sec;
      ObjectDelete(0, obj_fibo);
      if(ObjectCreate(0, obj_fibo, OBJ_FIBO, 0, t1, bearish ? h : l, t2, bearish ? l : h)) {
         color fcol = bearish ? InpM15CV_Bear : InpM15CV_Bull;
         ObjectSetInteger(0, obj_fibo, OBJPROP_COLOR,     (long)fcol);
         ObjectSetInteger(0, obj_fibo, OBJPROP_WIDTH,     1);
         ObjectSetInteger(0, obj_fibo, OBJPROP_RAY_RIGHT, false);
         ObjectSetInteger(0, obj_fibo, OBJPROP_BACK,      true);
         ObjectSetInteger(0, obj_fibo, OBJPROP_SELECTABLE,false);
         ObjectSetInteger(0, obj_fibo, OBJPROP_LEVELS,    11);
         double lv[] = {2.618, 1.618, 1.0, 0.618, 0.5, 0.382, 0.236, 0.0, -0.618, -1.0, -1.618};
         string lt[] = {"261.8","161.8","100.0","61.8","50.0","38.2","23.6","0.0","-61.8","-100.0","-161.8"};
         for(int i = 0; i < 11; i++) {
            ObjectSetDouble(0, obj_fibo, OBJPROP_LEVELVALUE, i, lv[i]);
            ObjectSetString(0, obj_fibo, OBJPROP_LEVELTEXT,  i, lt[i]);
         }
      }
   }
   void Delete() { ObjectDelete(0,obj_body); ObjectDelete(0,obj_wu); ObjectDelete(0,obj_wl); ObjectDelete(0,obj_tro); ObjectDelete(0,obj_fibo); }
};

CM15Candle g_m15cv_candles[];
bool       g_m15cv_init = false;

void InitM15Candles() {
   ArrayResize(g_m15cv_candles, InpM15CV_Count);
   for(int i = 0; i < InpM15CV_Count; i++) g_m15cv_candles[i].Create(i);
   g_m15cv_init = true;
}

void DrawM15Candles() {
   if(!InpM15CV_Show || !g_m15cv_init) return;
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, PERIOD_M15, 0, InpM15CV_Count + 1, rates) < InpM15CV_Count) return;

   int period_sec  = PeriodSeconds(_Period);
   int width_sec   = period_sec * InpM15CV_Width * 2;
   int spacing_sec = period_sec * 2;
   datetime start  = TimeCurrent() + (InpM15CV_Offset * period_sec);

   double max_h = 0;
   for(int i = InpM15CV_Count - 1; i >= 0; i--) {
      int pos_idx    = (InpM15CV_Count - 1) - i;
      datetime dtime = start + (pos_idx * (width_sec + spacing_sec));
      g_m15cv_candles[i].Draw(dtime, width_sec,
                               rates[i].open, rates[i].high, rates[i].low, rates[i].close,
                               (i == 0));
      if(i == 1)
         g_m15cv_candles[i].DrawFibo(dtime, width_sec, rates[i].high, rates[i].low,
                                     rates[i].close < rates[i].open);
      if(rates[i].high > max_h) max_h = rates[i].high;
   }

   // label
   string lbl = M15CV_PREFIX"LBL";
   datetime lbl_time = start;
   bool bullish = (rates[0].close >= rates[0].open);
   ObjectCreate(0, lbl, OBJ_TEXT, 0, lbl_time, max_h);
   ObjectSetString (0, lbl, OBJPROP_TEXT,     "M15: " + (bullish ? "BULLISH" : "BEARISH"));
   ObjectSetInteger(0, lbl, OBJPROP_COLOR,    bullish ? clrGreen : clrRed);
   ObjectSetInteger(0, lbl, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, lbl, OBJPROP_ANCHOR,   ANCHOR_BOTTOM);

   // progress label — แสดง elapsed M1 bars ในแท่ง M15 ปัจจุบัน "5/15"
   {
      int    m1Per     = PeriodSeconds(PERIOD_M1);
      int    m15Per    = PeriodSeconds(PERIOD_M15);
      int    totalBars = m15Per / m1Per;  // = 15
      datetime m15Open = iTime(_Symbol, PERIOD_M15, 0);
      int    elapsed   = (int)((TimeCurrent() - m15Open) / m1Per) + 1;
      if(elapsed > totalBars) elapsed = totalBars;

      // วางกลางแท่ง M15 i=0 (แท่งขวาสุดที่วาด = pos_idx 0 → dtime ตำแหน่งซ้ายสุดของ box)
      // คำนวณเวลากลางแท่ง = dtime + half width
      datetime dt0     = start + ((InpM15CV_Count - 1) * (width_sec + spacing_sec));
      datetime dt_mid  = dt0 + width_sec / 2;
      double   mid_y   = (rates[0].high + rates[0].low) * 0.5;
      color    progClr = bullish ? InpM15CV_Bull : InpM15CV_Bear;

      string progLbl = M15CV_PREFIX"PROG";
      if(ObjectFind(0, progLbl) < 0) ObjectCreate(0, progLbl, OBJ_TEXT, 0, dt_mid, mid_y);
      ObjectSetInteger(0, progLbl, OBJPROP_TIME,      0, dt_mid);
      ObjectSetDouble (0, progLbl, OBJPROP_PRICE,     0, mid_y);
      ObjectSetString (0, progLbl, OBJPROP_TEXT,      StringFormat("%d/%d", elapsed, totalBars));
      ObjectSetInteger(0, progLbl, OBJPROP_COLOR,     clrYellow);
      ObjectSetInteger(0, progLbl, OBJPROP_FONTSIZE,  7);
      ObjectSetString (0, progLbl, OBJPROP_FONT,      "Arial Bold");
      ObjectSetInteger(0, progLbl, OBJPROP_ANCHOR,    ANCHOR_CENTER);
      ObjectSetInteger(0, progLbl, OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0, progLbl, OBJPROP_BACK,      false);
   }
}

void CleanupM15Candles() {
   for(int i = 0; i < ArraySize(g_m15cv_candles); i++) g_m15cv_candles[i].Delete();
   ObjectDelete(0, M15CV_PREFIX"LBL");
   ObjectDelete(0, M15CV_PREFIX"PROG");
}

//+------------------------------------------------------------------+
//|  OnInit                                                          |
//+------------------------------------------------------------------+
int OnInit()
{
   ArrayResize(g_zones_htf, 0);
   ArrayResize(g_histHighs_htf, 0);
   ArrayResize(g_histLows_htf, 0);
   g_htfInitialized = false;
   InitM15Candles();

   ObjectsDeleteAll(0, OBJ_PREFIX);
   ObjectsDeleteAll(0, DASH_PREFIX); // ลบ Dashboard เก่าถ้ามี
   
   ArrayResize(g_zones,     0);
   ArrayResize(g_histHighs, 0);
   ArrayResize(g_histLows,  0);
   g_objCounter  = 0;
   g_lastBarTimeProcessed = 0;
   g_isLive = false;

   // Reset OFA globals
   ArrayResize(gdx_swings,  0); gdx_swingCount=0; gdx_LastConfirmedCount=0;  gdx_LastBarTime=0;
   ArrayResize(gdx_swings2, 0); gdx_swingCount2=0; gdx_LastConfirmedCount2=0; gdx_LastBarTime2=0;
   ObjectsDeleteAll(0, "GDEA_OFA_");
   ObjectsDeleteAll(0, "GDEA_OFA2_");

   // Reset Hull globals
   ArrayResize(g_hullValM1,  0); ArrayResize(g_hullTrdM1,  0); g_hullInitM1  = false; g_hullBarM1  = 0; g_hullDirM1  = 0;
   ArrayResize(g_hullValM15, 0); ArrayResize(g_hullTrdM15, 0); g_hullInitM15 = false; g_hullBarM15 = 0; g_hullDirM15 = 0;

   // ATR handle
   if(g_atrHandle != INVALID_HANDLE) IndicatorRelease(g_atrHandle);
   g_atrHandle = iATR(_Symbol, PERIOD_M1, 14);

   // ATR D1 handle
   if(g_atr_d1_handle != INVALID_HANDLE) IndicatorRelease(g_atr_d1_handle);
   g_atr_d1_handle = iATR(_Symbol, PERIOD_D1, InpATRLevelsPeriod);
   if(g_atr_d1_handle == INVALID_HANDLE) Print("ATR D1 Handle Failed!");

   // EMA — สร้าง iMA handles (วาดด้วย OBJ_TREND ใน DrawEMALines)
   {
      int emaPeriods[2] = {200,720};
      ObjectsDeleteAll(0, "DLZ_EMA");
      g_emaLastBar = 0;
      if(InpShowEMA)
      {
         for(int i = 0; i < 2; i++)
         {
            if(g_emaHandle[i] != INVALID_HANDLE) { IndicatorRelease(g_emaHandle[i]); g_emaHandle[i] = INVALID_HANDLE; }
            g_emaHandle[i] = iMA(_Symbol, PERIOD_M1, emaPeriods[i], 0, MODE_EMA, PRICE_CLOSE);
            if(g_emaHandle[i] == INVALID_HANDLE) Print("EMA Handle Failed! period=", emaPeriods[i]);
         }
      }
   }

   ObjectsDeleteAll(0, "DLZ_HULLM1_");
   ObjectsDeleteAll(0, "DLZ_HULLM15_");
   
//   // --- [REPLACE] Dashboard Initialization in OnInit ---
//   if(InpShowDash) {
//      int y = InpDashY;
//      CreateDashLabel(DASH_PREFIX+"TITLE",    y,      "", clrWhite, 10, true);
//      CreateDashLabel(DASH_PREFIX+"LINE1",    y+15,   "________________________________________", clrGray);
//      CreateDashLabel(DASH_PREFIX+"STRUCT",   y+35,   "", clrWhite);
//      CreateDashLabel(DASH_PREFIX+"MOMENTUM", y+55,   "", clrSilver);
//      CreateDashLabel(DASH_PREFIX+"INSIGHT",  y+75,   "", clrYellow);
//      CreateDashLabel(DASH_PREFIX+"LINE2",    y+90,   "________________________________________", clrGray);
//      CreateDashLabel(DASH_PREFIX+"RADAR_H",  y+110,  "", InpBearColor);
//      CreateDashLabel(DASH_PREFIX+"RADAR_L",  y+130,  "", InpBullColor);
//      CreateDashLabel(DASH_PREFIX+"STATUS",   y+155,  "", clrWhite, 10, true);
//   }
//   
//   // --- [ADD] Smart Trade Plan Labels in OnInit ---
//   if(InpShowDash) {
//      int y_start = InpDashY + 180; // ต่อท้ายจาก STATUS เดิม
//      CreateDashLabel(DASH_PREFIX+"PLAN_HDR", y_start,      "[ SMART TRADE PLAN ]", clrAqua, 10, true);
//      CreateDashLabel(DASH_PREFIX+"ACTION",   y_start + 20, "Action: Scanning Structure...", clrWhite);
//      CreateDashLabel(DASH_PREFIX+"POI",      y_start + 40, "Entry POI: ---", clrSilver);
//      CreateDashLabel(DASH_PREFIX+"TARGET",   y_start + 60, "Next Target: ---", clrDodgerBlue);
//      CreateDashLabel(DASH_PREFIX+"CONF",     y_start + 80, "Confluence: ---", clrYellow);
//   }
// --- Dashboard Initialization (Layout: WN → Market Context → EA Status) ---
if(InpShowDash) {
      // ─── Panel 1: WHAT'S NEXT (บนสุด — Decision Making) ───
      string bgWN = DASH_PREFIX+"BG_WN";
      ObjectDelete(0, bgWN);
      ObjectCreate(0, bgWN, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, bgWN, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
      ObjectSetInteger(0, bgWN, OBJPROP_XDISTANCE, InpDashX);
      ObjectSetInteger(0, bgWN, OBJPROP_YDISTANCE, InpDashY);
      ObjectSetInteger(0, bgWN, OBJPROP_XSIZE,     390);
      ObjectSetInteger(0, bgWN, OBJPROP_YSIZE,     165);
      ObjectSetInteger(0, bgWN, OBJPROP_BGCOLOR,   C'10,10,25');
      ObjectSetInteger(0, bgWN, OBJPROP_FILL,      true);
      ObjectSetInteger(0, bgWN, OBJPROP_BACK,      false);
      ObjectSetInteger(0, bgWN, OBJPROP_SELECTABLE,false);

      int yw = InpDashY + 4;
      CreateDashLabel(DASH_PREFIX+"WN_HDR",      yw,      "── STRATEGIC WHAT'S NEXT ──", clrAqua,   9, true);
      CreateDashLabel(DASH_PREFIX+"WN_SELL_ROW", yw+14,   "SELL | --",                   clrSilver, 9);
      CreateDashLabel(DASH_PREFIX+"WN_BUY_ROW",  yw+28,   "BUY  | --",                   clrSilver, 9);
      CreateDashLabel(DASH_PREFIX+"WN_LINE",     yw+41,   "────────────────────────────────────────", clrGray);
      CreateDashLabel(DASH_PREFIX+"WN_SELL_STS", yw+51,   "SELL Status: --",              clrSilver, 9);
      CreateDashLabel(DASH_PREFIX+"WN_BUY_STS",  yw+65,   "BUY  Status: --",              clrSilver, 9);
      CreateDashLabel(DASH_PREFIX+"WN_LINE2",    yw+78,   "────────────────────────────────────────", clrGray);
      CreateDashLabel(DASH_PREFIX+"WN_TARGET",   yw+88,   "Target: --",                   clrAqua,   9);
      CreateDashLabel(DASH_PREFIX+"WN_RR",       yw+102,  "Est. R:R  --",                 clrSilver, 9);
      CreateDashLabel(DASH_PREFIX+"WN_SPREAD",   yw+116,  "Spread: --",                   clrSilver, 9);
      CreateDashLabel(DASH_PREFIX+"WN_PROB_BAR", yw+130,  "Confluence: --",               clrSilver, 9);

      // ─── Panel 2: MARKET CONTEXT (กลาง — Monitoring) ───
      int ctxY = InpDashY + 173;
      int y    = ctxY;

      string bgName = DASH_PREFIX+"BG";
      ObjectDelete(0, bgName);
      ObjectCreate(0, bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, bgName, OBJPROP_CORNER,     CORNER_LEFT_UPPER);
      ObjectSetInteger(0, bgName, OBJPROP_XDISTANCE,  InpDashX);
      ObjectSetInteger(0, bgName, OBJPROP_YDISTANCE,  ctxY);
      ObjectSetInteger(0, bgName, OBJPROP_XSIZE,      390);
      ObjectSetInteger(0, bgName, OBJPROP_YSIZE,      232);
      ObjectSetInteger(0, bgName, OBJPROP_BGCOLOR,    clrBlack);
      ObjectSetInteger(0, bgName, OBJPROP_FILL,       true);
      ObjectSetInteger(0, bgName, OBJPROP_BACK,       false);
      ObjectSetInteger(0, bgName, OBJPROP_SELECTABLE, false);

      CreateDashLabel(DASH_PREFIX+"TITLE",      y +  5, "", clrWhite,  9, true);
      CreateDashLabel(DASH_PREFIX+"EMA_STATUS", y + 17, "EMA: --", clrSilver, 9);
      CreateDashLabel(DASH_PREFIX+"LINE1",      y + 29, "────────────────────────────────────────", clrGray);
      CreateDashLabel(DASH_PREFIX+"STRUCT",     y + 39, "", clrWhite,  9);
      CreateDashLabel(DASH_PREFIX+"HULL_M1",    y + 53, "Hull: ...",   clrSilver, 9);
      CreateDashLabel(DASH_PREFIX+"MOMENTUM",   y + 67, "", clrSilver, 9);
      CreateDashLabel(DASH_PREFIX+"INSIGHT",    y + 81, "", clrYellow, 9);
      CreateDashLabel(DASH_PREFIX+"LINE2",      y + 93, "────────────────────────────────────────", clrGray);
      CreateDashLabel(DASH_PREFIX+"RADAR_H",    y +103, "", clrSilver, 9);
      CreateDashLabel(DASH_PREFIX+"STATUS",     y +117, "", clrWhite,  9, true);
      CreateDashLabel(DASH_PREFIX+"LINE3",      y +129, "────────────────────────────────────────", clrGray);
      CreateDashLabel(DASH_PREFIX+"ACTION",     y +139, "", clrWhite,  9);
      CreateDashLabel(DASH_PREFIX+"CONF",       y +153, "", clrYellow, 9);
      CreateDashLabel(DASH_PREFIX+"LINE4",      y +165, "────────────────────────────────────────", clrGray);
      CreateDashLabel(DASH_PREFIX+"CLUSTER",    y +175, "Scanning...", clrSilver, 9);
      CreateDashLabel(DASH_PREFIX+"SWEPT",      y +189, "Swept: -",    clrSilver, 9);
      CreateDashLabel(DASH_PREFIX+"DECISION",   y +203, "◉ SCANNING",  clrSilver, 9, true);

      // ─── Panel 3: EA ORDER STATUS (ล่าง — Monitoring) ───
      string bgEA = DASH_PREFIX+"BG_EA";
      ObjectDelete(0, bgEA);
      ObjectCreate(0, bgEA, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, bgEA, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
      ObjectSetInteger(0, bgEA, OBJPROP_XDISTANCE, InpDashX);
      ObjectSetInteger(0, bgEA, OBJPROP_YDISTANCE, InpDashY + 401);
      ObjectSetInteger(0, bgEA, OBJPROP_XSIZE,     390);
      ObjectSetInteger(0, bgEA, OBJPROP_YSIZE,     240);
      ObjectSetInteger(0, bgEA, OBJPROP_BGCOLOR,   C'10,20,10');
      ObjectSetInteger(0, bgEA, OBJPROP_FILL,      true);
      ObjectSetInteger(0, bgEA, OBJPROP_BACK,      false);
      ObjectSetInteger(0, bgEA, OBJPROP_SELECTABLE,false);

      int ye = InpDashY + 405;
      CreateDashLabel(DASH_PREFIX+"EA_HDR",      ye,     "── EA ORDER STATUS ──",    clrAqua,   9, true);
      CreateDashLabel(DASH_PREFIX+"EA_BIAS",     ye+14,  "Master Bias: --",          clrSilver, 9, true);
      CreateDashLabel(DASH_PREFIX+"DXY_TREND",   ye+28,  "DXY Monitor: --",          clrSilver, 9, true);
      CreateDashLabel(DASH_PREFIX+"EA_SESSION",  ye+44,  "Session: --",              clrSilver, 9);
      CreateDashLabel(DASH_PREFIX+"EA_STREAK",   ye+58,  "Streak: EQL 0 | EQH 0",   clrSilver, 9);
      CreateDashLabel(DASH_PREFIX+"EA_LINE",     ye+70,  "────────────────────────────────────────", clrGray);
      CreateDashLabel(DASH_PREFIX+"EA_BUY",      ye+80,  "BUY  Open: 0/2",           clrSilver, 9);
      CreateDashLabel(DASH_PREFIX+"EA_SELL",     ye+94,  "SELL Open: 0/2",           clrSilver, 9);
      CreateDashLabel(DASH_PREFIX+"EA_LINE2",    ye+106, "────────────────────────────────────────", clrGray);
      CreateDashLabel(DASH_PREFIX+"EA_LASTBUY",  ye+116, "Last BUY : --",            clrSilver, 9);
      CreateDashLabel(DASH_PREFIX+"EA_LASTSELL", ye+130, "Last SELL: --",            clrSilver, 9);
      CreateDashLabel(DASH_PREFIX+"EA_PNL",      ye+144, "Total P/L : --",           clrSilver, 9);
      CreateDashLabel(DASH_PREFIX+"EA_PENDING",  ye+158, "Pending: none",             clrSilver, 9);
      CreateDashLabel(DASH_PREFIX+"EA_CRITICAL", ye+172, " ",                         clrSilver, 9);
      CreateDashLabel(DASH_PREFIX+"EA_STATUS",   ye+186, "◉ EA READY",               clrLime,   9, true);
      CreateDashLabel(DASH_PREFIX+"EA_M1SLOPE",  ye+200, "M1 Slope: --",   clrSilver, 8);
      CreateDashLabel(DASH_PREFIX+"EA_HULL_GAP", ye+214, "Hull M1 Gap: --", clrSilver, 8);
   }

   // --- EA Init ---
   g_trade.SetExpertMagicNumber(InpMagicNumber);
   g_trade.SetDeviationInPoints(10);
   g_eql_streak  = 0;
   g_eqh_streak  = 0;
   g_eqlPendingCount = 0;
   ArrayResize(g_eqlPendingList, 0);
   g_eqhPendingCount = 0;
   ArrayResize(g_eqhPendingList, 0);
   g_eaStartTime = TimeCurrent(); // จับเวลาเริ่มต้น EA สำหรับ Notification Flood Guard
   Commander.DrawPanel();
   NR_Init();
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//|  OnDeinit                                                        |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, OBJ_PREFIX);
   ObjectsDeleteAll(0, DASH_PREFIX);
   ObjectsDeleteAll(0, "DLZ_BTN_");
   ObjectsDeleteAll(0, "DLZ_INFO_");
   ObjectsDeleteAll(0, "GDEA_OFA_");
   ObjectsDeleteAll(0, "GDEA_OFA2_");
   
   // ---> เพิ่มบรรทัดนี้ เพื่อกวาดล้าง Object ของ HTF <---
   ObjectsDeleteAll(0, "HTF_");

   CleanupM15Candles();
   // Hull cleanup
   ObjectsDeleteAll(0, "DLZ_HULLM1_");
   ObjectsDeleteAll(0, "DLZ_HULLM15_");
   ArrayFree(g_hullValM1);  ArrayFree(g_hullTrdM1);
   ArrayFree(g_hullValM15); ArrayFree(g_hullTrdM15);
   
   // เพิ่มการเคลียร์ Array
   ArrayFree(g_zones);
   ArrayFree(g_histHighs);
   ArrayFree(g_histLows);
   ArrayFree(gdx_swings);
   ArrayFree(gdx_swings2);
   
   ArrayFree(g_zones_htf);
   ArrayFree(g_histHighs_htf);
   ArrayFree(g_histLows_htf);
   
   // เพิ่มใน OnDeinit เดิมที่มีอยู่แล้ว
   ObjectsDeleteAll(0, DASH_PREFIX+"BG_WN");
   ObjectsDeleteAll(0, DASH_PREFIX+"WN_");
   ObjectDelete(0, DASH_PREFIX+"POI_DOT");
   ObjectDelete(0, DASH_PREFIX+"POI_TXT");
   ObjectDelete(0, DASH_PREFIX+"TGT_DOT");
   ObjectDelete(0, DASH_PREFIX+"TGT_TXT");

   // ATR D1 cleanup
   if(g_atr_d1_handle != INVALID_HANDLE) { IndicatorRelease(g_atr_d1_handle); g_atr_d1_handle = INVALID_HANDLE; }
   ObjectsDeleteAll(0, "DLZ_ATR_");

   // Arrow profit label cleanup
   ObjectDelete(0, "DLZ_ArrowProfitLabel");
   ObjectDelete(0, "DLZ_ArrowProfitLabel2");

   // EMA cleanup
   ObjectsDeleteAll(0, "DLZ_EMA");
   for(int i = 0; i < 4; i++)
   {
      if(g_emaHandle[i] != INVALID_HANDLE) { IndicatorRelease(g_emaHandle[i]); g_emaHandle[i] = INVALID_HANDLE; }
   }
   NR_Deinit();
}

//+------------------------------------------------------------------+
//| [REPLACE] สร้างกล่องและเส้น Liquidity สำหรับ Timeframe ใหญ่ (HTF) |
//+------------------------------------------------------------------+
void CreateZoneHTF(bool isHigh, double topPrice, double bottomPrice, datetime leftTime, datetime rightTime, double totalVol, datetime eventTime=0)
{
   color zClr = isHigh ? InpHTFBearColor : InpHTFBullColor;
   
   // บังคับให้กล่องมีความหนาอย่างน้อย 20 Points เพื่อไม่ให้กล่องบางจนล่องหน
   if(MathAbs(topPrice - bottomPrice) < 20 * _Point) {
      topPrice += 10 * _Point;
      bottomPrice -= 10 * _Point;
   }
   double mid = (topPrice + bottomPrice) * 0.5;

   LiquidityZone z;
   z.boxName       = ObjName("HTF_BOX_");
   z.midName       = ObjName("HTF_MID_");  // <--- เปิดใช้งานชื่อ Midline
   z.lblName       = ObjName("HTF_LBL_");
   z.b1Name = ""; z.b2Name = ""; z.v1Name = ""; z.v2Name = ""; // จุดวงกลมยังปิดไว้เพื่อไม่ให้รก
   z.sweepLevel    = isHigh ? topPrice : bottomPrice;
   z.totalVol      = totalVol;
   z.isHigh        = isHigh;
   z.isSwept       = false;

   //--- วาดกล่อง HTF พื้นหลัง
   ObjectCreate(0, z.boxName, OBJ_RECTANGLE, 0, leftTime, topPrice, rightTime, bottomPrice);
   ObjectSetInteger(0, z.boxName, OBJPROP_FILL,        true);
   ObjectSetInteger(0, z.boxName, OBJPROP_BGCOLOR,     AlphaColor(zClr, InpHTFTransp));
   ObjectSetInteger(0, z.boxName, OBJPROP_COLOR,       zClr);
   ObjectSetInteger(0, z.boxName, OBJPROP_WIDTH,       1);
   ObjectSetInteger(0, z.boxName, OBJPROP_BACK,        true);
   ObjectSetInteger(0, z.boxName, OBJPROP_SELECTABLE,  false);

   //--- [NEW] วาดเส้นกลาง (Midline) เป็นเส้นทึบหนาๆ ให้เห็นชัดเจน
   ObjectCreate(0, z.midName, OBJ_TREND, 0, leftTime, mid, rightTime, mid);
   ObjectSetInteger(0, z.midName, OBJPROP_COLOR,      zClr);
   ObjectSetInteger(0, z.midName, OBJPROP_STYLE,      STYLE_SOLID); // ใช้เส้นทึบ
   ObjectSetInteger(0, z.midName, OBJPROP_WIDTH,      2);           // ความหนาระดับ 2
   ObjectSetInteger(0, z.midName, OBJPROP_RAY_RIGHT,  false);
   ObjectSetInteger(0, z.midName, OBJPROP_SELECTABLE, false);

   //--- Label ระบุว่าเป็นของ HTF
   string tfName = StringSubstr(EnumToString(InpHTF), 7);
   ObjectCreate(0, z.lblName, OBJ_TEXT, 0, rightTime, mid);
   ObjectSetInteger(0, z.lblName, OBJPROP_COLOR,     zClr);
   ObjectSetInteger(0, z.lblName, OBJPROP_FONTSIZE,  9);
   ObjectSetInteger(0, z.lblName, OBJPROP_ANCHOR,    ANCHOR_LEFT);
   ObjectSetString (0, z.lblName, OBJPROP_TEXT,      "  [" + tfName + "] " + (isHigh ? "EQH" : "EQL"));
   ObjectSetInteger(0, z.lblName, OBJPROP_SELECTABLE,false);

   int sz = ArraySize(g_zones_htf);
   ArrayResize(g_zones_htf, sz + 1);
   g_zones_htf[sz] = z;
   
   NotifyNewZoneHTF(z, eventTime > 0 ? eventTime : TimeCurrent());
}
//+------------------------------------------------------------------+
//| [NEW] ประมวลผลหา EQH/EQL จากข้อมูลของ HTF                        |
//+------------------------------------------------------------------+
void ProcessHTFConfirmBar(const double &h[], const double &l[], const datetime &t[], const long &v[], int confirmBarNS, int total)
{
   int pivotBarNS = confirmBarNS - InpRightLen;
   if(pivotBarNS < InpLeftLen) return;

   // ---- HTF EQH ----
   if(IsPivotHigh(h, pivotBarNS, InpLeftLen, InpRightLen, total)) {
      double pH = h[pivotBarNS];
      for(int i = 0; i < ArraySize(g_histHighs_htf); i++) {
         if(MathAbs(pH - g_histHighs_htf[i].price) / g_histHighs_htf[i].price * 100.0 <= InpThresholdPct) {
            double top = MathMax(pH, g_histHighs_htf[i].price);
            double bot = MathMin(pH, g_histHighs_htf[i].price);
            CreateZoneHTF(true, top, bot, g_histHighs_htf[i].barTime, t[confirmBarNS], (double)v[pivotBarNS] + g_histHighs_htf[i].vol, t[pivotBarNS]);
            break;
         }
      }
      PrependPivot(g_histHighs_htf, pH, t[pivotBarNS], (double)v[pivotBarNS], 20);
   }

   // ---- HTF EQL ----
   if(IsPivotLow(l, pivotBarNS, InpLeftLen, InpRightLen, total)) {
      double pL = l[pivotBarNS];
      for(int i = 0; i < ArraySize(g_histLows_htf); i++) {
         if(MathAbs(pL - g_histLows_htf[i].price) / g_histLows_htf[i].price * 100.0 <= InpThresholdPct) {
            double top = MathMax(pL, g_histLows_htf[i].price);
            double bot = MathMin(pL, g_histLows_htf[i].price);
            CreateZoneHTF(false, top, bot, g_histLows_htf[i].barTime, t[confirmBarNS], (double)v[pivotBarNS] + g_histLows_htf[i].vol, t[pivotBarNS]);
            break;
         }
      }
      PrependPivot(g_histLows_htf, pL, t[pivotBarNS], (double)v[pivotBarNS], 20);
   }
}

//+------------------------------------------------------------------+
//| [REPLACE] อัปเดตกล่อง HTF และเส้น Midline แบบ Real-time           |
//+------------------------------------------------------------------+
void UpdateHTFZones_SweepCheck(double current_high, double current_low, datetime current_time)
{
   for(int idx = ArraySize(g_zones_htf) - 1; idx >= 0; idx--) {
      if(g_zones_htf[idx].isSwept) continue;

      // ลากกล่อง HTF และเส้น Midline ให้ยาวมาถึงเวลาปัจจุบันของ M1
      ObjectSetInteger(0, g_zones_htf[idx].boxName, OBJPROP_TIME, 1, current_time);
      ObjectSetInteger(0, g_zones_htf[idx].lblName, OBJPROP_TIME, 0, current_time);
      
      // ลากเส้น Midline ตามเวลาปัจจุบัน
      if(g_zones_htf[idx].midName != "") {
         ObjectSetInteger(0, g_zones_htf[idx].midName, OBJPROP_TIME, 1, current_time);
      }

      // เช็คการถูกล้าง (Sweep) ด้วยไส้เทียนของ M1
      bool swept = g_zones_htf[idx].isHigh ? (current_high > g_zones_htf[idx].sweepLevel) : (current_low < g_zones_htf[idx].sweepLevel);
      if(swept) {
         
         NotifySweepHTF(g_zones_htf[idx], current_time);
         
         g_zones_htf[idx].isSwept = true;
         
         // ปรับสีกล่องให้เป็นสีเทา
         ObjectSetInteger(0, g_zones_htf[idx].boxName, OBJPROP_BGCOLOR, AlphaColor(clrDarkGray, 90));
         ObjectSetInteger(0, g_zones_htf[idx].boxName, OBJPROP_COLOR, clrDarkGray);
         
         // ปรับเส้น Midline ให้กลายเป็นสีเทาและเปลี่ยนเป็นเส้นประ (Dot) เมื่อถูกทะลุ
         if(g_zones_htf[idx].midName != "") {
            ObjectSetInteger(0, g_zones_htf[idx].midName, OBJPROP_COLOR, AlphaColor(clrDarkGray, 50));
            ObjectSetInteger(0, g_zones_htf[idx].midName, OBJPROP_STYLE, STYLE_DOT);
            ObjectSetInteger(0, g_zones_htf[idx].midName, OBJPROP_WIDTH, 1);
         }

         ObjectSetString (0, g_zones_htf[idx].lblName, OBJPROP_TEXT, "  Swept HTF");
         ObjectSetInteger(0, g_zones_htf[idx].lblName, OBJPROP_COLOR, clrDarkGray);
      }
   }
}
//+------------------------------------------------------------------+
//|  SMART NR/IB — Helper Functions                                 |
//+------------------------------------------------------------------+
color NR_MixToWhite(color c, int pct) {
   int r = (c >> 16) & 0xFF; r += (255 - r) * pct / 100;
   int g = (c >>  8) & 0xFF; g += (255 - g) * pct / 100;
   int b =  c        & 0xFF; b += (255 - b) * pct / 100;
   return (color)((r << 16) | (g << 8) | b);
}

ENUM_LINE_STYLE NR_LvlStyle() {
   if(InpNR_LvlStyleStr == "Solid")  return STYLE_SOLID;
   if(InpNR_LvlStyleStr == "Dashed") return STYLE_DASH;
   return STYLE_DOT;
}

double NR_RmaUpd(double prev, double src, int len) {
   return src / len + prev * (1.0 - 1.0 / len);
}
double NR_EmaUpd(double prev, double src, int len) {
   double a = 2.0 / (len + 1);
   return a * src + (1.0 - a) * prev;
}
double NR_TR(int i, const double &h[], const double &l[], const double &c[]) {
   if(i == 0) return h[i] - l[i];
   return MathMax(h[i] - l[i], MathMax(MathAbs(h[i] - c[i-1]), MathAbs(l[i] - c[i-1])));
}
double NR_HiArr(const double &a[], int i, int n) {
   int s = MathMax(0, i - n + 1); double m = a[s];
   for(int k = s + 1; k <= i; k++) if(a[k] > m) m = a[k];
   return m;
}
double NR_LoArr(const double &a[], int i, int n) {
   int s = MathMax(0, i - n + 1); double m = a[s];
   for(int k = s + 1; k <= i; k++) if(a[k] < m) m = a[k];
   return m;
}
double NR_RangeN(int n, int i, const double &h[], const double &l[]) {
   return NR_HiArr(h, i, n) - NR_LoArr(l, i, n);
}
bool NR_IsNR(int n, int lb, int i, const double &h[], const double &l[]) {
   if(i < 1) return false;
   int L = MathMax(lb, 1);
   double r = NR_RangeN(n, i, h, l), mn = 1e18;
   for(int k = 1; k <= L && i - k >= 0; k++) {
      double rk = NR_RangeN(n, i - k, h, l);
      if(rk < mn) mn = rk;
   }
   return r < mn;
}
double NR_RankTight(int n, int lb, int i, const double &h[], const double &l[]) {
   if(i < 1) return -1.0;
   int L = MathMax(lb, 1);
   double cnt = 0;
   for(int k = 0; k < L && i - k >= 0; k++) {
      double r_k    = NR_RangeN(n, i - k,     h, l);
      double r_prev = NR_RangeN(n, i - k - 1, h, l);
      if(i - k - 1 >= 0 && r_prev <= r_k) cnt++;
   }
   return cnt / (double)L;
}

void NR_DelPat(int idx) {
   if(idx < 0 || idx >= nr_patCnt) return;
   string id = nr_pats[idx].id;
   ObjectDelete(0, NR_OBJ_PFX + "box_" + id);
   ObjectDelete(0, NR_OBJ_PFX + "hiL_" + id);
   ObjectDelete(0, NR_OBJ_PFX + "loL_" + id);
   ObjectDelete(0, NR_OBJ_PFX + "tg_"  + id);
   ObjectDelete(0, NR_OBJ_PFX + "ex_"  + id);
   ObjectDelete(0, NR_OBJ_PFX + "ar_"  + id);
}

void NR_ObjText(string nm, datetime t, double y, string txt, color col, int fs, ENUM_ANCHOR_POINT anch) {
   ObjectDelete(0, nm);
   ObjectCreate(0, nm, OBJ_TEXT, 0, t, y);
   ObjectSetString(0,  nm, OBJPROP_TEXT,      txt);
   ObjectSetInteger(0, nm, OBJPROP_COLOR,     col);
   ObjectSetInteger(0, nm, OBJPROP_FONTSIZE,  fs);
   ObjectSetInteger(0, nm, OBJPROP_ANCHOR,    anch);
   ObjectSetInteger(0, nm, OBJPROP_SELECTABLE,false);
}

//--- Init / Deinit wrappers
void NR_Init() {
   if(!InpNR_Enable) return;
   ObjectsDeleteAll(0, NR_OBJ_PFX);
   nr_patCnt = 0;
   ArrayResize(nr_pats, 0);
   nr_pend      = false;
   nr_rev_active = false;
   nr_r1_dir    = 0;
   nr_prevCalc  = 0;
}

void NR_Deinit() {
   ObjectsDeleteAll(0, NR_OBJ_PFX);
   ArrayFree(nr_pats);
   ArrayFree(nr_trendMA);
   ArrayFree(nr_atrRma);
   ArrayFree(nr_plusRma);
   ArrayFree(nr_minusRma);
   ArrayFree(nr_adxRma);
   ArrayFree(nr_wasSetup);
}

//--- Mode 4: Open order on NR breakout arrow (live bar only)
void CheckNRArrowEntry(int dir, datetime barTime, double barHigh, double barLow)
{
   if(!InpEA_Enable || !g_isLive) { Print("[NR Mode4 DBG] blocked — EA disabled or not live"); return; }
   if(!InpNR_DirectEntry) {
      if(IsNewsTime())           { Print("[NR Mode4 DBG] blocked — news time"); return; }
      if(!CheckSessionAndExit()) { Print("[NR Mode4 DBG] blocked — session/daily exit"); return; }
   }
   SessionProfile prof = GetActiveProfile();
   if(!InpNR_DirectEntry) {
      if(!IsSpreadAllowed(prof.maxSpreadUSD)) { PrintFormat("[NR Mode4 DBG] blocked — spread too wide (maxSpread:%.2f)", prof.maxSpreadUSD); return; }
   }

   bool p50Bull = (gdx_swingCount2 > 1 && gdx_swings2[gdx_swingCount2-1].isHigh);
   double tpGap    = USDtoPriceGap(InpTP_USD);
   if(tpGap <= 0) { Print("[NR Mode4 DBG] blocked — tpGap<=0 (InpTP_USD too small?)"); return; }
   PrintFormat("[NR Mode4 DBG] reached filter | dir:%d p50Bull:%s hullM1:%d directEntry:%s", dir, (string)p50Bull, g_hullDirM1, (string)InpNR_DirectEntry);
   long   stopsLvl = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double minDist  = (stopsLvl + 50) * _Point;

   if(dir > 0) // BUY
   {
      if(g_hullDirM1  != 1) { Print("[NR Mode4] BUY blocked — Hull M1 DN (hard)"); return; }
      if(!InpNR_DirectEntry) {
         if(!p50Bull)         { Print("[NR Mode4] BUY blocked — p50 BEARISH"); return; }
      }
      if(CountOpenOrders(POSITION_TYPE_BUY) >= InpMaxBuy) { Print("[NR Mode4] BUY blocked — max orders"); return; }
      if(InpFiboFilter && (gdx_swingCount > 1 || gdx_swingCount2 > 1)) {
         double fiboP26 = GetFiboP26Pct(SymbolInfoDouble(_Symbol, SYMBOL_ASK), false);
         double fiboFx  = GetSwingFiboPct(SymbolInfoDouble(_Symbol, SYMBOL_ASK), false);
         double fiboMax = MathMax(fiboP26 >= 0.0 ? fiboP26 : 0.0, fiboFx >= 0.0 ? fiboFx : 0.0);
         if((fiboP26 >= 0.0 || fiboFx >= 0.0) && fiboMax > prof.fiboMaxPct) {
            PrintFormat("[NR Mode4] BUY blocked — Fibo max:%.1f%%(p26:%.1f%%/fx:%.1f%%)", fiboMax, fiboP26, fiboFx); return;
         }
      }
      double ask    = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double slGap  = CalcSLGap(ask, true);
      double fixedTP= ask + tpGap;
      double zoneTP = FindZoneTP_Buy(ask);
      double tp     = (zoneTP > ask && zoneTP < fixedTP) ? zoneTP : fixedTP;
      double sl     = ask - slGap;
      if(MathAbs(tp - ask) < minDist) tp = ask + minDist;
      if(MathAbs(ask - sl) < minDist) sl = ask - minDist;
      tp = NormalizeDouble(tp, _Digits);
      sl = NormalizeDouble(sl, _Digits);
      if(!ValidateTrade(ask, sl, tp)) return;
      Print("[NR Mode4] BUY open | Ask:", DoubleToString(ask,_Digits), " SL:", DoubleToString(sl,_Digits), " TP:", DoubleToString(tp,_Digits));
      if(g_trade.Buy(InpLot, _Symbol, ask, sl, tp, "NR_ARROW_BUY"))
         LogTradeOpen(g_trade.ResultOrder(), "NR_ARROW_BUY", ask);
   }
   else // SELL
   {
      if(g_hullDirM1 != -1) { Print("[NR Mode4] SELL blocked — Hull M1 UP (hard)"); return; }
      if(!InpNR_DirectEntry) {
         if(p50Bull)              { Print("[NR Mode4] SELL blocked — p50 BULLISH"); return; }
      }
      if(CountOpenOrders(POSITION_TYPE_SELL) >= InpMaxSell) { Print("[NR Mode4] SELL blocked — max orders"); return; }
      if(InpFiboFilter && (gdx_swingCount > 1 || gdx_swingCount2 > 1)) {
         double fiboP26 = GetFiboP26Pct(SymbolInfoDouble(_Symbol, SYMBOL_BID), true);
         double fiboFx  = GetSwingFiboPct(SymbolInfoDouble(_Symbol, SYMBOL_BID), true);
         double fiboMax = MathMax(fiboP26 >= 0.0 ? fiboP26 : 0.0, fiboFx >= 0.0 ? fiboFx : 0.0);
         if((fiboP26 >= 0.0 || fiboFx >= 0.0) && fiboMax > prof.fiboMaxPct) {
            PrintFormat("[NR Mode4] SELL blocked — Fibo max:%.1f%%(p26:%.1f%%/fx:%.1f%%)", fiboMax, fiboP26, fiboFx); return;
         }
         if(fiboP26 >= 0.0 && fiboP26 < 38.2) { PrintFormat("[NR Mode4] SELL blocked — Fibo p26:%.1f%% < 38.2%%", fiboP26); return; }
      }
      double bid    = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double slGap  = CalcSLGap(bid, false);
      double fixedTP= bid - tpGap;
      double zoneTP = FindZoneTP_Sell(bid);
      double tp     = (zoneTP < bid && zoneTP > fixedTP) ? zoneTP : fixedTP;
      double sl     = bid + slGap;
      if(MathAbs(bid - tp) < minDist) tp = bid - minDist;
      if(MathAbs(sl - bid) < minDist) sl = bid + minDist;
      tp = NormalizeDouble(tp, _Digits);
      sl = NormalizeDouble(sl, _Digits);
      if(!ValidateTrade(bid, sl, tp)) return;
      Print("[NR Mode4] SELL open | Bid:", DoubleToString(bid,_Digits), " SL:", DoubleToString(sl,_Digits), " TP:", DoubleToString(tp,_Digits));
      if(g_trade.Sell(InpLot, _Symbol, bid, sl, tp, "NR_ARROW_SELL"))
         LogTradeOpen(g_trade.ResultOrder(), "NR_ARROW_SELL", bid);
   }
}

//--- NR MA color-flip → close opposite positions (comment-filtered)
void CheckNRMAFlipClose()
{
   if(nr_prevCalc < 2) return;
   static datetime s_lastFlipBar = 0;
   datetime curBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(curBarTime == s_lastFlipBar) return;

   int last = nr_prevCalc - 1;
   int prev = nr_prevCalc - 2;
   if(last >= ArraySize(nr_trendMA) || prev < 0) return;

   int    _lbF  = (InpNR_MaSlopeLB < 1) ? 1 : InpNR_MaSlopeLB;
   double _thrF = InpNR_MaSlopeThresh * _Point;
   int    _prevIdx = last - _lbF;
   if(_prevIdx < 0 || _prevIdx >= ArraySize(nr_trendMA)) return;
   double _slopeF = nr_trendMA[last] - nr_trendMA[_prevIdx];
   if(MathAbs(_slopeF) < _thrF) return; // slope อ่อน — hold dir เดิม
   bool isUP = (_slopeF > 0);
   int newDir = isUP ? 1 : -1;
   if(newDir == g_nrMADir) return;  // ไม่มี flip

   int oldDir    = g_nrMADir;
   g_nrMADir     = newDir;
   s_lastFlipBar = curBarTime;

   string closeComment = (newDir == 1) ? "NR_ARROW_SELL" : "NR_ARROW_BUY";
   ENUM_POSITION_TYPE closeType = (newDir == 1) ? POSITION_TYPE_SELL : POSITION_TYPE_BUY;

   if(oldDir == 0) return;  // cold-start: อัปเดต dir เฉพาะ ไม่ปิด

   // v1.82: disabled — NR MA flip no longer closes positions
}

//--- Main calculation (called from OnTick, receives bar arrays already copied)
void NR_Calculate(const int rates_total,
                  const datetime &time[],
                  const double   &open[],
                  const double   &high[],
                  const double   &low[],
                  const double   &close[]) {
   if(!InpNR_Enable) return;
   if(rates_total < 3) return;

   if(ArraySize(nr_trendMA) < rates_total) {
      ArrayResize(nr_trendMA,  rates_total + 256);
      ArrayResize(nr_atrRma,   rates_total + 256);
      ArrayResize(nr_plusRma,  rates_total + 256);
      ArrayResize(nr_minusRma, rates_total + 256);
      ArrayResize(nr_adxRma,   rates_total + 256);
      ArrayResize(nr_wasSetup, rates_total + 256);
   }

   bool wasColdStart = (nr_prevCalc <= 1);
   // Recalc last 400 bars on new bar to keep MA display window fresh (fix drift after long run)
   bool isNewMaBar = (!wasColdStart && rates_total > 1 && time[rates_total-1] != g_nrMALastBar);
   int start = wasColdStart ? 0 : (isNewMaBar ? MathMax(0, rates_total - 400) : rates_total - 1);
   if(wasColdStart) {
      for(int k = 0; k < nr_patCnt; k++) NR_DelPat(k);
      nr_patCnt = 0; ArrayResize(nr_pats, 0);
      nr_pend = false;
   }

   int per = PeriodSeconds();

   // Detect sliding window shift — adjust all stored bar indices to stay in sync
   if(!wasColdStart && nr_windowStartTime != 0 && time[0] != nr_windowStartTime) {
      int shift = (int)MathRound((double)(time[0] - nr_windowStartTime) / per);
      if(shift > 0) {
         for(int k = 0; k < nr_patCnt; k++) {
            nr_pats[k].leftBar -= shift;
            nr_pats[k].trigBar -= shift;
            nr_pats[k].endBar  -= shift;
         }
         nr_pendLeft   -= shift;
         nr_pendRight  -= shift;
         nr_r1_expBar  -= shift;
         nr_rev_expBar -= shift;
         int keep = rates_total - shift;
         if(keep > 0) ArrayCopy(nr_wasSetup, nr_wasSetup, 0, shift, keep);
         ArrayFill(nr_wasSetup, MathMax(0, keep), shift, false);
      }
   }
   nr_windowStartTime = time[0];

   for(int i = start; i < rates_total; i++) {
      //--- ADX components
      double tr_  = NR_TR(i, high, low, close);
      double upMv = (i > 0) ? high[i] - high[i-1] : 0.0;
      double dnMv = (i > 0) ? low[i-1] - low[i]   : 0.0;
      double pDM  = (upMv > dnMv && upMv > 0) ? upMv : 0.0;
      double mDM  = (dnMv > upMv && dnMv > 0) ? dnMv : 0.0;

      if(i == 0) {
         nr_atrRma[0] = tr_; nr_plusRma[0] = pDM;
         nr_minusRma[0] = mDM; nr_adxRma[0] = 0.0;
      } else {
         nr_atrRma[i]   = NR_RmaUpd(nr_atrRma[i-1],   tr_,  InpNR_AdxLen);
         nr_plusRma[i]  = NR_RmaUpd(nr_plusRma[i-1],  pDM,  InpNR_AdxLen);
         nr_minusRma[i] = NR_RmaUpd(nr_minusRma[i-1], mDM,  InpNR_AdxLen);
         double pDI = (nr_atrRma[i] > 0) ? 100.0 * nr_plusRma[i]  / nr_atrRma[i] : 0.0;
         double mDI = (nr_atrRma[i] > 0) ? 100.0 * nr_minusRma[i] / nr_atrRma[i] : 0.0;
         double sDI = pDI + mDI;
         double dx  = (sDI > 0) ? 100.0 * MathAbs(pDI - mDI) / sDI : 0.0;
         nr_adxRma[i] = NR_RmaUpd(nr_adxRma[i-1], dx, InpNR_AdxLen);
      }

      //--- Effective Look Back
      int _mn = MathMin(InpNR_LbMin, InpNR_LbMax), _mx = MathMax(InpNR_LbMin, InpNR_LbMax);
      double bLo = MathMin(InpNR_AdxLo, InpNR_AdxHi), bHi = MathMax(InpNR_AdxLo, InpNR_AdxHi);
      double tB  = (bHi > bLo) ? (nr_adxRma[i] - bLo) / (bHi - bLo) : 0.0;
      tB = MathMax(0.0, MathMin(1.0, tB));
      int lbAdx = (int)MathRound(_mx - tB * (_mx - _mn));
      int lb    = (InpNR_LbMode == "ADX Adaptive")
          ? MathMax(2, MathMin(500, lbAdx))
          : NR_LOOKBACK;

      //--- Trend MA
      int tLen = (InpNR_TrendMode == "NR-Adaptive")
          ? MathMax(20, MathMin(200, (int)MathRound(lb * InpNR_TrendMul)))
          : InpNR_TrendMaLen;

      if(i == 0) nr_trendMA[0] = close[0];
      else nr_trendMA[i] = (InpNR_TrendMaType == "EMA")
          ? NR_EmaUpd(nr_trendMA[i-1], close[i], tLen)
          : NR_RmaUpd(nr_trendMA[i-1], close[i], tLen);

      bool allowL = !InpNR_UseTrendFilter || close[i] > nr_trendMA[i];
      bool allowS = !InpNR_UseTrendFilter || close[i] < nr_trendMA[i];

      //--- Smart NR detection (n=2..20)
      double sRank = -1.0; int sLen = 0; bool sFound = false;
      for(int n = 2; n <= 20 && i >= n; n++) {
         if(NR_IsNR(n, lb, i, high, low)) {
            sFound = true;
            double rk = NR_RankTight(n, lb, i, high, low);
            bool take = (sLen == 0);
            if(!take) {
               if     (rk >= 0 && sRank >= 0) take = (rk < sRank) || (rk == sRank && n < sLen);
               else if(rk >= 0 && sRank <  0) take = true;
               else if(rk <  0 && sRank <  0) take = (n < sLen);
            }
            if(take) { sRank = rk; sLen = n; }
         }
      }
      bool setupNow = false; bool setupIsNR = false; int setupLen = 0;
      if(sFound && sLen > 0) { setupNow = true; setupIsNR = true; setupLen = sLen; }

      //--- Inside Bar fallback
      if(!setupNow && InpNR_UseInsideBar && i >= 1 &&
         high[i] < high[i-1] && low[i] > low[i-1]) {
         setupNow = true; setupIsNR = false; setupLen = 1;
      }

      //--- New setup
      bool prevSetup = (i > 0) ? nr_wasSetup[i-1] : false;
      bool newSetup  = setupNow && !prevSetup;
      nr_wasSetup[i] = setupNow;

      if(newSetup) {
         int pLen   = setupIsNR ? setupLen : 1;
         nr_pend     = true;
         nr_pendLeft = i - (pLen - 1);
         nr_pendRight= i;
         nr_pendHi   = NR_HiArr(high, i, pLen);
         nr_pendLo   = NR_LoArr(low,  i, pLen);
         nr_pendName = setupIsNR ? "S NR" : "Inside";
      }

      //--- Setup Timeout: ปิด — Pine Script ไม่มี timeout (รอ trigger ไปเรื่อยๆ)
      // if(nr_pend && (i - nr_pendRight > InpNR_ExtendFwd))
      //    nr_pend = false;

      //--- Trigger
      bool bT = nr_pend && high[i] >= nr_pendHi && allowL;
      bool sT = nr_pend && low[i]  <= nr_pendLo && allowS;
      int  dir = 0;
      if(bT && sT)
         dir = (MathAbs(open[i] - nr_pendHi) <= MathAbs(open[i] - nr_pendLo)) ? +1 : -1;
      else if(bT) dir = +1;
      else if(sT) dir = -1;

      if(dir != 0) {
         // Pine Script logic: check only last pattern, bar overlap only
         bool overlaps = false;
         if(nr_patCnt > 0)
            overlaps = (nr_pendLeft <= nr_pats[nr_patCnt - 1].endBar);
         if(!overlaps) {
            color base  = (dir > 0) ? InpNR_BullCol : InpNR_BearCol;
            color bFill = NR_MixToWhite(base, InpNR_BoxFillAlpha);
            color bEdge = NR_MixToWhite(base, InpNR_BoxEdgeAlpha);

            datetime dt1 = time[MathMax(0, nr_pendLeft)];
            datetime dtR = time[nr_pendRight];
            datetime dt2 = time[i] + (datetime)(InpNR_ExtendFwd * per);

            string sid = IntegerToString(i) + "_" + IntegerToString((long)time[i]);

            // วาด object เฉพาะ bar ใน window ล่าสุด (เหมือน Pine Script — ไม่วาดทั้งประวัติ)
            bool shouldDraw = (i >= rates_total - InpNR_MaxKeep);

            if(shouldDraw) {
               string bNm = NR_OBJ_PFX + "box_" + sid;
               ObjectCreate(0, bNm, OBJ_RECTANGLE, 0, dt1, nr_pendHi, dtR, nr_pendLo);
               ObjectSetInteger(0, bNm, OBJPROP_BGCOLOR,    bFill);
               ObjectSetInteger(0, bNm, OBJPROP_COLOR,      bEdge);
               ObjectSetInteger(0, bNm, OBJPROP_BACK,       true);
               ObjectSetInteger(0, bNm, OBJPROP_SELECTABLE, false);

               string hNm = NR_OBJ_PFX + "hiL_" + sid;
               ObjectCreate(0, hNm, OBJ_TREND, 0, dtR, nr_pendHi, dt2, nr_pendHi);
               ObjectSetInteger(0, hNm, OBJPROP_COLOR,      base);
               ObjectSetInteger(0, hNm, OBJPROP_WIDTH,      InpNR_LvlW);
               ObjectSetInteger(0, hNm, OBJPROP_STYLE,      NR_LvlStyle());
               ObjectSetInteger(0, hNm, OBJPROP_RAY_RIGHT,  false);
               ObjectSetInteger(0, hNm, OBJPROP_SELECTABLE, false);

               string lNm = NR_OBJ_PFX + "loL_" + sid;
               ObjectCreate(0, lNm, OBJ_TREND, 0, dtR, nr_pendLo, dt2, nr_pendLo);
               ObjectSetInteger(0, lNm, OBJPROP_COLOR,      base);
               ObjectSetInteger(0, lNm, OBJPROP_WIDTH,      InpNR_LvlW);
               ObjectSetInteger(0, lNm, OBJPROP_STYLE,      NR_LvlStyle());
               ObjectSetInteger(0, lNm, OBJPROP_RAY_RIGHT,  false);
               ObjectSetInteger(0, lNm, OBJPROP_SELECTABLE, false);

               if(InpNR_ShowTrigIcon) {
                  string tTxt = nr_pendName + (dir > 0 ? " ▲" : " ▼");
                  double tY   = (dir > 0) ? nr_pendLo : nr_pendHi;
                  ENUM_ANCHOR_POINT tAnch = (dir > 0) ? ANCHOR_UPPER : ANCHOR_LOWER;
                  NR_ObjText(NR_OBJ_PFX + "tg_" + sid, dtR, tY, tTxt, base, 9, tAnch);
               }
            }

            double rng   = MathMax(nr_pendHi - nr_pendLo, _Point);
            double entry = (dir > 0) ? nr_pendHi : nr_pendLo;
            double stp   = (dir > 0) ? nr_pendLo : nr_pendHi;
            double tgt   = (dir > 0) ? entry + InpNR_ExitR * rng : entry - InpNR_ExitR * rng;

            NR_PatData pd;
            pd.leftBar = nr_pendLeft; pd.trigBar = i;
            pd.endBar  = i + InpNR_ExtendFwd;
            pd.dir     = dir;
            pd.entry   = entry; pd.stop = stp; pd.tgt = tgt;
            pd.exited   = false; pd.notified = false; pd.id = sid;

            if(nr_patCnt >= ArraySize(nr_pats)) ArrayResize(nr_pats, nr_patCnt + 64);
            nr_pats[nr_patCnt++] = pd;

            // Mode 4: 2-Round confirmation — determine round & arrow color
            bool isRound2 = false;
            if(InpNR_ArrowEntry && i == rates_total - 1) {
               // expire stale round 1
               if(nr_r1_dir != 0 && i > nr_r1_expBar) nr_r1_dir = 0;

               if(nr_r1_dir == 0) {
                  // Round 1: record state
                  nr_r1_dir    = dir;
                  nr_r1_hi     = nr_pendHi;
                  nr_r1_lo     = nr_pendLo;
                  nr_r1_time   = time[i];
                  nr_r1_expBar = i + InpNR_ExtendFwd;
                  Print("[NR Mode4] Round1 recorded | dir:", dir, " expBar:", nr_r1_expBar);
               } else if(nr_r1_dir == dir) {
                  // Round 2: same direction → trigger order
                  isRound2  = true;
                  nr_r1_dir = 0; // clear state
               } else {
                  // Opposite direction → reset to new round 1
                  nr_r1_dir    = dir;
                  nr_r1_hi     = nr_pendHi;
                  nr_r1_lo     = nr_pendLo;
                  nr_r1_time   = time[i];
                  nr_r1_expBar = i + InpNR_ExtendFwd;
                  Print("[NR Mode4] Round1 reset (opposite dir) | dir:", dir);
               }
            }

            // Breakout arrow — วาดเฉพาะใน window เดียวกับ box
            if(InpNR_ShowBreakArrow && shouldDraw) {
               string arNm  = NR_OBJ_PFX + "ar_" + sid;
               double arY   = (dir > 0) ? low[i]  - 3 * _Point : high[i] + 3 * _Point;
               int    arCode= (dir > 0) ? 241 : 242;
               ENUM_ARROW_ANCHOR arAnch = (dir > 0) ? ANCHOR_TOP : ANCHOR_BOTTOM;
               color  arClr = isRound2 ? clrWhite : clrGray;
               ObjectDelete(0, arNm);
               ObjectCreate(0, arNm, OBJ_ARROW, 0, time[i], arY);
               ObjectSetInteger(0, arNm, OBJPROP_ARROWCODE,  arCode);
               ObjectSetInteger(0, arNm, OBJPROP_COLOR,      arClr);
               ObjectSetInteger(0, arNm, OBJPROP_WIDTH,      2);
               ObjectSetInteger(0, arNm, OBJPROP_ANCHOR,     arAnch);
               ObjectSetInteger(0, arNm, OBJPROP_SELECTABLE, false);
               ObjectSetInteger(0, arNm, OBJPROP_BACK,       false);
            }

            // Mode 4: open order on every arrow (Round1+Round2), live bar only — once per bar
            if(InpNR_ArrowEntry && InpEA_Enable && g_isLive && i == rates_total - 1 && time[i] != g_lastNROrderBar)
            {
               g_lastNROrderBar = time[i];
               CheckNRArrowEntry(dir, time[i], high[i], low[i]);
            }

            // Push notify — live bar only, no duplicate
            if(InpNR_Notify && InpAlertPush && i == rates_total - 1 && !pd.notified) {
               double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
               double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
               double rangeUSD = (tickSize > 0) ? (nr_pendHi - nr_pendLo) / tickSize * tickVal * InpLot : 0;
               double tpUSD    = rangeUSD * InpNR_ExitR;
               string arrow    = (dir > 0) ? "▲" : "▼";
               string side     = (dir > 0) ? "BUY" : "SELL";
               string emoji    = (dir > 0) ? "🟢" : "🔴";
               string msg = emoji + " [SmartNR " + side + "] " + _Symbol + " " + EnumToString(_Period)
                          + " | " + nr_pendName + arrow
                          + " | Entry:" + DoubleToString(entry, _Digits)
                          + " SL:" + DoubleToString(stp, _Digits)
                          + " TP:" + DoubleToString(tgt, _Digits)
                          + " | Range:" + DoubleToString(rangeUSD, 2) + "$ R:" + DoubleToString(InpNR_ExitR, 1)
                          + " | " + TimeToString(time[i], TIME_DATE|TIME_MINUTES);
               SafeSendNotification(msg);
               nr_pats[nr_patCnt - 1].notified = true;
            }

            if(nr_patCnt > InpNR_MaxKeep) {
               NR_DelPat(0);
               for(int k = 0; k < nr_patCnt - 1; k++) nr_pats[k] = nr_pats[k+1];
               nr_patCnt--;
            }
         }
         // Reversal watch: after trigger, watch opposite breakout within same ExtendFwd window
         nr_rev_active = true;
         nr_rev_dir    = -dir;   // opposite direction
         nr_rev_hi     = nr_pendHi;
         nr_rev_lo     = nr_pendLo;
         nr_rev_expBar = i + InpNR_ExtendFwd;
         nr_pend = false;
      }

      //--- Reversal trigger check (after original trigger cleared nr_pend)
      if(nr_rev_active) {
         if(i > nr_rev_expBar) {
            nr_rev_active = false;
         } else {
            bool revBT = (nr_rev_dir > 0) && high[i] >= nr_rev_hi && allowL;
            bool revST = (nr_rev_dir < 0) && low[i]  <= nr_rev_lo && allowS;
            int  revDir = revBT ? +1 : revST ? -1 : 0;
            if(revDir != 0) {
               nr_rev_active = false;   // ยิงได้ครั้งเดียว
               string sid2 = IntegerToString(time[i]) + "_rev";
               double entry2 = (revDir > 0) ? nr_rev_hi : nr_rev_lo;
               double stp2   = (revDir > 0) ? nr_rev_lo : nr_rev_hi;
               double rng2   = MathMax(nr_rev_hi - nr_rev_lo, _Point);
               double tgt2   = (revDir > 0) ? entry2 + InpNR_ExitR * rng2 : entry2 - InpNR_ExitR * rng2;

               if(InpNR_ShowBreakArrow && (i >= rates_total - InpNR_MaxKeep)) {
                  string arNm2 = NR_OBJ_PFX + "ar_" + sid2;
                  double arY2  = (revDir > 0) ? low[i]  - 3 * _Point : high[i] + 3 * _Point;
                  int arCode2  = (revDir > 0) ? 241 : 242;
                  ENUM_ARROW_ANCHOR arAnch2 = (revDir > 0) ? ANCHOR_TOP : ANCHOR_BOTTOM;
                  ObjectDelete(0, arNm2);
                  ObjectCreate(0, arNm2, OBJ_ARROW, 0, time[i], arY2);
                  ObjectSetInteger(0, arNm2, OBJPROP_ARROWCODE,  arCode2);
                  ObjectSetInteger(0, arNm2, OBJPROP_COLOR,      clrDodgerBlue);  // สีต่างเพื่อแยกแยะ reversal
                  ObjectSetInteger(0, arNm2, OBJPROP_WIDTH,      2);
                  ObjectSetInteger(0, arNm2, OBJPROP_ANCHOR,     arAnch2);
                  ObjectSetInteger(0, arNm2, OBJPROP_SELECTABLE, false);
                  ObjectSetInteger(0, arNm2, OBJPROP_BACK,       false);
               }

               // เปิด order reversal — live bar only, once per bar
               if(InpNR_ArrowEntry && InpEA_Enable && g_isLive && i == rates_total - 1 && time[i] != g_lastNROrderBar) {
                  g_lastNROrderBar = time[i];
                  CheckNRArrowEntry(revDir, time[i], high[i], low[i]);
                  Print("[NR Rev] Reversal ", (revDir > 0 ? "BUY" : "SELL"), " @ ", DoubleToString(entry2, _Digits));
               }
            }
         }
      }

      //--- Exit markers
      if(InpNR_ShowExitX) {
         for(int p = 0; p < nr_patCnt; p++) {
            if(nr_pats[p].exited) continue;
            bool inW = InpNR_UseTimeExit
               ? (i >= nr_pats[p].trigBar && i <= nr_pats[p].trigBar + InpNR_ExitBars)
               : (i >= nr_pats[p].trigBar);
            bool hitSL = false, hitTP = false;
            if(inW) {
               if(nr_pats[p].dir > 0) {
                  hitSL = InpNR_UseSL     && close[i] <= nr_pats[p].stop;
                  hitTP = InpNR_UseCondTP && high[i]  >= nr_pats[p].tgt;
               } else {
                  hitSL = InpNR_UseSL     && close[i] >= nr_pats[p].stop;
                  hitTP = InpNR_UseCondTP && low[i]   <= nr_pats[p].tgt;
               }
            }
            int    ek = 0;
            double exP = 0;
            if(hitTP || hitSL) {
               if(hitTP && hitSL)
                  ek = (MathAbs(open[i] - nr_pats[p].tgt) <= MathAbs(open[i] - nr_pats[p].stop)) ? 1 : -1;
               else ek = hitTP ? 1 : -1;
               exP = (ek == 1) ? nr_pats[p].tgt : nr_pats[p].stop;
            }
            if(ek == 0 && InpNR_UseTimeExit && i >= nr_pats[p].trigBar + InpNR_ExitBars) {
               ek = 2; exP = close[i];
            }
            if(ek != 0) {
               string eTxt = (ek == 1) ? "TP" : (ek == -1) ? "SL" : "T";
               color  eCol = (ek == 1) ? InpNR_TpExitCol : (ek == -1) ? InpNR_SlExitCol : InpNR_TimeExitCol;
               bool   above = false;
               double eY;
               if(nr_pats[p].dir > 0) {
                  above = (ek == 1 || ek == 2);
                  eY    = above ? high[i] : low[i];
               } else {
                  above = (ek == -1);
                  eY    = above ? high[i] : low[i];
               }
               ENUM_ANCHOR_POINT anch = above ? ANCHOR_LOWER : ANCHOR_UPPER;
               NR_ObjText(NR_OBJ_PFX + "ex_" + nr_pats[p].id, time[i], eY, eTxt, eCol, 9, anch);
               nr_pats[p].exited = true;
            }
         }
      }
   } // end bar loop

   // Cold-start: suppress all historical notifications
   // ไม่ reset nr_patCnt → overlap memory ยังทำงานได้สำหรับ live bar ถัดไป
   if(wasColdStart) {
      for(int k = 0; k < nr_patCnt; k++) nr_pats[k].notified = true;
      // ลบ pattern ที่ exited แล้วออก เพื่อไม่ให้ block live patterns โดยไม่จำเป็น
      int alive = 0;
      for(int k = 0; k < nr_patCnt; k++) {
         if(!nr_pats[k].exited) nr_pats[alive++] = nr_pats[k];
      }
      nr_patCnt = alive;
      // shouldDraw=false during cold-start — no NR objects created, nothing to delete
   }

   // ปิด: อย่าดึงปลายเส้นตาม current bar — ให้เส้นพุ่งไปข้างหน้าคงที่ (dt2) เหมือน Pine Script
   // if(!wasColdStart && rates_total > 0) {
   //    datetime curTime = time[rates_total - 1];
   //    int curBarIdx = rates_total - 1;
   //    for(int p = 0; p < nr_patCnt; p++) {
   //       if(curBarIdx > nr_pats[p].endBar) continue;
   //       string hNm = NR_OBJ_PFX + "hiL_" + nr_pats[p].id;
   //       string lNm = NR_OBJ_PFX + "loL_" + nr_pats[p].id;
   //       if(ObjectFind(0, hNm) >= 0) ObjectSetInteger(0, hNm, OBJPROP_TIME, 1, curTime);
   //       if(ObjectFind(0, lNm) >= 0) ObjectSetInteger(0, lNm, OBJPROP_TIME, 1, curTime);
   //    }
   // }

   nr_prevCalc = rates_total;
}

//+------------------------------------------------------------------+
//|  OnCalculate                                                     |
//+------------------------------------------------------------------+
void OnTick()
{
   CheckRetryNotification();
   // ตรวจสอบการเปลี่ยน Timeframe
   if(_Period != g_lastTF) {
      g_lastTF = _Period;
      ObjectsDeleteAll(0, "DLZ_ATR_");
      if(InpATRLevelsEnable) DrawATRLevels();
   }

   DrawM15Candles();
   int total_bars = Bars(_Symbol, _Period);
   if(total_bars < 1) return;
   int rates_total = MathMin(total_bars, 5000);

   MqlRates rates[];
   ArraySetAsSeries(rates, false);
   if(CopyRates(_Symbol, _Period, 0, rates_total, rates) <= 0) return;

   double open_arr[], high_arr[], low_arr[], close_arr[];
   datetime time_arr[];
   long tick_vol[], real_vol[];
   int spread_arr[];

   ArrayResize(open_arr,  rates_total); ArrayResize(high_arr,   rates_total);
   ArrayResize(low_arr,   rates_total); ArrayResize(close_arr,  rates_total);
   ArrayResize(time_arr,  rates_total); ArrayResize(tick_vol,   rates_total);
   ArrayResize(real_vol,  rates_total); ArrayResize(spread_arr, rates_total);

   for(int i = 0; i < rates_total; i++) {
      open_arr[i]  = rates[i].open;  high_arr[i]  = rates[i].high;
      low_arr[i]   = rates[i].low;   close_arr[i] = rates[i].close;
      time_arr[i]  = rates[i].time;  tick_vol[i]  = rates[i].tick_volume;
      real_vol[i]  = rates[i].real_volume;
   }

   g_prevHullDirM1  = g_hullDirM1;
   g_prevHullDirM15 = g_hullDirM15;
   DLZ_Process(rates_total, time_arr, open_arr, high_arr, low_arr, close_arr, tick_vol, real_vol);
   NR_Calculate(rates_total, time_arr, open_arr, high_arr, low_arr, close_arr);
   if(InpEA_Enable && g_isLive) CheckNRMAFlipClose();
   if(InpEA_Enable) {
      UpdateMaxDrawdown();
      CheckBreakEven();
      ManageSLExpansion();
      ManageHullTrail();
      CloseAllIfProfitTarget();
      CheckFlatCloseOrders();
      if(InpHullFollowEntry) CheckHullFollowEntry();
      ManageAutoPending();
   }
   CheckDXYTrendNotification();
   CheckDXYPendingSignal();
   CheckOFAFibNotification();
   Commander.UpdateAccountInfo();
   UpdateEADashboard();

   // ATR Previous Day Levels — redraw on new day (wait until handle is ready)
   if(InpATRLevelsEnable) {
      static int lastATRDay = 0;
      MqlDateTime dt; TimeCurrent(dt);
      double _atrReady[1];
      bool handleReady = (g_atr_d1_handle != INVALID_HANDLE &&
                          CopyBuffer(g_atr_d1_handle, 0, 1, 1, _atrReady) == 1);
      if(handleReady && dt.day != lastATRDay) {
         lastATRDay = dt.day;
         ObjectsDeleteAll(0, "DLZ_ATR_");
         DrawATRLevels();
      }
   }
}

//+------------------------------------------------------------------+
//| GetSwingFiboPct — คำนวณ Fibo% ของ price จาก 2 swing ล่าสุด      |
//| ใช้ gdx_swings (p26) — เดียวกับที่แสดงใน LogTradeOpen           |
//| return: -1.0 ถ้าไม่มี swing เพียงพอ (ไม่ block)                 |
//+------------------------------------------------------------------+
double GetSwingFiboPct(double price, bool isSell)
{
   if(gdx_swingCount2 < 2) return -1.0;
   GDX_SwingPoint s1 = gdx_swings2[gdx_swingCount2 - 2];
   GDX_SwingPoint s2 = gdx_swings2[gdx_swingCount2 - 1];
   double swingLow  = MathMin(s1.price, s2.price);
   double swingHigh = MathMax(s1.price, s2.price);
   double range = swingHigh - swingLow;
   if(range <= 0.0) return -1.0;
   // SELL: วัดจาก Low ขึ้น → สูง = premium zone (ควร SELL)
   // BUY:  วัดจาก High ลง → สูง = discount zone (ควร BUY)
   if(isSell) return ((price - swingLow)  / range) * 100.0;
   else        return ((swingHigh - price) / range) * 100.0;
}

// Fibo% จาก p26 swings (gdx_swings) — directional เหมือน GetSwingFiboPct
double GetFiboP26Pct(double price, bool isSell)
{
   if(gdx_swingCount < 2) return -1.0;
   GDX_SwingPoint s1 = gdx_swings[gdx_swingCount - 2];
   GDX_SwingPoint s2 = gdx_swings[gdx_swingCount - 1];
   double swingLow  = MathMin(s1.price, s2.price);
   double swingHigh = MathMax(s1.price, s2.price);
   double range = swingHigh - swingLow;
   if(range <= 0.0) return -1.0;
   if(isSell) return ((price - swingLow)  / range) * 100.0;
   else        return ((swingHigh - price) / range) * 100.0;
}

//+------------------------------------------------------------------+
//| DXY AutoTrade: ตรวจว่าราคาห่างจาก Hull M1 เกิน Limit หรือไม่    |
//| type: 0=BUY(ASK), 1=SELL(BID)                                   |
//+------------------------------------------------------------------+
bool IsPriceTooFarFromHull(int type)
{
   if(InpMaxHullDistM1 <= 0) return false;

   double currentPrice = (type == 0) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                                     : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double currentHull  = g_hullValueM1_Curr;
   if(currentHull <= 0) return false;

   // ระยะห่างราคาตรง * 100 → 1 USD = 100 pts (ไม่ผ่าน Lot/tickVal)
   double distance = MathAbs(currentPrice - currentHull) * 100.0;

   double finalLimit = (double)InpMaxHullDistM1;
   if(InpUseDynamicATR)
   {
      double atrPrice = 0;
      double buf[1];
      if(CopyBuffer(g_atrHandle, 0, 0, 1, buf) > 0) atrPrice = buf[0];
      if(atrPrice > 0) finalLimit = (atrPrice * 100.0) * InpATRMultiplier;
   }

   string side = (type == 0) ? "BUY" : "SELL";
   if(distance > finalLimit)
   {
      static datetime lastPrintBarBuy  = 0;
      static datetime lastPrintBarSell = 0;
      datetime curBar = iTime(_Symbol, _Period, 0);
      datetime lastBar = (type == 0) ? lastPrintBarBuy : lastPrintBarSell;
      if(curBar != lastBar)
      {
         if(type == 0) lastPrintBarBuy = curBar; else lastPrintBarSell = curBar;
         PrintFormat("[DXY Block] %s Blocked 🚫 | Gap: %.1f pts | Limit: %.1f pts | Price: %.2f | Hull: %.2f",
                     side, distance, finalLimit, currentPrice, currentHull);
      }
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
void CheckDXYPendingSignal()
{
   if(!g_dxyPending.isPending) return;
   if(!InpDXY_AutoTrade || !InpEA_Enable) return;

   // นับแท่งใหม่เท่านั้น
   static datetime lastBarCheck = 0;
   datetime curBarTime = iTime(_Symbol, _Period, 0);
   if(curBarTime == lastBarCheck) return;
   lastBarCheck = curBarTime;

   // ถ้าเป็นแท่งเดียวกับที่ block ยังไม่นับ
   if(curBarTime == g_dxyPending.signalTime) return;

   g_dxyPending.barsWaited++;

   int    currentTrend = GetDXYTrendDirection();
   double currClose    = iClose(_Symbol, _Period, 0);

   // --- Cancel: มี order เปิดอยู่แล้ว ---
   if(g_dxyPending.direction == -1 && CountOpenOrders(POSITION_TYPE_SELL) >= InpMaxSell)
   {
      Print("[DXY_PENDING] SELL pending CANCEL — max sell orders reached");
      g_dxyPending.isPending = false; return;
   }
   if(g_dxyPending.direction == 1 && CountOpenOrders(POSITION_TYPE_BUY) >= InpMaxBuy)
   {
      Print("[DXY_PENDING] BUY pending CANCEL — max buy orders reached");
      g_dxyPending.isPending = false; return;
   }

   // --- Cancel: DXY กลับทิศหรือ FLAT ---
   if(g_dxyPending.direction == -1 && currentTrend != 1)
   {
      PrintFormat("[DXY_PENDING] SELL pending CANCEL — DXY no longer UP (trend=%d)", currentTrend);
      g_dxyPending.isPending = false; return;
   }
   if(g_dxyPending.direction == 1 && currentTrend != -1)
   {
      PrintFormat("[DXY_PENDING] BUY pending CANCEL — DXY no longer DOWN (trend=%d)", currentTrend);
      g_dxyPending.isPending = false; return;
   }

   // --- Cancel: ครบ 5 แท่ง ---
   if(g_dxyPending.barsWaited > 5)
   {
      PrintFormat("[DXY_PENDING] %s pending CANCEL — timeout (5 bars elapsed)",
                  (g_dxyPending.direction == -1 ? "SELL" : "BUY"));
      g_dxyPending.isPending = false; return;
   }

   // --- Fire: Low/High ยืนยัน direction ---
   bool fireNow = false;
   double currLow  = iLow(_Symbol, _Period, 0);
   double currHigh = iHigh(_Symbol, _Period, 0);
   if(g_dxyPending.direction == -1 && currLow  < g_dxyPending.signalClose) fireNow = true;
   if(g_dxyPending.direction ==  1 && currHigh > g_dxyPending.signalClose) fireNow = true;

   if(fireNow)
   {
      // Re-Validation: Hull direction + Candle alignment ก่อน fire จริง
      bool isHullValid   = false;
      bool isCandleValid = false;
      if(g_dxyPending.direction == 1) {
         isHullValid   = (g_hullDirM1 == 1);
         isCandleValid = (iHigh(_Symbol, _Period, 0) > iHigh(_Symbol, _Period, 1));
      } else {
         isHullValid   = (g_hullDirM1 == -1);
         isCandleValid = (iLow(_Symbol, _Period, 0) < iLow(_Symbol, _Period, 1));
      }
      if(!isHullValid || !isCandleValid) {
         PrintFormat("[DXY_PENDING] Fire Blocked — Re-Validation Failed | Hull:%s Candle:%s | bar=%d",
                     isHullValid ? "OK" : "NO", isCandleValid ? "OK" : "NO", g_dxyPending.barsWaited);
         return; // รอแท่งถัดไป ยังไม่ cancel pending
      }

      double ask   = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double bid   = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double tpGap = USDtoPriceGap(InpTP_USD);
      long   stopLvl  = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
      double minDist  = MathMax((stopLvl + 10) * _Point,
                                SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point + 10 * _Point);

      if(g_dxyPending.direction == -1) // SELL
      {
         double slGap = CalcSLGap(bid, false);
         double sl = NormalizeDouble(MathMax(bid + slGap, bid + minDist), _Digits);
         double tp = NormalizeDouble(MathMin(bid - tpGap, bid - minDist), _Digits);
         PrintFormat("[DXY_PENDING] SELL FIRED | bar=%d close=%.2f < signal=%.2f",
                     g_dxyPending.barsWaited, currClose, g_dxyPending.signalClose);
         if(ValidateTrade(bid, sl, tp) && g_trade.Sell(InpLot, _Symbol, bid, sl, tp, "DXY_PENDING_SELL"))
            LogTradeOpen(g_trade.ResultOrder(), "DXY_PENDING_SELL", bid);
      }
      else // BUY
      {
         double slGap = CalcSLGap(ask, true);
         double sl = NormalizeDouble(MathMin(ask - slGap, ask - minDist), _Digits);
         double tp = NormalizeDouble(MathMax(ask + tpGap, ask + minDist), _Digits);
         PrintFormat("[DXY_PENDING] BUY FIRED | bar=%d close=%.2f > signal=%.2f",
                     g_dxyPending.barsWaited, currClose, g_dxyPending.signalClose);
         if(ValidateTrade(ask, sl, tp) && g_trade.Buy(InpLot, _Symbol, ask, sl, tp, "DXY_PENDING_BUY"))
            LogTradeOpen(g_trade.ResultOrder(), "DXY_PENDING_BUY", ask);
      }
      g_dxyPending.isPending = false;
   }
}

//+------------------------------------------------------------------+
void CheckDXYTrendNotification()
{
   if(!g_isLive) return;

   static datetime lastNotifyTime = 0;
   if(TimeCurrent() - lastNotifyTime < 300) return;

   static int lastSentTrend = -99;
   int currentTrend = GetDXYTrendDirection();

   double dxyPrice  = SymbolInfoDouble(InpDXY_Symbol, SYMBOL_BID);
   double goldPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   if(currentTrend == lastSentTrend) return;
   if(lastSentTrend == -99) { lastSentTrend = currentTrend; return; }

   string dxySide  = (currentTrend ==  1) ? "UP ↗️"      : (currentTrend == -1) ? "DOWN ↘️"  : "FLAT ↔️";
   string goldSide = (currentTrend ==  1) ? "DOWN ↘️"    : (currentTrend == -1) ? "UP ↗️"    : "NEUTRAL ↔️";

   string msg = StringFormat("[DXY Alert] DXY %s %.4f - Gold %s %.2f",
                              dxySide, dxyPrice, goldSide, goldPrice);

   Print(msg);
   if(InpNotifySignal && InpAlertPush)  SafeSendNotification(msg);
   if(InpAlertPopup) Alert(msg);

   // วาดลูกศรบนกราฟ
   string objName = "DXY_TREND_ARROW_" + TimeToString(TimeCurrent(), TIME_SECONDS);
   int    arrowCode; color arrowClr; double arrowPrice;
   if(currentTrend ==  1) { arrowCode = 234; arrowClr = clrOrange;     arrowPrice = goldPrice + 15*_Point; }
   else if(currentTrend == -1) { arrowCode = 233; arrowClr = clrDodgerBlue; arrowPrice = goldPrice - 15*_Point; }
   else                        { arrowCode = 110; arrowClr = clrGray;       arrowPrice = goldPrice; }

   ObjectCreate(0, objName, OBJ_ARROW, 0, TimeCurrent(), arrowPrice);
   ObjectSetInteger(0, objName, OBJPROP_ARROWCODE, arrowCode);
   ObjectSetInteger(0, objName, OBJPROP_COLOR,     arrowClr);
   ObjectSetInteger(0, objName, OBJPROP_WIDTH,     2);
   ObjectSetString(0, objName, OBJPROP_TOOLTIP,    msg);

   lastSentTrend  = currentTrend;   // อัปเดตก่อน AutoTrade เพื่อกัน loop reprint
   g_lastDXYTrend = currentTrend;

   // --- [DXY AutoTrade] เปิด Order เมื่อ DXY เปลี่ยนทิศทาง ---
   if(InpDXY_AutoTrade && InpEA_Enable)
   {
      int dxyDir2  = currentTrend; // [V.1.31] ใช้ค่าเดิมแทน call ซ้ำ ป้องกัน boundary flip
      int goldDir2 = GetGoldTrendDirection();
      bool isAligned = (dxyDir2 != 0 && goldDir2 != 0 && dxyDir2 != goldDir2);
      PrintFormat("[DLZ DXY Debug] dxyDir2=%d goldDir2=%d isAligned=%s",
                  dxyDir2, goldDir2, isAligned ? "true" : "false");
      if(!isAligned)
      {
         Print("[DLZ DXY] Blocked: Market Conflict/Flat");
      }
      else
      {
         double ask  = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double bid  = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double tpGap = USDtoPriceGap(InpTP_USD);

         double candleCurr = iClose(_Symbol, _Period, 0);
         double candlePrev = iClose(_Symbol, _Period, 1);

         if(currentTrend == 1) // DXY UP → Gold DOWN → SELL
         {
            if(IsPriceTooFarFromHull(1)) { /* Log printed inside */ }
            else
            {
               // [D] Block SELL เมื่อ M15 Hull UP — selling against trend
               if(g_hullDirM15 == 1)
               {
                  Print("[DXY_AUTO] SELL Blocked — M15 Hull UP (trend conflict)");
                  return;
               }
               // [E] Block SELL เมื่อ p50 Master Bias = BULLISH
               bool _dxyP50Bull = (gdx_swingCount2 > 1 && gdx_swings2[gdx_swingCount2-1].isHigh);
               if(_dxyP50Bull)
               {
                  Print("[DXY_AUTO] SELL Blocked — p50 Master Bias BULLISH (▲)");
                  return;
               }
               // [B] Hard minimum Fibo 38.2% — block SELL ใน shallow pullback
               double _fiboHard = GetSwingFiboPct(bid, true);
               if(_fiboHard >= 0.0 && _fiboHard < 38.2)
               {
                  PrintFormat("[DXY_AUTO] SELL Blocked — Fibo:%.1f%% < 38.2%% premium zone", _fiboHard);
                  return;
               }
               // [V.1.30] Fibo filter — block SELL ถ้าราคาใกล้ swing Low เกินไป (premium zone ไม่ชัด)
               if(InpDXY_FiboFilter)
               {
                  double _fibo = GetSwingFiboPct(bid, true);
                  if(_fibo >= 0.0 && _fibo < InpDXY_FiboMinPct)
                  {
                     if(gdx_swingCount2 >= 2) {
                        GDX_SwingPoint _s1 = gdx_swings2[gdx_swingCount2-2];
                        GDX_SwingPoint _s2 = gdx_swings2[gdx_swingCount2-1];
                        PrintFormat("[DXY_AUTO] SELL Blocked — Fibo:%.1f%% < min:%.1f%% (near swing Low, not premium) | s1=%.2f(%s) s2=%.2f(%s)",
                                    _fibo, InpDXY_FiboMinPct,
                                    _s1.price, (_s1.isHigh?"H":"L"),
                                    _s2.price, (_s2.isHigh?"H":"L"));
                     } else
                        PrintFormat("[DXY_AUTO] SELL Blocked — Fibo:%.1f%% < min:%.1f%% (near swing Low, not premium)",
                                    _fibo, InpDXY_FiboMinPct);
                     return;
                  }
               }
               bool isSellAllowed = (g_hullDirM1 == -1 &&
                                     g_hullValueM1_Curr < g_hullValueM1_Prev &&
                                     candleCurr < candlePrev);
               int currentOpenSells = CountOpenOrders(POSITION_TYPE_SELL);
               if(currentOpenSells < InpMaxSell && isSellAllowed)
               {
                  PrintFormat("[DXY_AUTO] SELL Passed | Hull:OK(%.2f<%.2f) Candle:OK(%.2f<%.2f) | Orders:%d/%d",
                              g_hullValueM1_Curr, g_hullValueM1_Prev, candleCurr, candlePrev, currentOpenSells, InpMaxSell);
                  long   _dxyStopLvl  = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
                  double _dxyMinDist  = MathMax((_dxyStopLvl + 10) * _Point,
                                                SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point + 10 * _Point);
                  double slGap = CalcSLGap(bid, false);
                  double sl = NormalizeDouble(MathMax(bid + slGap, bid + _dxyMinDist), _Digits);
                  double tp = NormalizeDouble(MathMin(bid - tpGap, bid - _dxyMinDist), _Digits);
                  if(ValidateTrade(bid, sl, tp) && g_trade.Sell(InpLot, _Symbol, bid, sl, tp, "DXY_AUTO"))
                     LogTradeOpen(g_trade.ResultOrder(), "DXY_AUTO_SELL", bid);
               }
               else if(!isSellAllowed)
               {
                  Print(StringFormat("[DXY_AUTO] SELL Blocked | Hull:%s(%.2f<%.2f) Candle:%s(%.2f<%.2f)",
                        (g_hullValueM1_Curr < g_hullValueM1_Prev ? "OK" : "NO"), g_hullValueM1_Curr, g_hullValueM1_Prev,
                        (candleCurr < candlePrev ? "OK" : "NO"), candleCurr, candlePrev));
                  if(!g_dxyPending.isPending)
                  {
                     g_dxyPending.isPending   = true;
                     g_dxyPending.direction   = -1;
                     g_dxyPending.signalClose = iLow(_Symbol, _Period, 0);
                     g_dxyPending.signalTime  = iTime(_Symbol, _Period, 0);
                     g_dxyPending.barsWaited  = 0;
                     PrintFormat("[DXY_PENDING] SELL pending set | signalLow=%.2f | waiting up to 5 bars",
                                 g_dxyPending.signalClose);
                  }
               }
            }
         }
         else if(currentTrend == -1) // DXY DOWN → Gold UP → BUY
         {
            if(IsPriceTooFarFromHull(0)) { /* Log printed inside */ }
            else
            {
               // [D] Block BUY เมื่อ M15 Hull DN — buying against trend
               if(g_hullDirM15 == -1)
               {
                  Print("[DXY_AUTO] BUY Blocked — M15 Hull DN (trend conflict)");
                  return;
               }
               // [B] Hard maximum Fibo 61.8% — block BUY ใกล้ swing High (not discount)
               double _fiboHard = GetSwingFiboPct(ask, false);
               if(_fiboHard >= 0.0 && _fiboHard > 61.8)
               {
                  PrintFormat("[DXY_AUTO] BUY Blocked — Fibo:%.1f%% > 61.8%% (near swing High, not discount)", _fiboHard);
                  return;
               }
               // [V.1.30] Fibo filter — block BUY ถ้าราคาใกล้ swing High เกินไป (discount zone ไม่ชัด)
               if(InpDXY_FiboFilter)
               {
                  double _fibo = GetSwingFiboPct(ask, false);
                  if(_fibo >= 0.0 && _fibo < InpDXY_FiboMinPct)
                  {
                     if(gdx_swingCount2 >= 2) {
                        GDX_SwingPoint _s1 = gdx_swings2[gdx_swingCount2-2];
                        GDX_SwingPoint _s2 = gdx_swings2[gdx_swingCount2-1];
                        PrintFormat("[DXY_AUTO] BUY Blocked — Fibo:%.1f%% < min:%.1f%% (near swing High, not discount) | s1=%.2f(%s) s2=%.2f(%s)",
                                    _fibo, InpDXY_FiboMinPct,
                                    _s1.price, (_s1.isHigh?"H":"L"),
                                    _s2.price, (_s2.isHigh?"H":"L"));
                     } else
                        PrintFormat("[DXY_AUTO] BUY Blocked — Fibo:%.1f%% < min:%.1f%% (near swing High, not discount)",
                                    _fibo, InpDXY_FiboMinPct);
                     return;
                  }
               }
               bool isBuyAllowed = (g_hullDirM1 == 1 &&
                                    g_hullValueM1_Curr > g_hullValueM1_Prev &&
                                    candleCurr > candlePrev);
               int currentOpenBuys = CountOpenOrders(POSITION_TYPE_BUY);
               if(currentOpenBuys < InpMaxBuy && isBuyAllowed)
               {
                  PrintFormat("[DXY_AUTO] BUY Passed | Hull:OK(%.2f>%.2f) Candle:OK(%.2f>%.2f) | Orders:%d/%d",
                              g_hullValueM1_Curr, g_hullValueM1_Prev, candleCurr, candlePrev, currentOpenBuys, InpMaxBuy);
                  long   _dxyStopLvl  = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
                  double _dxyMinDist  = MathMax((_dxyStopLvl + 10) * _Point,
                                                SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point + 10 * _Point);
                  double slGap = CalcSLGap(ask, true);
                  double sl = NormalizeDouble(MathMin(ask - slGap, ask - _dxyMinDist), _Digits);
                  double tp = NormalizeDouble(MathMax(ask + tpGap, ask + _dxyMinDist), _Digits);
                  if(ValidateTrade(ask, sl, tp) && g_trade.Buy(InpLot, _Symbol, ask, sl, tp, "DXY_AUTO"))
                     LogTradeOpen(g_trade.ResultOrder(), "DXY_AUTO_BUY", ask);
               }
               else if(!isBuyAllowed)
               {
                  Print(StringFormat("[DXY_AUTO] BUY Blocked | Hull:%s(%.2f>%.2f) Candle:%s(%.2f>%.2f)",
                        (g_hullValueM1_Curr > g_hullValueM1_Prev ? "OK" : "NO"), g_hullValueM1_Curr, g_hullValueM1_Prev,
                        (candleCurr > candlePrev ? "OK" : "NO"), candleCurr, candlePrev));
                  if(!g_dxyPending.isPending)
                  {
                     g_dxyPending.isPending   = true;
                     g_dxyPending.direction   = 1;
                     g_dxyPending.signalClose = iHigh(_Symbol, _Period, 0);
                     g_dxyPending.signalTime  = iTime(_Symbol, _Period, 0);
                     g_dxyPending.barsWaited  = 0;
                     PrintFormat("[DXY_PENDING] BUY pending set | signalHigh=%.2f | waiting up to 5 bars",
                                 g_dxyPending.signalClose);
                  }
               }
            }
         }
      }
   }

   lastNotifyTime = TimeCurrent();
}

//+------------------------------------------------------------------+
void CheckOFAFibNotification()
{
   if(!InpNotifyFibo618 || !g_isLive) return;
   if(gdx_swingCount2 < 2) return;
   if(TimeCurrent() - g_lastFibNotifyTime < 300) return;
   if(g_lastFibNotifiedSwing == gdx_swingCount2) return;

   GDX_SwingPoint sStart = gdx_swings2[gdx_swingCount2 - 2]; // 0%
   GDX_SwingPoint sEnd   = gdx_swings2[gdx_swingCount2 - 1]; // 100%

   double range = MathAbs(sStart.price - sEnd.price);
   if(range <= 0) return;

   double curPrice       = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double currentRetrace = (MathAbs(curPrice - sEnd.price) / range) * 100.0;

   if(currentRetrace >= 50.0 && currentRetrace <= 61.8)
   {
      bool   isBull = sEnd.isHigh;
      string side   = isBull ? "BUY (Discount Zone)" : "SELL (Premium Zone)";
      string icon   = isBull ? "🔵" : "🔴";
      string msg    = StringFormat("[OFA Golden Zone] %s %s | %s | 50%%-61.8%% | Price: %s | %s",
                                   icon, _Symbol, (isBull ? "BULLISH" : "BEARISH"),
                                   DoubleToString(curPrice, _Digits), side);
      Print(msg);
      if(InpNotifySignal && InpAlertPush)  SafeSendNotification(msg);
      if(InpAlertPopup) Alert(msg);

      g_lastFibNotifyTime    = TimeCurrent();
      g_lastFibNotifiedSwing = gdx_swingCount2;
   }
}

int DLZ_Process(
   const int      rates_total,
   const datetime &time[],
   const double   &open[],
   const double   &high[],
   const double   &low[],
   const double   &close[],
   const long     &tick_volume[],
   const long     &volume[]
)
{
   int minBars = InpLeftLen + InpRightLen + 1;
   if(rates_total < minBars + 1) return 0;

   int currentBarNS = rates_total - 1;

   // PHASE 1: หา startBar จากเวลาแทน Index (แก้ bug Sliding Window)
   int startBar = InpLeftLen + InpRightLen; // ครั้งแรก: ย้อนหลังทั้งหมด
   if(g_lastBarTimeProcessed > 0) {
      for(int i = rates_total - 2; i >= 0; i--) {
         if(time[i] <= g_lastBarTimeProcessed) { startBar = i + 1; break; }
      }
   }

   int endBar = rates_total - 2;
   for(int b = startBar; b <= endBar; b++)
   {
      if(InpVolType == Vol_Tick)
         ProcessConfirmBar(high, low, time, tick_volume, b, rates_total);
      else
         ProcessConfirmBar(high, low, time, volume, b, rates_total);
      UpdateZones(high, low, time, rates_total, b);
      g_lastBarTimeProcessed = time[b];
   }
   if(!g_isLive) {
      g_isLive = true;
      g_prevHullDirM1  = g_hullDirM1;
      g_prevHullDirM15 = g_hullDirM15;
      Print("[DLZ System] Historical Sync Complete. Live Monitoring Started.");
   }

   // ---------------------------------------------------------------
   // PHASE 2: Every tick -- extend active zones to current bar and
   //          check sweep against the live (forming) bar
   // ---------------------------------------------------------------
   UpdateZones(high, low, time, rates_total, currentBarNS);

   // --- [NEW] PHASE 4: Update Dashboard ---
   UpdateDashboard();

   // --- PHASE 5: OFA Update ---
   if(InpVolType == Vol_Tick) {
      RunOFAUpdate(rates_total, time, open, high, low, close, tick_volume);
   } else {
      RunOFAUpdate(rates_total, time, open, high, low, close, volume);
   }

   // --- PHASE 4b: Cluster Dashboard + ConsolidateLabels — เฉพาะ Bar Close ---
   datetime curBarTime = time[currentBarNS];
   if(curBarTime != g_lastClusterBarTime)
   {
      g_lastClusterBarTime = curBarTime;
      if(ArraySize(g_zones) > 0) ConsolidateLabels();
      UpdateClusterDashboard();
      CheckEQLConfirmation();
      CheckEQHConfirmation();
      CheckClusterZoneFastEntry();
   }
   
   // --- PHASE 7: Hull Suite M1 + M15 ---
   if(InpHullM1_Enable)
   {  double _dummy = 0;
      RunHullMTF(g_hullEngineM1,  g_hullInitM1,  g_hullValM1,  g_hullTrdM1,  g_hullBarM1,  g_hullDirM1,
                 PERIOD_M1,  InpHullM1_Period,  InpHullM1_Divisor,
                 InpHullM1_UpColor,  InpHullM1_DnColor,  InpHullM1_Width,  "DLZ_HULLM1_",
                 InpHullM1_Threshold, InpHullM1_SlopeLB, g_hullSlopeDummy, _dummy);
   }
   if(InpHullM15_Enable)
      RunHullMTF(g_hullEngineM15, g_hullInitM15, g_hullValM15, g_hullTrdM15, g_hullBarM15, g_hullDirM15,
                 PERIOD_M1, InpHullM15_Period * 15, InpHullM15_Divisor,
                 InpHullM15_UpColor, InpHullM15_DnColor, InpHullM15_Width, "DLZ_HULLM15_",
                 InpHullM15_Threshold, InpHullM15_SlopeLB, g_hullSlopeM15, g_hullLastM15);

   // --- [NEW] PHASE 6: Process Higher Timeframe (MTF) ---
   if(InpEnableHTF && PeriodSeconds(InpHTF) > PeriodSeconds(Period())) 
   {
      int htf_bars = Bars(_Symbol, InpHTF);
      if(htf_bars > 300) htf_bars = 300; // ดึงข้อมูลจำกัดแค่ 500 แท่งเพื่อความเบาเครื่อง

      double h_htf[], l_htf[]; datetime t_htf[]; long v_htf[];
      ArraySetAsSeries(h_htf, false); ArraySetAsSeries(l_htf, false);
      ArraySetAsSeries(t_htf, false); ArraySetAsSeries(v_htf, false);

      // โหลดข้อมูลเฉพาะเมื่อเกิดแท่งเทียน HTF ใหม่ (เช่น ทุกๆ 15 นาที) หรือตอนเปิดกราฟครั้งแรก
      datetime curHTFTime = iTime(_Symbol, InpHTF, 0);
      if(curHTFTime != g_lastHTFBarTime || !g_htfInitialized) 
      {
         CopyHigh(_Symbol, InpHTF, 0, htf_bars, h_htf);
         CopyLow(_Symbol, InpHTF, 0, htf_bars, l_htf);
         CopyTime(_Symbol, InpHTF, 0, htf_bars, t_htf);
         if(InpVolType == Vol_Tick) CopyTickVolume(_Symbol, InpHTF, 0, htf_bars, v_htf);
         else CopyRealVolume(_Symbol, InpHTF, 0, htf_bars, v_htf);

         if(!g_htfInitialized) {
            // รันย้อนหลังตอนเปิดกราฟครั้งแรก
            for(int b = InpLeftLen + InpRightLen; b < htf_bars - 1; b++) {
               ProcessHTFConfirmBar(h_htf, l_htf, t_htf, v_htf, b, htf_bars);
            }
            g_htfInitialized = true;
         } else {
            // รันเฉพาะแท่ง HTF ล่าสุดที่เพิ่งจบไป
            ProcessHTFConfirmBar(h_htf, l_htf, t_htf, v_htf, htf_bars - 2, htf_bars);
         }
         g_lastHTFBarTime = curHTFTime;
      }

      // ตรวจสอบการโดนกวาด (Sweep) ของโซน M15 ด้วยไส้เทียนของ M1 (แท่งปัจจุบัน)
      UpdateHTFZones_SweepCheck(high[currentBarNS], low[currentBarNS], time[currentBarNS]);
   }
   DrawEMALines();
   DrawNRTrendMA();
   ChartRedraw(0);
   return rates_total;
}

//+------------------------------------------------------------------+
//|  EA: นับ Open Orders ฝั่ง Buy หรือ Sell                          |
//+------------------------------------------------------------------+
int CountOpenOrders(int orderType)
{
   int count = 0;
   for(int i = 0; i < PositionsTotal(); i++) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC)  == InpMagicNumber &&
            PositionGetInteger(POSITION_TYPE)   == orderType)
            count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//|  EA: แปลง USD เป็น Points                                        |
//+------------------------------------------------------------------+
bool ValidateTrade(double price, double sl, double tp)
{
   double minLevel = (SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) + 10) * _Point;
   if(MathAbs(price - sl) < minLevel) { Print("[ValidateTrade] SL too close: ", MathAbs(price-sl)/_Point, " pts < min ", minLevel/_Point); return false; }
   if(MathAbs(price - tp) < minLevel) { Print("[ValidateTrade] TP too close: ", MathAbs(price-tp)/_Point, " pts < min ", minLevel/_Point); return false; }
   double marginReq = SymbolInfoDouble(_Symbol, SYMBOL_MARGIN_INITIAL) * InpLot;
   if(marginReq > 0 && AccountInfoDouble(ACCOUNT_MARGIN_FREE) < marginReq)
   { Print("[ValidateTrade] Insufficient margin: free=$", AccountInfoDouble(ACCOUNT_MARGIN_FREE), " req=$", marginReq); return false; }
   return true;
}

//+------------------------------------------------------------------+
//|  CalcSLGap — คืนค่า SL price gap (distance) ตาม InpSL_Mode      |
//|  Mode 0: USD Fixed (InpSL_USD)                                   |
//|  Mode 1: Fibo 261.8% Extension จาก P26 (M1 swing) + buffer       |
//|          ต้องมากกว่า Mode 0 เสมอ (MathMax)                       |
//+------------------------------------------------------------------+
double CalcSLGap(double entryPrice, bool isBuy)
{
   double baseGap = USDtoPriceGap(InpSL_USD);   // floor เสมอ

   if(InpSL_Mode == 1 && gdx_swingCount >= 2)
   {
      GDX_SwingPoint s1 = gdx_swings[gdx_swingCount - 2];
      GDX_SwingPoint s2 = gdx_swings[gdx_swingCount - 1];
      double range = MathAbs(s2.price - s1.price);
      if(range > 0)
      {
         // 261.8% Extension: s2 เป็นจุดปลายขา
         // BUY  → SL ต่ำกว่า entry → ext ลงมาจาก s2 (ถ้า s2 เป็น Low) หรือ projection ลง
         // SELL → SL สูงกว่า entry → ext ขึ้นจาก s2
         double ext261;
         if(isBuy)
            ext261 = s2.price - range * 2.618;  // SL ใต้ 261.8% ext ฝั่ง down
         else
            ext261 = s2.price + range * 2.618;  // SL เหนือ 261.8% ext ฝั่ง up

         double bufGap   = USDtoPriceGap(InpSL_FiboBuffer);
         double fiboGap  = MathAbs(entryPrice - ext261) + bufGap;

         // Mode 1 ต้องมากกว่า Mode 0 เสมอ
         double resultGap = MathMax(fiboGap, baseGap);

         Print("[CalcSLGap] Mode1 | range:", DoubleToString(range,_Digits),
               " ext261:", DoubleToString(ext261,_Digits),
               " fiboGap:", DoubleToString(fiboGap/_Point,0), "pts",
               " baseGap:", DoubleToString(baseGap/_Point,0), "pts",
               " used:", DoubleToString(resultGap/_Point,0), "pts");
         return resultGap;
      }
   }
   return baseGap;
}

double USDtoPriceGap(double usd)
{
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickValue <= 0 || tickSize <= 0 || InpLot <= 0) return 0;

   // Price gap = (USD / Lot) / (tickValue / tickSize)
   // ตัวอย่าง XAUUSDm: (20 / 0.01) / (1.0 / 0.01) = 20.0
   double gap = (usd / InpLot) / (tickValue / tickSize);

   return MathAbs(gap);
}

// คืนค่า TP price สำหรับ BUY (ใต้ EQH zone ที่ใกล้ที่สุด) หรือ 0 ถ้าไม่มี zone
double FindZoneTP_Buy(double ask)
{
   double nearest = 0;
   for(int i = 0; i < ArraySize(g_zones); i++)
   {
      if(g_zones[i].isSwept) continue;
      if(!g_zones[i].isHigh) continue;
      if(g_zones[i].sweepLevel <= ask) continue;         // ต้องอยู่เหนือ ask
      if(nearest == 0 || g_zones[i].sweepLevel < nearest)
         nearest = g_zones[i].bottomPrice;               // ใช้ขอบล่างของ zone
   }
   if(nearest <= ask) return 0;
   double buffer = USDtoPriceGap(1.0);                   // buffer $1 ใต้ zone bottom
   return nearest - buffer;
}

// คืนค่า TP price สำหรับ SELL (เหนือ EQL zone ที่ใกล้ที่สุด) หรือ 0 ถ้าไม่มี zone
double FindZoneTP_Sell(double bid)
{
   double nearest = 0;
   for(int i = 0; i < ArraySize(g_zones); i++)
   {
      if(g_zones[i].isSwept) continue;
      if(g_zones[i].isHigh) continue;
      if(g_zones[i].sweepLevel >= bid) continue;         // ต้องอยู่ใต้ bid
      if(nearest == 0 || g_zones[i].sweepLevel > nearest)
         nearest = g_zones[i].topPrice;                  // ใช้ขอบบนของ zone
   }
   if(nearest >= bid || nearest <= 0) return 0;
   double buffer = USDtoPriceGap(1.0);                   // buffer $1 เหนือ zone top
   return nearest + buffer;
}

//+------------------------------------------------------------------+
//|  EA: CheckAndOpenOrder — เรียกทุกครั้งที่เกิด Zone ใหม่           |
//+------------------------------------------------------------------+
double GetAvgVolume(int period = 50)
{
   long vols[];
   ArraySetAsSeries(vols, true);
   if(InpVolType == Vol_Tick)
      CopyTickVolume(_Symbol, _Period, 0, period, vols);
   else
      CopyRealVolume(_Symbol, _Period, 0, period, vols);
   double sum = 0;
   for(int i = 0; i < period; i++) sum += (double)vols[i];
   return (period > 0) ? (sum / period) : 0;
}

void CheckAndOpenOrder(const LiquidityZone &z)
{
   if(IsNewsTime() || !CheckSessionAndExit()) return;
   SessionProfile prof = GetActiveProfile();
   if(!IsSpreadAllowed(prof.maxSpreadUSD)) return;

   // RVol filter — require significant zone volume before opening order
   if(InpRVolOrderMult > 0)
   {
      double avgVol = GetAvgVolume(InpRVolPeriod);
      if(avgVol > 0 && z.totalVol < avgVol * InpRVolOrderMult)
      {
         Print("[DLZ Order] Blocked: Zone Vol(", z.totalVol, ") < Avg×", InpRVolOrderMult, "(", avgVol * InpRVolOrderMult, ")");
         return;
      }
   }

   double tpGap = USDtoPriceGap(InpTP_USD);
   if(tpGap <= 0) return;

   long   stopsLvl   = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double minDistance = (stopsLvl + 50) * _Point;

   double priceBuf = USDtoPriceGap(InpPriceBuffer);

   if(!z.isHigh) {
      // --- EQL → BUY ---

      // ★ Filter 0: OFA p50 Master Bias — ด่านแรกสุด ห้ามข้าม
      bool p50Bull = (gdx_swingCount2 > 1 && gdx_swings2[gdx_swingCount2-1].isHigh);
      // Instant Flip: p50 Low Break หรือ HullBearForce → block BUY
      double _czAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      bool _czStructBreak  = (g_p50LastLow > 0 && _czAsk < g_p50LastLow);
      bool _czHullBearForce = (g_hullLastM15 > 0 && _czAsk < g_hullLastM15 && g_hullSlopeM15 < 0);
      if(!p50Bull || _czStructBreak) {
         Print("[DLZ Order] BUY blocked — Master Bias SELL/StructBreak");
         return;
      }
      if(_czHullBearForce) {
         Print("[DLZ Order] BUY blocked — Price < HullM15 slope▼ (Instant Flip B)");
         return;
      }

      g_eql_streak++;
      g_eqh_streak = 0;

      int openBuy = CountOpenOrders(POSITION_TYPE_BUY);
      bool canBuy = (openBuy < InpMaxBuy) ||
                    (openBuy == InpMaxBuy && g_eql_streak >= prof.eqlStreak);
      if(!canBuy) {
         Print("[DLZ Order] BUY blocked — OpenBuy:", openBuy, "/", InpMaxBuy,
               " EQL_streak:", g_eql_streak, "/", prof.eqlStreak, " Sp:$", DoubleToString(GetSpreadUSD(),3));
         return;
      }

      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      // Filter 1: Hull direction
      if(InpHullFilter && !(g_hullDirM15 == 1 && g_hullDirM1 == 1)) {
         Print("[DLZ Order] BUY blocked — Hull not aligned M15:", g_hullDirM15, " M1:", g_hullDirM1);
         return;
      }

      // Filter 2: Price must be below existing SELL entries
      if(InpPriceFilter) {
         double minSellEntry = 0;
         for(int i = 0; i < PositionsTotal(); i++) {
            ulong t = PositionGetTicket(i);
            if(!PositionSelectByTicket(t)) continue;
            if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
            if(PositionGetInteger(POSITION_MAGIC)  != InpMagicNumber) continue;
            if(PositionGetInteger(POSITION_TYPE)   != POSITION_TYPE_SELL) continue;
            double ep = PositionGetDouble(POSITION_PRICE_OPEN);
            if(minSellEntry == 0 || ep < minSellEntry) minSellEntry = ep;
         }
         if(minSellEntry > 0 && ask >= minSellEntry - priceBuf) {
            Print("[DLZ Order] BUY blocked — Ask:", ask, " >= minSellEntry:", minSellEntry, " - buf");
            return;
         }
      }

      // Filter 3: Gap to nearest EQH must not exceed InpMaxGapUSD
      if(InpGapFilter) {
         double nearEQH = 0;
         for(int i = 0; i < ArraySize(g_zones); i++) {
            if(g_zones[i].isSwept) continue;
            if(!g_zones[i].isHigh) continue;
            if(g_zones[i].sweepLevel <= ask) continue;
            if(nearEQH == 0 || g_zones[i].sweepLevel < nearEQH) nearEQH = g_zones[i].sweepLevel;
         }
         if(nearEQH > 0) {
            double gapUSD = (nearEQH - ask) / SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE)
                            * SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) * InpLot;
            if(gapUSD > InpMaxGapUSD) {
               Print("[DLZ Order] BUY blocked — Gap to EQH $", gapUSD, " > max $", InpMaxGapUSD);
               return;
            }
            // Filter 3b: Min Gap — block if too close to EQH (stop hunt risk)
            if(InpMinGapEntryFilter && gapUSD < InpMinEntryGapUSD) {
               Print("[DLZ Order] BUY blocked — Too close to EQH! Gap:$", DoubleToString(gapUSD,2), " < min $", DoubleToString(InpMinEntryGapUSD,2));
               return;
            }
         }
      }

      // Filter 4: EQL streak must not exceed InpMaxEQLStreak
      if(InpStreakFilter && g_eql_streak > InpMaxEQLStreak) {
         Print("[DLZ Order] BUY blocked — EQL streak:", g_eql_streak, " > max:", InpMaxEQLStreak);
         return;
      }

      double slGap   = CalcSLGap(ask, true);
      double fixedTP = ask + tpGap;
      double zoneTP  = FindZoneTP_Buy(ask);
      double tp      = (zoneTP > ask && zoneTP < fixedTP) ? zoneTP : fixedTP;
      double sl      = ask - slGap;
      if(MathAbs(tp - ask) < minDistance) tp = ask + minDistance;
      if(MathAbs(ask - sl) < minDistance) sl = ask - minDistance;
      tp = NormalizeDouble(tp, _Digits);
      sl = NormalizeDouble(sl, _Digits);
      if(InpEQL_ConfirmMaxBars > 0) {
         // Candle Confirmation mode — รอ rejection candle ก่อน
         ArrayResize(g_eqlPendingList, g_eqlPendingCount + 1);
         g_eqlPendingList[g_eqlPendingCount].topPrice    = z.topPrice;
         g_eqlPendingList[g_eqlPendingCount].bottomPrice = z.bottomPrice;
         g_eqlPendingList[g_eqlPendingCount].createdTime = TimeCurrent();
         g_eqlPendingList[g_eqlPendingCount].touched     = false;
         g_eqlPendingList[g_eqlPendingCount].barsWaited  = 0;
         g_eqlPendingCount++;
         Print("[DLZ Order] EQL Pending confirm — zone:", DoubleToString(z.topPrice,_Digits),
               "~", DoubleToString(z.bottomPrice,_Digits), " max:", InpEQL_ConfirmMaxBars, "bars");
      } else {
         // Instant mode (InpEQL_ConfirmMaxBars=0) — เปิดทันทีเหมือนเดิม
         string reason  = (openBuy == InpMaxBuy) ? "EQL_3RD_BUY" : "EQL_NORMAL";
         double _eqlFibo = GetSwingFiboPct(ask, false);
         string _eqlFiboStr = (_eqlFibo >= 0.0) ? StringFormat("%.1f%%", _eqlFibo) : "N/A";
         Print("[DLZ Order] BUY open | EQL:", g_eql_streak, " Fibo:", _eqlFiboStr,
               " ATR:$", DoubleToString(GetATR(),2),
               " Sp:$", DoubleToString(GetSpreadUSD(),3), " Ask:", DoubleToString(ask,_Digits));
         if(g_trade.Buy(InpLot, _Symbol, ask, sl, tp, "DLZ_BUY"))
            LogTradeOpen(g_trade.ResultOrder(), reason, ask);
      }
   }
   else {
      // --- EQH → SELL ---

      // ★ Filter 0: OFA p50 Master Bias — ด่านแรกสุด ห้ามข้าม
      bool p50BullS = (gdx_swingCount2 > 1 && gdx_swings2[gdx_swingCount2-1].isHigh);
      if(p50BullS) {
         bool p50Known = (gdx_swingCount2 > 1);
         Print("[DLZ Order] SELL blocked — OFA p50 Master Bias BULLISH (▲) | p50LastHigh=",
               p50Known ? (string)gdx_swings2[gdx_swingCount2-1].isHigh : "unknown");
         return;
      }

      g_eqh_streak++;
      g_eql_streak = 0;

      if(g_eqh_streak < prof.eqhStreak) {
         Print("[DLZ Signal] SELL wait — EQH streak:", g_eqh_streak, "/", prof.eqhStreak,
               " Sp:$", DoubleToString(GetSpreadUSD(),3));
         return;
      }

      int openSell = CountOpenOrders(POSITION_TYPE_SELL);
      if(openSell >= InpMaxSell) {
         Print("[DLZ Order] SELL blocked — OpenSell:", openSell, "/", InpMaxSell,
               " EQH_streak:", g_eqh_streak, " Sp:$", DoubleToString(GetSpreadUSD(),3));
         return;
      }

      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

      // Filter 1: Hull direction
      if(InpHullFilter && !(g_hullDirM15 == -1 && g_hullDirM1 == -1)) {
         Print("[DLZ Order] SELL blocked — Hull not aligned M15:", g_hullDirM15, " M1:", g_hullDirM1);
         return;
      }

      // Filter 2: Price must be above existing BUY entries
      if(InpPriceFilter) {
         double maxBuyEntry = 0;
         for(int i = 0; i < PositionsTotal(); i++) {
            ulong t = PositionGetTicket(i);
            if(!PositionSelectByTicket(t)) continue;
            if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
            if(PositionGetInteger(POSITION_MAGIC)  != InpMagicNumber) continue;
            if(PositionGetInteger(POSITION_TYPE)   != POSITION_TYPE_BUY) continue;
            double ep = PositionGetDouble(POSITION_PRICE_OPEN);
            if(ep > maxBuyEntry) maxBuyEntry = ep;
         }
         if(maxBuyEntry > 0 && bid <= maxBuyEntry + priceBuf) {
            Print("[DLZ Order] SELL blocked — Bid:", bid, " <= maxBuyEntry:", maxBuyEntry, " + buf");
            return;
         }
      }

      // Filter 3: Gap to nearest EQL must not exceed InpMaxGapUSD
      if(InpGapFilter) {
         double nearEQL = 0;
         for(int i = 0; i < ArraySize(g_zones); i++) {
            if(g_zones[i].isSwept) continue;
            if(g_zones[i].isHigh) continue;
            if(g_zones[i].sweepLevel >= bid) continue;
            if(nearEQL == 0 || g_zones[i].sweepLevel > nearEQL) nearEQL = g_zones[i].sweepLevel;
         }
         if(nearEQL > 0) {
            double gapUSD = (bid - nearEQL) / SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE)
                            * SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) * InpLot;
            if(gapUSD > InpMaxGapUSD) {
               Print("[DLZ Order] SELL blocked — Gap to EQL $", gapUSD, " > max $", InpMaxGapUSD);
               return;
            }
            // Filter 3b: Min Gap — block if too close to EQL (stop hunt risk)
            if(InpMinGapEntryFilter && gapUSD < InpMinEntryGapUSD) {
               Print("[DLZ Order] SELL blocked — Too close to EQL! Gap:$", DoubleToString(gapUSD,2), " < min $", DoubleToString(InpMinEntryGapUSD,2));
               return;
            }
         }
      }

      // Filter 4: EQH streak must not exceed InpMaxEQHStreak
      if(InpStreakFilter && g_eqh_streak > InpMaxEQHStreak) {
         Print("[DLZ Order] SELL blocked — EQH streak:", g_eqh_streak, " > max:", InpMaxEQHStreak);
         return;
      }

      double slGap   = CalcSLGap(bid, false);
      double fixedTP = bid - tpGap;
      double zoneTP  = FindZoneTP_Sell(bid);
      double tp      = (zoneTP < bid && zoneTP > fixedTP) ? zoneTP : fixedTP;
      double sl      = bid + slGap;
      if(MathAbs(bid - tp) < minDistance) tp = bid - minDistance;
      if(MathAbs(sl - bid) < minDistance) sl = bid + minDistance;
      tp = NormalizeDouble(tp, _Digits);
      sl = NormalizeDouble(sl, _Digits);
      if(InpEQH_ConfirmMaxBars > 0) {
         // Candle Confirmation mode — รอ rejection candle ก่อน
         ArrayResize(g_eqhPendingList, g_eqhPendingCount + 1);
         g_eqhPendingList[g_eqhPendingCount].topPrice    = z.topPrice;
         g_eqhPendingList[g_eqhPendingCount].bottomPrice = z.bottomPrice;
         g_eqhPendingList[g_eqhPendingCount].createdTime = TimeCurrent();
         g_eqhPendingList[g_eqhPendingCount].touched     = false;
         g_eqhPendingList[g_eqhPendingCount].barsWaited  = 0;
         g_eqhPendingCount++;
         Print("[DLZ Order] EQH Pending confirm — zone:", DoubleToString(z.topPrice,_Digits),
               "~", DoubleToString(z.bottomPrice,_Digits), " max:", InpEQH_ConfirmMaxBars, "bars");
      } else {
         // Instant mode (InpEQH_ConfirmMaxBars=0) — เปิดทันทีเหมือนเดิม
         double _eqhFibo = GetSwingFiboPct(bid, true);
         string _eqhFiboStr = (_eqhFibo >= 0.0) ? StringFormat("%.1f%%", _eqhFibo) : "N/A";
         Print("[DLZ Order] SELL open | EQH:", g_eqh_streak, " Fibo:", _eqhFiboStr,
               " ATR:$", DoubleToString(GetATR(),2),
               " Sp:$", DoubleToString(GetSpreadUSD(),3), " Bid:", DoubleToString(bid,_Digits));
         if(g_trade.Sell(InpLot, _Symbol, bid, sl, tp, "DLZ_SELL"))
            LogTradeOpen(g_trade.ResultOrder(), "EQH_STREAK", bid);
      }
   }
}

//+------------------------------------------------------------------+
//|  EA: CheckHullFollowEntry — เข้า order เมื่อ M1 หรือ M15 เปลี่ยนทิศ  |
//+------------------------------------------------------------------+
void CheckHullFollowEntry()
{
   if(g_hullDirM1 == 0 || g_hullDirM15 == 0) return;

   bool m1Flipped  = (g_prevHullDirM1  != 0 && g_prevHullDirM1  != g_hullDirM1);
   bool m15Flipped = (g_prevHullDirM15 != 0 && g_prevHullDirM15 != g_hullDirM15);
   if(!m1Flipped && !m15Flipped) return; // ไม่มีการเปลี่ยนทิศใดเลย

   if(IsNewsTime() || !CheckSessionAndExit()) return;
   SessionProfile prof = GetActiveProfile();
   if(!IsSpreadAllowed(prof.maxSpreadUSD)) return;

   double tpGap = USDtoPriceGap(InpTP_USD);
   if(tpGap <= 0) return;

   long   stopsLvl   = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double minDistance = (stopsLvl + 50) * _Point;

   double ask     = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid     = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double proxPts = prof.zoneProximityPts * _Point;

   // OFA p50 Master Bias
   bool hfe_p50Bull = (gdx_swingCount2 > 1 && gdx_swings2[gdx_swingCount2-1].isHigh);
   // Instant Flip guards (ใช้ร่วมกับ HFE BUY)
   bool hfe_structBreak   = (g_p50LastLow > 0 && ask < g_p50LastLow);
   bool hfe_hullBearForce = (g_hullLastM15 > 0 && ask < g_hullLastM15 && g_hullSlopeM15 < 0);
   bool hfe_buyAllowed    = hfe_p50Bull && !hfe_structBreak && !hfe_hullBearForce;

   // ── BUY ──────────────────────────────────────────────────────────
   // Trigger A: M1 เพิ่งเปลี่ยน DN→UP และ M15=UP
   // Trigger B: M15 เพิ่งเปลี่ยน DN→UP และ M1=UP
   bool buyM1  = hfe_buyAllowed && (m1Flipped  && g_prevHullDirM1  == -1 && g_hullDirM1  == 1 && g_hullDirM15 == 1);
   bool buyM15 = hfe_buyAllowed && (m15Flipped && g_prevHullDirM15 == -1 && g_hullDirM15 == 1 && g_hullDirM1  == 1);

   if(buyM1 || buyM15)
   {
      string triggerTag = buyM15 ? "M15FLIP" : "M1FLIP";
      bool buyOK = true;
      if(InpFiboFilter && gdx_swingCount > 1) {
         GDX_SwingPoint s1 = gdx_swings[gdx_swingCount-2];
         GDX_SwingPoint s2 = gdx_swings[gdx_swingCount-1];
         double range = MathAbs(s1.price - s2.price);
         if(range > 0) {
            double retrace = (MathAbs(ask - s2.price) / range) * 100.0;
            if(retrace > prof.fiboMaxPct) {
               Print("[DLZ HFE|", triggerTag, "] BUY Blocked — Fibo:", DoubleToString(retrace,1), "% Max:", DoubleToString(prof.fiboMaxPct,0),
                     "% Sp:$", DoubleToString(GetSpreadUSD(),3), " ATR:$", DoubleToString(GetATR(),2));
               buyOK = false;
            } else {
               Print("[DLZ HFE|", triggerTag, "] BUY Fibo OK — Fibo:", DoubleToString(retrace,1), "% Max:", DoubleToString(prof.fiboMaxPct,0), "%");
            }
         }
      }
      if(buyOK && CountOpenOrders(POSITION_TYPE_BUY) >= InpMaxBuy) buyOK = false;
      if(buyOK) {
         bool nearEQL = false;
         double nearEQLDist = -1;
         for(int i = 0; i < ArraySize(g_zones); i++) {
            if(g_zones[i].isSwept || g_zones[i].isHigh) continue;
            double dist = MathAbs(ask - g_zones[i].sweepLevel);
            if(nearEQLDist < 0 || dist / _Point < nearEQLDist) nearEQLDist = dist / _Point;
            if(dist <= proxPts) { nearEQL = true; break; }
         }
         if(!nearEQL) {
            string distInfo = (nearEQLDist >= 0) ? StringFormat("%.0f", nearEQLDist) : "N/A (no EQL zone)";
            Print(StringFormat("[DLZ HFE|%s] BUY skipped — no EQL zone within %d pts (Nearest: %s pts) Sp:$%.3f",
                  triggerTag, prof.zoneProximityPts, distInfo, GetSpreadUSD()));
            buyOK = false;
         }
         if(buyOK) {
            // Min Gap filter — block HFE BUY if too close to nearest EQH
            if(InpMinGapEntryFilter) {
               double nearHFE_EQH = 0;
               for(int i = 0; i < ArraySize(g_zones); i++) {
                  if(g_zones[i].isSwept || !g_zones[i].isHigh) continue;
                  if(g_zones[i].sweepLevel > ask) {
                     if(nearHFE_EQH == 0 || g_zones[i].sweepLevel < nearHFE_EQH) nearHFE_EQH = g_zones[i].sweepLevel;
                  }
               }
               if(nearHFE_EQH > 0) {
                  double hfeGapUSD = (nearHFE_EQH - ask) / SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE)
                                     * SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) * InpLot;
                  if(hfeGapUSD < InpMinEntryGapUSD) {
                     Print("[DLZ HFE|", triggerTag, "] BUY blocked — Too close to EQH! Gap:$", DoubleToString(hfeGapUSD,2), " < min $", DoubleToString(InpMinEntryGapUSD,2));
                     buyOK = false;
                  }
               }
            }
            if(buyOK) {
               double slGap   = CalcSLGap(ask, true);
               double fixedTP = ask + tpGap;
               double zoneTP  = FindZoneTP_Buy(ask);
               double tp      = (zoneTP > ask && zoneTP < fixedTP) ? zoneTP : fixedTP;
               double sl      = ask - slGap;
               if(MathAbs(tp - ask) < minDistance) tp = ask + minDistance;
               if(MathAbs(ask - sl) < minDistance) sl = ask - minDistance;
               tp = NormalizeDouble(tp, _Digits);
               sl = NormalizeDouble(sl, _Digits);
               Print("[DLZ Order] HFE|", triggerTag, " BUY open | EQL_dist:", DoubleToString(nearEQLDist,1), "pts ATR:$", DoubleToString(GetATR(),2),
                     " Sp:$", DoubleToString(GetSpreadUSD(),3), " Ask:", DoubleToString(ask,_Digits));
               if(g_trade.Buy(InpLot, _Symbol, ask, sl, tp, "DLZ_HFE_BUY"))
                  LogTradeOpen(g_trade.ResultOrder(), "HFE_BUY|"+triggerTag, ask);
            }
         }
      }
   }

   // ── SELL check (runs regardless of BUY result) ──
   // ── SELL ─────────────────────────────────────────────────────────
   // Trigger A: M1 เพิ่งเปลี่ยน UP→DN และ M15=DN
   // Trigger B: M15 เพิ่งเปลี่ยน UP→DN และ M1=DN
   bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   bool sellM1  = !hfe_p50Bull && (m1Flipped  && g_prevHullDirM1  == 1 && g_hullDirM1  == -1 && g_hullDirM15 == -1);
   bool sellM15 = !hfe_p50Bull && (m15Flipped && g_prevHullDirM15 == 1 && g_hullDirM15 == -1 && g_hullDirM1  == -1);

   if(sellM1 || sellM15)
   {
      string triggerTag = sellM15 ? "M15FLIP" : "M1FLIP";
      if(InpFiboFilter && gdx_swingCount > 1) {
         GDX_SwingPoint s1 = gdx_swings[gdx_swingCount-2];
         GDX_SwingPoint s2 = gdx_swings[gdx_swingCount-1];
         double range = MathAbs(s1.price - s2.price);
         if(range > 0) {
            double retrace = (MathAbs(bid - s2.price) / range) * 100.0;
            if(retrace > prof.fiboMaxPct) {
               Print("[DLZ HFE|", triggerTag, "] SELL Blocked — Fibo:", DoubleToString(retrace,1), "% Max:", DoubleToString(prof.fiboMaxPct,0),
                     "% Sp:$", DoubleToString(GetSpreadUSD(),3), " ATR:$", DoubleToString(GetATR(),2));
               return;
            } else {
               Print("[DLZ HFE|", triggerTag, "] SELL Fibo OK — Fibo:", DoubleToString(retrace,1), "% Max:", DoubleToString(prof.fiboMaxPct,0), "%");
            }
         }
      }
      if(CountOpenOrders(POSITION_TYPE_SELL) >= InpMaxSell) return;
      bool nearEQH = false;
      double nearEQHDist = -1;
      for(int i = 0; i < ArraySize(g_zones); i++) {
         if(g_zones[i].isSwept || !g_zones[i].isHigh) continue;
         double dist = MathAbs(bid - g_zones[i].sweepLevel);
         if(dist <= proxPts) { nearEQH = true; nearEQHDist = dist / _Point; break; }
      }
      if(!nearEQH) {
         Print("[DLZ HFE|", triggerTag, "] SELL skipped — no EQH zone within ", prof.zoneProximityPts, " pts Sp:$", DoubleToString(GetSpreadUSD(),3));
         return;
      }
      // Min Gap filter — block HFE SELL if too close to nearest EQL
      if(InpMinGapEntryFilter) {
         double nearHFE_EQL = 0;
         for(int i = 0; i < ArraySize(g_zones); i++) {
            if(g_zones[i].isSwept || g_zones[i].isHigh) continue;
            if(g_zones[i].sweepLevel < bid) {
               if(nearHFE_EQL == 0 || g_zones[i].sweepLevel > nearHFE_EQL) nearHFE_EQL = g_zones[i].sweepLevel;
            }
         }
         if(nearHFE_EQL > 0) {
            double hfeGapUSD = (bid - nearHFE_EQL) / _Point * SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE)
                               * SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE) * InpLot;
            if(hfeGapUSD < InpMinEntryGapUSD) {
               Print("[DLZ HFE|", triggerTag, "] SELL blocked — Too close to EQL! Gap:$", DoubleToString(hfeGapUSD,2), " < min $", DoubleToString(InpMinEntryGapUSD,2));
               return;
            }
         }
      }
      double slGap   = CalcSLGap(bid, false);
      double fixedTP = bid - tpGap;
      double zoneTP  = FindZoneTP_Sell(bid);
      double tp      = (zoneTP < bid && zoneTP > fixedTP) ? zoneTP : fixedTP;
      double sl      = bid + slGap;
      if(MathAbs(bid - tp) < minDistance) tp = bid - minDistance;
      if(MathAbs(sl - bid) < minDistance) sl = bid + minDistance;
      tp = NormalizeDouble(tp, _Digits);
      sl = NormalizeDouble(sl, _Digits);
      Print("[DLZ Order] HFE|", triggerTag, " SELL open | EQH_dist:", DoubleToString(nearEQHDist,1), "pts ATR:$", DoubleToString(GetATR(),2),
            " Sp:$", DoubleToString(GetSpreadUSD(),3), " Bid:", DoubleToString(bid,_Digits));
      if(g_trade.Sell(InpLot, _Symbol, bid, sl, tp, "DLZ_HFE_SELL"))
         LogTradeOpen(g_trade.ResultOrder(), "HFE_SELL|"+triggerTag, bid);
   }
}

//+------------------------------------------------------------------+
//|  EA: CheckClusterZoneFastEntry — 2x EQL/EQH + Fast Reversal     |
//+------------------------------------------------------------------+
void CheckClusterZoneFastEntry()
{
   if(!InpClusterEntry || !InpEA_Enable || !g_isLive) return;
   if(IsNewsTime() || !CheckSessionAndExit()) return;
   SessionProfile prof = GetActiveProfile();
   if(!IsSpreadAllowed(prof.maxSpreadUSD)) return;

   double prevLow   = iLow (_Symbol, _Period, 1);
   double prevHigh  = iHigh(_Symbol, _Period, 1);
   double prevClose = iClose(_Symbol, _Period, 1);
   double clusterRange = InpClusterRangePts * _Point;
   double tpGap     = USDtoPriceGap(InpTP_USD);
   if(tpGap <= 0) return;
   long   stopsLvl  = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double minDist   = (stopsLvl + 50) * _Point;

   bool p50Bull = (gdx_swingCount2 > 1 && gdx_swings2[gdx_swingCount2-1].isHigh);

   // === EQL Cluster → BUY ===
   if(p50Bull && CountOpenOrders(POSITION_TYPE_BUY) < InpMaxBuy)
   {
      for(int i = 0; i < ArraySize(g_zones); i++)
      {
         if(g_zones[i].isSwept || g_zones[i].isHigh) continue;

         double zTop = g_zones[i].topPrice;
         double zBot = g_zones[i].bottomPrice;

         // Fast Reversal: prevLow แตะ zone แต่ close กลับขึ้นเหนือ zone top
         if(prevLow  > zTop)  continue; // ไม่แตะ zone
         if(prevLow  < zBot)  continue; // ทะลุ sweep แล้ว
         if(prevClose <= zTop) continue; // ไม่ reverse กลับขึ้น

         // นับ cluster
         int cnt = 0;
         for(int j = 0; j < ArraySize(g_zones); j++) {
            if(g_zones[j].isSwept || g_zones[j].isHigh) continue;
            if(MathAbs(g_zones[j].sweepLevel - g_zones[i].sweepLevel) <= clusterRange) cnt++;
         }
         if(cnt < InpClusterMinCount) continue;

         // Zone matched — log ถ้า p50 block (ถึงตรงนี้แปลว่า p50Bull=true แล้ว แต่ใส่ไว้เพื่อ debug symmetry)
         // Hull M15 filter (ไม่บังคับ M1 เพราะเป็น fast reversal)
         if(InpHullFilter && g_hullDirM15 != 1) {
            Print("[DLZ Cluster] BUY blocked — M15 Hull:", g_hullDirM15);
            break;
         }

         // Fibo filter
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         if(InpFiboFilter && gdx_swingCount > 1) {
            GDX_SwingPoint s1 = gdx_swings[gdx_swingCount-2];
            GDX_SwingPoint s2 = gdx_swings[gdx_swingCount-1];
            double range = MathAbs(s1.price - s2.price);
            if(range > 0) {
               double retrace = (MathAbs(ask - s2.price) / range) * 100.0;
               if(retrace > prof.fiboMaxPct) {
                  Print("[DLZ Cluster] BUY blocked — Fibo:", DoubleToString(retrace,1), "%");
                  break;
               }
            }
         }

         // SL/TP เงื่อนไขกลาง (เหมือน CheckAndOpenOrder)
         double slGap  = CalcSLGap(ask, true);
         double fixedTP = ask + tpGap;
         double zoneTP  = FindZoneTP_Buy(ask);
         double tp = (zoneTP > ask && zoneTP < fixedTP) ? zoneTP : fixedTP;
         double sl = ask - slGap;
         if(MathAbs(tp  - ask) < minDist) tp = ask + minDist;
         if(MathAbs(ask - sl)  < minDist) sl = ask - minDist;
         tp = NormalizeDouble(tp, _Digits);
         sl = NormalizeDouble(sl, _Digits);

         Print("[DLZ Cluster] BUY x", cnt, " EQL:", DoubleToString(zTop,_Digits),
               " Low:", DoubleToString(prevLow,_Digits),
               " Close:", DoubleToString(prevClose,_Digits),
               " Sp:$", DoubleToString(GetSpreadUSD(),3));
         if(ValidateTrade(ask, sl, tp) && g_trade.Buy(InpLot, _Symbol, ask, sl, tp, "DLZ_CLUSTER_BUY"))
            LogTradeOpen(g_trade.ResultOrder(), "CLUSTER_BUY_x"+IntegerToString(cnt), ask);
         break;
      }
   }

   // === EQH Cluster → SELL ===
   if(!p50Bull && CountOpenOrders(POSITION_TYPE_SELL) < InpMaxSell)
   {
      for(int i = 0; i < ArraySize(g_zones); i++)
      {
         if(g_zones[i].isSwept || !g_zones[i].isHigh) continue;

         double zTop = g_zones[i].topPrice;
         double zBot = g_zones[i].bottomPrice;

         // Fast Reversal: prevHigh แตะ zone แต่ close กลับลงใต้ zone bottom
         if(prevHigh  < zBot)  continue; // ไม่แตะ zone
         if(prevHigh  > zTop)  continue; // ทะลุ sweep แล้ว
         if(prevClose >= zBot) continue; // ไม่ reverse กลับลง

         // นับ cluster
         int cnt = 0;
         for(int j = 0; j < ArraySize(g_zones); j++) {
            if(g_zones[j].isSwept || !g_zones[j].isHigh) continue;
            if(MathAbs(g_zones[j].sweepLevel - g_zones[i].sweepLevel) <= clusterRange) cnt++;
         }
         if(cnt < InpClusterMinCount) continue;

         // Hull M15 filter
         if(InpHullFilter && g_hullDirM15 != -1) {
            Print("[DLZ Cluster] SELL blocked — M15 Hull:", g_hullDirM15);
            break;
         }

         // Hull M1 filter
         if(InpHullFilter && g_hullDirM1 != -1) {
            Print("[DLZ Cluster] SELL blocked — M1 Hull:", g_hullDirM1);
            break;
         }

         // Fibo filter
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         if(InpFiboFilter && gdx_swingCount > 1) {
            GDX_SwingPoint s1 = gdx_swings[gdx_swingCount-2];
            GDX_SwingPoint s2 = gdx_swings[gdx_swingCount-1];
            double range = MathAbs(s1.price - s2.price);
            if(range > 0) {
               double retrace = (MathAbs(bid - s2.price) / range) * 100.0;
               if(retrace > prof.fiboMaxPct) {
                  Print("[DLZ Cluster] SELL blocked — Fibo:", DoubleToString(retrace,1), "%");
                  break;
               }
            }
         }

         // SL/TP เงื่อนไขกลาง
         double slGap  = CalcSLGap(bid, false);
         double fixedTP = bid - tpGap;
         double zoneTP  = FindZoneTP_Sell(bid);
         double tp = (zoneTP < bid && zoneTP > fixedTP) ? zoneTP : fixedTP;
         double sl = bid + slGap;
         if(MathAbs(bid - tp) < minDist) tp = bid - minDist;
         if(MathAbs(sl  - bid) < minDist) sl = bid + minDist;
         tp = NormalizeDouble(tp, _Digits);
         sl = NormalizeDouble(sl, _Digits);

         Print("[DLZ Cluster] SELL x", cnt, " EQH:", DoubleToString(zBot,_Digits),
               " High:", DoubleToString(prevHigh,_Digits),
               " Close:", DoubleToString(prevClose,_Digits),
               " Sp:$", DoubleToString(GetSpreadUSD(),3));
         if(ValidateTrade(bid, sl, tp) && g_trade.Sell(InpLot, _Symbol, bid, sl, tp, "DLZ_CLUSTER_SELL"))
            LogTradeOpen(g_trade.ResultOrder(), "CLUSTER_SELL_x"+IntegerToString(cnt), bid);
         break;
      }
   }
}

//+------------------------------------------------------------------+
//|  Auto Pending Order Management                                   |
//+------------------------------------------------------------------+
void ManageAutoPending()
{
   if(!InpAutoPending || !InpEA_Enable) return;

   // Spam Guard — พิมพ์ Log ซ้ำได้ไม่เร็วกว่า 60 วินาที
   static datetime lastSpamTime = 0;
   bool canPrint = (TimeCurrent() - lastSpamTime > 60);

   if(g_poiPrice <= 0 || g_targetPrice <= 0) {
      if(g_pendingTicket > 0) {
         if(OrderSelect(g_pendingTicket) &&
            (ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE) == ORDER_STATE_PLACED)
            { if(!g_trade.OrderDelete(g_pendingTicket)) Print("Cancel Failed: ", g_trade.ResultRetcodeDescription()); }
         g_pendingTicket = 0; g_pendingPOI = 0;
      }
      return;
   }

   // --- Distance Filter: ห้ามวาง Pending ใกล้ Position หรือ Pending เดิม ---
   double minDist = InpMinOrderDistancePts * _Point;

   // 1. เช็ค Positions ที่เปิดอยู่
   for(int i = 0; i < PositionsTotal(); i++) {
      ulong t = PositionGetTicket(i);
      if(!PositionSelectByTicket(t)) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(MathAbs(PositionGetDouble(POSITION_PRICE_OPEN) - g_poiPrice) < minDist) {
         if(g_pendingTicket > 0) {
            if(OrderSelect(g_pendingTicket) &&
               (ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE) == ORDER_STATE_PLACED)
               g_trade.OrderDelete(g_pendingTicket);
            g_pendingTicket = 0; g_pendingPOI = 0;
         }
         if(canPrint) {
            Print("[DLZ Pending] Skip — open position near POI ", DoubleToString(g_poiPrice, _Digits),
                  " dist<", InpMinOrderDistancePts, "pts");
            lastSpamTime = TimeCurrent();
         }
         return;
      }
   }

   // 2. เช็ค Pending Orders อื่นๆ (ไม่ใช่ ticket ของเราเอง)
   for(int i = 0; i < OrdersTotal(); i++) {
      ulong t = OrderGetTicket(i);
      if(!OrderSelect(t)) continue;
      if(OrderGetInteger(ORDER_MAGIC) != InpMagicNumber) continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol) continue;
      if(t == g_pendingTicket) continue;
      if(MathAbs(OrderGetDouble(ORDER_PRICE_OPEN) - g_poiPrice) < minDist) {
         if(canPrint) {
            Print("[DLZ Pending] Blocked — another pending near POI ", DoubleToString(g_poiPrice, _Digits));
            lastSpamTime = TimeCurrent();
         }
         return;
      }
   }

   // ตรวจว่า pending ticket ยังมีอยู่จริงไหม
   bool ticketAlive = false;
   if(g_pendingTicket > 0) {
      for(int i = 0; i < OrdersTotal(); i++) {
         ulong t = OrderGetTicket(i);
         if(t == g_pendingTicket && OrderGetString(ORDER_SYMBOL) == _Symbol) { ticketAlive = true; break; }
      }
      if(!ticketAlive) { g_pendingTicket = 0; g_pendingPOI = 0; }
   }

   // ตรวจว่าต้อง re-place ไหม
   if(ticketAlive) {
      bool biasFlipped = (g_pendingIsBull != g_isBullStructure);
      double drift     = MathAbs(g_poiPrice - g_pendingPOI) / _Point;
      bool poiMoved    = (drift > InpPendingDriftPts);
      if(biasFlipped || poiMoved) {
         if(OrderSelect(g_pendingTicket) &&
            (ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE) == ORDER_STATE_PLACED)
            { if(!g_trade.OrderDelete(g_pendingTicket)) Print("Cancel Failed: ", g_trade.ResultRetcodeDescription()); }
         g_pendingTicket = 0; g_pendingPOI = 0;
         ticketAlive = false;
      }
   }

   if(ticketAlive) return; // pending ยังดีอยู่ ไม่ต้องวางใหม่

   // --- StopLevel check + SL calc ---
   double ask      = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid      = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   long   slvPts   = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double stopDist = slvPts * _Point;
   double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSz   = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickSz <= 0) return;
   double slDist   = (InpPendingSL_USD / (InpLot * tickVal / tickSz)) * _Point;

   double entryPrice = NormalizeDouble(g_poiPrice,    _Digits);
   double tpPrice    = NormalizeDouble(g_targetPrice, _Digits);
   double slPrice    = 0;

   // Instant Flip guard — ห้ามวาง BuyLimit เมื่อ structBreak หรือ hullBearForce
   bool pend_structBreak   = (g_p50LastLow > 0 && ask < g_p50LastLow);
   bool pend_hullBearForce = (g_hullLastM15 > 0 && ask < g_hullLastM15 && g_hullSlopeM15 < 0);

   if(g_isBullStructure) {
      if(pend_structBreak || pend_hullBearForce) return;
      if(entryPrice >= ask - stopDist) return;
      slPrice = NormalizeDouble(entryPrice - slDist, _Digits);
      if(tpPrice <= entryPrice + stopDist) return;
      if(slPrice >= entryPrice - stopDist) return;
      if(g_trade.BuyLimit(InpLot, entryPrice, _Symbol, slPrice, tpPrice, ORDER_TIME_GTC, 0, "DLZ_PEND_BUY")) {
         g_pendingTicket = g_trade.ResultOrder();
         g_pendingPOI    = entryPrice;
         g_pendingIsBull = true;
      }
   } else {
      if(entryPrice <= bid + stopDist) return;
      slPrice = NormalizeDouble(entryPrice + slDist, _Digits);
      if(tpPrice >= entryPrice - stopDist) return;
      if(slPrice <= entryPrice + stopDist) return;
      if(g_trade.SellLimit(InpLot, entryPrice, _Symbol, slPrice, tpPrice, ORDER_TIME_GTC, 0, "DLZ_PEND_SELL")) {
         g_pendingTicket = g_trade.ResultOrder();
         g_pendingPOI    = entryPrice;
         g_pendingIsBull = false;
      }
   }
}

//+------------------------------------------------------------------+
//| Layer 1: Bias Score — โครงสร้างตลาดเชิง Macro (0-100)           |
//+------------------------------------------------------------------+
int GetBiasScore(bool isBuy)
{
   int score = 0;
   bool p50Bull = (gdx_swingCount2 > 1 && gdx_swings2[gdx_swingCount2-1].isHigh);
   int  dxy     = GetDXYTrendDirection();

   // p50 Master Bias — 40 pts (gate ที่สำคัญสุด)
   if( isBuy && p50Bull)  score += 40;
   if(!isBuy && !p50Bull) score += 40;

   // Hull M15 Trend Align — 35 pts
   if( isBuy && g_hullDirM15 == 1)  score += 35;
   if(!isBuy && g_hullDirM15 == -1) score += 35;

   // DXY Correlation — 25 pts
   if( isBuy && dxy == -1) score += 25;
   if(!isBuy && dxy ==  1) score += 25;

   // Penalty: p50 ขัดทิศทาง → hard block (ลบทั้งหมดออก)
   if( isBuy && !p50Bull) score = 0;
   if(!isBuy &&  p50Bull) score = 0;

   // Penalty: Hull M15 ขัดทิศทาง
   if( isBuy && g_hullDirM15 == -1) score = MathMax(0, score - 30);
   if(!isBuy && g_hullDirM15 ==  1) score = MathMax(0, score - 30);

   return MathMin(100, score);
}

//+------------------------------------------------------------------+
//| Layer 2: Setup Quality Score (0-100)                             |
//| วัดว่า setup ดีแค่ไหน — sweep decay, zone distance, R:R, M1     |
//+------------------------------------------------------------------+
int GetSetupScore(bool isBuy)
{
   int score = 0;
   double curPrice  = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double tickVal   = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   // A. Sweep Decay — max 30 pts (ยิ่งสด ยิ่งดี)
   bool sweepEQH = (StringFind(g_lastSweptMsg, "EQH") >= 0 && g_lastSweptMsg != "-");
   bool sweepEQL = (StringFind(g_lastSweptMsg, "EQL") >= 0 && g_lastSweptMsg != "-");
   bool sweepMatch = (!isBuy && sweepEQH) || (isBuy && sweepEQL);
   if(sweepMatch && g_lastSweptTime > 0) {
      int sweepBars = (int)((TimeCurrent() - g_lastSweptTime) / PeriodSeconds(_Period));
      if(sweepBars <= 3)       score += 30;
      else if(sweepBars <= 8)  score += 15;
      // เกิน 8 bars = 0 (sweep เก่าเกินไป)
   }

   // B. Hull M1 Momentum Align — 20 pts
   if( isBuy && g_hullDirM1 == 1)  score += 20;
   if(!isBuy && g_hullDirM1 == -1) score += 20;

   // C. Distance to nearest Zone (POI) — 25 pts
   // ยิ่งใกล้ EQL (BUY) หรือ EQH (SELL) ยิ่งดี
   double nearZonePts = -1;
   for(int i = 0; i < ArraySize(g_zones); i++) {
      if(g_zones[i].isSwept) continue;
      bool isTarget = isBuy ? !g_zones[i].isHigh : g_zones[i].isHigh;
      if(!isTarget) continue;
      double dist = MathAbs(curPrice - g_zones[i].sweepLevel) / _Point;
      if(nearZonePts < 0 || dist < nearZonePts) nearZonePts = dist;
   }
   if(nearZonePts >= 0) {
      if(nearZonePts <= 100)       score += 25; // ใกล้มาก
      else if(nearZonePts <= 300)  score += 15; // ใกล้พอ
      else if(nearZonePts <= 600)  score += 5;  // ยังพอไหว
      // เกิน 600 pts = 0
   }

   // D. R:R Check — 25 pts (ต้องมี target)
   if(g_targetPrice > 0 && InpSL_USD > 0 && tickSize > 0 && tickVal > 0) {
      double gapUSD = MathAbs(g_targetPrice - curPrice) / tickSize * tickVal;
      double rr     = gapUSD / InpSL_USD;
      if(rr >= 3.0)       score += 25;
      else if(rr >= 2.0)  score += 15;
      else if(rr >= 1.0)  score += 5;
   }

   return MathMin(100, score);
}

//+------------------------------------------------------------------+
//| Layer 3: Entry Block Reason — ตรวจ hard filters ของ EA จริง      |
//| คืน "" = ผ่านทุก filter / คืน string = block เหตุผลนั้น          |
//+------------------------------------------------------------------+
string GetEntryBlockReason(bool isBuy)
{
   // 1. News filter
   if(IsNewsTime()) return "NEWS BLOCK";

   // 2. Session / Daily exit
   MqlDateTime dt; TimeCurrent(dt);
   if(InpFridayExit && dt.day_of_week == 5 && dt.hour >= InpFridayExitHour)
      return "FRIDAY EXIT";
   if(InpDailyExit && dt.hour >= InpDailyExitHour)
      return "DAILY EXIT";

   // 3. Spread
   SessionProfile prof = GetActiveProfile();
   if(prof.maxSpreadUSD > 0 && GetSpreadUSD() > prof.maxSpreadUSD)
      return StringFormat("SPREAD $%.3f > $%.2f", GetSpreadUSD(), prof.maxSpreadUSD);

   // 4. Max orders
   if( isBuy && CountOpenOrders(POSITION_TYPE_BUY)  >= InpMaxBuy)
      return StringFormat("MAX BUY %d/%d", CountOpenOrders(POSITION_TYPE_BUY), InpMaxBuy);
   if(!isBuy && CountOpenOrders(POSITION_TYPE_SELL) >= InpMaxSell)
      return StringFormat("MAX SELL %d/%d", CountOpenOrders(POSITION_TYPE_SELL), InpMaxSell);

   // 5. Fibo filter (p26 swing)
   double curPrice = isBuy ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(InpFiboFilter && gdx_swingCount > 1) {
      double _fibo = GetSwingFiboPct(curPrice, !isBuy);
      SessionProfile sp = GetActiveProfile();
      if(_fibo >= 0.0 && _fibo > sp.fiboMaxPct)
         return StringFormat("FIBO %.1f%% > MAX %.0f%%", _fibo, sp.fiboMaxPct);
      if(!isBuy && _fibo >= 0.0 && _fibo < 38.2)
         return StringFormat("FIBO %.1f%% < 38.2%% (not premium)", _fibo);
   }

   // 6. Hull M15 direction (hard block ถ้า enabled)
   if(InpHullFilter) {
      if( isBuy && g_hullDirM15 != 1)  return StringFormat("HULL M15 %s (need UP)",  g_hullDirM15==-1?"DN":"--");
      if(!isBuy && g_hullDirM15 != -1) return StringFormat("HULL M15 %s (need DN)",  g_hullDirM15==1?"UP":"--");
      if( isBuy && g_hullDirM1  != 1)  return StringFormat("HULL M1 %s (need UP)",   g_hullDirM1==-1?"DN":"--");
      if(!isBuy && g_hullDirM1  != -1) return StringFormat("HULL M1 %s (need DN)",   g_hullDirM1==1?"UP":"--");
   }

   // 7. Hull distance filter
   if(IsPriceTooFarFromHull(isBuy ? 0 : 1))
      return "PRICE TOO FAR FROM HULL";

   // 8. p50 Master Bias — hard gate
   bool p50Bull = (gdx_swingCount2 > 1 && gdx_swings2[gdx_swingCount2-1].isHigh);
   if( isBuy && !p50Bull) return "BIAS: p50 BEARISH";
   if(!isBuy &&  p50Bull) return "BIAS: p50 BULLISH";

   // 9. Min gap to opposite zone
   if(InpMinGapEntryFilter) {
      for(int i = 0; i < ArraySize(g_zones); i++) {
         if(g_zones[i].isSwept) continue;
         bool isOpposite = isBuy ? g_zones[i].isHigh : !g_zones[i].isHigh;
         if(!isOpposite) continue;
         bool oppAbove = isBuy ? (g_zones[i].sweepLevel > curPrice) : (g_zones[i].sweepLevel < curPrice);
         if(!oppAbove) continue;
         double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
         double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
         if(tickSize <= 0) break;
         double gapUSD = MathAbs(g_zones[i].sweepLevel - curPrice) / tickSize * tickVal * InpLot;
         if(gapUSD < InpMinEntryGapUSD)
            return StringFormat("NEAR %s $%.2f < min $%.2f", isBuy?"EQH":"EQL", gapUSD, InpMinEntryGapUSD);
         break;
      }
   }

   return ""; // ผ่านทุก filter
}

//+------------------------------------------------------------------+
//| What's Next Dashboard — 3-Layer Decision Engine                  |
//+------------------------------------------------------------------+
void UpdateWhatNextDashboard()
{
   if(!InpShowDash) return;

   bool p50Bull = (gdx_swingCount2 > 1 && gdx_swings2[gdx_swingCount2-1].isHigh);
   int  buyBias  = GetBiasScore(true);
   int  sellBias = GetBiasScore(false);
   int  buySetup  = GetSetupScore(true);
   int  sellSetup = GetSetupScore(false);
   string buyBlock  = GetEntryBlockReason(true);
   string sellBlock = GetEntryBlockReason(false);

   bool buyReady  = (buyBlock  == "" && buyBias  >= 40 && buySetup  >= 20);
   bool sellReady = (sellBlock == "" && sellBias >= 40 && sellSetup >= 20);

   // --- SELL row: Bias / Setup / Block ---
   string sellRow, sellSts;
   color  sellClr;
   if(sellReady) {
      sellRow = StringFormat("SELL | Bias:%d%%  Setup:%d%%", sellBias, sellSetup);
      sellSts = "READY ✅"; sellClr = clrTomato;
   } else if(sellBias >= 40) {
      sellRow = StringFormat("SELL | Bias:%d%%  Setup:%d%%", sellBias, sellSetup);
      sellSts = StringFormat("BLOCKED: %s", sellBlock == "" ? "low setup" : sellBlock);
      sellClr = clrOrangeRed;
   } else {
      sellRow = StringFormat("SELL | Bias:%d%%  --", sellBias);
      sellSts = "WAIT: " + (p50Bull ? "BIAS FLIP (p50 BULL)" : "no M15 align");
      sellClr = clrGray;
   }
   ObjectSetString (0, DASH_PREFIX+"WN_SELL_ROW", OBJPROP_TEXT, sellRow);
   ObjectSetInteger(0, DASH_PREFIX+"WN_SELL_ROW", OBJPROP_COLOR, sellClr);
   ObjectSetString (0, DASH_PREFIX+"WN_SELL_STS", OBJPROP_TEXT, sellSts);
   ObjectSetInteger(0, DASH_PREFIX+"WN_SELL_STS", OBJPROP_COLOR, sellClr);

   // --- BUY row: Bias / Setup / Block ---
   string buyRow, buySts;
   color  buyClr;
   if(buyReady) {
      buyRow = StringFormat("BUY  | Bias:%d%%  Setup:%d%%", buyBias, buySetup);
      buySts = "READY ✅"; buyClr = clrLime;
   } else if(buyBias >= 40) {
      buyRow = StringFormat("BUY  | Bias:%d%%  Setup:%d%%", buyBias, buySetup);
      buySts = StringFormat("BLOCKED: %s", buyBlock == "" ? "low setup" : buyBlock);
      buyClr = clrDeepSkyBlue;
   } else {
      buyRow = StringFormat("BUY  | Bias:%d%%  --", buyBias);
      buySts = "WAIT: " + (!p50Bull ? "BIAS FLIP (p50 BEAR)" : "no M15 align");
      buyClr = clrGray;
   }
   ObjectSetString (0, DASH_PREFIX+"WN_BUY_ROW", OBJPROP_TEXT, buyRow);
   ObjectSetInteger(0, DASH_PREFIX+"WN_BUY_ROW", OBJPROP_COLOR, buyClr);
   ObjectSetString (0, DASH_PREFIX+"WN_BUY_STS",  OBJPROP_TEXT, buySts);
   ObjectSetInteger(0, DASH_PREFIX+"WN_BUY_STS",  OBJPROP_COLOR, buyClr);

   // --- DYNAMIC TARGET ---
   double curPrice  = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double targetVal = g_targetPrice;
   string targetSide = (buyBias > sellBias) ? "UPPER EQH" : "LOWER EQL";
   string tgtStr = "--"; string rrStr = "--";
   if(targetVal > 0) {
      double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double gapUSD = (tickSize > 0) ? MathAbs(targetVal - curPrice) / tickSize * tickVal * InpLot : 0;
      tgtStr = StringFormat("%.2f (%s)  Gap $%.1f", targetVal, targetSide, gapUSD);
      if(InpSL_USD > 0 && gapUSD > 0) rrStr = StringFormat("Est. R:R  1 : %.1f", gapUSD / InpSL_USD);
   }
   ObjectSetString(0, DASH_PREFIX+"WN_TARGET", OBJPROP_TEXT, "Target: " + tgtStr);
   ObjectSetString(0, DASH_PREFIX+"WN_RR",     OBJPROP_TEXT, rrStr);

   // --- DXY + Gold Trend + Spread ---
   {
      int    dxyDir  = GetDXYTrendDirection();
      int    goldDir = GetGoldTrendDirection();
      double spUSD   = GetSpreadUSD();
      SessionProfile spProf = GetActiveProfile();
      string dxyTxt  = (dxyDir  ==  1) ? "DXY:▲" : (dxyDir  == -1) ? "DXY:▼" : "DXY:─";
      string gldTxt  = (goldDir ==  1) ? "GOLD:▲" : (goldDir == -1) ? "GOLD:▼" : "GOLD:─";
      bool   isCorr  = (dxyDir != 0 && goldDir != 0 && dxyDir != goldDir);
      color  stateClr = clrLime;
      string stateTxt = "Corr: OK";
      if(dxyDir == 0 || goldDir == 0) { stateClr = clrSilver; stateTxt = "Corr: FLAT"; }
      else if(!isCorr)                { stateClr = clrYellow; stateTxt = "Corr: CONFLICT"; }
      if(spProf.maxSpreadUSD > 0 && spUSD > spProf.maxSpreadUSD) stateClr = clrTomato;
      ObjectSetString (0, DASH_PREFIX+"WN_SPREAD", OBJPROP_TEXT,
                       StringFormat("%s  %s  | %s | Spread: $%.3f", dxyTxt, gldTxt, stateTxt, spUSD));
      ObjectSetInteger(0, DASH_PREFIX+"WN_SPREAD", OBJPROP_COLOR, stateClr);
   }

   // --- AI Confidence bar (ใช้ setup score ฝั่งที่ bias ดีกว่า) ---
   int bestBias  = MathMax(buyBias,  sellBias);
   int bestSetup = (buyBias >= sellBias) ? buySetup : sellSetup;
   bool bestReady = (buyBias >= sellBias) ? buyReady : sellReady;
   // Combined confidence = bias 60% weight + setup 40% weight
   int combined = (int)(bestBias * 0.6 + bestSetup * 0.4);
   combined = MathMin(98, combined);
   string barStr = "";
   int filled = combined / 10;
   for(int i=0;i<filled;i++) barStr += "█";
   for(int i=filled;i<10;i++) barStr += "░";
   string readyTag = bestReady ? " ✅ ENTRY OK" : " ⏳ WAIT";
   color  barClr   = bestReady ? clrLime : (combined >= 50) ? clrYellow : clrGray;
   ObjectSetString (0, DASH_PREFIX+"WN_PROB_BAR", OBJPROP_TEXT,
      StringFormat("Confidence: [%s] %d%%%s", barStr, combined, readyTag));
   ObjectSetInteger(0, DASH_PREFIX+"WN_PROB_BAR", OBJPROP_COLOR, barClr);
}

//+------------------------------------------------------------------+
//|  EA: อัพเดท Dashboard ส่วน EA Order Status                       |
//+------------------------------------------------------------------+
void UpdateEADashboard()
{
   if(!InpShowDash) return;

   // Bias / DXY ย้ายไป WN panel แล้ว — ล้างให้ว่าง
   ObjectSetString(0, DASH_PREFIX+"EA_BIAS",    OBJPROP_TEXT, " ");
   ObjectSetString(0, DASH_PREFIX+"DXY_TREND",  OBJPROP_TEXT, " ");
   ObjectSetString(0, DASH_PREFIX+"EA_CRITICAL",OBJPROP_TEXT, " ");

   // SynM15 Slope (ยังคงแสดง — ช่วย debug Hull)
   {
      string slopeSign = (g_hullSlopeM15 > 0) ? "+" : "";
      string slopeTxt  = StringFormat("SynM15 Slope: %s%.4f  M15:%s M1:%s",
                                      slopeSign, g_hullSlopeM15,
                                      g_hullDirM15==1?"▲":g_hullDirM15==-1?"▼":"─",
                                      g_hullDirM1 ==1?"▲":g_hullDirM1 ==-1?"▼":"─");
      color slopeClr = (g_hullSlopeM15 > 0) ? clrLime : (g_hullSlopeM15 < 0) ? clrTomato : clrSilver;
      ObjectSetString (0, DASH_PREFIX+"EA_SESSION", OBJPROP_TEXT,  slopeTxt);
      ObjectSetInteger(0, DASH_PREFIX+"EA_SESSION", OBJPROP_COLOR, slopeClr);
   }

   // Streak
   string eqlIcons = "", eqhIcons = "";
   for(int i = 0; i < g_eql_streak; i++) eqlIcons += "🟢";
   for(int i = 0; i < g_eqh_streak; i++) eqhIcons += "🔴";
   color streakClr = (g_eql_streak >= InpEQL_Streak3rd || g_eqh_streak >= InpEQH_Streak)
                     ? clrYellow : clrSilver;
   ObjectSetString (0, DASH_PREFIX+"EA_STREAK", OBJPROP_TEXT,
                    StringFormat("Streak  EQL %d%s | EQH %d%s", g_eql_streak, eqlIcons, g_eqh_streak, eqhIcons));
   ObjectSetInteger(0, DASH_PREFIX+"EA_STREAK", OBJPROP_COLOR, streakClr);

   // BUY positions
   int openBuy  = CountOpenOrders(POSITION_TYPE_BUY);
   color buyClr = (openBuy >= InpMaxBuy) ? clrOrangeRed : clrLime;
   ObjectSetString (0, DASH_PREFIX+"EA_BUY", OBJPROP_TEXT,
                    StringFormat("BUY  Positions: %d / %d%s", openBuy, InpMaxBuy,
                                 openBuy >= InpMaxBuy ? "  MAX" : ""));
   ObjectSetInteger(0, DASH_PREFIX+"EA_BUY", OBJPROP_COLOR, buyClr);

   // SELL positions
   int openSell = CountOpenOrders(POSITION_TYPE_SELL);
   color sellClr = (openSell >= InpMaxSell) ? clrOrangeRed : clrTomato;
   string sellWait = (g_eqh_streak > 0 && g_eqh_streak < InpEQH_Streak)
                     ? StringFormat("  (wait %d/%d)", g_eqh_streak, InpEQH_Streak) : "";
   ObjectSetString (0, DASH_PREFIX+"EA_SELL", OBJPROP_TEXT,
                    StringFormat("SELL Positions: %d / %d%s%s", openSell, InpMaxSell,
                                 openSell >= InpMaxSell ? "  MAX" : "", sellWait));
   ObjectSetInteger(0, DASH_PREFIX+"EA_SELL", OBJPROP_COLOR, sellClr);

   // Last BUY / SELL tickets
   double lastBuyEntry = 0, lastBuyTP = 0, lastBuySL = 0;
   double lastSellEntry = 0, lastSellTP = 0, lastSellSL = 0;
   for(int i = 0; i < PositionsTotal(); i++) {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC)  != InpMagicNumber) continue;
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
         lastBuyEntry = PositionGetDouble(POSITION_PRICE_OPEN);
         lastBuyTP    = PositionGetDouble(POSITION_TP);
         lastBuySL    = PositionGetDouble(POSITION_SL);
      }
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
         lastSellEntry = PositionGetDouble(POSITION_PRICE_OPEN);
         lastSellTP    = PositionGetDouble(POSITION_TP);
         lastSellSL    = PositionGetDouble(POSITION_SL);
      }
   }
   if(lastBuyEntry > 0)
      ObjectSetString(0, DASH_PREFIX+"EA_LASTBUY", OBJPROP_TEXT,
                      StringFormat("Last BUY : %.3f  TP:%.3f  SL:%.3f", lastBuyEntry, lastBuyTP, lastBuySL));
   if(lastSellEntry > 0)
      ObjectSetString(0, DASH_PREFIX+"EA_LASTSELL", OBJPROP_TEXT,
                      StringFormat("Last SELL: %.3f  TP:%.3f  SL:%.3f", lastSellEntry, lastSellTP, lastSellSL));

   // Total P/L
   double totalPnl = 0;
   for(int i = 0; i < PositionsTotal(); i++) {
      ulong t = PositionGetTicket(i);
      if(!PositionSelectByTicket(t)) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;
      totalPnl += PositionGetDouble(POSITION_PROFIT);
   }
   string pnlTxt = StringFormat("Total P/L : %+.2f USD", totalPnl);
   if(InpCloseAllProfit > 0)
      pnlTxt += StringFormat(" / %.2f", InpCloseAllProfit);
   color pnlClr = clrSilver;
   if(totalPnl > 0) {
      pnlClr = (InpCloseAllProfit > 0 && totalPnl >= InpCloseAllProfit * 0.8) ? clrYellow : clrLime;
   } else if(totalPnl < 0) {
      pnlClr = clrTomato;
   }
   ObjectSetString (0, DASH_PREFIX+"EA_PNL", OBJPROP_TEXT,  pnlTxt);
   ObjectSetInteger(0, DASH_PREFIX+"EA_PNL", OBJPROP_COLOR, pnlClr);

   // Pending Order status
   if(InpAutoPending) {
      string pendTxt; color pendClr;
      if(g_pendingTicket > 0) {
         string pendType = g_pendingIsBull ? "BuyLimit" : "SellLimit";
         pendTxt = StringFormat("Pending: %s @ %.3f  TP:%.3f", pendType, g_pendingPOI, g_targetPrice);
         pendClr = g_pendingIsBull ? clrDeepSkyBlue : clrTomato;
      } else {
         pendTxt = "Pending: none";
         pendClr = clrSilver;
      }
      ObjectSetString (0, DASH_PREFIX+"EA_PENDING", OBJPROP_TEXT,  pendTxt);
      ObjectSetInteger(0, DASH_PREFIX+"EA_PENDING", OBJPROP_COLOR, pendClr);
   }

   // EA Status (รวม News/Session filter state)
   string eaStatus;
   color  eaClr;
   if(!InpEA_Enable) {
      eaStatus = "◎ EA OFF"; eaClr = clrSilver;
   } else if(g_TradingStatus == "PAUSED BY NEWS") {
      eaStatus = "⏸ " + g_TradingStatus; eaClr = g_StatusColor;
   } else if(g_TradingStatus == "SESSION CLOSED" || g_TradingStatus == "WEEKEND CLOSED") {
      eaStatus = "🔒 " + g_TradingStatus; eaClr = g_StatusColor;
   } else {
      eaStatus = "◉ EA ACTIVE"; eaClr = clrLime;
   }
   ObjectSetString (0, DASH_PREFIX+"EA_STATUS", OBJPROP_TEXT,  eaStatus);
   ObjectSetInteger(0, DASH_PREFIX+"EA_STATUS", OBJPROP_COLOR, eaClr);

   // --- M1 Slope Comparison ---
   {
      string slopeDir; color slopeClr;
      if     (g_hullValueM1_Curr > g_hullValueM1_Prev) { slopeDir = "UP ▲";     slopeClr = clrSpringGreen; }
      else if(g_hullValueM1_Curr < g_hullValueM1_Prev) { slopeDir = "DOWN ▼";   slopeClr = clrOrangeRed;   }
      else                                               { slopeDir = "STEADY ─"; slopeClr = clrSilver;      }
      ObjectSetString (0, DASH_PREFIX+"EA_M1SLOPE", OBJPROP_TEXT,
         StringFormat("Hull M1 Value  Prev:%.2f  Curr:%.2f  [%s]",
                      g_hullValueM1_Prev, g_hullValueM1_Curr, slopeDir));
      ObjectSetInteger(0, DASH_PREFIX+"EA_M1SLOPE", OBJPROP_COLOR, slopeClr);
   }

   // --- Hull M1 Gap Monitoring ---
   {
      double curPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double curHull  = g_hullValueM1_Curr;
      // ระยะห่างราคาตรง * 100 → 1 USD = 100 pts (ไม่ผ่าน Lot/tickVal)
      double distPts  = (curHull > 0) ? MathAbs(curPrice - curHull) * 100.0 : 0;

      double currentLimit = (double)InpMaxHullDistM1;
      if(InpUseDynamicATR) {
         double atrPrice = 0;
         double buf[1];
         if(CopyBuffer(g_atrHandle, 0, 0, 1, buf) > 0) atrPrice = buf[0];
         if(atrPrice > 0) currentLimit = (atrPrice * 100.0) * InpATRMultiplier;
      }

      bool   tooFar  = (InpMaxHullDistM1 > 0 && distPts > currentLimit);
      string gapTxt  = StringFormat("Hull M1 Gap: %.1f pts  (Limit: %.0f)  [%s]",
                                    distPts, currentLimit, tooFar ? "⚠️ TOO FAR" : "✅ OK");
      color  gapClr  = tooFar ? clrTomato : clrSpringGreen;
      ObjectSetString (0, DASH_PREFIX+"EA_HULL_GAP", OBJPROP_TEXT,  gapTxt);
      ObjectSetInteger(0, DASH_PREFIX+"EA_HULL_GAP", OBJPROP_COLOR, gapClr);
   }

   UpdateWhatNextDashboard();
}

//+------------------------------------------------------------------+
//|  EA: ปิดทุก Position เมื่อ Total Profit ถึง Target               |
//+------------------------------------------------------------------+
void CloseAllIfProfitTarget()
{
   if(InpCloseAllProfit <= 0) return;

   double totalPnl = 0;
   for(int i = 0; i < PositionsTotal(); i++) {
      ulong t = PositionGetTicket(i);
      if(!PositionSelectByTicket(t)) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;
      totalPnl += PositionGetDouble(POSITION_PROFIT);
   }

   if(totalPnl < InpCloseAllProfit) return;

   // ถึง Target — ปิดทั้งหมด
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong t = PositionGetTicket(i);
      if(!PositionSelectByTicket(t)) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;
      g_trade.PositionClose(t);
   }

   // Reset streak หลังปิดทั้งหมด
   g_eql_streak = 0;
   g_eqh_streak = 0;

   string msg = StringFormat("[DLZ Order] CLOSE ALL — Total Profit $%.2f reached target $%.2f",
                              totalPnl, InpCloseAllProfit);
   Print(msg);
   if(InpNotifyOrder && InpAlertPush) SafeSendNotification(msg);
}

//+------------------------------------------------------------------+
//|  EA: Track helper — เพิ่ม/หา/ลบ ใน g_trackList                  |
//+------------------------------------------------------------------+
int FindTrack(ulong ticket)
{
   for(int i=0;i<g_trackCount;i++) if(g_trackList[i].ticket==ticket) return i;
   return -1;
}
void AddTrack(ulong ticket, string reason, double reqPrice, double entryPrice)
{
   ArrayResize(g_trackList, g_trackCount+1);
   g_trackList[g_trackCount].ticket      = ticket;
   g_trackList[g_trackCount].maxDD_USD   = 0;
   g_trackList[g_trackCount].entryPrice  = entryPrice;
   g_trackList[g_trackCount].openTime    = TimeCurrent();
   g_trackList[g_trackCount].reason      = reason;
   g_trackList[g_trackCount].reqPrice    = reqPrice;
   g_trackList[g_trackCount].beTriggered    = false;
   g_trackList[g_trackCount].slExpandCount = 0;
   g_trackCount++;
}
void RemoveTrack(int idx)
{
   for(int i=idx;i<g_trackCount-1;i++) g_trackList[i]=g_trackList[i+1];
   g_trackCount--;
   ArrayResize(g_trackList, g_trackCount);
}

//+------------------------------------------------------------------+
//|  EA: DrawRRBox — วาด TP/SL Rectangle บนชาร์ตตอนเปิด Order       |
//+------------------------------------------------------------------+
void DrawRRBox(datetime entryTime, double entry, double tp, double sl, double lots, bool isBuy)
{
   if(!InpRR_DrawEnable) return;

   datetime endTime = entryTime + PeriodSeconds(PERIOD_CURRENT);
   string   base    = "DLZ_RR_" + IntegerToString(entryTime);

   double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickSize == 0) tickSize = _Point;
   double profitUSD = (MathAbs(tp - entry) / tickSize) * tickVal * lots;
   double lossUSD   = (MathAbs(sl - entry) / tickSize) * tickVal * lots;

   // ── TP Box ──
   string tpObj = base + "_TP";
   if(ObjectFind(0,tpObj)<0) ObjectCreate(0,tpObj,OBJ_RECTANGLE,0,entryTime,entry,endTime,tp);
   ObjectSetInteger(0,tpObj,OBJPROP_COLOR,      InpRR_TPColor);
   ObjectSetInteger(0,tpObj,OBJPROP_FILL,       true);
   ObjectSetInteger(0,tpObj,OBJPROP_BACK,       true);
   ObjectSetInteger(0,tpObj,OBJPROP_STYLE,      STYLE_SOLID);
   ObjectSetDouble (0,tpObj,OBJPROP_PRICE,  0,  entry);
   ObjectSetDouble (0,tpObj,OBJPROP_PRICE,  1,  tp);
   ObjectSetInteger(0,tpObj,OBJPROP_TIME,   0,  entryTime);
   ObjectSetInteger(0,tpObj,OBJPROP_TIME,   1,  endTime);
   ObjectSetInteger(0,tpObj,OBJPROP_SELECTABLE, false);

   // ── SL Box ──
   string slObj = base + "_SL";
   if(ObjectFind(0,slObj)<0) ObjectCreate(0,slObj,OBJ_RECTANGLE,0,entryTime,entry,endTime,sl);
   ObjectSetInteger(0,slObj,OBJPROP_COLOR,      InpRR_SLColor);
   ObjectSetInteger(0,slObj,OBJPROP_FILL,       true);
   ObjectSetInteger(0,slObj,OBJPROP_BACK,       true);
   ObjectSetInteger(0,slObj,OBJPROP_STYLE,      STYLE_SOLID);
   ObjectSetDouble (0,slObj,OBJPROP_PRICE,  0,  entry);
   ObjectSetDouble (0,slObj,OBJPROP_PRICE,  1,  sl);
   ObjectSetInteger(0,slObj,OBJPROP_TIME,   0,  entryTime);
   ObjectSetInteger(0,slObj,OBJPROP_TIME,   1,  endTime);
   ObjectSetInteger(0,slObj,OBJPROP_SELECTABLE, false);

   // ── Entry dotted line ──
   string entLine = base + "_Ent";
   if(ObjectFind(0,entLine)<0) ObjectCreate(0,entLine,OBJ_TREND,0,entryTime,entry,endTime,entry);
   ObjectSetInteger(0,entLine,OBJPROP_COLOR,     clrWhite);
   ObjectSetInteger(0,entLine,OBJPROP_STYLE,     STYLE_DOT);
   ObjectSetInteger(0,entLine,OBJPROP_RAY_RIGHT, false);
   ObjectSetDouble (0,entLine,OBJPROP_PRICE,0,   entry);
   ObjectSetDouble (0,entLine,OBJPROP_PRICE,1,   entry);
   ObjectSetInteger(0,entLine,OBJPROP_TIME, 0,   entryTime);
   ObjectSetInteger(0,entLine,OBJPROP_TIME, 1,   endTime);
   ObjectSetInteger(0,entLine,OBJPROP_SELECTABLE,false);

   // ── USD Labels ──
   if(InpRR_ShowText)
   {
      string tpLbl = base + "_TP_USD";
      if(ObjectFind(0,tpLbl)<0) ObjectCreate(0,tpLbl,OBJ_TEXT,0,entryTime,tp);
      ObjectSetInteger(0,tpLbl,OBJPROP_TIME,      entryTime);
      ObjectSetDouble (0,tpLbl,OBJPROP_PRICE,     tp);
      ObjectSetString (0,tpLbl,OBJPROP_TEXT,      StringFormat("+$%d",(int)MathRound(profitUSD)));
      ObjectSetInteger(0,tpLbl,OBJPROP_COLOR,     InpRR_TPColor);
      ObjectSetInteger(0,tpLbl,OBJPROP_FONTSIZE,  9);
      ObjectSetString (0,tpLbl,OBJPROP_FONT,      "Arial Bold");
      ObjectSetInteger(0,tpLbl,OBJPROP_ANCHOR,    isBuy ? ANCHOR_LEFT_LOWER : ANCHOR_LEFT_UPPER);
      ObjectSetInteger(0,tpLbl,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,tpLbl,OBJPROP_BACK,      false);

      string slLbl = base + "_SL_USD";
      if(ObjectFind(0,slLbl)<0) ObjectCreate(0,slLbl,OBJ_TEXT,0,entryTime,sl);
      ObjectSetInteger(0,slLbl,OBJPROP_TIME,      entryTime);
      ObjectSetDouble (0,slLbl,OBJPROP_PRICE,     sl);
      ObjectSetString (0,slLbl,OBJPROP_TEXT,      StringFormat("-$%d",(int)MathRound(lossUSD)));
      ObjectSetInteger(0,slLbl,OBJPROP_COLOR,     InpRR_SLColor);
      ObjectSetInteger(0,slLbl,OBJPROP_FONTSIZE,  9);
      ObjectSetString (0,slLbl,OBJPROP_FONT,      "Arial Bold");
      ObjectSetInteger(0,slLbl,OBJPROP_ANCHOR,    isBuy ? ANCHOR_LEFT_UPPER : ANCHOR_LEFT_LOWER);
      ObjectSetInteger(0,slLbl,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,slLbl,OBJPROP_BACK,      false);
   }
   ChartRedraw();
}

//+------------------------------------------------------------------+
//|  EA: LogTradeOpen — Print + Notify เมื่อเปิด Order               |
//+------------------------------------------------------------------+
void LogTradeOpen(ulong ticket, string reason, double reqPrice)
{
   if(!PositionSelectByTicket(ticket)) return;
   int    posType  = (int)PositionGetInteger(POSITION_TYPE);
   double entry    = PositionGetDouble(POSITION_PRICE_OPEN);
   double tp       = PositionGetDouble(POSITION_TP);
   double sl       = PositionGetDouble(POSITION_SL);
   double slip     = (posType==POSITION_TYPE_BUY) ? (entry-reqPrice)/_Point : (reqPrice-entry)/_Point;
   int    spread   = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   string sType    = (posType==POSITION_TYPE_BUY) ? "BUY" : "SELL";
   string hullM15  = (g_hullDirM15==1) ? "UP" : (g_hullDirM15==-1) ? "DN" : "--";
   string hullM1   = (g_hullDirM1 ==1) ? "UP" : (g_hullDirM1 ==-1) ? "DN" : "--";

   // Fibo retrace — p26=OFA primary, fx=DXY filter reference (gdx_swings2)
   string fiboStr = "--";
   if(gdx_swingCount > 1) {
      GDX_SwingPoint s1=gdx_swings[gdx_swingCount-2], s2=gdx_swings[gdx_swingCount-1];
      double range = MathAbs(s1.price-s2.price);
      if(range > 0) fiboStr = StringFormat("%.1f%%(p26)", (MathAbs(entry-s2.price)/range)*100.0);
   }
   if(gdx_swingCount2 > 1) {
      GDX_SwingPoint s1=gdx_swings2[gdx_swingCount2-2], s2=gdx_swings2[gdx_swingCount2-1];
      double range = MathAbs(s1.price-s2.price);
      if(range > 0) fiboStr += StringFormat("/%.1f%%(fx)", (MathAbs(entry-s2.price)/range)*100.0);
   }

   long   curVol   = iTickVolume(_Symbol, _Period, 0);
   double avgVol   = GetAvgVolume(InpRVolPeriod);
   double volRatio = (avgVol > 0) ? (double)curVol / avgVol : 0;

   Print(StringFormat("[DLZ Order] %s #%d @ %.3f | TP:%.3f SL:%.3f | Reason:%s streak:EQL%d/EQH%d | M15:%s M1:%s Fibo:%s Spread:%dpts Slip:%.1fpts | Vol:%d Avg:%.1f (x%.2f)",
         sType, ticket, entry, tp, sl, reason, g_eql_streak, g_eqh_streak, hullM15, hullM1, fiboStr, spread, slip, curVol, avgVol, volRatio));

   string icon = (posType==POSITION_TYPE_BUY) ? "🟢" : "🔴";
   string notif = StringFormat("[DLZ Order] %s %s @ %.3f | TP:+$%.0f SL:-$%.0f\nReason:%s | M15:%s Spread:%dpts\nVol:%d (x%.2f)",
                               icon, sType, entry, InpTP_USD, InpSL_USD, reason, hullM15, spread, curVol, volRatio);
   if(InpNotifyOrder && InpAlertPush) SafeSendNotification(notif);

   AddTrack(ticket, reason, reqPrice, entry);
}

//+------------------------------------------------------------------+
//|  EA: NotifyOrderClose — Print + Notify เมื่อปิด Order            |
//+------------------------------------------------------------------+
void NotifyOrderClose(ulong ticket, string closeReason, string openReason, double pnl, int durMin, double maxDD)
{
   string icon = (StringFind(closeReason,"TP")>=0) ? "✅" :
                 (StringFind(closeReason,"BE")>=0) ? "🔒" : "❌";
   string reason_full = StringFormat("%s (OpenBy:%s)", closeReason, openReason);
   string msg = StringFormat("[DLZ Order] %s [%s] PnL:%+.2f USD | %dmin MaxDD:-$%.2f",
                              icon, reason_full, pnl, durMin, maxDD);
   Print(msg);
   if(InpNotifyOrder && InpAlertPush) SafeSendNotification(msg);
}

//+------------------------------------------------------------------+
//|  EA: UpdateMaxDrawdown — ติดตาม MaxDD ทุก tick                   |
//+------------------------------------------------------------------+
void CheckEQLConfirmation()
{
   if(g_eqlPendingCount == 0) return;
   if(!InpZoneEntry || !InpEA_Enable) return;

   double prevLow   = iLow(_Symbol,  _Period, 1);
   double prevClose = iClose(_Symbol, _Period, 1);

   for(int i = g_eqlPendingCount - 1; i >= 0; i--)
   {
      g_eqlPendingList[i].barsWaited++;

      // หมดอายุ
      if(g_eqlPendingList[i].barsWaited > InpEQL_ConfirmMaxBars) {
         Print("[DLZ EQL] Pending expired — zone:", DoubleToString(g_eqlPendingList[i].topPrice,_Digits));
         for(int k=i; k<g_eqlPendingCount-1; k++) g_eqlPendingList[k]=g_eqlPendingList[k+1];
         g_eqlPendingCount--; ArrayResize(g_eqlPendingList, g_eqlPendingCount);
         continue;
      }

      // zone ถูก Sweep (Low ทะลุ bottomPrice) → ยกเลิก
      if(prevLow < g_eqlPendingList[i].bottomPrice) {
         Print("[DLZ EQL] Pending swept — zone:", DoubleToString(g_eqlPendingList[i].topPrice,_Digits));
         for(int k=i; k<g_eqlPendingCount-1; k++) g_eqlPendingList[k]=g_eqlPendingList[k+1];
         g_eqlPendingCount--; ArrayResize(g_eqlPendingList, g_eqlPendingCount);
         continue;
      }

      // ตรวจว่าแท่งที่ผ่านมาแตะ zone
      if(prevLow <= g_eqlPendingList[i].topPrice)
         g_eqlPendingList[i].touched = true;

      // ต้อง touched AND close เหนือ topPrice (Rejection Candle)
      if(!g_eqlPendingList[i].touched) continue;
      if(prevClose <= g_eqlPendingList[i].topPrice) continue;

      // --- Confirmation ครบ — Re-check live filters ---
      SessionProfile prof = GetActiveProfile();
      if(IsNewsTime() || !CheckSessionAndExit()) continue;
      if(!IsSpreadAllowed(prof.maxSpreadUSD)) continue;

      if(InpHullFilter && !(g_hullDirM15 == 1 && g_hullDirM1 == 1)) {
         Print("[DLZ EQL Confirm] Blocked — Hull M15:", g_hullDirM15, " M1:", g_hullDirM1);
         for(int k=i; k<g_eqlPendingCount-1; k++) g_eqlPendingList[k]=g_eqlPendingList[k+1];
         g_eqlPendingCount--; ArrayResize(g_eqlPendingList, g_eqlPendingCount);
         continue;
      }

      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      if(InpFiboFilter && gdx_swingCount > 1) {
         GDX_SwingPoint s1 = gdx_swings[gdx_swingCount-2];
         GDX_SwingPoint s2 = gdx_swings[gdx_swingCount-1];
         double range = MathAbs(s1.price - s2.price);
         if(range > 0) {
            double retrace = (MathAbs(ask - s2.price) / range) * 100.0;
            if(retrace > prof.fiboMaxPct) {
               Print("[DLZ EQL Confirm] Blocked — Fibo:", DoubleToString(retrace,1), "%");
               for(int k=i; k<g_eqlPendingCount-1; k++) g_eqlPendingList[k]=g_eqlPendingList[k+1];
               g_eqlPendingCount--; ArrayResize(g_eqlPendingList, g_eqlPendingCount);
               continue;
            }
         }
      }

      if(CountOpenOrders(POSITION_TYPE_BUY) >= InpMaxBuy) continue;

      double tpGap = USDtoPriceGap(InpTP_USD);
      double slGap = CalcSLGap(ask, true);
      double minDist = (SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) + 50) * _Point;
      double fixedTP = ask + tpGap;
      double zoneTP  = FindZoneTP_Buy(ask);
      double tp = (zoneTP > ask && zoneTP < fixedTP) ? zoneTP : fixedTP;
      double sl = ask - slGap;
      if(MathAbs(tp - ask) < minDist) tp = ask + minDist;
      if(MathAbs(ask - sl) < minDist) sl = ask - minDist;
      tp = NormalizeDouble(tp, _Digits);
      sl = NormalizeDouble(sl, _Digits);

      double _cFibo = GetSwingFiboPct(ask, false);
      Print("[DLZ Order] BUY open (EQL_CONFIRM) zone:", DoubleToString(g_eqlPendingList[i].topPrice,_Digits),
            " Fibo:", (_cFibo>=0.0)?StringFormat("%.1f%%",_cFibo):"N/A",
            " Sp:$", DoubleToString(GetSpreadUSD(),3), " Ask:", DoubleToString(ask,_Digits));

      if(g_trade.Buy(InpLot, _Symbol, ask, sl, tp, "DLZ_BUY"))
         LogTradeOpen(g_trade.ResultOrder(), "EQL_CONFIRM", ask);

      for(int k=i; k<g_eqlPendingCount-1; k++) g_eqlPendingList[k]=g_eqlPendingList[k+1];
      g_eqlPendingCount--; ArrayResize(g_eqlPendingList, g_eqlPendingCount);
   }
}

void CheckEQHConfirmation()
{
   if(g_eqhPendingCount == 0) return;
   if(!InpZoneEntry || !InpEA_Enable) return;

   double prevHigh  = iHigh(_Symbol,  _Period, 1);
   double prevClose = iClose(_Symbol, _Period, 1);

   for(int i = g_eqhPendingCount - 1; i >= 0; i--)
   {
      g_eqhPendingList[i].barsWaited++;

      // หมดอายุ
      if(g_eqhPendingList[i].barsWaited > InpEQH_ConfirmMaxBars) {
         Print("[DLZ EQH] Pending expired — zone:", DoubleToString(g_eqhPendingList[i].bottomPrice,_Digits));
         for(int k=i; k<g_eqhPendingCount-1; k++) g_eqhPendingList[k]=g_eqhPendingList[k+1];
         g_eqhPendingCount--; ArrayResize(g_eqhPendingList, g_eqhPendingCount);
         continue;
      }

      // zone ถูก Sweep (High ทะลุ topPrice) → ยกเลิก
      if(prevHigh > g_eqhPendingList[i].topPrice) {
         Print("[DLZ EQH] Pending swept — zone:", DoubleToString(g_eqhPendingList[i].bottomPrice,_Digits));
         for(int k=i; k<g_eqhPendingCount-1; k++) g_eqhPendingList[k]=g_eqhPendingList[k+1];
         g_eqhPendingCount--; ArrayResize(g_eqhPendingList, g_eqhPendingCount);
         continue;
      }

      // ตรวจว่าแท่งที่ผ่านมาแตะ zone (High ขึ้นไปถึง bottomPrice)
      if(prevHigh >= g_eqhPendingList[i].bottomPrice)
         g_eqhPendingList[i].touched = true;

      // ต้อง touched AND close ต่ำกว่า bottomPrice (Rejection Candle)
      if(!g_eqhPendingList[i].touched) continue;
      if(prevClose >= g_eqhPendingList[i].bottomPrice) continue;

      // --- Confirmation ครบ — Re-check live filters ---
      SessionProfile prof = GetActiveProfile();
      if(IsNewsTime() || !CheckSessionAndExit()) continue;
      if(!IsSpreadAllowed(prof.maxSpreadUSD)) continue;

      if(InpHullFilter && !(g_hullDirM15 == -1 && g_hullDirM1 == -1)) {
         Print("[DLZ EQH Confirm] Blocked — Hull M15:", g_hullDirM15, " M1:", g_hullDirM1);
         for(int k=i; k<g_eqhPendingCount-1; k++) g_eqhPendingList[k]=g_eqhPendingList[k+1];
         g_eqhPendingCount--; ArrayResize(g_eqhPendingList, g_eqhPendingCount);
         continue;
      }

      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      if(InpFiboFilter && gdx_swingCount > 1) {
         GDX_SwingPoint s1 = gdx_swings[gdx_swingCount-2];
         GDX_SwingPoint s2 = gdx_swings[gdx_swingCount-1];
         double range = MathAbs(s1.price - s2.price);
         if(range > 0) {
            double retrace = (MathAbs(bid - s2.price) / range) * 100.0;
            if(retrace > prof.fiboMaxPct) {
               Print("[DLZ EQH Confirm] Blocked — Fibo:", DoubleToString(retrace,1), "% > max:", DoubleToString(prof.fiboMaxPct,0), "%");
               for(int k=i; k<g_eqhPendingCount-1; k++) g_eqhPendingList[k]=g_eqhPendingList[k+1];
               g_eqhPendingCount--; ArrayResize(g_eqhPendingList, g_eqhPendingCount);
               continue;
            }
            // block SELL ถ้า Fibo < 38.2% — ราคาใกล้ Swing Low (Discount Zone ไม่ใช่ Premium)
            if(retrace < 38.2) {
               Print("[DLZ EQH Confirm] Blocked — Fibo:", DoubleToString(retrace,1), "% < 38.2% (not premium zone)");
               for(int k=i; k<g_eqhPendingCount-1; k++) g_eqhPendingList[k]=g_eqhPendingList[k+1];
               g_eqhPendingCount--; ArrayResize(g_eqhPendingList, g_eqhPendingCount);
               continue;
            }
         }
      }

      if(CountOpenOrders(POSITION_TYPE_SELL) >= InpMaxSell) continue;

      double tpGap = USDtoPriceGap(InpTP_USD);
      double slGap = CalcSLGap(bid, false);
      double minDist = (SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) + 50) * _Point;
      double fixedTP = bid - tpGap;
      double zoneTP  = FindZoneTP_Sell(bid);
      double tp = (zoneTP < bid && zoneTP > fixedTP) ? zoneTP : fixedTP;
      double sl = bid + slGap;
      if(MathAbs(bid - tp) < minDist) tp = bid - minDist;
      if(MathAbs(sl - bid) < minDist) sl = bid + minDist;
      tp = NormalizeDouble(tp, _Digits);
      sl = NormalizeDouble(sl, _Digits);

      double _cFibo = GetSwingFiboPct(bid, true);
      Print("[DLZ Order] SELL open (EQH_CONFIRM) zone:", DoubleToString(g_eqhPendingList[i].bottomPrice,_Digits),
            " Fibo:", (_cFibo>=0.0)?StringFormat("%.1f%%",_cFibo):"N/A",
            " Sp:$", DoubleToString(GetSpreadUSD(),3), " Bid:", DoubleToString(bid,_Digits));

      if(g_trade.Sell(InpLot, _Symbol, bid, sl, tp, "DLZ_SELL"))
         LogTradeOpen(g_trade.ResultOrder(), "EQH_CONFIRM", bid);

      for(int k=i; k<g_eqhPendingCount-1; k++) g_eqhPendingList[k]=g_eqhPendingList[k+1];
      g_eqhPendingCount--; ArrayResize(g_eqhPendingList, g_eqhPendingCount);
   }
}

void CheckFlatCloseOrders()
{
   if(!InpFlatClose_Enable) return;

   static datetime flatSince = 0;
   int dxyDir = GetDXYTrendDirection();

   if(dxyDir != 0) { flatSince = 0; return; }  // DXY ไม่ Flat → reset timer

   if(flatSince == 0) flatSince = TimeCurrent();  // บันทึกเวลาเริ่ม Flat

   int elapsed = (int)(TimeCurrent() - flatSince);
   if(InpFlatClose_DelaySec > 0 && elapsed < InpFlatClose_DelaySec) return;  // รอไม่ครบ

   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;
      double pnl = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      if(pnl < InpFlatClose_MinProfit) continue;

      ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

      // Hull Filter: hold position, wait for Hull M1 to flip or slope decelerate
      if(InpFlatClose_HullFilter) {
         bool timeout = (InpFlatClose_TimeoutSec > 0 && elapsed >= InpFlatClose_TimeoutSec);
         if(!timeout) {
            // SELL → รอ Hull M1 = +1 (green); BUY → รอ Hull M1 = -1 (red)
            bool hullFlipped = (posType == POSITION_TYPE_SELL && g_hullDirM1 == 1) ||
                               (posType == POSITION_TYPE_BUY  && g_hullDirM1 == -1);

            // Slope decel: Hull momentum หมดแรง ก่อน flip จริง
            double slopeM1 = g_hullValueM1_Curr - g_hullValueM1_Prev;
            bool hullDecel = false;
            if(InpFlatClose_SlopeThreshold > 0.0 && elapsed >= 180) {
               if(posType == POSITION_TYPE_SELL)
                  hullDecel = (slopeM1 > -InpFlatClose_SlopeThreshold && slopeM1 < 0.0);
               else
                  hullDecel = (slopeM1 <  InpFlatClose_SlopeThreshold && slopeM1 > 0.0);
            }

            if(!hullFlipped && !hullDecel) {
               static datetime lastHoldPrint = 0;
               if(TimeCurrent() - lastHoldPrint >= 60) {
                  string waitClr = (posType == POSITION_TYPE_SELL) ? "green" : "red";
                  PrintFormat("[DLZ FlatClose] Hold #%d — waiting Hull M1 %s | slope:%.4f (elapsed:%ds)", ticket, waitClr, slopeM1, elapsed);
                  lastHoldPrint = TimeCurrent();
               }
               continue;
            }
            if(hullDecel && !hullFlipped)
               PrintFormat("[DLZ FlatClose] DXY_FLAT_CLOSE[DECEL] → Close #%d slope:%.4f elapsed:%ds PnL:+$%.2f", ticket, slopeM1, elapsed, pnl);
         } else {
            PrintFormat("[DLZ FlatClose] DXY_FLAT_CLOSE[TIMEOUT_%ds] → Close #%d PnL:+$%.2f (profit confirmed)", elapsed, ticket, pnl);
         }
      }

      g_trade.PositionClose(ticket);
      if(!InpFlatClose_HullFilter || (InpFlatClose_TimeoutSec > 0 && elapsed < InpFlatClose_TimeoutSec))
         PrintFormat("[DLZ FlatClose] DXY FLAT %ds → Close #%d PnL:+$%.2f", elapsed, ticket, pnl);
   }
}

void UpdateMaxDrawdown()
{
   for(int i=0;i<PositionsTotal();i++) {
      ulong t = PositionGetTicket(i);
      if(!PositionSelectByTicket(t)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=InpMagicNumber) continue;
      double pnl = PositionGetDouble(POSITION_PROFIT);
      int idx = FindTrack(t);
      if(idx<0) continue;
      if(pnl < 0 && MathAbs(pnl) > g_trackList[idx].maxDD_USD)
         g_trackList[idx].maxDD_USD = MathAbs(pnl);
   }
}

//+------------------------------------------------------------------+
//|  EA: CheckBreakEven — เลื่อน SL มาที่ทุน                        |
//+------------------------------------------------------------------+
void CheckBreakEven()
{
   if(InpBE_TriggerUSD <= 0) return;

   double bufPts = USDtoPriceGap(InpBE_BufferUSD);

   for(int i=0;i<PositionsTotal();i++) {
      ulong t = PositionGetTicket(i);
      if(!PositionSelectByTicket(t)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=InpMagicNumber) continue;

      int    idx      = FindTrack(t);
      if(idx>=0 && g_trackList[idx].beTriggered) continue;

      double pnl      = PositionGetDouble(POSITION_PROFIT);
      if(pnl < InpBE_TriggerUSD) continue;

      int    posType  = (int)PositionGetInteger(POSITION_TYPE);
      double entry    = PositionGetDouble(POSITION_PRICE_OPEN);
      double curSL    = PositionGetDouble(POSITION_SL);
      double curTP    = PositionGetDouble(POSITION_TP);
      double newSL    = (posType==POSITION_TYPE_BUY) ? entry+bufPts : entry-bufPts;

      // ตรวจว่า SL ยังไม่ถึง BE
      bool needMove = (posType==POSITION_TYPE_BUY)  ? (curSL < newSL) :
                      (posType==POSITION_TYPE_SELL) ? (curSL > newSL) : false;
      if(!needMove) continue;
      if(MathAbs(newSL - curSL) < _Point) continue; // ป้องกันส่งราคาเดิมซ้ำ (no-change spam)

      if(g_trade.PositionModify(t, newSL, curTP)) {
         if(idx>=0) g_trackList[idx].beTriggered = true;
         string sType = (posType==POSITION_TYPE_BUY) ? "BUY" : "SELL";
         string msg   = StringFormat("[DLZ Order] 🔒 BE moved %s #%d SL→%.3f (+$%.2f buffer)",
                                     sType, t, newSL, InpBE_BufferUSD);
         Print(msg);
         if(InpNotifyOrder && InpAlertPush) SafeSendNotification(msg);
      }
   }
}

//+------------------------------------------------------------------+
//|  SL Expansion — ขยาย SL ออกทุก 30 นาที (max 3 ครั้ง) เพื่อให้     |
//|  trade มีพื้นที่ช่วงต้น ก่อน Hull Trail เริ่มทำงาน               |
//+------------------------------------------------------------------+
void ManageSLExpansion()
{
   const int    MAX_EXPAND  = 3;
   const int    EXPAND_MINS = 30;
   const double EXPAND_USD  = 2.0;

   for(int i = 0; i < g_trackCount; i++)
   {
      if(!PositionSelectByTicket(g_trackList[i].ticket)) continue;
      if(g_trackList[i].slExpandCount >= MAX_EXPAND)     continue;
      if(g_trackList[i].beTriggered)                     continue;

      int elapsedMins = (int)((TimeCurrent() - g_trackList[i].openTime) / 60);
      int nextThresh  = (g_trackList[i].slExpandCount + 1) * EXPAND_MINS;
      if(elapsedMins < nextThresh) continue;

      int    posType = (int)PositionGetInteger(POSITION_TYPE);
      double curSL   = PositionGetDouble(POSITION_SL);
      double curTP   = PositionGetDouble(POSITION_TP);
      double gap     = USDtoPriceGap(EXPAND_USD);

      double newSL = (posType == POSITION_TYPE_BUY) ? curSL - gap : curSL + gap;
      newSL = NormalizeDouble(newSL, _Digits);

      if(g_trade.PositionModify(g_trackList[i].ticket, newSL, curTP))
      {
         g_trackList[i].slExpandCount++;
         PrintFormat("[SLExpand] #%I64u SL %s %.3f→%.3f (expand %d/%d)",
            g_trackList[i].ticket,
            posType == POSITION_TYPE_BUY ? "BUY" : "SELL",
            curSL, newSL,
            g_trackList[i].slExpandCount, MAX_EXPAND);
      }
   }
}

//+------------------------------------------------------------------+
//|  Hull Trail SL + Dynamic TP (candle-close based)                 |
//+------------------------------------------------------------------+
void ManageHullTrail()
{
   if(!InpHullTrailEnable && !InpHullDynTPEnable) return;

   // trigger เฉพาะแท่งใหม่ M1
   static datetime s_lastBar = 0;
   datetime curBar = iTime(_Symbol, PERIOD_M1, 0);
   if(curBar == s_lastBar) return;
   s_lastBar = curBar;

   // ต้องการ Hull array อย่างน้อย bars+1
   int need = InpHullTrailBars + 1;
   if(ArraySize(g_hullValM1) < need) return;

   double hullSL   = g_hullValM1[InpHullTrailBars]; // SL reference (e.g. index 3)
   double hullCurr = g_hullValM1[1];                 // แท่งล่าสุดที่ปิดแล้ว
   double hullPrev = g_hullValM1[need > 1 ? need-1 : 1]; // สำหรับ slope

   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if(tickSize == 0 || tickValue == 0) return;
   double ptValue   = tickValue / tickSize * _Point; // มูลค่า 1 point ต่อ lot

   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong t = PositionGetTicket(i);
      if(!PositionSelectByTicket(t)) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC)  != InpMagicNumber) continue;

      ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double curSL    = PositionGetDouble(POSITION_SL);
      double curTP    = PositionGetDouble(POSITION_TP);
      double entryPx  = PositionGetDouble(POSITION_PRICE_OPEN);
      double curPrice = (posType == POSITION_TYPE_BUY)
                        ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                        : SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      double newSL = curSL;
      double newTP = curTP;

      // threshold: กำไรต้องถึง $1 ก่อน Hull Trail จึงทำงาน
      double lots        = PositionGetDouble(POSITION_VOLUME);
      double profitPts   = (posType == POSITION_TYPE_BUY)
                           ? (curPrice - entryPx)
                           : (entryPx - curPrice);
      double profitUSD   = profitPts / _Point * ptValue * lots;
      if(profitUSD < InpBE_TriggerUSD) continue;

      // ── B: Trail SL → Hull[bars] (ทิศเดียว + guard) ──────────────
      if(posType == POSITION_TYPE_BUY)
      {
         if(hullSL > curSL           // เลื่อนขึ้นเท่านั้น (ratchet)
            && hullSL < curPrice)    // ต่ำกว่าราคาปัจจุบัน
            newSL = hullSL;
      }
      else // SELL
      {
         if(hullSL < curSL           // เลื่อนลงเท่านั้น (ratchet)
            && hullSL > curPrice)    // สูงกว่าราคาปัจจุบัน
            newSL = hullSL;
      }

      // ── C: Dynamic TP → next EQH/EQL (เฉพาะ slope ยังเป็นทิศเดิม) ─
      if(InpHullDynTPEnable)
      {
         bool slopeUp   = (hullCurr > hullPrev);
         bool slopeDown = (hullCurr < hullPrev);
         double nextTarget = 0;

         if(posType == POSITION_TYPE_BUY && slopeUp)
         {
            // หา next EQH เหนือราคาปัจจุบัน (closest, not swept)
            for(int z = 0; z < ArraySize(g_zones); z++)
            {
               if(g_zones[z].isSwept) continue;
               if(!g_zones[z].isHigh) continue;
               if(g_zones[z].sweepLevel <= curPrice) continue;
               if(nextTarget == 0 || g_zones[z].sweepLevel < nextTarget)
                  nextTarget = g_zones[z].sweepLevel;
            }
            // fallback: dist × multiplier
            if(nextTarget == 0)
               nextTarget = curPrice + (curPrice - hullSL) * InpHullDynTP_Mult;
            // ปรับ TP เฉพาะถ้าดีกว่าเดิม (ไกลกว่า)
            if(nextTarget > curTP && nextTarget > curPrice)
               newTP = nextTarget;
         }
         else if(posType == POSITION_TYPE_SELL && slopeDown)
         {
            // หา next EQL ใต้ราคาปัจจุบัน (closest, not swept)
            for(int z = 0; z < ArraySize(g_zones); z++)
            {
               if(g_zones[z].isSwept) continue;
               if(g_zones[z].isHigh) continue;
               if(g_zones[z].sweepLevel >= curPrice) continue;
               if(nextTarget == 0 || g_zones[z].sweepLevel > nextTarget)
                  nextTarget = g_zones[z].sweepLevel;
            }
            // fallback: dist × multiplier
            if(nextTarget == 0)
               nextTarget = curPrice - (hullSL - curPrice) * InpHullDynTP_Mult;
            // ปรับ TP เฉพาะถ้าดีกว่าเดิม (ไกลกว่า)
            if(nextTarget < curTP && nextTarget < curPrice)
               newTP = nextTarget;
         }
      }

      // ── ส่ง modify ถ้ามีการเปลี่ยนแปลง ─────────────────────────────
      bool slChanged = (MathAbs(newSL - curSL) >= _Point);
      bool tpChanged = (MathAbs(newTP - curTP) >= _Point);
      if(!slChanged && !tpChanged) continue;

      if(g_trade.PositionModify(t, newSL, newTP))
      {
         string sType  = (posType == POSITION_TYPE_BUY) ? "BUY" : "SELL";
         string slPart = slChanged ? StringFormat(" SL:%.3f→%.3f", curSL, newSL) : "";
         string tpPart = tpChanged ? StringFormat(" TP:%.3f→%.3f", curTP, newTP) : "";
         Print(StringFormat("[Hull Trail] %s #%I64u%s%s", sType, t, slPart, tpPart));
      }
   }
}

//+------------------------------------------------------------------+
//|  EA: OnTradeTransaction — ตรวจจับการปิด Order                    |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest     &request,
                        const MqlTradeResult      &result)
{
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD) return;

   ulong dealTicket = trans.deal;
   if(!HistoryDealSelect(dealTicket)) return;
   if(HistoryDealGetInteger(dealTicket, DEAL_MAGIC) != InpMagicNumber) return;
   if(HistoryDealGetString(dealTicket, DEAL_SYMBOL) != _Symbol) return;

   long dealEntry = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);

   // --- วาด RR Box เมื่อ position เปิดใหม่ ---
   if(dealEntry == DEAL_ENTRY_IN)
   {
      ulong  posId2  = (ulong)HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
      double price2  = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
      long   type2   = HistoryDealGetInteger(dealTicket, DEAL_TYPE);
      if(PositionSelectByTicket(posId2))
      {
         double tp2 = PositionGetDouble(POSITION_TP);
         double sl2 = PositionGetDouble(POSITION_SL);
         DrawRRBox(TimeCurrent(), price2, tp2, sl2, InpLot, type2 == DEAL_TYPE_BUY);
      }
      return;
   }

   if(dealEntry != DEAL_ENTRY_OUT && dealEntry != DEAL_ENTRY_INOUT) return;

   double pnl      = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
   long   reason   = HistoryDealGetInteger(dealTicket, DEAL_REASON);
   ulong  posId    = HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);

   int    idx       = FindTrack(posId);
   double openPrice = (idx >= 0) ? g_trackList[idx].entryPrice : 0;
   double maxDD     = (idx >= 0) ? g_trackList[idx].maxDD_USD  : 0;
   int    durMin    = (idx >= 0) ? (int)((TimeCurrent()-g_trackList[idx].openTime)/60) : 0;

   // fallback: ดึง entry price จาก History เมื่อ track หลุด (restart/recompile)
   if(openPrice == 0 && HistorySelectByPosition(posId)) {
      int dTotal = HistoryDealsTotal();
      for(int i = 0; i < dTotal; i++) {
         ulong dt = HistoryDealGetTicket(i);
         if(HistoryDealGetInteger(dt, DEAL_POSITION_ID) != (long)posId) continue;
         if(HistoryDealGetInteger(dt, DEAL_ENTRY) == DEAL_ENTRY_IN) {
            openPrice = HistoryDealGetDouble(dt, DEAL_PRICE);
            long tIn  = HistoryDealGetInteger(dt, DEAL_TIME);
            long tOut = HistoryDealGetInteger(dealTicket, DEAL_TIME);
            durMin    = (int)((tOut - tIn) / 60);
            break;
         }
      }
   }

   string openReason  = (idx >= 0) ? g_trackList[idx].reason : "Unknown";
   string closeReason;
   if(reason == DEAL_REASON_TP)     closeReason = "TP";
   else if(reason == DEAL_REASON_SL)
      closeReason = (idx >= 0 && g_trackList[idx].beTriggered) ? "BE" : "SL";
   else                             closeReason = "CLOSE_ALL";

   NotifyOrderClose(posId, closeReason, openReason, pnl, durMin, maxDD);
   Print(StringFormat("[DLZ Order] CLOSE #%d [%s→%s] PnL:%+.2f | Entry:%.3f | Dur:%dmin | MaxDD:-$%.2f",
                      posId, openReason, closeReason, pnl, openPrice, durMin, maxDD));

   if(idx >= 0) RemoveTrack(idx);
}

//+------------------------------------------------------------------+
//| [NEW] FUNCTION: SEND NOTIFICATION WHEN ZONE CREATED              |
//+------------------------------------------------------------------+
void NotifyNewZone(const LiquidityZone &z, datetime eventTime)
{
   if(!g_isLive || eventTime < g_eaStartTime) return;

   string tf    = StringSubstr(EnumToString(Period()), 7);
   string icon  = z.isHigh ? "🔴" : "🟢";
   string type  = z.isHigh ? "EQH" : "EQL";
   string price = DoubleToString(z.sweepLevel, _Digits);
   string vol   = FormatVol(z.totalVol);

   string distStr = "";
   double bestDist = -1;
   for(int i = 0; i < ArraySize(g_zones); i++)
   {
      if(g_zones[i].isSwept) continue;
      if(g_zones[i].isHigh == z.isHigh) continue;
      double d = MathAbs(z.sweepLevel - g_zones[i].sweepLevel) / _Point;
      if(bestDist < 0 || d < bestDist)
      {
         bestDist = d;
         string oppType = g_zones[i].isHigh ? "EQH" : "EQL";
         distStr = StringFormat("Gap to %s: $%.2f", oppType, d * _Point);
      }
   }
   if(distStr == "") distStr = "No opposite zone";

   string msg = StringFormat("[DLZ Signal] %s %s: %s %s at %s (Vol: %s) | %s",
                             _Symbol, tf, icon, type, price, vol, distStr);

   Print(msg);
   if(!InpNotifySignal) return;
   if(eventTime < g_eaStartTime) return; // Flood Guard: ห้ามส่งเหตุการณ์ก่อนเปิด EA
   if(InpAlertPopup) Alert(msg);
   //if(InpAlertPush)  SendNotification(msg);
}

//+------------------------------------------------------------------+
//| [NEW] FUNCTION: แจ้งเตือนเมื่อเกิดโซน HTF ใหม่                     |
//+------------------------------------------------------------------+
void NotifyNewZoneHTF(const LiquidityZone &z, datetime eventTime)
{
   if(!g_isLive || !g_htfInitialized) return;
   if(!InpNotifySignal) return;

   string tf    = StringSubstr(EnumToString(InpHTF), 7);
   string icon  = z.isHigh ? "🟠" : "🔵";
   string type  = z.isHigh ? "EQH" : "EQL";
   string price = DoubleToString(z.sweepLevel, _Digits);

   string msg = StringFormat("[DLZ Signal HTF %s] %s %s Formed at %s | Smart Money Target",
                             tf, icon, type, price);

   Print(msg);
   if(eventTime < g_eaStartTime) return; // Flood Guard: ห้ามส่งเหตุการณ์ก่อนเปิด EA
   if(InpAlertPopup) Alert(msg);
   if(InpNotifySignal && InpAlertPush)  SafeSendNotification(msg);
}

//+------------------------------------------------------------------+
//| [NEW] FUNCTION: แจ้งเตือนวินาทีที่โซน HTF ถูกทะลุ (Sweep Alert!)  |
//+------------------------------------------------------------------+
void NotifySweepHTF(const LiquidityZone &z, datetime eventTime)
{
   if(!g_isLive || !g_htfInitialized) return;
   if(!InpNotifySignal) return;

   string tf    = StringSubstr(EnumToString(InpHTF), 7);
   string icon  = "💥";
   string type  = z.isHigh ? "Sell Stop (EQH)" : "Buy Stop (EQL)";
   string price = DoubleToString(z.sweepLevel, _Digits);

   string msg = StringFormat("[DLZ Signal] %s %s %s Grabbed at %s! Watch for Reversal.",
                             tf, icon, type, price);

   Print(msg);
   if(eventTime < g_eaStartTime) return; // Flood Guard: ห้ามส่งเหตุการณ์ก่อนเปิด EA
   if(InpAlertPopup) Alert(msg);
   //if(InpAlertPush)  SendNotification(msg);
}

//+------------------------------------------------------------------+
//| FUNCTION: ส่ง notification เมื่อราคา retest โซน EQH/EQL          |
//+------------------------------------------------------------------+
void NotifyRetest(const LiquidityZone &z, datetime eventTime)
{
   if(!g_isLive) return;
   if(!InpNotifySignal) return;

   string tf     = StringSubstr(EnumToString(Period()), 7);
   string icon   = z.isHigh ? "⚠️🔴" : "⚠️🟢";
   string type   = z.isHigh ? "EQH" : "EQL";
   string price  = DoubleToString(z.sweepLevel, _Digits);
   string vol    = FormatVol(z.totalVol);
   string action = z.isHigh ? "watch for rejection (Sell)" : "watch for bounce (Buy)";

   string msg = StringFormat("[DLZ Signal] %s %s: %s %s RETEST at %s (Vol: %s) | %s",
                             _Symbol, tf, icon, type, price, vol, action);

   Print(msg);
   if(eventTime < g_eaStartTime) return; // Flood Guard: ห้ามส่งเหตุการณ์ก่อนเปิด EA
   if(InpAlertPopup) Alert(msg);
   //if(InpAlertPush)  SendNotification(msg);
}

//+------------------------------------------------------------------+
//| FUNCTION: ตรวจสอบ retest ทุก tick — เรียกจาก UpdateZones()        |
//+------------------------------------------------------------------+
void CheckRetestZones(double curHigh, double curLow)
{
   double tolerance = InpRetestPips * _Point * 10; // แปลง pips → points (Gold: 1 pip = 10 pts)

   for(int idx = ArraySize(g_zones) - 1; idx >= 0; idx--)
   {
      if(g_zones[idx].isSwept)        continue;
      if(g_zones[idx].retestNotified) continue;

      double zLv = g_zones[idx].sweepLevel;

      // EQH retest: ราคาขึ้นมาใกล้ sweepLevel แต่ยังไม่ทะลุ
      if(g_zones[idx].isHigh)
      {
         if(curHigh >= zLv - tolerance && curHigh < zLv)
         {
            g_zones[idx].retestNotified = true;
            NotifyRetest(g_zones[idx], TimeCurrent());
         }
      }
      // EQL retest: ราคาลงมาใกล้ sweepLevel แต่ยังไม่ทะลุ
      else
      {
         if(curLow <= zLv + tolerance && curLow > zLv)
         {
            g_zones[idx].retestNotified = true;
            NotifyRetest(g_zones[idx], TimeCurrent());
         }
      }
   }
}
//+------------------------------------------------------------------+
void DrawArrowProfitLabel()
{
   static string lastDir      = "";
   static double lastOpen     = 0;
   static datetime lastDirTime  = 0;
   static int    dirCount     = 0;
   static string lastHullM1   = "";
   static datetime lastDirLatest = 0;

   // Find latest Up/Down (233/234) and latest Flat (110) separately
   string dirObjName = "", flatObjName = "";
   datetime dirLatest = 0, flatLatest = 0;
   int total = ObjectsTotal(0, 0, OBJ_ARROW);
   for(int i = 0; i < total; i++)
   {
      string name = ObjectName(0, i, 0, OBJ_ARROW);
      if(StringFind(name, "DXY_TREND_ARROW_") < 0) continue;
      long   code = ObjectGetInteger(0, name, OBJPROP_ARROWCODE);
      datetime t  = (datetime)ObjectGetInteger(0, name, OBJPROP_TIME);
      if(code == 110) { if(t > flatLatest) { flatLatest = t; flatObjName = name; } }
      else            { if(t > dirLatest)  { dirLatest  = t; dirObjName  = name; } }
   }
   if(dirObjName == "" && flatObjName == "") return;

   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   datetime liveTime = iTime(_Symbol, _Period, 0) + (datetime)(PeriodSeconds(_Period) * 3)+500;

   // --- Line 1: Up/Down arrow ---
   string line1 = "";
   double dirPrice = 0; bool isUp = true; bool isProfit = false;
   if(dirObjName != "")
   {
      long arrowCode = ObjectGetInteger(0, dirObjName, OBJPROP_ARROWCODE);
      dirPrice = ObjectGetDouble(0, dirObjName, OBJPROP_PRICE);
      double diff = currentPrice - dirPrice;
      isUp = (arrowCode == 233);
      isProfit = isUp ? (diff > 0) : (diff < 0);
      double profitUSD = (tickVal > 0 && tickSize > 0) ? (diff / tickSize * tickVal) * InpLot : 0;
      double displayUSD = isUp ? profitUSD : -profitUSD;
      int eSec = (int)(TimeCurrent() - dirLatest);
      int hh = eSec / 3600, mm = (eSec % 3600) / 60;
      string elapsed = (hh > 0) ? StringFormat("%dh%02dm", hh, mm) : StringFormat("%dm", mm);
      string arrowSym = isUp ? "↑" : "↓";
      line1 = StringFormat("%s $%+.2f  [%s]", arrowSym, displayUSD, elapsed);
   }

   // --- Line 2: Flat arrow ---
   string line2 = "";
   double flatUSDDebug = 0;
   string flatElapsedDebug = "";
   if(flatObjName != "")
   {
      double flatPrice = ObjectGetDouble(0, flatObjName, OBJPROP_PRICE);
      double flatDiff  = currentPrice - flatPrice;
      flatUSDDebug     = (tickVal > 0 && tickSize > 0) ? (flatDiff / tickSize * tickVal) * InpLot : 0;
      int eSec = (int)(TimeCurrent() - flatLatest);
      int hh = eSec / 3600, mm = (eSec % 3600) / 60;
      flatElapsedDebug = (hh > 0) ? StringFormat("%dh%02dm", hh, mm) : StringFormat("%dm", mm);
      line2 = StringFormat(" FLAT: $%+.2f  [%s]", flatUSDDebug, flatElapsedDebug);
   }

   // --- Debug: fire on UP↔DN change, log result of PREVIOUS arrow ---
   if(dirObjName != "")
   {
      long   arrowCode2 = ObjectGetInteger(0, dirObjName, OBJPROP_ARROWCODE);
      double openPrice  = ObjectGetDouble(0, dirObjName, OBJPROP_PRICE);
      string curDir     = (arrowCode2 == 233) ? "UP" : "DN";

      if(curDir == lastDir)
      {
         if(dirLatest != lastDirLatest)
         {
            dirCount++;
            lastDirLatest = dirLatest;
         }
      }
      else
      {
         if(lastDir != "")
         {
            double diff = currentPrice - lastOpen;
            double pnl  = (tickVal > 0 && tickSize > 0) ? (diff / tickSize * tickVal) * InpLot : 0;
            double disp = (lastDir == "UP") ? pnl : -pnl;
            int    es   = (int)(TimeCurrent() - lastDirTime);
            int    hh   = es / 3600, mm = (es % 3600) / 60;
            string el   = (hh > 0) ? StringFormat("%dh%02dm", hh, mm) : StringFormat("%dm", mm);
            Print("[DLZ_ARROW] [", TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES), "] ",
                  StringFormat("%s(x%d)→%s | WasOpen:%.2f Now:%.2f PnL:$%.2f Dur:%s | HullM1@Start:%s HullM1@End:%s",
                               lastDir, dirCount, curDir, lastOpen, currentPrice, disp, el, lastHullM1,
                               (g_hullDirM1 == 1) ? "UP" : (g_hullDirM1 == -1) ? "DN" : "?"));
         }
         lastDir       = curDir;
         lastOpen      = openPrice;
         lastDirTime   = dirLatest;
         dirCount      = 1;
         lastDirLatest = dirLatest;
         lastHullM1    = (g_hullDirM1 == 1) ? "UP" : (g_hullDirM1 == -1) ? "DN" : "?";
      }
   }

   double anchorPrice = (dirObjName != "") ? dirPrice : ObjectGetDouble(0, flatObjName, OBJPROP_PRICE);
   double lineOffset = USDtoPriceGap(8.0);

   // --- Object บรรทัด 1: Up/Down ---
   string lbl1 = "DLZ_ArrowProfitLabel";
   if(line1 != "")
   {
      if(ObjectFind(0, lbl1) < 0) ObjectCreate(0, lbl1, OBJ_TEXT, 0, 0, 0);
      ObjectSetInteger(0, lbl1, OBJPROP_TIME,       0, liveTime);
      ObjectSetDouble (0, lbl1, OBJPROP_PRICE,      0, anchorPrice);
      ObjectSetString (0, lbl1, OBJPROP_TEXT,       line1);
      ObjectSetInteger(0, lbl1, OBJPROP_COLOR,      isProfit ? clrLime : clrOrangeRed);
      ObjectSetInteger(0, lbl1, OBJPROP_FONTSIZE,   10);
      ObjectSetInteger(0, lbl1, OBJPROP_ANCHOR,     isUp ? ANCHOR_LEFT_LOWER : ANCHOR_LEFT_UPPER);
      ObjectSetInteger(0, lbl1, OBJPROP_SELECTABLE, false);
   }
   else ObjectDelete(0, lbl1);

   // --- Object บรรทัด 2: Flat — วางตรงตำแหน่ง arrow 110 ---
   string lbl2 = "DLZ_ArrowProfitLabel2";
   if(line2 != "")
   {
      double flatPrice = ObjectGetDouble(0, flatObjName, OBJPROP_PRICE);
      if(ObjectFind(0, lbl2) < 0) ObjectCreate(0, lbl2, OBJ_TEXT, 0, 0, 0);
      ObjectSetInteger(0, lbl2, OBJPROP_TIME,       0, liveTime);
      ObjectSetDouble (0, lbl2, OBJPROP_PRICE,      0, flatPrice);
      ObjectSetString (0, lbl2, OBJPROP_TEXT,       line2);
      ObjectSetInteger(0, lbl2, OBJPROP_COLOR,      clrGray);
      ObjectSetInteger(0, lbl2, OBJPROP_FONTSIZE,   10);
      ObjectSetInteger(0, lbl2, OBJPROP_ANCHOR,     ANCHOR_LEFT_LOWER);
      ObjectSetInteger(0, lbl2, OBJPROP_SELECTABLE, false);
   }
   else ObjectDelete(0, lbl2);
}
//+------------------------------------------------------------------+
//|  OnChartEvent — Cockpit button handler                           |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK && StringFind(sparam, "DLZ_BTN_") >= 0)
   {
      Commander.ProcessClick(sparam);
      ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      ChartRedraw();
   }

   if(id == CHARTEVENT_CHART_CHANGE) {
      if(_Period != g_lastTF) {
         g_lastTF = _Period;
         ObjectsDeleteAll(0, "DLZ_ATR_");
         if(InpATRLevelsEnable) DrawATRLevels();
         }
   }
}

//+------------------------------------------------------------------+
//|  ATR Previous Day Levels                                         |
//+------------------------------------------------------------------+
double GDEA_GetATRDaily(int period)
{
   if(g_atr_d1_handle == INVALID_HANDLE) return 0;
   double buf[];
   if(CopyBuffer(g_atr_d1_handle, 0, 1, 1, buf) != 1) return 0;
   return buf[0];
}

double GetATRBaseline()
{
   MqlDateTime dt; TimeCurrent(dt);
   dt.hour = 0; dt.min = 0; dt.sec = 0;
   datetime tStart = StructToTime(dt);
   int barIdx = iBarShift(_Symbol, PERIOD_M1, tStart, false);
   if(barIdx >= 0) return iOpen(_Symbol, PERIOD_M1, barIdx);
   double buf[];
   if(CopyClose(_Symbol, PERIOD_D1, 1, 1, buf) == 1) return buf[0];
   return 0;
}

void GDEA_DrawATRLine(string name, double price, string text, color clr, datetime tStart, datetime tEnd)
{
   if(price <= 0) return;
   string objLine = "DLZ_ATR_L_" + name;
   string objLbl  = "DLZ_ATR_T_" + name;
   ObjectDelete(0, objLine);
   ObjectCreate(0, objLine, OBJ_TREND, 0, tStart, price, tEnd, price);
   ObjectSetInteger(0, objLine, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, objLine, OBJPROP_WIDTH, InpATRLineWidth);
   ObjectSetInteger(0, objLine, OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(0, objLine, OBJPROP_RAY_RIGHT, false);
   ObjectDelete(0, objLbl);
   ObjectCreate(0, objLbl, OBJ_TEXT, 0, tEnd, price);
   ObjectSetInteger(0, objLbl, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, objLbl, OBJPROP_FONTSIZE, InpATRLabelSize);
   ObjectSetString(0, objLbl, OBJPROP_TEXT, text + "  " + DoubleToString(price, _Digits));
   ObjectSetInteger(0, objLbl, OBJPROP_ANCHOR, ANCHOR_LEFT);
}

void DrawATRLevels()
{
   ObjectsDeleteAll(0, "DLZ_ATR_");

   double atr = GDEA_GetATRDaily(InpATRLevelsPeriod);
   if(atr <= 0) return;
   double baseline = GetATRBaseline();
   if(baseline <= 0) return;

   datetime tStart = iTime(_Symbol, PERIOD_D1, 0);
   datetime tEnd   = tStart + 86400;

   if(InpATRShow300)   GDEA_DrawATRLine("P300",  baseline + atr*3.0,  "ATR+300%", InpATRColorPlus300,  tStart, tEnd);
   if(InpATRShow250)   GDEA_DrawATRLine("P250",  baseline + atr*2.5,  "ATR+250%", InpATRColorPlus250,  tStart, tEnd);
   if(InpATRShow200)   GDEA_DrawATRLine("P200",  baseline + atr*2.0,  "ATR+200%", InpATRColorPlus200,  tStart, tEnd);
   if(InpATRShow150)   GDEA_DrawATRLine("P150",  baseline + atr*1.5,  "ATR+150%", InpATRColorPlus150,  tStart, tEnd);
   if(InpATRShow100)   GDEA_DrawATRLine("P100",  baseline + atr*1.0,  "ATR+100%", InpATRColorPlus100,  tStart, tEnd);
   if(InpATRShow75)    GDEA_DrawATRLine("P75",   baseline + atr*0.75, "ATR+75%",  InpATRColorPlus75,   tStart, tEnd);
   if(InpATRShow50)    GDEA_DrawATRLine("P50",   baseline + atr*0.50, "ATR+50%",  InpATRColorPlus50,   tStart, tEnd);
   if(InpATRShow25)    GDEA_DrawATRLine("P25",   baseline + atr*0.25, "ATR+25%",  InpATRColorPlus25,   tStart, tEnd);
   if(InpATRShowClose) GDEA_DrawATRLine("Close", baseline,            "AsiaOpen", InpATRColorClose,    tStart, tEnd);
   if(InpATRShow25)    GDEA_DrawATRLine("M25",   baseline - atr*0.25, "ATR-25%",  InpATRColorMinus25,  tStart, tEnd);
   if(InpATRShow50)    GDEA_DrawATRLine("M50",   baseline - atr*0.50, "ATR-50%",  InpATRColorMinus50,  tStart, tEnd);
   if(InpATRShow75)    GDEA_DrawATRLine("M75",   baseline - atr*0.75, "ATR-75%",  InpATRColorMinus75,  tStart, tEnd);
   if(InpATRShow100)   GDEA_DrawATRLine("M100",  baseline - atr*1.0,  "ATR-100%", InpATRColorMinus100, tStart, tEnd);
   if(InpATRShow150)   GDEA_DrawATRLine("M150",  baseline - atr*1.5,  "ATR-150%", InpATRColorMinus150, tStart, tEnd);
   if(InpATRShow200)   GDEA_DrawATRLine("M200",  baseline - atr*2.0,  "ATR-200%", InpATRColorMinus200, tStart, tEnd);
   if(InpATRShow250)   GDEA_DrawATRLine("M250",  baseline - atr*2.5,  "ATR-250%", InpATRColorMinus250, tStart, tEnd);
   if(InpATRShow300)   GDEA_DrawATRLine("M300",  baseline - atr*3.0,  "ATR-300%", InpATRColorMinus300, tStart, tEnd);
}

bool SafeSendNotification(string message)
{
   static datetime s_lastSend = 0;
   if(TimeCurrent() - s_lastSend < 10) { Print("[DLZ Push] Throttled: ", message); return false; }
   s_lastSend = TimeCurrent();
   bool ok = SendNotification(message);
   if(!ok) {
      int err = GetLastError();
      Print("[DLZ Push] Failed (err=", err, ") queued for retry: ", message);
      g_retryMsg   = message;
      g_retryAfter = TimeCurrent() + 5;
   } else {
      g_retryMsg = ""; // clear pending retry on successful send
   }
   return ok;
}

void CheckRetryNotification()
{
   if(g_retryMsg == "") return;
   if(TimeCurrent() < g_retryAfter) return;
   string msg = g_retryMsg;
   g_retryMsg  = ""; // clear before send to prevent double-queue
   bool ok = SendNotification(msg);
   if(!ok) Print("[DLZ Push] Retry failed (err=", GetLastError(), "): ", msg);
   else    Print("[DLZ Push] Retry OK: ", msg);
}
