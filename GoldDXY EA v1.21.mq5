//+------------------------------------------------------------------+
//|                   GoldDXY EA V1.30.mq5                        |
//+------------------------------------------------------------------+
//|  VERSION HISTORY                                                  |
//|  ---------------------------------------------------------------- |
//|  V.1.42 | 2026-04-21 | Z-Score Re-Check at Execute Time                       |
//|          | [Fix] OpenBuyPosition/OpenSellPosition: re-compute Z ก่อน submit    |
//|          |   ป้องกัน race condition ที่ signal ผ่าน Z=1.43 แต่ execute Z=1.87  |
//|          |   BUY: z >= g_sp.zLimit → block | SELL: z <= -g_sp.zLimit → block  |
//|  V.1.41 | 2026-04-13 | Hull SlopeLB — slope lookback หลาย bar ลด Whipsaw        |
//|          | [Feature] InpHL_SlopeLB: slope = Hull[i]-Hull[i-lb] แทน 1-bar diff  |
//|          |   default=3, ยิ่งมาก→เปลี่ยนสีช้าลง (เหมือน DLZ_EA SlopeLB)       |
//|  V.1.40 | 2026-04-13 | Fibonacci Price Gate — Block BUY/SELL at 127.2% Extension |
//|          | [Feature] InpFibGate_Enable: block BUY if ask>=127.2% ext (P26/P50) |
//|          |   block SELL if bid<=-127.2% ext (P26/P50). Per-bar log throttle.   |
//|  V.1.39 | 2026-04-02 | Slope Threshold ใน CheckHullTrendChange — consistent กับ  |
//|          | [Fix] GdxUpdateHull ใช้ InpHL_SlopeThreshold แล้ว แต่ Check       |
//|          |   HullTrendChange ยังแค่ hullCur>hullPrev → เพิ่ม thr เหมือนกัน  |
//|  V.1.38 | 2026-04-02 | ลบ V.1.33 Breakout Zone ออก → Hull color = entry ทันที |
//|          | [Remove] InpHL_BreakoutConfirm, InpHL_CancelBuffer, Pending vars  |
//|          | [Remove] WAIT/CANCEL block ใน OnTick — ลด over-filter ที่ทำให้    |
//|          |   ไม่มี Order ออกเลยทั้งวัน (Zone High/Low ของ Bar A strict เกิน) |
//|  V.1.37 | 2026-04-02 | Hull Cancel Buffer — ป้องกัน false cancel             |
//|          | [Feature] InpHL_CancelBuffer=4.0 USD: BUY cancel ต้องทะลุ Low-4$ |
//|          |   SELL cancel ต้องทะลุ High+4$ (ไม่ใช่แค่แตะ border)            |
//|  V.1.36 | 2026-04-02 | Z-Score per Session — ปรับ Spectrum ตาม Behavior   |
//|          | [Feature] London: เพิ่ม InpSF_London_ZScore=2.8 (ไม่มีมาก่อน) |
//|          | [Tune] Asia 1.5→1.8 | NYM 1.5→2.2 | NYPM คงที่ 1.5            |
//|  V.1.35 | 2026-04-02 | Fix log bug: HULL-TREND CANCEL แสดง High/Low=0     |
//|          | [Fix] Save High/Low ก่อน reset → Print ถูกต้อง               |
//|  V.1.34 | 2026-04-02 | Hull Slope Threshold — ลด Whipsaw สีสลับไปมา      |
//|          | [Feature] InpHL_SlopeThreshold: Hull ต้องขยับ >= X points   |
//|          |   ก่อนเปลี่ยนสี (default 3.0 pt = $0.30) กรอง noise M1     |
//|  V.1.33 | 2026-04-02 | Hull Breakout Confirm: Zone Box (High/Low of Bar A)|
//|          | [Fix] BUY:  Close > High[BarA] → Order, Close < Low[BarA] → Cancel|
//|          | [Fix] SELL: Close < Low[BarA]  → Order, Close > High[BarA] → Cancel|
//|          | [Fix] Hull กลับสีระหว่างรอ → Cancel Pending ฝั่งตรงข้ามทันที  |
//|          | [Fix] รอได้หลาย bar จนกว่าจะ Break หรือ Cancel              |
//|  V.1.32 | 2026-04-02 | Hull Breakout Confirm: Close > High[-1] / < Low[-1]|
//|          | [Feature] InpHL_BreakoutConfirm — filter Bull/Bear Trap |
//|          |   BUY: Close[0]>High[1], SELL: Close[0]<Low[1]         |
//|  V.1.31 | 2026-04-02 | InpStandardEntry_Enable — gate Standard Entry|


//|          | [Feature] ปิด Standard 7-step entry โดยไม่กระทบ       |
//|          |   Hull Trend Change / OFA×Hull Cross entry             |
//|  V.1.30 | 2026-04-01 | Scalp Analyst Panel: OFA MIXED suppress    |
//|          | [Fix] Panel Entry/TP1/SL/RR แสดง --- เมื่อ OFA MIXED  |
//|          | [Fix] Panel Decision: BLOCK — OFA MIXED (P26≠P50)      |
//|          | [Fix] Panel Mode: แสดง BULL/BEAR direction แทน session |
//|          | [Fix] TryOpenHullArrowTrade: เพิ่ม HTF Hull gate       |
//|          |   BUY blocked เมื่อ HTF DN, SELL blocked เมื่อ HTF UP  |
//|  V.1.29 | 2026-03-31 | TrendMode MaxSL แยกจาก Normal MaxSL        |
//|          | [Fix] [TrendMode] BUY/SELL ถูก block โดย LiqSL Cap     |
//|          |   เพิ่ม InpTrendMode_MaxSL (default 400)               |
//|          |   เมื่อ g_trendmode_active=ON ใช้ InpTrendMode_MaxSL   |
//|          |   แทน InpMaxSL_Distance ป้องกัน ATR(D1)×2 ถูก block   |
//|  V.1.28 | 2026-03-30 | Fix TrendMode SL log spam                    |
//|          | [Fix] [TrendMode] BUY/SELL SL log spam                   |
//|          |   เพิ่ม per-bar throttle (g_blk_trendmode_buy/sell_bar) |
//|          |   print ได้ 1 ครั้ง/แท่ง M1 แทนการ print ทุก tick      |
//|  V.1.27 | 2026-03-30 | Fix LiqFilter log spam                       |
//|          | [Fix] [LiqFilter] SELL/BUY blocked log spam              |
//|          |   เพิ่ม per-bar throttle (g_blk_liqflt_buy/sell_bar)    |
//|          |   print ได้ 1 ครั้ง/แท่ง M1 แทนการ print ทุก tick      |
//|  V.1.26 | 2026-03-30 | Tune ZCap+MaxSL + Fix LiqSL log spam        |
//|          | [Tune] InpSmartExit_ZCap 2.5→2.8                       |
//|          |   ถือ trade นานขึ้นก่อน Z-Cap exit (8 trade/วัน +$52)  |
//|          | [Tune] InpMaxSL_Distance 60→80                          |
//|          |   unlock 8 trade ที่ SL=60-80 ที่ถูก block ต่อวัน      |
//|          | [Fix] [LiqSL Cap] + OpenBuy/Sell "SL too wide" log spam |
//|          |   เพิ่ม per-bar throttle (g_blk_liqsl_buy/sell_bar)    |
//|          |   print ได้ 1 ครั้ง/แท่ง M1 แทนการ print ทุก tick      |
//|  V.1.25 | 2026-03-30 | Fix Entry=0.00 + HTF Bypass after restart  |
//|          | [BugFix] OnInit: recover g_buyOpenPrice/g_sellOpenPrice  |
//|          |   จาก broker เมื่อ EA restart ขณะมี position เปิดอยู่   |
//|          | [BugFix] InpHTFExit_MinLossUSD default 200→20            |
//|          |   ป้องกัน SELL ค้างอยู่เมื่อ HTF flip UP แต่ loss < $200 |
//|          | [BugFix] HTF warmup guard: block trades เมื่อ            |
//|          |   g_htf_hull_trend==0 (ยังไม่โหลดเสร็จหลัง reinit)      |
//|  V.1.24 | 2026-03-30 | Throttle SF-4a Z-Score BLOCKED log          
//|          | [Fix] g_blk_zscore_buy/sell bool → datetime bar guard    |
//|          |   พิมพ์ [SF-4a] Z-Score BLOCKED ได้ 1 ครั้ง/แท่งM1      |
//|          |   แทนการใช้ bool ที่ reset ทุก tick → log spam           |
//|  V.1.23 | 2026-03-30 | Fib Levels ครบตามตาราง + Zone Desc         |
//|          | [Feature] DrawFibSet: ขยาย 5→11 levels                  |
//|          |   เพิ่ม 78.6%, 100%, 127.2%, 261.8%, -127.2%, -261.8%  |
//|          | [Feature] CheckFibNotify: เพิ่ม pct param → FibZoneDesc |
//|          |   msg: [P26] 61.8% | BUY | ⭐⭐⭐ Golden Ratio | ...      |
//|          | [Feature] DrawFibRetracement: notify ครบ 11 levels      |
//|  V.1.22 | 2026-03-30 | Fix Smart Exit ปิด SELL ทันทีหลัง open    |
//|          | [BugFix] CheckSmartFibExit Hard TP 261.8%:              |
//|          |   1. เพิ่ม rng > 0 guard ป้องกัน swing HH/LL ทำ rng<0  |
//|          |   2. เพิ่ม sanity check: p261 ต้องอยู่ฝั่งกำไรก่อน    |
//|          |      (BUY: p261>entry, SELL: p261<entry)                |
//|  V.1.21 | 2026-03-28 | Session Specialization + Scalp Analyst   |
//|          | [10a] Asia Stop Hunt Guard (ATR M75/P75 block)         |
//|          | [10b] NY Afternoon HalfLot option (InpNYPM_HalfLot)   |
//|          | [10c] London Breakout Boost TP factor → 1.0            |
//|          | [11]  M1 Scalp Analyst Dashboard (Display Only)        |
//|          | [V.20i] Directional ATR consumption (up/down แยกกัน)  |
//|          | [V.20h] ATRExhaust_Cap 0.80→1.10, TrendMode default ON |
//|          | [V.21]  RR Float Precision Fix                         |
//|          |         → actualRR < InpMinRR - 0.001 (tolerance fix)  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026"
#property version   "1.42"
#property strict

#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| INPUTS                                                           |
//+------------------------------------------------------------------+
// ══════════════════════════════════════════════════════════════════
// [1]  EA IDENTITY
// ══════════════════════════════════════════════════════════════════
input group "--- [1] EA Info ---"
input string inpEaObject       = "GoldDXY EA v1.42";
static input long   InpMagicnumber = 8821;

// ══════════════════════════════════════════════════════════════════
// [2]  SIGNAL CORE — Entry Accuracy  ★★★★★
//      ตัวแปรเหล่านี้ส่งผลโดยตรงต่อ WinRate / ความแม่นยำ entry
// ══════════════════════════════════════════════════════════════════
input group "--- [2a] GoldDXY Core (Signal Engine) ---"
input string InpDXY_Symbol     = "DXYm";          // Symbol DXY ที่ใช้
input int    InpZPeriod        = 14;               // Z-Score lookback bars
input double InpGoldZLimit     = 1.3;             // Z-Score limit |z|<X (ป้องกัน overbought) ★ [V.14: 1.0→1.3]
input double InpMomentumRatio  = 0.6;             // Momentum ratio ขั้นต่ำ (body/range) ★
input int    InpGoldCheckBars  = 4;               // Momentum check bars ★
input int    InpMacroBars      = 30;              // Macro Trendline bars (Step 1)
input int    InpRecentBars     = 10;              // Recent Trendline bars (Step 2)
input int    InpTriggerBars    = 3;               // DXY Trigger bars (Step 3) ★
input int    InpMinBarGap      = 5;               // Min bar gap ระหว่าง signals

input group "--- [2b] MACD Filter (Step 5) ---"
input bool   InpUseMACDFilter  = true;            // เปิด/ปิด MACD Filter ★
input int    InpMACD_Fast      = 12;
input int    InpMACD_Slow      = 26;
input int    InpMACD_Signal    = 9;
input double InpMACD_MinGap    = 0.0;             // MACD line vs signal ขั้นต่ำ ★

input group "--- [2c] Hull Suite (Step 6) ---"
input int    InpHL_Period      = 50;              // Hull Period ★
input double InpHL_Divisor     = 2.0;
input ENUM_APPLIED_PRICE InpHL_Price = PRICE_CLOSE;
input double InpHL_SlopeThreshold = 8.0;          // Hull Slope Threshold (points) — ลด Whipsaw ★
input int    InpHL_SlopeLB        = 10;            // Hull Slope Lookback bars (1=fast, 3-5=slow) ★

input group "--- [2d] HTF Hull Trend Lock — SolD (Step 6b) ---"
input bool              InpHTF_Enable     = true;         // เปิด/ปิด HTF Hull Lock ★
input ENUM_TIMEFRAMES   InpHTF_Timeframe  = PERIOD_M15;   // Timeframe HTF Hull ★
input int               InpHTF_Period     = 50;           // Hull Period บน HTF
input bool              InpHTF_StrictMode = true;        // Strict: block ทั้ง BUY+SELL ถ้าไม่ align

input group "--- [2e] OFA Order Flow (Step 7) ---"
input bool   InpOFA_AggressiveFractal   = true;
input int    InpOFA_FractalPeriod       = 26;             // Fast fractal period ★
input int    InpOFA_FractalPeriod2      = 50;             // Slow fractal period ★

// ══════════════════════════════════════════════════════════════════
// [3]  SESSION-ADAPTIVE FILTER  ★★★★★  [V.5 NEW]
//      ปรับความเข้มของ 7 Steps ตาม Session character
//      ป้องกัน Buy ที่ยอด / Sell ที่ก้น แบบ context-aware
// ══════════════════════════════════════════════════════════════════
input group "--- [3] Session Filter — Master Switch ---"
input bool   InpSF_Enable              = true;    // เปิด/ปิด Session-Adaptive Filter ทั้งหมด ★

input group "--- [3a] Asia Session (00-08 GMT+2) — Strict ---"
// Asia = Range-bound, ความเสี่ยง Buy-top/Sell-bottom สูงสุด
input double InpSF_Asia_ZScore         = 1.8;    // Z-Score ≤ X (Asia range-bound) ★ [V.1.36: 1.5→1.8]
input int    InpSF_Asia_TrigBars       = 5;      // DXY Trigger bars (รอชัดกว่าปกติ 3) ★
input int    InpSF_Asia_MomBars        = 6;      // Momentum check bars (เข้มกว่าปกติ 4)
input double InpSF_Asia_MACDGap        = 0.30;   // MACD MinGap (กรอง noise ปกติ=0.0) ★
input double InpSF_Asia_RangeGuard     = 0.70;   // Block BUY ใกล้ Asia VAH/SELL ใกล้ VAL ≥ X% ของ range ★

input group "--- [3b] London Session (08-13 GMT+2) — Breakout ---"
// London = Breakout session, ระวัง Fake Move 15 นาทีแรก
input double InpSF_London_ZScore      = 2.8;    // Z-Score ≤ X (London breakout ผ่อนสุด) ★ [V.1.36: new]
input int    InpSF_London_OpenMins     = 15;     // Block entry N นาทีแรกหลัง London open ★
input bool   InpSF_London_WaitSweep   = true;   // รอ London sweep Asia High/Low ก่อน entry ★

input group "--- [3c] NY Morning (13-17 GMT+2) — Continuation ---"
// NY Morning = Breakout continuation จาก London
input double InpSF_NYM_ZScore          = 2.2;    // Z-Score ผ่อนสำหรับ breakout continuation ★ [V.1.36: 1.5→2.2]

input group "--- [3d] NY Afternoon (17-21 GMT+2) — Fatigue ---"
// NY Afternoon = ตลาดมักหมดแรง ระวังซื้อยอด/ขายก้น
input int    InpSF_NYPM_StartHr        = 17;     // NY Afternoon เริ่มกี่โมง (server hour) ★
input double InpSF_NYPM_ZScore         = 2.2;    // Z-Score กลับมา standard
input double InpSF_NYPM_ATRCap         = 0.90;   // Block ถ้า Daily ATR consumed ≥ X% ★

input group "--- [3e] Daily ATR Exhaustion — ทุก Session (Step 4c) ---"
// ป้องกัน entry ตอนที่ตลาด "วิ่งไปแล้ว" ส่วนใหญ่ของวัน
input bool   InpSF_ATRExhaust_Enable   = true;   // เปิด/ปิด Daily ATR Exhaustion filter ★
input double InpSF_ATRExhaust_Cap      = 1.10;   // Block entry ถ้าวันนี้วิ่ง ≥ X% ของ ATR(D1) ★ [V.20h: 0.80→1.10]

input group "--- [3f] Wick Ratio Filter — Stop Hunt V.11 ---"
// กรอง entry ที่ไม่มี Rejection Candle → ลด Buy-Top/Sell-Bottom
input bool   InpWick_Enable       = false;  // [V.14] ปิด — M1 impulse bar ไม่มี wick = strong momentum (ดี)
input double InpWick_MinRatio     = 0.25;
input int    InpWick_LookbackBars = 5;

// ══════════════════════════════════════════════════════════════════
// [4]  SL/TP SETUP  ★★★★☆
// ══════════════════════════════════════════════════════════════════
input group "--- [4a] Swing SL/TP (Primary) ---"
input bool   InpUseSwingSL     = true;            // ใช้ Swing High/Low เป็น SL แทน ATR ★
input bool   InpUseSwingTP     = true;            // ใช้ Swing ตรงข้ามเป็น TP
input bool   InpTP_UseFib      = true;            // เพิ่ม Fib -61.8%/161.8% เป็น TP Candidate
input bool   InpTP_UseSession  = true;            // Cap TP ด้วย Session Remaining Range
input double InpTP_Asia_Factor   = 0.50;          // Asia TP Cap = Remaining × Factor ★
input double InpTP_London_Factor = 0.75;          // London TP Cap = Remaining × Factor ★
input double InpTP_NY_Factor     = 1.00;          // NY TP Cap = Remaining × Factor
input double InpSwingBuffer    = 0.30;            // buffer เพิ่มจาก Swing price (price value)
input double InpLondon_SLBuffer = 5.0;           // extra SL buffer ใน London session (price pts) — V.18 ★
input double InpMinRR          = 1.5;             // RR ขั้นต่ำ → ถ้าไม่ถึง ไม่เปิด Order ★
input int    InpSwingLookback  = 3;               // ใช้ Swing ย้อนหลังกี่จุด (1=ล่าสุด)

input group "--- [4b] ATR SL/TP (Fallback) ---"
input bool   InpUseATR_SL      = true;
input int    InpATRPeriod      = 14;
input double InpATRMulti       = 1.5;
input double InpMinProfitUSD   = 5.0;

input group "--- [4c] Liquidity-Aware SL — SolC ---"
input bool   InpLiqSL_Enable   = true;            // เปิด/ปิด Liquidity-Aware SL ★
input double InpLiqSL_Zone     = 0.50;            // ระยะ SL "ใกล้" ATR Level (price) [V.2: 0.15→0.50]
input double InpLiqSL_Buffer   = 0.50;            // buffer = ATR Daily × factor [V.2: 0.30→0.50]
input bool   InpLiqSL_Notify   = true;
input double InpMaxSL_Multiplier = 3.0;           // Adjusted SL ≤ Original SL × N (0=ปิด)
input double InpMaxSL_Distance   = 80.0;          // Hard cap SL distance (price, 0=ปิด) [V.1.26: 60→80]
input bool   InpLiqZone_Filter   = true;          // Block Order ถ้า Zone กีดขวางทิศ TP ★
input double InpLiqZone_MinDist  = 5.0;          // ระยะขั้นต่ำจาก Entry ถึง Zone (USD)
input bool   InpLiqZone_AllowRaid = true;         // อนุญาตถ้า Zone Raided แล้ว
input int    InpLiqZone_MaxCheck  = 2;            // ตรวจเฉพาะ N Zone ที่ใกล้ Entry ที่สุด

// ══════════════════════════════════════════════════════════════════
// [5]  RISK MANAGEMENT  ★★★★☆
// ══════════════════════════════════════════════════════════════════
input group "--- [5a] Lot & Risk ---"
input double InpLotSize        = 0.01;            // [V.12] กลับ FIXED=0.01 (PCT_ACCOUNT ใช้ไม่ได้บน $1000+XAUUSDm)
enum LOT_MODE_ENUM { LOT_MODE_FIXED, LOT_MODE_MONEY, LOT_MODE_PCT_ACCOUNT };
input LOT_MODE_ENUM InpLotMode = LOT_MODE_FIXED;  // [V.12] revert → PCT_ACCOUNT lot min เกิน risk budget
input bool   InpCloseSignal    = false;

input group "--- [5b] Position Limit ---"
input int    InpTotalPosition  = 2;               // จำนวน Position สูงสุดต่อทิศ ★
input double InpTotalTP        = 0;               // ปิดทั้งหมดเมื่อ Total PnL ≥ X USD
input bool   InpBuyPosition    = true;
input bool   InpSellPosition   = true;
input bool   InpStandardEntry_Enable = false; // เปิด/ปิด Standard Entry (7 ขั้นตอน) ★

input group "--- [5c] Break-Even ---"
input bool   InpBE_Enable      = true;            // เปิด/ปิด Break-Even ★
input double InpBE_TriggerRR   = 0.3;             // ระยะ Trigger BE คิดเป็นสัดส่วนของ SL (เช่น 0.3 = 0.3R) ★
input double InpBE_ProfitUSD   = 3.0;             // [เพิ่มใหม่] ล็อกกำไรบวกเพิ่มจากหน้าทุน (USD) ★
input double InpBE_BufferPts   = 2.0;             // (Fallback) กรณีคำนวณไม่ได้ จะใช้ค่า Buffer นี้แทน
input bool   InpBE_Notify      = true;

input group "--- [5d] Same-SL Cooldown — SolB ---"
input bool   InpSameSL_Enable    = true;          // เปิด/ปิด Same-SL Cooldown ★
input int    InpSameSL_MaxTrades = 3;             // เปิดซ้ำบน SL เดิมได้สูงสุด N ครั้ง
input double InpSameSL_Tolerance = 1.0;           // tolerance ถือว่า SL "เดิม" (price)
input int    InpSameSL_Cooldown  = 30;            // นาทีรอหลังชนะครบ MaxTrades (0=ปิด)

input group "--- [5e] Daily Profit Target ---"
input bool   InpProfitTarget_Enable = true;
input double InpProfitTarget_Total  = 10.0;      // ปิดทั้งหมดเมื่อ Floating ≥ X USD ★
input double InpProfitTarget_Buy    = 3.0;       // ปิด BUY เมื่อ Floating BUY ≥ X USD
input double InpProfitTarget_Sell   = 3.0;       // ปิด SELL เมื่อ Floating SELL ≥ X USD
input bool   InpProfitTarget_Notify = true;

input group "--- [5f] Daily Loss Limit — V.11 ---"
// หยุดเทรดทั้งวันถ้า Realized Loss รวม ≥ X USD
input bool   InpDailyLoss_Enable = false;         // [V.9 restore] ปิด Daily Loss Limit
input double InpDailyLoss_Limit  = 100.0;         // หยุดเทรดถ้า daily loss ≥ X USD ★
input bool   InpDailyLoss_Notify = true;

// ══════════════════════════════════════════════════════════════════
// [6]  EXIT MANAGEMENT  ★★★☆☆
// ══════════════════════════════════════════════════════════════════
input group "--- [6a] VP Early Exit — SolA ---"
input bool   InpVPExit_Enable      = false;       // เปิด/ปิด VP Early Exit ★
input int    InpVPExit_ConfirmBars = 5;           // ยืนยัน N bar (ป้องกัน false breakout)
input bool   InpVPExit_Notify      = true;

input group "--- [6c] HTF Hull Exit — V.17 ---"
input bool   InpHTFExit_Enable = true;         // ปิด position ทันทีเมื่อ HTF Hull (H1) พลิกสวนทิศ ★
input bool   InpHTFExit_Notify = true;         // แจ้งเตือนเมื่อ HTF Exit ทำงาน
input double InpHTFExit_MinLossUSD = 0;    // exit เฉพาะถ้า float loss >= $X (ป้องกัน false flip) [V.25: 200→20]

input group "--- [6b] VP Session Filter (Step 8) ---"
input bool   InpVP_FilterEnable        = false;   // เปิด/ปิด VP Filter
input bool   InpVP_UseEntryZone        = true;    // BUY ใกล้ VAL / SELL ใกล้ VAH
input bool   InpVP_UseBreakout         = true;    // กรอง VP State: Breakout ยืนยัน
input bool   InpVP_UseRetest           = true;    // กรอง Retest หลัง Breakout
input bool   InpVP_UseTPTarget         = false;   // ใช้ POC/VAH/VAL เป็น TP แทน RR
input double InpVP_EntryZonePts        = 0.50;    // ระยะ "ใกล้" VAL/VAH [FBS≈0.50]

input group "--- [6d] Smart Fibonacci Exit (New) ---"
input bool   InpSmartExit_Enable   = true;  // เปิดใช้งานระบบ Smart Exit ★
input double InpSmartExit_ZCap     = 2.8;   // Z-Score Super Cap (ถึงค่านี้ปิดทันที) ★ [V.1.26: 2.5→2.8]
input bool   InpSmartExit_Notify   = true;  // แจ้งเตือนเมื่อปิดด้วย Smart Exit

// ══════════════════════════════════════════════════════════════════
// [7]  SESSION CONTEXT — VP + Session Box  ★★★☆☆
// ══════════════════════════════════════════════════════════════════
input group "--- [7a] Session Hours (GMT+2 Server Time) ---"
input int    InpAsiaStartHr            = 0;       // Asia Start Hour ★
input int    InpAsiaEndHr              = 8;       // Asia End Hour ★
input int    InpLondonStartHr          = 8;       // London Start Hour ★
input int    InpLondonEndHr            = 13;      // London End Hour ★
input int    InpNYStartHr              = 13;      // NY Start Hour ★
input int    InpNYEndHr                = 21;      // NY End Hour ★

input group "--- [7b] VP Session Monitor ---"
input bool   InpVpSession              = true;
input int    InpVpRowSize              = 100;
input double InpVpValueArea            = 0.68;
input double InpRetestTolerancePts     = 1.50;    // Retest tolerance [FBS≈1.50]
input double InpBreakoutBufferPts      = 1.00;    // Breakout buffer (price)
input double InpVpConfluenceRange      = 2.00;    // VP Confluence range (price)
input bool   InpVpNotifyBreakout       = true;
input bool   InpVpNotifyRetest         = true;
input bool   InpVpNotifyConfl          = true;
input bool   InpExtendNYtoAsia         = true;
input color  InpColorPOC_Asia          = clrDeepPink;
input color  InpColorPOC_London        = clrDarkOrange;
input color  InpColorPOC_NY            = clrDodgerBlue;
input color  InpColorVAH               = clrLime;
input color  InpColorVAL               = clrOrangeRed;

input group "--- [7c] Session Box ---"
input bool   InpShowSessionBox         = true;
input bool   InpSessionBoxAsiaEnable   = true;
input bool   InpSessionBoxLondonEnable = true;
input bool   InpSessionBoxNYEnable     = true;
input int    InpSessionBoxLookbackDays = 3;
input color  InpSessionBoxAsiaColor    = C'30,60,100';
input color  InpSessionBoxLondonColor  = C'30,90,50';
input color  InpSessionBoxNYColor      = C'100,55,20';
input bool   InpSessionBoxBorder       = true;
input int    InpSessionBoxBorderWidth  = 3;
input bool   InpSessionBoxLabel        = true;
input int    InpSessionBoxLabelSize    = 11;
input bool   InpSessionBoxShowHL       = true;
input int    InpSessionBoxHLWidth      = 2;

// ══════════════════════════════════════════════════════════════════
// [8]  VISUAL / DISPLAY  ★★☆☆☆  (ไม่กระทบ Logic การเทรด)
// ══════════════════════════════════════════════════════════════════
input group "--- [8a] Dashboard & Panels ---"
input bool   InpShowDashboard  = true;
input int    InpDashX          = 15;
input int    InpDashY          = 20;
input bool   InpSendAlert      = false;
input bool   InpShowSMPanel    = true;
input int    InpSMPanelX       = 15;

input group "--- [8b] TP/SL Box Visual ---"
input bool   InpRR_DrawEnable  = true;
input double InpRR             = 1.5;
input int    InpRR_LookbackSwing = 100;
input int    InpRR_SlOffset    = 500;
input int    InpRR_LineLen     = 10;
input int    InpArrowSize      = 3;
input int    InpArrowPoints    = 150;
input color  InpRR_TPColor     = clrLime;
input color  InpRR_SLColor     = clrCrimson;
input bool   InpRR_ShowText    = true;
input color  InpRR_TextColor   = clrWhite;
string       InpRR_ObjPrefix   = "GDEA_RR_";

input group "--- [8c] Hull Visual ---"
input bool   InpHL_ShowLine    = true;
input color  InpHL_UpColor     = clrMediumSeaGreen;
input color  InpHL_DownColor   = clrOrangeRed;
input int    InpHL_LineWidth   = 2;
input bool   InpHL_ColorArrow       = false;   // วาดลูกศร เมื่อ OFA P26 ตัดกับ Hull Suite (ขึ้น=เขียว ลง=แดง) ★
input bool   InpHL_ColorArrow_Trade = false;   // เปิด Trade เมื่อ OFA×Hull cross arrow ★
input bool   InpHL_TrendArrow       = true;   // วาดลูกศร เมื่อ Hull เปลี่ยนสี (แดง→เขียว=ขึ้น, เขียว→แดง=ลง) ★
input bool   InpHL_TrendArrow_Trade = true;   // เปิด Trade เมื่อ Hull color-change arrow ★

input group "--- [8d] Trendlines ---"
input bool            InpShowTL_Step1    = true;
input color           InpColorTL_S1_Gold = clrGold;
input int             InpWidthTL_Step1   = 2;
input ENUM_LINE_STYLE InpStyleTL_S1      = STYLE_SOLID;
input bool            InpShowTL_Step2    = true;
input color           InpColorTL_S2_Gold = clrYellow;
input int             InpWidthTL_Step2   = 1;
input ENUM_LINE_STYLE InpStyleTL_S2      = STYLE_DOT;

input group "--- [8e] OFA Display ---"
input bool   InpOFA_ShowZigzag          = true;
input bool   InpOFA_ShowZigzag2         = true;
input color  InpOFA_BullishColour       = clrDodgerBlue;
input color  InpOFA_BearishColour       = clrOrangeRed;
input color  InpOFA_SlowBullColour      = clrDeepSkyBlue;
input color  InpOFA_SlowBearColour      = clrTomato;
input int    InpOFA_SlowLineWidth       = 3;
input bool   InpOFA_DisplayCurrentSwing = true;
input bool   InpOFA_ShowLabels          = true;
input bool   InpOFA_IncludeVelMag       = true;
input bool   InpOFA_IncludePriceChange  = true;
input bool   InpOFA_IncludePercentChange= false;
input bool   InpOFA_IncludeBarChange    = false;
input bool   InpOFA_ShowFibLabel        = true;  // [V.20e] แสดง Fibo XX.X% บน swing label
input int    InpOFA_LabelFontSize       = 9;
input int    InpOFA_MaxBars             = 1000;
input bool   InpOFA_SendNotification    = false;
input bool   InpOFA_SendAlert2          = false;
input bool   InpOFA_NotifyBullOnly      = false;
input bool   InpOFA_NotifyBearOnly      = false;
input bool   InpOFA_NotifyOnLiveSwing   = true;
input double InpOFA_NotifyUpdatePts     = 5.0;
input double InpOFA_NotifyUpdatePct     = 50.0;

input group "--- [8f] Fibonacci Retracement (p26) ---"
input bool   InpFib_Enable     = true;
input color  InpFib_Color382   = clrGold;
input color  InpFib_Color50    = clrWhite;
input color  InpFib_Color618   = clrOrange;
input color  InpFib_ColorN618  = clrCrimson;
input color  InpFib_Color1618  = clrDeepSkyBlue;
input int    InpFib_LineWidth  = 1;
input int    InpFib_LabelSize  = 8;
input int    InpFib_LabelOffset = 15;
input bool   InpFib_Notify     = true;

input group "--- [8g] Fibonacci p50 ---"
input bool   InpFib50_Enable    = true;
input color  InpFib50_Color382  = C'180,140,0';
input color  InpFib50_Color50   = C'180,180,180';
input color  InpFib50_Color618  = C'180,80,0';
input color  InpFib50_ColorN618 = C'160,30,30';
input color  InpFib50_Color1618 = C'30,100,160';
input int    InpFib50_LabelOffset = 35;

input group "--- [8h] Liquidity Zone Box ---"
input bool   InpLiqBox_Enable      = true;
input bool   InpLiqBox_ShowSwing   = true;
input bool   InpLiqBox_ShowEQHL    = true;
input double InpLiqBox_SwingFactor = 0.04;
input double InpLiqBox_EQLTol      = 5.0;
input int    InpLiqBox_SwingLookback = 5;
input color  InpLiqBox_BuyStopClr  = C'20,60,120';
input color  InpLiqBox_SellStopClr = C'120,20,20';
input color  InpLiqBox_EQHLClr     = C'80,20,100';
input bool   InpLiqBox_Notify      = true;
input bool   InpLiqBox_NotifyEnter = true;
input bool   InpLiqBox_NotifyRaid  = true;

input group "--- [8i] ATR Previous Day Levels ---"
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

input group "--- [8j] Notifications ---"
input bool InpSendPush         = true;
input int  InpQuietHourStart   = 22;     // Quiet เริ่ม (Server hour GMT+2) = ตี3 ไทย
input int  InpQuietHourEnd     = 1;      // Quiet สิ้นสุด = ตี6 ไทย (GMT+2:22/1 | GMT+3:23/2)

input group "--- [8k] Trade Time Window ---"
input string inpStartTime      = "00:00";
input string inpEndTime        = "23:59";

// ══════════════════════════════════════════════════════════════════
// [9]  TREND MODE — Dynamic Bypass  ★★★★★  [V.19 NEW]
//      เมื่อตลาด Trend รุนแรง: bypass Asia Range Guard,
//      ผ่อน Z-Score + ATR cap, ใช้ ATR-based SL + ATR PDATr TP
// ══════════════════════════════════════════════════════════════════
input group "--- [9] Trend Mode — Dynamic Bypass V.19 ---"
input bool   InpTrendMode_Enable  = false;  // เปิด/ปิด Trend Mode [V.1.32: false] bypass ATR cap ใน trend ★
input double InpTrend_ATRConsume  = 0.30;   // ATR consumed ขั้นต่ำเพื่อเปิด Trend Mode (0.30=30%) ★
input double InpTrend_ZLimit      = 2.50;   // Z-Score limit เมื่อ TrendMode (ผ่อนกว่าปกติ 1.3) ★
input double InpTrend_ATRCap      = 1.20;   // ATR Exhaustion cap เมื่อ TrendMode (120% = ไม่บล็อก) ★
input double InpTrend_SLMulti     = 2.00;   // SL = ATR(D1)×N เมื่อ TrendMode (แทน Swing SL) ★
input double InpTrendMode_MaxSL   = 400.0;  // Hard cap SL distance เมื่อ TrendMode ON (รองรับ ATR(D1)×2) ★ [V.1.29]
input bool   InpTrend_PartialTP   = true;   // Partial close 50% เมื่อถึง ATR M25/P25 ★

// ══════════════════════════════════════════════════════════════════
// [10]  SESSION SPECIALIZATION — V.20 Per-Session Character ★★★★☆
//       แต่ละ Session มี logic แยกชัดเจน ไม่งง ไม่ปนกัน
// ══════════════════════════════════════════════════════════════════
input group "--- [10a] Asia — Stop Hunt Guard V.20 ---"
// Asia = Range-bound, ATR M75/P75 เป็น Stop Hunt reversal zone
input bool   InpAsia_StopHuntGuard = true;   // Block SELL ถ้า price ≤ ATR M75 (reversal zone) ★
input double InpAsia_M75_Buffer    = 0.30;   // Buffer รอบ M75/P75 level (price pts)
input int    InpAsia_MaxPositions  = 1;      // Max positions ใน Asia session (0=ปิด check) ★

input group "--- [10b] NY Afternoon — Fatigue Protection V.20 ---"
// NY Afternoon = ตลาดหมดแรง, Lot ลดเพื่อป้องกัน Fade-into-reversal
input bool   InpNYPM_HalfLot       = false;  // ลด lot 50% ใน NY Afternoon session ★

input group "--- [10c] London — Breakout Boost V.20 ---"
// London Breakout: ถ้า sweep+OFA+HTF aligned → TP factor boost 1.0
input bool   InpLon_BreakoutBoost  = true;   // TP factor → 1.0 เมื่อ strong London breakout ★

input group "--- [11] M1 Scalp Analyst (Display Only) V.20d ---"
// Read-only dashboard วิเคราะห์ Scenario + Entry Zone สำหรับ M1 Scalping
input bool   InpScalp_Enable      = true;    // เปิด Scalp Analyst Dashboard ★
input int    InpScalp_X           = 10;      // ตำแหน่ง X (pixels จากซ้าย)
input int    InpScalp_Y           = 360;     // ตำแหน่ง Y (pixels จากบน)
input double InpScalp_WickRatio   = 0.30;    // wick/range สำหรับ Rejection candle (0.30 = 30%)
input int    InpScalp_RaidBuffer  = 10;      // pts จาก Swing Low/High = "near STOPS zone"
input int    InpScalp_BExpireBars = 30;      // bars ก่อน Scenario B/D หมดอายุ
input bool   InpScalp_Circles     = true;    // วาดวงกลม Entry Zone บนกราฟ ★
input int    InpScalp_CircleBars  = 15;      // ความกว้างวงกลม (bars)
input double InpScalp_CirclePts   = 8.0;     // ความสูงวงกลม (price points)

input group "--- [12] Fib Price Gate — V.1.40 ---"
input bool   InpFibGate_Enable    = true;    // Block BUY/SELL at 127.2% Extension ★

//+------------------------------------------------------------------+
//| GLOBALS                                                          |
//+------------------------------------------------------------------+

// ── V.5: Session-Adaptive Filter — Session Enum ──────────────────
enum ENUM_SF_SESSION {
   SESSION_ASIA,           // 00:00–08:00 GMT+2  Range, strict filter
   SESSION_LONDON,         // 08:00–13:00 GMT+2  Breakout, sweep check
   SESSION_NY_MORNING,     // 13:00–InpSF_NYPM_StartHr  Continuation, relaxed Z
   SESSION_NY_AFTERNOON,   // InpSF_NYPM_StartHr–21:00  Fatigue, ATR cap
   SESSION_OFF             // นอกช่วง session หลัก
};

// ── V.20: SessionProfile — character ของแต่ละ Session ─────────────
// สร้างครั้งเดียวต่อ tick ใน ReadGoldDXYSignal → ใช้ใน Open functions
struct SessionProfile {
   double   zLimit;          // Z-Score threshold per session
   int      trigBars;        // DXY trigger bars per session
   double   macdGap;         // MACD min gap per session
   double   atrCap;          // ATR exhaustion cap per session
   double   slBufferPts;     // extra SL buffer (pts) — เช่น London +5 pts
   double   tpFactor;        // TP = remaining range × factor
   double   rangeGuard;      // Asia range guard % (0=ปิด)
   bool     waitSweep;       // London: รอ Asia sweep ก่อน entry
   int      openBlockMins;   // London: block N min แรก (0=ปิด)
   bool     stopHuntZone;    // Asia: price ใกล้ ATR M75/P75 = reversal risk
   int      maxPositions;    // max positions ที่เปิดได้ใน session (0=ปิด)
   double   lotMultiplier;   // 1.0=normal, 0.5=half lot (NYPM fatigue)
};
SessionProfile g_sp;    // current session profile — set in ReadGoldDXYSignal

CTrade Trade;
MqlTick currentTick;

int    g_atr_handle   = INVALID_HANDLE;
int    g_macd_handle  = INVALID_HANDLE;
int    g_atr_d1_handle = INVALID_HANDLE;  // Phase1Fix: global D1 ATR — ป้องกัน handle leak ใน GetDailyData/DrawTradeHighLowSetup
string OBJ_PREFIX     = "GDEA21_";
string SB_Prefix      = "GDEA21_SB_";
string LIQ_PREFIX     = "GDEA21_LIQ_";
string FIB_PREFIX     = "GDEA21_FIB_";

// Liquidity Box state — Raid detection
struct LiqZoneState {
   double   zoneHigh;          // บน Zone
   double   zoneLow;           // ล่าง Zone
   bool     priceWasInside;    // ราคาเคยเข้า Zone แล้ว
   bool     raidNotified;      // ส่ง notification Raid/Breakout แล้ว
   bool     enterNotified;     // ส่ง notification Enter แล้ว
   datetime lastEnterTime;     // เวลาที่ส่ง Enter ล่าสุด
   datetime lastExitTime;      // เวลาที่ออกจาก Zone ล่าสุด (cooldown re-enter)
   double   entryFromPrice;    // ราคาก่อนเข้า Zone
   bool     isBuyStopsZone;    // true=BUY STOPS, false=SELL STOPS
   string   label;
};
LiqZoneState g_liqZones[];   // array ของทุก Zone ที่วาดไว้
datetime     g_eaStartTime = 0;  // เวลาที่ EA load — ใช้ delay notification ช่วงแรก
datetime     g_liqLastGlobalEnter = 0;  // Global cooldown — ส่ง Enter ได้แค่ 1 ข้อความต่อรอบ

// Fib 50% notification cooldown — reset เมื่อ Swing เปลี่ยน
// Fib notification cooldown — p26
datetime g_fib26_382_lastNotify  = 0;  double g_fib26_382_lastLevel  = 0;  // 38.2%
datetime g_fib26_50_lastNotify   = 0;  double g_fib26_50_lastLevel   = 0;  // 50.0%
datetime g_fib26_618_lastNotify  = 0;  double g_fib26_618_lastLevel  = 0;  // 61.8%
datetime g_fib26_786_lastNotify  = 0;  double g_fib26_786_lastLevel  = 0;  // 78.6%
datetime g_fib26_100_lastNotify  = 0;  double g_fib26_100_lastLevel  = 0;  // 100%
datetime g_fib26_1272_lastNotify = 0;  double g_fib26_1272_lastLevel = 0;  // 127.2% ext up
datetime g_fib26_1618_lastNotify = 0;  double g_fib26_1618_lastLevel = 0;  // 161.8% ext up
datetime g_fib26_2618_lastNotify = 0;  double g_fib26_2618_lastLevel = 0;  // 261.8% ext up
datetime g_fib26_n618_lastNotify = 0;  double g_fib26_n618_lastLevel = 0;  // -61.8% ext dn
datetime g_fib26_n1272_lastNotify= 0;  double g_fib26_n1272_lastLevel= 0;  // -127.2% ext dn
datetime g_fib26_n2618_lastNotify= 0;  double g_fib26_n2618_lastLevel= 0;  // -261.8% ext dn
// Fib notification cooldown — p50
datetime g_fib50_382_lastNotify  = 0;  double g_fib50_382_lastLevel  = 0;
datetime g_fib50_50_lastNotify   = 0;  double g_fib50_50_lastLevel   = 0;
datetime g_fib50_618_lastNotify  = 0;  double g_fib50_618_lastLevel  = 0;
datetime g_fib50_786_lastNotify  = 0;  double g_fib50_786_lastLevel  = 0;
datetime g_fib50_100_lastNotify  = 0;  double g_fib50_100_lastLevel  = 0;
datetime g_fib50_1272_lastNotify = 0;  double g_fib50_1272_lastLevel = 0;
datetime g_fib50_1618_lastNotify = 0;  double g_fib50_1618_lastLevel = 0;
datetime g_fib50_2618_lastNotify = 0;  double g_fib50_2618_lastLevel = 0;
datetime g_fib50_n618_lastNotify = 0;  double g_fib50_n618_lastLevel = 0;
datetime g_fib50_n1272_lastNotify= 0;  double g_fib50_n1272_lastLevel= 0;
datetime g_fib50_n2618_lastNotify= 0;  double g_fib50_n2618_lastLevel= 0;
string       g_smLastEvent    = "--";   // Last event สำหรับ Smart Money Panel
color        g_smLastEventClr = clrGray;

// Stage2 one-shot tracking — ป้องกันวนซ้ำ
ulong    g_stage2DoneTickets[];   // tickets ที่ทำ Stage2 แล้ว
datetime g_stage2NotifyTime[];    // เวลาที่ส่ง Stage2 notification ล่าสุดต่อ ticket
ulong    g_beLockDoneTickets[];   // tickets ที่ทำ BE Lock แล้ว — ป้องกัน modify ซ้ำ

double slPrice = 0, tpPrice = 0;
double g_LatestSL = 0, g_LatestTP = 0;
string valInfo = "";

// ── Solution B: Same-SL Cooldown globals ──────────────────────────────
double   g_lastBuySL             = 0;     // SL ล่าสุดของ BUY ที่เปิด
double   g_lastSellSL            = 0;     // SL ล่าสุดของ SELL ที่เปิด
int      g_buySameSLCount        = 0;     // จำนวน BUY ที่ใช้ SL เดิมติดต่อกัน
int      g_sellSameSLCount       = 0;     // จำนวน SELL ที่ใช้ SL เดิมติดต่อกัน
datetime g_buySameSLCooldownEnd  = 0;     // เวลาสิ้นสุด cooldown สำหรับ BUY
datetime g_sellSameSLCooldownEnd = 0;     // เวลาสิ้นสุด cooldown สำหรับ SELL

// ── V.11: Daily Loss Limit globals ────────────────────────────────────
double   g_dailyLossTotal   = 0;          // รวม Realized Loss ของวันนี้ (USD, ค่าบวก)
datetime g_dailyLossDate    = 0;          // วันที่ที่นับ daily loss ล่าสุด
bool     g_dailyLossBlocked = false;      // true = EA หยุดเทรดวันนี้

// ── V.15: Trade Open Context — เก็บไว้ใช้ใน CLOSE log ───────────────
double   g_buyOpenPrice  = 0;       // ราคาเปิด BUY
datetime g_buyOpenTime   = 0;       // เวลาเปิด BUY
string   g_buyOpenSess   = "";      // Session ตอนเปิด BUY
string   g_buyOpenHTF    = "";      // HTF Hull ตอนเปิด BUY
double   g_buyOpenZ      = 0;       // Z-Score ตอนเปิด BUY
double   g_buyOpenATR    = 0;       // ATR% ตอนเปิด BUY
double   g_sellOpenPrice = 0;
datetime g_sellOpenTime  = 0;
string   g_sellOpenSess  = "";
string   g_sellOpenHTF   = "";
double   g_sellOpenZ     = 0;
double   g_sellOpenATR   = 0;

// ── Solution A: VP Early Exit globals ────────────────────────────────
int      g_vpExitDnBars  = 0;     // นับ bar ที่ VP เป็น BROKEN_DN ขณะถือ BUY
int      g_vpExitUpBars  = 0;     // นับ bar ที่ VP เป็น BROKEN_UP ขณะถือ SELL
datetime g_vpExitLastBar = 0;     // barTime ล่าสุดที่นับ (ป้องกันนับซ้ำใน bar เดิม)

// GoldDXY signal state
double   GoldDXYBuy               = EMPTY_VALUE;
double   GoldDXYSell              = EMPTY_VALUE;
datetime GoldDXYLastBuyBarTime    = 0;
datetime GoldDXYLastSellBarTime   = 0;
datetime GoldDXYSignalBarTimeBuy  = 0;
datetime GoldDXYSignalBarTimeSell = 0;

// Hull globals
double gdx_HullValue[];
double gdx_HullTrend[];

// Session VP structs & globals
struct SessionVP {
   double poc, vah, val;
   double sessionHigh, sessionLow;
   datetime sessionStart, sessionEnd;
   bool isFormed;
};
enum VP_STATE { VP_WAITING, VP_BROKEN_UP, VP_BROKEN_DN, VP_RETESTING_VAH, VP_RETESTING_VAL, VP_CONFIRMED };

SessionVP VpAsia, VpLondon, VpNY, VpPrevNY;
VP_STATE  VpStateAsia=VP_WAITING, VpStateLondon=VP_WAITING, VpStateNY=VP_WAITING, VpStatePrevNY=VP_WAITING;
datetime  VpLastNotifyAsia=0, VpLastNotifyLondon=0, VpLastNotifyNY=0, VpLastNotifyConfl=0;
bool VpBreakoutNotifiedAsia=false, VpBreakoutNotifiedLondon=false, VpBreakoutNotifiedNY=false, VpBreakoutNotifiedPrevNY=false;
bool VpRetestNotifiedAsia=false,   VpRetestNotifiedLondon=false,   VpRetestNotifiedNY=false,   VpRetestNotifiedPrevNY=false;

struct VP_Row { double priceByRow, volBuy, volSell, volTotal; };

// OFA notification globals
datetime gdx_LastNotifyBullTime    = 0;
datetime gdx_LastNotifyBearTime    = 0;
double   gdx_LastNotifyBullMag     = 0;
double   gdx_LastNotifyBearMag     = 0;
int      gdx_LastNotifyBullUpdateN = 0;
int      gdx_LastNotifyBearUpdateN = 0;
bool     gdx_IsHullInitialized     = false;
int      gdx_LastHullTrend         = 0;
int      g_hullOfaCrossState       = 0;  // 1=OFA above Hull, -1=OFA below Hull, 0=unknown
datetime g_hullCross_LastBuyBarTime  = 0;   // same-bar guard สำหรับ OFA×Hull trade
datetime g_hullCross_LastSellBarTime = 0;
datetime g_hullTrend_LastBuyBarTime  = 0;   // same-bar guard สำหรับ Hull color-change trade
datetime g_hullTrend_LastSellBarTime = 0;
datetime gdx_LastHullAlertTime     = 0;
int      g_hullLastWrittenIdx      = -1;   // last bar index written by GdxUpdateHull

// ── Combined Dashboard Panel — V.5 ──────────────────────────────────
bool     g_dashVisible = true;          // runtime show/hide (toggled by click)
string   g_DP_BTN      = "GDEA21_DP_BTN";  // toggle button object name
string   g_DP_PREFIX   = "GDEA21_DP_";     // combined panel object prefix

// ── Solution D: HTF Hull Lock globals ──────────────────────────────────
int      g_htf_wma_fast_handle  = INVALID_HANDLE;  // WMA(period/2) บน HTF
int      g_htf_wma_slow_handle  = INVALID_HANDLE;  // WMA(period) บน HTF
double   g_htf_hull_trend       = 0;               // 1=UP, -1=DN, 0=unknown
datetime g_htf_lastBarTime      = 0;               // bar time ล่าสุดที่คำนวณ
double   g_htf_lastPrintedBlock = 0;               // ป้องกัน print ทุก tick (0=none, 1=BUY, -1=SELL)
// ── Print-once guards — ป้องกัน filter log spam ทุก tick ──────────
datetime g_blk_zscore_buy_bar  = 0;   // per-bar throttle for SF-4a BUY log
datetime g_blk_zscore_sell_bar = 0;   // per-bar throttle for SF-4a SELL log
datetime g_blk_fibgate_buy_bar  = 0;  // per-bar throttle for FibGate BUY log [V.1.40]
datetime g_blk_fibgate_sell_bar = 0;  // per-bar throttle for FibGate SELL log [V.1.40]
datetime g_blk_liqsl_buy_bar   = 0;   // per-bar throttle for [LiqSL Cap] BUY skip log
datetime g_blk_liqsl_sell_bar  = 0;   // per-bar throttle for [LiqSL Cap] SELL skip log
datetime g_blk_liqflt_buy_bar  = 0;   // per-bar throttle for [LiqFilter] BUY blocked log
datetime g_blk_liqflt_sell_bar = 0;   // per-bar throttle for [LiqFilter] SELL blocked log
datetime g_blk_trendmode_buy_bar  = 0;   // per-bar throttle for [TrendMode] BUY SL log
datetime g_blk_trendmode_sell_bar = 0;   // per-bar throttle for [TrendMode] SELL SL log
bool     g_blk_atr_exhaust     = false;
bool     g_blk_london_open     = false;
bool     g_blk_asia_range      = false;
bool     g_blk_london_sweep    = false;
// ── V.20 print-once guards ─────────────────────────────────────────
bool     g_blk_asia_stophunt   = false;  // Asia Stop Hunt Guard
bool     g_blk_asia_maxpos     = false;  // Asia MaxPositions
bool     g_lon_breakout_boost  = false;  // London strong breakout flag (sets TP factor)
// ── V.20h Debug ──────────────────────────────────────────────────────
datetime g_debug_last_print    = 0;      // timer สำหรับ periodic blocker print ทุก 30 นาที
string   g_lastBlockReason     = "SCAN"; // สาเหตุล่าสุดที่ block signal (อัปเดตทุก tick)

// ── V.20d: M1 Scalp Analyst Dashboard ────────────────────────────────
bool     g_scalp_visible   = true;
string   g_SA_BTN          = "GDEA21_SA_BTN";
string   g_SA_PREFIX       = "GDEA21_SA_";
int      g_scen_active     = 0;     // 0=none,1=A(RaidBUY),2=B(HoldBUY),3=C(RaidSELL),4=D(HoldSELL)
bool     g_scen_step1      = false;
bool     g_scen_step2      = false;
bool     g_scen_step3      = false;
bool     g_scen_invalid    = false;
int      g_scen_bExpBar    = 0;
double   g_scen_entryPrice = 0;
bool     g_scen_isBuy      = true;
double   g_scen_swingHigh  = 0;
double   g_scen_swingLow   = 0;
double   g_scen_fib786     = 0;
double   g_scen_fib618     = 0;
double   g_scen_fib382     = 0;

// ── V.19: Trend Mode globals ───────────────────────────────────────
bool     g_trendmode_active       = false;  // true = Trend Mode active ใน tick นี้
bool     g_trendmode_last         = false;  // ใช้ detect change (print ครั้งเดียว)
// Signal Blocked print-once (per signal bar)
datetime g_blk_buy_signal_bar     = 0;      // barTime ล่าสุดที่ print [Signal Blocked] BUY
datetime g_blk_sell_signal_bar    = 0;      // barTime ล่าสุดที่ print [Signal Blocked] SELL
// ATR PDATr partial close tracking
double   g_buy_atr_tp25           = 0;      // ATR M25 target สำหรับ BUY TrendMode
double   g_sell_atr_tp25          = 0;      // ATR M25 target สำหรับ SELL TrendMode
bool     g_buy_partial_done       = false;  // partial close BUY ที่ M25 ทำแล้วหรือยัง
bool     g_sell_partial_done      = false;  // partial close SELL ที่ M25 ทำแล้วหรือยัง


// Position tracking globals (used by CountOpenPositions)
double totalLotBuy  = 0;
double totalLotSell = 0;
double totalBuy     = 0;
double totalSell    = 0;




// Trendline object names
int      g_subwin       = -1;
string   OBJ_DXY_LBL    = "GDEA_DXY_LBL";
string   TL_S1_GOLD     = "GDEA_TL_S1_GOLD";
string   TL_S1_DXY      = "GDEA_TL_S1_DXY";
string   TL_S2_GOLD     = "GDEA_TL_S2_GOLD";
string   TL_S2_DXY      = "GDEA_TL_S2_DXY";
string   TL_S1_GOLD_LBL = "GDEA_TL_S1_GOLD_LBL";
string   TL_S1_DXY_LBL  = "GDEA_TL_S1_DXY_LBL";
string   TL_S2_GOLD_LBL = "GDEA_TL_S2_GOLD_LBL";
string   TL_S2_DXY_LBL  = "GDEA_TL_S2_DXY_LBL";
//+------------------------------------------------------------------+
//| OFA STRUCTS & ARRAY GLOBALS                                      |
//+------------------------------------------------------------------+
struct GDX_SwingPoint {
   datetime time;
   double   price;
   int      bar;
   bool     isHigh;
   double   velocity;
   double   magnitude;
   double   magPct;
   long     volume;    // tick volume ของแท่ง Swing
   double   open;      // สำหรับคำนวณ Delta Volume
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
//| HULL ENGINE — CGdxHull (identical to GoldDXY indicator)         |
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

double GdxGetHullPrice(ENUM_APPLIED_PRICE type, const double &o[], const double &h[],
                       const double &l[], const double &c[], int i)
{
   switch(type) {
      case PRICE_CLOSE:    return c[i];
      case PRICE_OPEN:     return o[i];
      case PRICE_HIGH:     return h[i];
      case PRICE_LOW:      return l[i];
      case PRICE_MEDIAN:   return (h[i]+l[i])/2.0;
      case PRICE_TYPICAL:  return (h[i]+l[i]+c[i])/3.0;
      case PRICE_WEIGHTED: return (h[i]+l[i]+c[i]+c[i])/4.0;
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
      double p = GdxGetHullPrice(InpHL_Price, o, h, l, c, i);
      gdx_HullValue[i] = gdx_HullEngine.calculate(p, i, total);
      if(i > 0) {
         int    lb    = MathMax(1, InpHL_SlopeLB);
         int    from  = MathMax(0, i - lb);
         double slope = (gdx_HullValue[i] - gdx_HullValue[from]) / (i - from);
         double thr   = InpHL_SlopeThreshold * _Point;
         if     (slope >  thr) gdx_HullTrend[i] =  1.0;
         else if(slope < -thr) gdx_HullTrend[i] = -1.0;
         else                  gdx_HullTrend[i] = gdx_HullTrend[i-1]; // slope เล็กเกิน → คงสีเดิม
      } else {
         gdx_HullTrend[i] = 0.0;
      }
   }
   g_hullLastWrittenIdx = total - 1;   // track last written
}

void GdxDrawHullLine(int total, const datetime &time[], bool isFullRecalc)
{
   if(!InpHL_ShowLine) return;
   if(isFullRecalc) ObjectsDeleteAll(0, "GDEA_HULL_");
   int seg_start = total - 500;
   if(seg_start < 1) seg_start = 1;
   for(int i = seg_start; i < total; i++) {
      if(gdx_HullValue[i]==0 || gdx_HullValue[i-1]==0) continue;
      string n = "GDEA_HULL_" + IntegerToString(i);
      if(ObjectFind(0, n) < 0) {
         ObjectCreate(0, n, OBJ_TREND, 0, time[i-1], gdx_HullValue[i-1], time[i], gdx_HullValue[i]);
         ObjectSetInteger(0, n, OBJPROP_RAY_RIGHT, false);
         ObjectSetInteger(0, n, OBJPROP_WIDTH,     InpHL_LineWidth);
         ObjectSetInteger(0, n, OBJPROP_SELECTABLE,false);
         ObjectSetInteger(0, n, OBJPROP_BACK,      true);
      }
      color hclr = (gdx_HullTrend[i] == 1.0) ? InpHL_UpColor : InpHL_DownColor;
      ObjectSetInteger(0, n, OBJPROP_COLOR, hclr);
      ObjectSetInteger(0, n, OBJPROP_TIME,  0, time[i-1]);
      ObjectSetDouble (0, n, OBJPROP_PRICE, 0, gdx_HullValue[i-1]);
      ObjectSetInteger(0, n, OBJPROP_TIME,  1, time[i]);
      ObjectSetDouble (0, n, OBJPROP_PRICE, 1, gdx_HullValue[i]);
   }
}

//+------------------------------------------------------------------+
//| OnInit                                                           |
//+------------------------------------------------------------------+
int OnInit()
{
   Trade.SetExpertMagicNumber(InpMagicnumber);

   if(!SymbolSelect(InpDXY_Symbol, true)) {
      Print("ERROR: DXY symbol not found: ", InpDXY_Symbol);
      return INIT_FAILED;
   }
   g_atr_handle  = iATR(_Symbol, PERIOD_CURRENT, InpATRPeriod);
   g_macd_handle = iMACD(_Symbol, PERIOD_CURRENT, InpMACD_Fast, InpMACD_Slow, InpMACD_Signal, PRICE_CLOSE);
   g_atr_d1_handle = iATR(_Symbol, PERIOD_D1, 14);  // Phase1Fix: global D1 ATR handle
   if(g_atr_handle==INVALID_HANDLE || g_macd_handle==INVALID_HANDLE || g_atr_d1_handle==INVALID_HANDLE) {
      Print("ERROR: Cannot create indicator handles");
      return INIT_FAILED;
   }

   // ── Solution D: HTF Hull handles ──────────────────────────────────
   // Hull = 2×WMA(period/2) − WMA(period), smoothed by WMA(sqrt(period))
   // ใช้ iMA WMA เป็น approximation: fast=period/2, slow=period
   if(InpHTF_Enable)
   {
      int htfHalf = MathMax(2, InpHTF_Period / 2);
      g_htf_wma_fast_handle = iMA(_Symbol, InpHTF_Timeframe, htfHalf,        0, MODE_LWMA, PRICE_CLOSE);
      g_htf_wma_slow_handle = iMA(_Symbol, InpHTF_Timeframe, InpHTF_Period,  0, MODE_LWMA, PRICE_CLOSE);
      if(g_htf_wma_fast_handle==INVALID_HANDLE || g_htf_wma_slow_handle==INVALID_HANDLE)
      {
         Print("WARNING: HTF Hull handles failed — HTF Lock disabled");
         g_htf_wma_fast_handle = INVALID_HANDLE;
         g_htf_wma_slow_handle = INVALID_HANDLE;
      }
   }
   g_htf_hull_trend  = 0;
   g_htf_lastBarTime = 0;

   ArrayResize(gdx_HullValue, 0);
   ArrayResize(gdx_HullTrend, 0);

   GoldDXYLastBuyBarTime  = 0;
   GoldDXYLastSellBarTime = 0;

   ObjectsDeleteAll(0, OBJ_PREFIX);
   ObjectsDeleteAll(0, SB_Prefix);
   ObjectsDeleteAll(0, "GDEA_SVP");
   ObjectsDeleteAll(0, "GDEA_HULL_");
   ObjectsDeleteAll(0, "GDEA_HARW_");
   ObjectsDeleteAll(0, "GDEA_HARWS_");
   ObjectsDeleteAll(0, "GDEA_HARWT_");
   ObjectsDeleteAll(0, "GDEA_HARWTS_");

   // Reset OFA globals
   gdx_swingCount = 0; gdx_LastConfirmedCount = 0; gdx_LastBarTime = 0;
   gdx_swingCount2 = 0; gdx_LastConfirmedCount2 = 0; gdx_LastBarTime2 = 0;
   gdx_LastNotifyBullTime = 0; gdx_LastNotifyBearTime = 0;
   gdx_LastNotifyBullMag  = 0; gdx_LastNotifyBearMag  = 0;
   gdx_LastNotifyBullUpdateN = 0; gdx_LastNotifyBearUpdateN = 0;
   gdx_IsHullInitialized = false; gdx_LastHullTrend = 0; g_hullOfaCrossState = 0;
   g_subwin = -1;
   ObjectsDeleteAll(0, "GDEA_OFA_");
   ObjectsDeleteAll(0, "GDEA_OFA2_");


   g_dashVisible = InpShowDashboard;   // initial state จาก input

   // [V.25] Recover open price/time จาก broker เมื่อ EA restart ขณะมี position เปิดอยู่
   // ป้องกัน Entry=0.00 ใน close log เมื่อ g_buyOpenPrice/g_sellOpenPrice รีเซ็ตหลัง reinit
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicnumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      double recoveredPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      datetime recoveredTime = (datetime)PositionGetInteger(POSITION_TIME);
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
      {
         g_buyOpenPrice = recoveredPrice;
         g_buyOpenTime  = recoveredTime;
         Print(StringFormat("[V.25 Recover] BUY open price restored: %.5f", g_buyOpenPrice));
      }
      else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
      {
         g_sellOpenPrice = recoveredPrice;
         g_sellOpenTime  = recoveredTime;
         Print(StringFormat("[V.25 Recover] SELL open price restored: %.5f", g_sellOpenPrice));
      }
   }

   Print(inpEaObject, " Init OK | Magic=", InpMagicnumber,
         " | SessionFilter=", InpSF_Enable ? "ON" : "OFF",
         " | ATRExhaust=", InpSF_ATRExhaust_Enable ? "ON" : "OFF");
   g_lastBuySL = 0; g_lastSellSL = 0;
   g_buySameSLCount = 0; g_sellSameSLCount = 0;
   g_buySameSLCooldownEnd = 0; g_sellSameSLCooldownEnd = 0;
   // Reset Solution A globals
   g_vpExitDnBars = 0; g_vpExitUpBars = 0; g_vpExitLastBar = 0;
   g_eaStartTime = TimeCurrent();
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   if(g_atr_handle  != INVALID_HANDLE) IndicatorRelease(g_atr_handle);
   if(g_macd_handle != INVALID_HANDLE) IndicatorRelease(g_macd_handle);
   if(g_atr_d1_handle != INVALID_HANDLE) IndicatorRelease(g_atr_d1_handle);  // Phase1Fix
   if(g_htf_wma_fast_handle != INVALID_HANDLE) IndicatorRelease(g_htf_wma_fast_handle);  // SolD
   if(g_htf_wma_slow_handle != INVALID_HANDLE) IndicatorRelease(g_htf_wma_slow_handle);  // SolD
   ObjectsDeleteAll(0, OBJ_PREFIX);
   ObjectsDeleteAll(0, SB_Prefix);
   ObjectsDeleteAll(0, "GDEA_SVP");
   ObjectsDeleteAll(0, "GDEA_HULL_");
   ObjectsDeleteAll(0, "GDEA_HARW_");
   ObjectsDeleteAll(0, "GDEA_HARWS_");
   ObjectsDeleteAll(0, "GDEA_HARWT_");
   ObjectsDeleteAll(0, "GDEA_HARWTS_");
   ObjectsDeleteAll(0, "GDEA_OFA_");
   ObjectsDeleteAll(0, "GDEA_OFA2_");
   ObjectsDeleteAll(0, "GDEA_TL_");
   ObjectsDeleteAll(0, "GDEA_DXY");
   ObjectsDeleteAll(0, "GDEA_ATR");
   ObjectsDeleteAll(0, LIQ_PREFIX);
   ObjectsDeleteAll(0, "GDEA_SMP_");
   ObjectDelete(0, OBJ_PREFIX + "BG_DASH");
   ObjectsDeleteAll(0, g_DP_PREFIX);   // Combined Panel V.5
   ObjectDelete(0, g_DP_BTN);
   ObjectsDeleteAll(0, FIB_PREFIX);
}

//+------------------------------------------------------------------+
//| OnTick                                                           |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!SymbolInfoTick(_Symbol, currentTick)) return;
   if(!checkTradeTime(inpStartTime, inpEndTime)) return;

   // Read GoldDXY signal (Hull + DXY/Gold mismatch + MACD)
   ReadGoldDXYSignal();

   // ── V.20h Debug: periodic blocker summary ทุก 30 นาที ──────────────
   if(TimeCurrent() - g_debug_last_print >= 1800 && g_lastBlockReason != "SCAN") {
      Print(StringFormat("[Debug30m] %s | ATR=%.0f%% cap=%.0f%% | TM=%s | Ses=%d",
            g_lastBlockReason, GetDailyATRConsumption()*100, g_sp.atrCap*100,
            g_trendmode_active?"ON":"OFF", (int)GetCurrentSession()));
      g_debug_last_print = TimeCurrent();
   }

   // Trendlines
   UpdateTrendLines();

   // ── Combined Panel V.5: ปุ่มทุก tick, panel throttle เฉพาะ new M1 bar ──
   DrawDashBtn();   // ปุ่ม toggle — เบามาก (1 object)
   {
      static int dpLastBar = -1;
      int dpCurBar = Bars(_Symbol, PERIOD_M1);
      if(dpCurBar != dpLastBar) {
         dpLastBar = dpCurBar;
         DrawCombinedPanel();   // วาด panel เฉพาะ new bar (ไม่ใช่ทุก tick)
      }
   }

   // Fibonacci Retracement บน OFA p26 Swing ก่อนสุดท้าย
   if(InpFib_Enable) DrawFibRetracement();

   // M1 Scalp Analyst Dashboard [V.20d] — display only, no orders
   if(InpScalp_Enable) {
      DrawScalpBtn();
      static int saLastBar = -1;
      int saCurBar = Bars(_Symbol, PERIOD_M1);
      if(saCurBar != saLastBar) {
         saLastBar = saCurBar;
         UpdateScenarioTracker();
         DrawScalpDashboard();
         if(InpScalp_Circles) DrawEntryZoneCircles();
      }
   }

   // Session VP Monitor
   RunSessionVP();

   // ATR Previous Day Levels
   // - redraw ทุก new D1 bar (ATR value เปลี่ยน)
   // - redraw ทุก new M1 bar ในช่วง Asia เปิดแรก เพื่อให้ baseline ราคา update ทันที
   if(InpATRLevelsEnable)
   {
      static int  atrLastD1Bar = -1;
      static int  atrLastM1Bar = -1;
      static bool atrBaselined = false;   // true เมื่อ Asia open bar ถูก lock แล้ว

      int curD1Bar = Bars(_Symbol, PERIOD_D1);
      int curM1Bar = Bars(_Symbol, PERIOD_M1);

      MqlDateTime dtNow; TimeCurrent(dtNow);
      datetime tBase = TimeCurrent() - (dtNow.hour*3600 + dtNow.min*60 + dtNow.sec);
      datetime asiaOpen = tBase + InpAsiaStartHr * 3600;
      bool nearAsiaOpen = (TimeCurrent() >= asiaOpen &&
                           TimeCurrent() <  asiaOpen + 300);   // 5 นาทีแรกหลัง Asia เปิด

      // reset flag เมื่อขึ้นวันใหม่
      if(curD1Bar != atrLastD1Bar) {
         atrBaselined = false;
         atrLastD1Bar = curD1Bar;
         ObjectsDeleteAll(0, "GDEA_ATR");
         DrawATRLevels();
      }
      // update ทุก M1 ใน 5 นาทีแรกของ Asia จนกว่าจะ lock baseline
      else if(!atrBaselined && nearAsiaOpen && curM1Bar != atrLastM1Bar) {
         atrLastM1Bar = curM1Bar;
         ObjectsDeleteAll(0, "GDEA_ATR");
         DrawATRLevels();
         // lock baseline หลังจากแท่ง Asia Open ปิดแล้ว (bar shift = 1)
         int idx = iBarShift(_Symbol, PERIOD_M1, asiaOpen, false);
         if(idx >= 1) atrBaselined = true;
      }
   }

   // Session Box (redraw on every new M1 bar — same cadence as VP so box always matches POC/VAH/VAL)
   {
      static int sbLastBar = -1;
      int sbCurBar = Bars(_Symbol, PERIOD_M1);
      if(sbCurBar != sbLastBar) {
         ObjectsDeleteAll(0, SB_Prefix);
         DrawSessionBoxes();
         sbLastBar = sbCurBar;
      }
   }

   // Liquidity Zone Box
   // - redraw เฉพาะเมื่อ Swing เปลี่ยน (gdx_LastConfirmedCount) ไม่ใช่ทุก M1 bar
   // - ตรวจ Raid ทุก tick เหมือนเดิม
   if(InpLiqBox_Enable)
   {
      static int liqLastSwingCount = -1;
      static int liqLastD1Bar      = -1;
      int curD1Bar = Bars(_Symbol, PERIOD_D1);

      bool swingChanged = (gdx_LastConfirmedCount != liqLastSwingCount);
      bool newDay       = (curD1Bar != liqLastD1Bar);

      if(swingChanged || newDay) {
         ObjectsDeleteAll(0, LIQ_PREFIX);
         DrawLiquidityBoxes();
         liqLastSwingCount = gdx_LastConfirmedCount;
         liqLastD1Bar      = curD1Bar;
      }
      if(InpLiqBox_Notify) CheckLiquidityRaid();
   }

   // Hull line update + draw (only on new bar — same as indicator)
   bool isNewBar = false;  // declared here so CheckHullOFACross() can use it below
   {
      int total_h = Bars(_Symbol, PERIOD_CURRENT);
      if(total_h >= InpHL_Period * 3) {
         static int   g_hullLastBar    = 0;
         static bool  g_hullFirstRun   = true;
         datetime curBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);

         // Full recalc on first run; incremental (last 3 bars) on new bar; skip intra-bar ticks
         static datetime g_hullLastBarTime = 0;
         isNewBar  = (curBarTime != g_hullLastBarTime);
         bool doRecalc  = (g_hullFirstRun || isNewBar);

         if(doRecalc) {
            // Use full bar history so CGdxHull running sums are accurate
            // Limit to 1000 bars for performance — enough warmup for period=50
            int seg = MathMin(1000, total_h);
            double ho[], hh[], hl[], hc[];
            datetime ht[];
            ArraySetAsSeries(ho,false); ArraySetAsSeries(hh,false);
            ArraySetAsSeries(hl,false); ArraySetAsSeries(hc,false);
            ArraySetAsSeries(ht,false);
            if(CopyOpen (_Symbol,PERIOD_CURRENT,0,seg,ho)>=seg &&
               CopyHigh (_Symbol,PERIOD_CURRENT,0,seg,hh)>=seg &&
               CopyLow  (_Symbol,PERIOD_CURRENT,0,seg,hl)>=seg &&
               CopyClose(_Symbol,PERIOD_CURRENT,0,seg,hc)>=seg &&
               CopyTime (_Symbol,PERIOD_CURRENT,0,seg,ht)>=seg) {
               // Always full recalc from bar 0 — ensures running sums are correct
               // (incremental fails because CopyXxx gives fresh arrays each call
               //  so previous running-sum state in CGdxHull.m_array is invalid)
               GdxUpdateHull(seg, 0, ho, hh, hl, hc);
               GdxDrawHullLine(seg, ht, g_hullFirstRun);

               // อัปเดต gdx_LastHullTrend + ตรวจ Hull trend-change arrow
               if(isNewBar) {
                  int lastIdx = g_hullLastWrittenIdx;
                  if(lastIdx >= 0 && lastIdx < ArraySize(gdx_HullTrend)) {
                     int curTrend = (int)gdx_HullTrend[lastIdx];
                     CheckHullTrendChange(curTrend);  // ตรวจก่อน update (gdx_LastHullTrend = prev)
                     gdx_LastHullTrend = curTrend;
                  }
               }

               g_hullFirstRun    = false;
               g_hullLastBarTime = curBarTime;
            }
         }
      }
   }

   // ── Solution D: อัปเดต HTF Hull Trend (ทุก HTF bar ใหม่) ──────
   if(InpHTF_Enable) UpdateHTFHullTrend();

   // OFA update
   RunOFAUpdate();

   // OFA P26 × Hull Suite cross arrow
   CheckHullOFACross(isNewBar);

   // ── Trade execution ──
   int cntBuy=0, cntSell=0;
   CountOpenPositions(cntBuy, cntSell);

   bool hasBuy  = (GoldDXYBuy  != EMPTY_VALUE && GoldDXYBuy  > 0);
   bool hasSell = (GoldDXYSell != EMPTY_VALUE && GoldDXYSell > 0);

   // Conflict filter
   if(hasBuy && hasSell) {
      if(GoldDXYSignalBarTimeBuy == GoldDXYSignalBarTimeSell)
         { hasBuy = false; hasSell = false; }
      else if(GoldDXYSignalBarTimeBuy > GoldDXYSignalBarTimeSell)
         hasSell = false;
      else
         hasBuy = false;
   }

   if(InpStandardEntry_Enable && hasBuy && InpBuyPosition && cntBuy < InpTotalPosition) {
      bool locked = (GoldDXYSignalBarTimeBuy != 0 &&
                     GoldDXYSignalBarTimeBuy == GoldDXYLastSellBarTime);
      if(!locked && GoldDXYSignalBarTimeBuy != GoldDXYLastBuyBarTime) {
         // ── STEP 8: VP Session Filter ──
         if(!InpVP_FilterEnable || CheckVPFilterBuy()) {
            if(OpenBuyPosition())
               GoldDXYLastBuyBarTime = GoldDXYSignalBarTimeBuy;
            else if(GoldDXYSignalBarTimeBuy != g_blk_buy_signal_bar) {
               // V.19 A2: print ครั้งเดียวต่อ signal bar
               Print(StringFormat("[Signal Blocked] BUY signal %.5f — order NOT placed (bar=%s, TrendMode=%s)",
                     currentTick.ask,
                     TimeToString(GoldDXYSignalBarTimeBuy, TIME_DATE|TIME_MINUTES),
                     g_trendmode_active ? "ON" : "OFF"));
               g_blk_buy_signal_bar = GoldDXYSignalBarTimeBuy;
            }
         }
      }
   }

   if(InpStandardEntry_Enable && hasSell && InpSellPosition && cntSell < InpTotalPosition) {
      bool locked = (GoldDXYSignalBarTimeSell != 0 &&
                     GoldDXYSignalBarTimeSell == GoldDXYLastBuyBarTime);
      if(!locked && GoldDXYSignalBarTimeSell != GoldDXYLastSellBarTime) {
         // ── STEP 8: VP Session Filter ──
         if(!InpVP_FilterEnable || CheckVPFilterSell()) {
            if(OpenSellPosition())
               GoldDXYLastSellBarTime = GoldDXYSignalBarTimeSell;
            else if(GoldDXYSignalBarTimeSell != g_blk_sell_signal_bar) {
               // V.19 A2: print ครั้งเดียวต่อ signal bar
               Print(StringFormat("[Signal Blocked] SELL signal %.5f — order NOT placed (bar=%s, TrendMode=%s)",
                     currentTick.bid,
                     TimeToString(GoldDXYSignalBarTimeSell, TIME_DATE|TIME_MINUTES),
                     g_trendmode_active ? "ON" : "OFF"));
               g_blk_sell_signal_bar = GoldDXYSignalBarTimeSell;
            }
         }
      }
   }

   // Total TP close-all
   if(InpTotalTP > 0) {
      double totalPnl = 0;
      for(int i = PositionsTotal()-1; i >= 0; i--) {
         ulong ticket = PositionGetTicket(i);
         if(PositionSelectByTicket(ticket) &&
            PositionGetInteger(POSITION_MAGIC) == InpMagicnumber)
            totalPnl += PositionGetDouble(POSITION_PROFIT);
      }
      if(totalPnl >= InpTotalTP) {
         for(int i = PositionsTotal()-1; i >= 0; i--) {
            ulong ticket = PositionGetTicket(i);
            if(PositionSelectByTicket(ticket) &&
               PositionGetInteger(POSITION_MAGIC) == InpMagicnumber)
               Trade.PositionClose(ticket);
         }
      }
   }

   // Break-Even: ตรวจทุก tick เพื่อไม่พลาดจังหวะ
   // ── Profit Target: ปิด Order เมื่อถึงเป้า ─────────────────
   CheckProfitTarget();

   // ── Solution A: VP Early Exit — ปิด Order เมื่อ VP พลิกทิศ ──
   CheckVPEarlyExit();
   
    // ── [เพิ่มบรรทัดนี้] ระบบ Smart Fibonacci Exit ─────────────────
   CheckSmartFibExit();
   
   if(InpBE_Enable) ManageBreakEven();

   // V.19: ATR PDATr Partial Close — ปิด 50% เมื่อถึง M25/P25
   ManageATRPartialClose();

   // ล้าง Stage2 done tickets ที่ปิดแล้ว (ทุก M1 bar)
   {
      static int cleanLastBar = -1;
      int cleanCurBar = Bars(_Symbol, PERIOD_M1);
      if(cleanCurBar != cleanLastBar) {
         CleanStage2Done();
         cleanLastBar = cleanCurBar;
      }
   }
}

//+------------------------------------------------------------------+
//| OnChartEvent — Toggle Combined Panel                             |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK && sparam == g_DP_BTN)
   {
      g_dashVisible = !g_dashVisible;
      if(!g_dashVisible)
         ObjectsDeleteAll(0, g_DP_PREFIX);   // ลบ panel objects เมื่อซ่อน
      else
         DrawCombinedPanel();                 // วาดทันทีเมื่อเปิด
      ObjectSetInteger(0, g_DP_BTN, OBJPROP_STATE, false);  // reset button pressed state
      ChartRedraw();
   }
   // [V.20d] Scalp Analyst toggle button
   if(id == CHARTEVENT_OBJECT_CLICK && sparam == g_SA_BTN)
   {
      g_scalp_visible = !g_scalp_visible;
      if(!g_scalp_visible)
         ObjectsDeleteAll(0, g_SA_PREFIX);
      else
         DrawScalpDashboard();
      ObjectSetInteger(0, g_SA_BTN, OBJPROP_STATE, false);
      ChartRedraw();
   }
}

//+------------------------------------------------------------------+
//| Solution D: UpdateHTFHullTrend                                    |
//| คำนวณ Hull MA direction บน HTF (H1 default)                      |
//| Hull = 2×WMA(n/2) − WMA(n) → ถ้า bar[0] > bar[1] = UP          |
//| ใช้ WMA ผ่าน iMA MODE_LWMA เป็น approximation ที่เบาและแม่น      |
//+------------------------------------------------------------------+
void UpdateHTFHullTrend()
{
   if(g_htf_wma_fast_handle==INVALID_HANDLE || g_htf_wma_slow_handle==INVALID_HANDLE) return;

   // อัปเดตเฉพาะเมื่อขึ้น HTF bar ใหม่
   datetime curHTFBar = iTime(_Symbol, InpHTF_Timeframe, 0);
   if(curHTFBar == g_htf_lastBarTime) return;
   g_htf_lastBarTime = curHTFBar;

   // ดึง WMA fast และ slow 3 bar (bar[0]=current, bar[1]=prev)
   double fast[], slow_arr[];
   ArraySetAsSeries(fast,     true);
   ArraySetAsSeries(slow_arr, true);

   if(CopyBuffer(g_htf_wma_fast_handle, 0, 0, 3, fast)     < 3) return;
   if(CopyBuffer(g_htf_wma_slow_handle, 0, 0, 3, slow_arr) < 3) return;

   // Hull[i] = 2×WMAfast[i] − WMAslow[i]
   double hull_now  = 2.0 * fast[0] - slow_arr[0];
   double hull_prev = 2.0 * fast[1] - slow_arr[1];

   double prevTrend = g_htf_hull_trend;

   if(hull_now > hull_prev)       g_htf_hull_trend =  1.0;   // HTF UP
   else if(hull_now < hull_prev)  g_htf_hull_trend = -1.0;   // HTF DN
   // ถ้าเท่ากัน → คง trend เดิม

   // Log + HTF Exit เมื่อ HTF trend เปลี่ยน
   if(g_htf_hull_trend != prevTrend && prevTrend != 0)
   {
      string dir = (g_htf_hull_trend == 1.0) ? "UP" : "DN";
      Print(StringFormat("[HTF Hull] %s trend flipped to %s | Hull=%.3f→%.3f",
            EnumToString(InpHTF_Timeframe), dir, hull_prev, hull_now));
      g_htf_lastPrintedBlock = 0;   // reset เพื่อให้ block log ใหม่ print ได้อีกครั้ง
      CheckHTFExit((int)g_htf_hull_trend);   // V.16: ปิด position ที่สวนทาง HTF ใหม่
   }
}

//+------------------------------------------------------------------+
//| V.5 SESSION-ADAPTIVE FILTER — Helper Functions                   |
//+------------------------------------------------------------------+

// ── GetCurrentSession: ระบุ session ปัจจุบัน ─────────────────────
ENUM_SF_SESSION GetCurrentSession()
{
   MqlDateTime dt; TimeCurrent(dt);
   int hr = dt.hour;
   if(hr >= InpAsiaStartHr   && hr < InpAsiaEndHr)          return SESSION_ASIA;
   if(hr >= InpLondonStartHr && hr < InpLondonEndHr)        return SESSION_LONDON;
   if(hr >= InpNYStartHr     && hr < InpSF_NYPM_StartHr)    return SESSION_NY_MORNING;
   if(hr >= InpSF_NYPM_StartHr && hr < InpNYEndHr)          return SESSION_NY_AFTERNOON;
   return SESSION_OFF;
}

// ── GetDailyATRConsumption: % ของ ATR(D1) ที่วันนี้วิ่งไปแล้ว ───
// คืน 0.0–1.0+ (เกิน 1.0 หมายถึงวิ่งเกิน 100% ATR วันนี้)
double GetDailyATRConsumption()
{
   if(g_atr_d1_handle == INVALID_HANDLE) return 0;
   double buf[]; ArraySetAsSeries(buf, true);
   if(CopyBuffer(g_atr_d1_handle, 0, 1, 1, buf) < 1) return 0;
   double atrD1 = buf[0];
   if(atrD1 <= 0) return 0;

   // ระยะที่ราคาขยับจาก CloseD-1 ถึงปัจจุบัน
   double prevClose[];
   if(CopyClose(_Symbol, PERIOD_D1, 1, 1, prevClose) < 1) return 0;
   double todayMove = MathAbs(currentTick.bid - prevClose[0]);
   return todayMove / atrD1;
}

// ── GetDailyATRConsumptionDir: Directional ATR consumption [V.20i] ──
// isBuy=true  → นับเฉพาะการเคลื่อนที่ขึ้นจาก prevClose (BUY cap)
// isBuy=false → นับเฉพาะการเคลื่อนที่ลงจาก prevClose (SELL cap)
// ป้องกันไม่ให้วันที่ bullish run สูง block SELL entry (และกลับกัน)
double GetDailyATRConsumptionDir(bool isBuy)
{
   if(g_atr_d1_handle == INVALID_HANDLE) return 0;
   double buf[]; ArraySetAsSeries(buf, true);
   if(CopyBuffer(g_atr_d1_handle, 0, 1, 1, buf) < 1) return 0;
   double atrD1 = buf[0];
   if(atrD1 <= 0) return 0;

   double prevClose[];
   if(CopyClose(_Symbol, PERIOD_D1, 1, 1, prevClose) < 1) return 0;
   double move = currentTick.bid - prevClose[0];
   // BUY cap: measure upside move only; SELL cap: measure downside move only
   double directional = isBuy ? MathMax(0, move) : MathMax(0, -move);
   return directional / atrD1;
}

// ── IsLondonOpenWindowActive: true ถ้าอยู่ใน N นาทีแรกของ London ─
bool IsLondonOpenWindowActive()
{
   if(InpSF_London_OpenMins <= 0) return false;
   MqlDateTime dt; TimeCurrent(dt);
   if(dt.hour != InpLondonStartHr) return false;
   return (dt.min < InpSF_London_OpenMins);
}

// ── CheckAsiaRangeGuard: Block entry ถ้าราคาใกล้ขอบ Asia range ───
// isBuy=true  → block ถ้าราคาอยู่ใกล้ Asia VAH (ใกล้ยอด range)
// isBuy=false → block ถ้าราคาอยู่ใกล้ Asia VAL (ใกล้ก้น range)
// คืน true = block entry
bool CheckAsiaRangeGuard(bool isBuy, double price)
{
   if(!VpAsia.isFormed) return false;
   double range = VpAsia.sessionHigh - VpAsia.sessionLow;
   if(range <= 0) return false;

   if(isBuy)
   {
      // price อยู่เหนือ VAH × guard% ของ range = ใกล้ยอดเกินไป
      double distFromVAH = VpAsia.vah - price;
      if(distFromVAH < 0) distFromVAH = 0;   // price เกิน VAH แล้ว
      double pctFromTop = 1.0 - (distFromVAH / range);
      return (pctFromTop >= InpSF_Asia_RangeGuard);
   }
   else
   {
      // price อยู่ใต้ VAL × guard% ของ range = ใกล้ก้นเกินไป
      double distFromVAL = price - VpAsia.val;
      if(distFromVAL < 0) distFromVAL = 0;   // price ต่ำกว่า VAL แล้ว
      double pctFromBot = 1.0 - (distFromVAL / range);
      return (pctFromBot >= InpSF_Asia_RangeGuard);
   }
}

// ── IsAsiaSweepDone: ตรวจว่า London ได้ sweep Asia H/L แล้วหรือยัง ─
// forBuy=true  → BUY setup: London ต้อง sweep Asia Low ก่อน
// forBuy=false → SELL setup: London ต้อง sweep Asia High ก่อน
// คืน true = sweep เสร็จแล้ว (อนุญาต entry)
bool IsAsiaSweepDone(bool forBuy)
{
   if(!VpAsia.isFormed) return true;   // ไม่มีข้อมูล Asia → pass through

   // หา bar ตั้งแต่ London เปิด
   MqlDateTime dtNow; TimeCurrent(dtNow);
   datetime tBase       = TimeCurrent() - (dtNow.hour*3600 + dtNow.min*60 + dtNow.sec);
   datetime londonStart = tBase + InpLondonStartHr * 3600;

   int barsInLondon = iBarShift(_Symbol, PERIOD_M1, londonStart, false);
   if(barsInLondon <= 0) return false;   // London เพิ่งเปิด ยังไม่มี bar

   double hiArr[], loArr[];
   if(CopyHigh(_Symbol, PERIOD_M1, 0, barsInLondon + 1, hiArr) <= 0) return false;
   if(CopyLow (_Symbol, PERIOD_M1, 0, barsInLondon + 1, loArr) <= 0) return false;

   double londonLow  = loArr[ArrayMinimum(loArr)];
   double londonHigh = hiArr[ArrayMaximum(hiArr)];

   if(forBuy)
      return (londonLow  <= VpAsia.sessionLow);    // London ได้ sweep Asia Low → BUY setup ✓
   else
      return (londonHigh >= VpAsia.sessionHigh);   // London ได้ sweep Asia High → SELL setup ✓
}

//+------------------------------------------------------------------+
//| V.20 — IsNearATRM75: ตรวจ price ใกล้ ATR M75/P75 (Stop Hunt zone)|
//+------------------------------------------------------------------+
bool IsNearATRM75(bool isBuy)
{
   double atr  = GDEA_GetATRDaily(InpATRLevelsPeriod);
   double base = GetATRBaseline();
   if(atr <= 0 || base <= 0) return false;
   double price = isBuy ? currentTick.ask : currentTick.bid;
   if(!isBuy)   // SELL entry ตอน price ใกล้ M75 → Stop Hunt zone (reversal BUY)
      return (MathAbs(price - (base - atr * 0.75)) <= InpAsia_M75_Buffer);
   else          // BUY entry ตอน price ใกล้ P75 → Stop Hunt zone (reversal SELL)
      return (MathAbs(price - (base + atr * 0.75)) <= InpAsia_M75_Buffer);
}

//+------------------------------------------------------------------+
//| V.20 — IsStrongLondonBreakout: sweep+OFA+HTF aligned            |
//+------------------------------------------------------------------+
bool IsStrongLondonBreakout(bool isBuy)
{
   if(!InpLon_BreakoutBoost) return false;
   if(!InpSF_London_WaitSweep) return false;
   if(!IsAsiaSweepDone(isBuy)) return false;
   if(gdx_LastConfirmedCount <= 0) return false;
   bool ofaBull = !gdx_swings[gdx_LastConfirmedCount-1].isHigh;
   if( isBuy && !ofaBull) return false;
   if(!isBuy &&  ofaBull) return false;
   if(InpHTF_Enable) {
      if( isBuy && g_htf_hull_trend != 1.0)  return false;
      if(!isBuy && g_htf_hull_trend != -1.0) return false;
   }
   return true;
}

//+------------------------------------------------------------------+
//| V.20 — GetSessionProfile: สร้าง SessionProfile สำหรับ session    |
//+------------------------------------------------------------------+
SessionProfile GetSessionProfile(ENUM_SF_SESSION sess)
{
   SessionProfile p;
   // ── Default values (ใช้ค่า input ตรงๆ) ─────────────────────────
   p.zLimit        = InpGoldZLimit;
   p.trigBars      = InpTriggerBars;
   p.macdGap       = InpMACD_MinGap;
   p.atrCap        = InpSF_ATRExhaust_Cap;
   p.slBufferPts   = 0.0;
   p.tpFactor      = InpTP_NY_Factor;
   p.rangeGuard    = 0.0;
   p.waitSweep     = false;
   p.openBlockMins = 0;
   p.stopHuntZone  = false;
   p.maxPositions  = 0;    // 0 = ไม่ใช้ check
   p.lotMultiplier = 1.0;

   if(!InpSF_Enable) return p;

   switch(sess)
   {
      // ── ASIA: Range-bound, Stop Hunt zone ──────────────────────────
      case SESSION_ASIA:
         p.zLimit        = InpSF_Asia_ZScore;
         p.trigBars      = InpSF_Asia_TrigBars;
         p.macdGap       = InpSF_Asia_MACDGap;
         p.rangeGuard    = InpSF_Asia_RangeGuard;
         p.tpFactor      = InpTP_Asia_Factor;
         // V.20 GroupC: MaxPositions
         if(InpAsia_MaxPositions > 0) p.maxPositions = InpAsia_MaxPositions;
         // V.20 GroupC: stopHuntZone — direction-independent detection
         // (direction-specific check ทำใน Step 8S-2 ด้วย IsNearATRM75)
         break;

      // ── LONDON: Breakout, sweep & fake move ────────────────────────
      case SESSION_LONDON:
         p.zLimit        = InpSF_London_ZScore;  // V.1.36: London มี Z-Score แยก (ผ่อนสุด)
         p.openBlockMins = InpSF_London_OpenMins;
         p.waitSweep     = InpSF_London_WaitSweep;
         p.slBufferPts   = InpLondon_SLBuffer;   // V.20 GroupB: consolidate SL buffer
         p.tpFactor      = InpTP_London_Factor;
         // V.20 GroupE: g_lon_breakout_boost ถูก set ใน ReadGoldDXYSignal หลัง Step1
         break;

      // ── NY MORNING: London continuation ────────────────────────────
      case SESSION_NY_MORNING:
         p.zLimit        = InpSF_NYM_ZScore;
         p.tpFactor      = InpTP_NY_Factor;
         break;

      // ── NY AFTERNOON: Fatigue protection ───────────────────────────
      case SESSION_NY_AFTERNOON:
         p.zLimit        = InpSF_NYPM_ZScore;
         p.atrCap        = MathMin(InpSF_ATRExhaust_Cap, InpSF_NYPM_ATRCap);
         p.tpFactor      = InpTP_NY_Factor;
         // V.20 GroupD: half lot
         if(InpNYPM_HalfLot) p.lotMultiplier = 0.5;
         break;

      case SESSION_OFF:
         break;
   }
   return p;
}

//+------------------------------------------------------------------+
//| ReadGoldDXYSignal                                                |
//+------------------------------------------------------------------+
void ReadGoldDXYSignal()
{
   // ══════════════════════════════════════════════════════════════════
   // Signal logic mirrors Dashboard exactly — ALL steps must pass
   // Step1: Macro Trend | Step2: Recent Trend | Step3: DXY Trigger
   // Step4: Gold Filters (Z-score + Momentum) | Step4c: ATR Exhaustion
   // Step5: MACD | Step6: Hull | Step6b: HTF Hull Lock
   // Step7: OFA Dual-Period | Step8S: Asia Range Guard
   // Step8L: London Open Window + Asia Sweep Check  [V.5]
   // Arrow & Order only when ALL steps = OK
   // ══════════════════════════════════════════════════════════════════
   GoldDXYBuy  = EMPTY_VALUE;
   GoldDXYSell = EMPTY_VALUE;
   GoldDXYSignalBarTimeBuy  = 0;
   GoldDXYSignalBarTimeSell = 0;
   g_trendmode_active  = false;   // V.19: reset ทุก tick ก่อน early return
   g_lon_breakout_boost = false;  // V.20: reset London boost flag
   g_lastBlockReason   = "SCAN";  // V.20h: reset ทุก tick

   int total = Bars(_Symbol, PERIOD_CURRENT);
   int need  = InpMacroBars + InpZPeriod + InpTriggerBars + 5;
   if(total < need) return;

   // ── V.20: Session Detection + SessionProfile ──────────────────────
   // session logic ทั้งหมดรวมอยู่ใน g_sp — ไม่มี inline if/else กระจาย
   ENUM_SF_SESSION curSession = GetCurrentSession();
   g_sp          = GetSessionProfile(curSession);   // V.20: สร้าง profile
   double sfZLimit   = g_sp.zLimit;
   int    sfTrigBars = g_sp.trigBars;
   double sfMACDGap  = g_sp.macdGap;

   // ── PRE-FILTER 8L(i): London Open Window Block ───────────────────
   // Block entry ใน N นาทีแรกของ London เพื่อหลีกเลี่ยง Fake Move
   if(InpSF_Enable && curSession == SESSION_LONDON && g_sp.openBlockMins > 0 && IsLondonOpenWindowActive())
   {
      if(!g_blk_london_open) {
         Print(StringFormat("[SF-8L] London Open Window active — entry blocked (%d min)",
               g_sp.openBlockMins));
         g_blk_london_open = true;
      }
      return;
   }
   g_blk_london_open = false;

   // ── STEP 1: Macro Trend (InpMacroBars bars) ──
   double dxy_m[], gold_m[];
   if(!GetSeries(InpDXY_Symbol, 0, InpMacroBars, dxy_m))  return;
   if(!GetSeries(_Symbol,       0, InpMacroBars, gold_m)) return;
   int md = TrendDir(dxy_m,  InpMacroBars);
   int mg = TrendDir(gold_m, InpMacroBars);
   bool bz = (md == -1 && mg ==  1);   // BUY zone
   bool sz = (md ==  1 && mg == -1);   // SELL zone
   if(!bz && !sz) {
      g_lastBlockReason = StringFormat("Step1: DXY=%s Gold=%s (no mismatch)",
         md>0?"UP":md<0?"DN":"--", mg>0?"UP":mg<0?"DN":"--");
      return;                          // Step 1 FAIL → no signal
   }

   // ── STEP 2: Recent Trend (InpRecentBars bars) ──
   double dxy_r[], gold_r[];
   if(!GetSeries(InpDXY_Symbol, 0, InpRecentBars, dxy_r))  return;
   if(!GetSeries(_Symbol,       0, InpRecentBars, gold_r)) return;
   int rd = TrendDir(dxy_r,  InpRecentBars);
   int rg = TrendDir(gold_r, InpRecentBars);
   bool s2 = bz ? (rd == -1 && rg ==  1) : (rd ==  1 && rg == -1);
   if(!s2) {
      g_lastBlockReason = StringFormat("Step2: Recent DXY=%s Gold=%s (need %s/%s)",
         rd>0?"UP":rd<0?"DN":"--", rg>0?"UP":rg<0?"DN":"--",
         bz?"DN":"UP", bz?"UP":"DN");
      return;                          // Step 2 FAIL
   }

   // ── V.19: Dynamic Trend Mode detection ───────────────────────────
   // เงื่อนไข: HTF Hull aligned + ATR consumed ≥ InpTrend_ATRConsume + OFA aligned
   if(InpTrendMode_Enable)
   {
      bool htfAligned = (bz && g_htf_hull_trend == 1.0) || (sz && g_htf_hull_trend == -1.0);
      bool atrOk      = GetDailyATRConsumption() >= InpTrend_ATRConsume;
      if(htfAligned && atrOk)
      {
         bool ofaOk = true;
         if(gdx_LastConfirmedCount > 0) {
            bool ofaBull = !gdx_swings[gdx_LastConfirmedCount-1].isHigh;
            if(sz && ofaBull)  ofaOk = false;   // OFA BULL ขณะ SELL trend → ไม่ใช่ Trend Mode
            if(bz && !ofaBull) ofaOk = false;   // OFA BEAR ขณะ BUY trend → ไม่ใช่ Trend Mode
         }
         g_trendmode_active = ofaOk;
      }
      // Print เมื่อ state เปลี่ยน (ครั้งเดียว)
      if(g_trendmode_active != g_trendmode_last) {
         Print(StringFormat("[TrendMode] %s — dir=%s HTF=%.0f ATR=%.0f%%",
               g_trendmode_active ? "ACTIVATED" : "DEACTIVATED",
               sz ? "SELL" : "BUY",
               g_htf_hull_trend, GetDailyATRConsumption()*100));
         g_trendmode_last = g_trendmode_active;
      }
      // เมื่อ Trend Mode active: ผ่อน Z-Score limit
      if(g_trendmode_active) sfZLimit = InpTrend_ZLimit;
   }

   // ── STEP 3: DXY Entry Trigger — session-adaptive bars ────────────
   // Asia: sfTrigBars=5 (รอสัญญาณชัดขึ้น) | อื่นๆ: sfTrigBars=3
   double dxy_t[];
   if(!GetSeries(InpDXY_Symbol, 0, sfTrigBars+1, dxy_t)) return;
   bool pb = (dxy_t[0] < dxy_t[sfTrigBars]);   // DXY pulling back
   bool rb = (dxy_t[0] > dxy_t[sfTrigBars]);   // DXY bouncing
   bool s3 = (bz && pb) || (sz && rb);
   if(!s3) {
      g_lastBlockReason = StringFormat("Step3: DXY trigger pending (%s wait %s)",
         bz?"BUY":"SELL", bz?"pullback":"bounce");
      return;                          // Step 3 FAIL — wait for trigger
   }

   // ── STEP 4a: Gold Z-Score — directional + session-adaptive [V.13] ──
   // BUY:  block ถ้า Gold overbought  (zg ≥ +sfZLimit) — ซื้อที่ยอด
   // SELL: block ถ้า Gold oversold    (zg ≤ -sfZLimit) — ขายที่ก้น
   double gc[];
   if(!GetSeries(_Symbol, 0, InpZPeriod, gc)) return;
   double zg   = ZScore(gc, InpZPeriod);
   bool   z_ok = bz ? (zg < sfZLimit) : (zg > -sfZLimit);
   if(!z_ok) {
      g_lastBlockReason = StringFormat("[SF-4a] Z=%.2f %s (lim=%.2f, ses=%d)",
         zg, bz?"overbought":"oversold", sfZLimit, curSession);
      datetime _curBar = iTime(_Symbol, PERIOD_M1, 0);
      if(bz && _curBar != g_blk_zscore_buy_bar) {
         Print(StringFormat("[SF-4a] Z-Score BLOCKED: z=%.2f (overbought) limit=%.2f session=%d",
               zg, sfZLimit, curSession));
         g_blk_zscore_buy_bar = _curBar;
      } else if(sz && _curBar != g_blk_zscore_sell_bar) {
         Print(StringFormat("[SF-4a] Z-Score BLOCKED: z=%.2f (oversold) limit=%.2f session=%d",
               zg, sfZLimit, curSession));
         g_blk_zscore_sell_bar = _curBar;
      }
      return;                          // Step 4a FAIL
   }

   // ── STEP 4b: Gold Momentum ────────────────────────────────────────
   bool gob = GoldOkForBuy(0);
   bool gos = GoldOkForSell(0);
   bool mom_ok = bz ? gob : gos;
   if(!mom_ok) {
      g_lastBlockReason = StringFormat("Step4b: Momentum fail (%s Gold)", bz?"bearish":"bullish");
      return;                          // Step 4b FAIL
   }

   // ── STEP 4c: Daily ATR Exhaustion Filter [V.5] ───────────────────
   // ป้องกัน entry ตอนที่ตลาดวิ่งไปมากกว่า X% ของ ATR(D1) แล้ว
   // V.20i: ใช้ Directional ATR — BUY cap นับเฉพาะ upside, SELL cap นับเฉพาะ downside
   //        วันที่ bullish 147% จะ block BUY แต่ไม่ block SELL (และกลับกัน)
   if(InpSF_Enable && InpSF_ATRExhaust_Enable)
   {
      double atrConsumed = GetDailyATRConsumptionDir(bz);  // directional
      double capToUse    = g_sp.atrCap;             // V.20: ใช้ SessionProfile
      // V.19: Trend Mode ผ่อน ATR cap (120% = แทบไม่บล็อก)
      if(g_trendmode_active) capToUse = InpTrend_ATRCap;

      if(atrConsumed >= capToUse)
      {
         g_lastBlockReason = StringFormat("[SF-4c] ATR%s=%.0f%% (cap=%.0f%% TM=%s ses=%d)",
            bz?"UP":"DN", atrConsumed*100, capToUse*100, g_trendmode_active?"ON":"OFF", curSession);
         bool _periodic4c = !g_blk_atr_exhaust || (TimeCurrent() - g_debug_last_print >= 1800);
         if(_periodic4c) {
            Print(StringFormat("[SF-4c] ATR Exhaustion BLOCKED: %s=%.0f%% consumed (cap=%.0f%%, TrendMode=%s, session=%d)",
                  bz?"ATARUP":"ATRDN", atrConsumed*100, capToUse*100, g_trendmode_active?"ON":"OFF", curSession));
            g_blk_atr_exhaust = true;
            g_debug_last_print = TimeCurrent();
         }
         return;                       // Step 4c FAIL
      }
      g_blk_atr_exhaust = false;
   }

   // ── STEP 5: MACD Filter — session-adaptive MinGap ────────────────
   // Asia: sfMACDGap=0.30 (กรอง noise) | อื่นๆ: 0.0
   bool macd_pass = true;
   if(InpUseMACDFilter) {
      double dm[], ds[];
      ArraySetAsSeries(dm, true); ArraySetAsSeries(ds, true);
      if(CopyBuffer(g_macd_handle, 0, 0, 2, dm) >= 2 &&
         CopyBuffer(g_macd_handle, 1, 0, 1, ds) >= 1) {
         double gap     = dm[0] - ds[0];
         bool   momBuy  = (dm[0] > dm[1]);
         bool   momSell = (dm[0] < dm[1]);
         if(bz) macd_pass = (gap >  sfMACDGap) && momBuy;
         if(sz) macd_pass = (gap < -sfMACDGap) && momSell;
      }
   }
   if(!macd_pass) {
      g_lastBlockReason = StringFormat("Step5: MACD fail (%s)", bz?"need bullish":"need bearish");
      return;                          // Step 5 FAIL
   }

   // ── STEP 6: Hull Trend ──
   if(g_hullLastWrittenIdx >= 0 && g_hullLastWrittenIdx < ArraySize(gdx_HullTrend)) {
      double ht = gdx_HullTrend[g_hullLastWrittenIdx];
      if(bz && ht == -1.0) { g_lastBlockReason = "Step6: Hull DOWN blocks BUY"; return; }
      if(sz && ht ==  1.0) { g_lastBlockReason = "Step6: Hull UP blocks SELL";  return; }
   }

   // ── STEP 6b: HTF Hull Trend Lock (Solution D) ─────────────────
   // ป้องกัน Counter-trend entry — BUY ต้องได้ HTF Hull UP, SELL ต้องได้ HTF Hull DN
   // [V.25] Warmup guard: ถ้า HTF ยังโหลดไม่เสร็จ (=0) → block ทุก trade ป้องกัน bypass หลัง reinit
   if(InpHTF_Enable && g_htf_hull_trend == 0)
   {
      g_lastBlockReason = "[HTF] Warmup — trend not ready";
      return;
   }
   if(InpHTF_Enable && g_htf_hull_trend != 0)
   {
      if(bz && g_htf_hull_trend == -1.0)
      {
         g_lastBlockReason = "[HTF] BUY blocked — H1 Hull DN";
         bool _periodicHTF = (g_htf_lastPrintedBlock != 1.0) || (TimeCurrent() - g_debug_last_print >= 1800);
         if(_periodicHTF) {
            Print(StringFormat("[HTF Hull] BUY BLOCKED — HTF %s Hull = DN",
                  EnumToString(InpHTF_Timeframe)));
            g_htf_lastPrintedBlock = 1.0;
            g_debug_last_print = TimeCurrent();
         }
         return;   // HTF DN blocks BUY
      }
      if(sz && g_htf_hull_trend ==  1.0)
      {
         g_lastBlockReason = "[HTF] SELL blocked — H1 Hull UP";
         bool _periodicHTF2 = (g_htf_lastPrintedBlock != -1.0) || (TimeCurrent() - g_debug_last_print >= 1800);
         if(_periodicHTF2) {
            Print(StringFormat("[HTF Hull] SELL BLOCKED — HTF %s Hull = UP",
                  EnumToString(InpHTF_Timeframe)));
            g_htf_lastPrintedBlock = -1.0;
            g_debug_last_print = TimeCurrent();
         }
         return;   // HTF UP blocks SELL
      }
   }

   // ── STEP 7: OFA Dual-Period filter ──
   bool ofaBull  = false, ofaBull2 = false;
   bool ofa_ok   = false;
   if(gdx_LastConfirmedCount > 0) {
      ofaBull = !gdx_swings[gdx_LastConfirmedCount-1].isHigh;
   }
   if(InpOFA_FractalPeriod2 > InpOFA_FractalPeriod && gdx_LastConfirmedCount2 > 0) {
      ofaBull2 = !gdx_swings2[gdx_LastConfirmedCount2-1].isHigh;
      ofa_ok   = (ofaBull == ofaBull2);   // ALIGNED
   } else if(gdx_LastConfirmedCount > 0) {
      ofa_ok = true;   // p50 not active — use p26 only
   }
   if(!ofa_ok) {
      g_lastBlockReason = "Step7: OFA p26/p50 mismatch";
      return;                         // Step 7 FAIL — OFA mismatch
   }
   if(gdx_LastConfirmedCount > 0) {
      if(bz && !ofaBull) { g_lastBlockReason = "Step7: OFA BEAR blocks BUY";  return; }
      if(sz &&  ofaBull) { g_lastBlockReason = "Step7: OFA BULL blocks SELL"; return; }
   }

   // ── STEP 8S: Asia Range Guard [V.5] ─────────────────────────────
   // Block BUY ใกล้ Asia VAH / Block SELL ใกล้ Asia VAL
   // ป้องกัน Buy ที่ยอด Asia range / Sell ที่ก้น Asia range
   // V.19: bypass เมื่อ TrendMode active | V.20: ใช้ g_sp.rangeGuard
   if(InpSF_Enable && curSession == SESSION_ASIA && g_sp.rangeGuard > 0 && !g_trendmode_active)
   {
      double entryPrice = bz ? currentTick.ask : currentTick.bid;
      if(CheckAsiaRangeGuard(bz, entryPrice))
      {
         if(!g_blk_asia_range) {
            Print(StringFormat("[SF-8S] Asia Range Guard blocked %s — price=%.2f near Asia %s (guard=%.0f%%)",
                  bz ? "BUY" : "SELL", entryPrice,
                  bz ? "VAH" : "VAL",
                  g_sp.rangeGuard * 100));
            g_blk_asia_range = true;
         }
         return;                       // Step 8S FAIL
      }
      g_blk_asia_range = false;
   }

   // ── V.20 STEP 8S-2: Asia Stop Hunt Guard ─────────────────────────
   // Block SELL ถ้า price ใกล้ ATR M75 → Stop Hunt reversal zone (BUY)
   // Block BUY ถ้า price ใกล้ ATR P75 → Stop Hunt reversal zone (SELL)
   if(InpSF_Enable && curSession == SESSION_ASIA && InpAsia_StopHuntGuard && !g_trendmode_active)
   {
      if(IsNearATRM75(bz))
      {
         if(!g_blk_asia_stophunt) {
            Print(StringFormat("[SF-8S2] Asia Stop Hunt Guard blocked %s — price near ATR %s (buf=%.2f)",
                  bz ? "BUY" : "SELL", bz ? "P75" : "M75", InpAsia_M75_Buffer));
            g_blk_asia_stophunt = true;
         }
         return;                       // Step 8S-2 FAIL
      }
      g_blk_asia_stophunt = false;
   }

   // ── V.20 STEP 8S-3: Asia Max Positions ───────────────────────────
   // ป้องกัน over-position ใน Asia range mode
   if(curSession == SESSION_ASIA && g_sp.maxPositions > 0)
   {
      int asiaPosCount = 0;
      for(int _i = PositionsTotal()-1; _i >= 0; _i--) {
         if(PositionGetSymbol(_i) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) == InpMagicnumber)
            asiaPosCount++;
      }
      if(asiaPosCount >= g_sp.maxPositions) {
         if(!g_blk_asia_maxpos) {
            Print(StringFormat("[SF-8S3] Asia MaxPositions=%d reached (%d open)",
                  g_sp.maxPositions, asiaPosCount));
            g_blk_asia_maxpos = true;
         }
         return;                       // Step 8S-3 FAIL
      }
      g_blk_asia_maxpos = false;
   }

   // ── V.20 GroupE: London Breakout Boost — set global flag ─────────
   // ตั้ง g_lon_breakout_boost เมื่อรู้ direction (bz/sz) แล้ว
   if(curSession == SESSION_LONDON)
      g_lon_breakout_boost = IsStrongLondonBreakout(bz);

   // ── STEP 8L(ii): London Asia Sweep Check [V.5] ──────────────────
   // รอให้ London sweep Asia High/Low ก่อนจึงค่อย entry
   // ป้องกัน entry ก่อน London Fake Move จบ
   // V.20: ใช้ g_sp.waitSweep แทน InpSF_London_WaitSweep inline
   if(InpSF_Enable && g_sp.waitSweep && curSession == SESSION_LONDON)
   {
      if(!IsAsiaSweepDone(bz))
      {
         if(!g_blk_london_sweep) {
            Print(StringFormat("[SF-8L] London Sweep Check blocked %s — Asia %s not swept yet",
                  bz ? "BUY" : "SELL",
                  bz ? "Low" : "High"));
            g_blk_london_sweep = true;
         }
         return;                       // Step 8L FAIL
      }
      g_blk_london_sweep = false;
   }

   // ══ ALL STEPS PASSED ══ Draw arrow + arm signal ══
   g_lastBlockReason = StringFormat("%s SIGNAL READY (TM=%s ATR=%.0f%%)",
      bz?"BUY":"SELL", g_trendmode_active?"ON":"OFF", GetDailyATRConsumption()*100);
   datetime barTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   double   barHigh = iHigh(_Symbol, PERIOD_CURRENT, 0);
   double   barLow  = iLow (_Symbol, PERIOD_CURRENT, 0);
   double   barClose= iClose(_Symbol, PERIOD_CURRENT, 0);

   if(bz) {
      GoldDXYBuy             = barClose;
      GoldDXYSignalBarTimeBuy = barTime;
      DrawBuyArrow(barTime, barLow);
   }
   if(sz) {
      GoldDXYSell              = barClose;
      GoldDXYSignalBarTimeSell = barTime;
      DrawSellArrow(barTime, barHigh);
   }

   // Stale filter
   datetime stale = TimeCurrent() - 120*60;
   if(GoldDXYSignalBarTimeBuy  != 0 && GoldDXYSignalBarTimeBuy  < stale)
      { GoldDXYBuy  = EMPTY_VALUE; GoldDXYSignalBarTimeBuy  = 0; }
   if(GoldDXYSignalBarTimeSell != 0 && GoldDXYSignalBarTimeSell < stale)
      { GoldDXYSell = EMPTY_VALUE; GoldDXYSignalBarTimeSell = 0; }
}

//+------------------------------------------------------------------+
//| V.11 — Daily Loss Limit                                          |
//+------------------------------------------------------------------+
// เรียกทุกครั้งที่ Trade ปิด (ใน OnTradeTransaction)
void UpdateDailyLoss(double closedPnL)
{
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(today != g_dailyLossDate) { g_dailyLossTotal = 0; g_dailyLossDate = today; g_dailyLossBlocked = false; }
   if(closedPnL < 0) g_dailyLossTotal += MathAbs(closedPnL);
   if(InpDailyLoss_Enable && !g_dailyLossBlocked && g_dailyLossTotal >= InpDailyLoss_Limit)
   {
      g_dailyLossBlocked = true;
      string msg = StringFormat("[DailyLoss] BLOCKED today — loss $%.2f ≥ limit $%.2f",
                                g_dailyLossTotal, InpDailyLoss_Limit);
      Print(msg);
      if(InpDailyLoss_Notify && InpSendPush && !GDEA_IsQuietHour()) SendNotification(msg);
   }
}

// ตรวจก่อนเปิด Order — return false = block entry
bool CheckDailyLossLimit()
{
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(today != g_dailyLossDate) { g_dailyLossTotal = 0; g_dailyLossDate = today; g_dailyLossBlocked = false; }
   if(InpDailyLoss_Enable && g_dailyLossBlocked)
   {
      Print(StringFormat("[DailyLoss] Entry blocked — daily loss $%.2f", g_dailyLossTotal));
      return false;
   }
   return true;
}

//+------------------------------------------------------------------+
//| V.11 — Wick Ratio Filter (Stop Hunt Rejection)                   |
//+------------------------------------------------------------------+
// BUY: ต้องมี Lower Wick ≥ InpWick_MinRatio × range (Bullish Rejection)
// SELL: ต้องมี Upper Wick ≥ InpWick_MinRatio × range (Bearish Rejection)
bool CheckWickFilter(bool isBuy)
{
   if(!InpWick_Enable) return true;
   for(int i = 1; i <= InpWick_LookbackBars; i++)
   {
      double open  = iOpen (_Symbol, PERIOD_CURRENT, i);
      double high  = iHigh (_Symbol, PERIOD_CURRENT, i);
      double low   = iLow  (_Symbol, PERIOD_CURRENT, i);
      double close = iClose(_Symbol, PERIOD_CURRENT, i);
      double range = high - low;
      if(range < _Point * 5) continue;   // แท่งเล็กเกิน → ข้าม
      if(isBuy)
      {
         double lowerWick = MathMin(open, close) - low;
         if(lowerWick / range >= InpWick_MinRatio) return true;
      }
      else
      {
         double upperWick = high - MathMax(open, close);
         if(upperWick / range >= InpWick_MinRatio) return true;
      }
   }
   Print(StringFormat("[WickFilter] %s blocked — no rejection wick ≥ %.0f%% in last %d bars",
         isBuy ? "BUY" : "SELL", InpWick_MinRatio * 100, InpWick_LookbackBars));
   return false;
}

//+------------------------------------------------------------------+
//| OpenBuyPosition                                                  |
//+------------------------------------------------------------------+
// ── หา Swing SL สำหรับ BUY: ใช้ Swing Low ที่ต่ำสุดใน N จุดล่าสุด ──
double GetSwingSL_Buy(double entry)
{
   if(gdx_LastConfirmedCount < 2) return 0;
   double bestLow = DBL_MAX;
   int checked = 0;
   // วน Swing ล่าสุดไปหาจุดต่ำสุดที่อยู่ต่ำกว่า Entry
   for(int i = gdx_LastConfirmedCount - 1; i >= 0 && checked < InpSwingLookback * 2; i--)
   {
      if(!gdx_swings[i].isHigh)  // Swing Low
      {
         if(gdx_swings[i].price < entry)  // ต้องต่ำกว่า Entry
         {
            if(gdx_swings[i].price < bestLow) bestLow = gdx_swings[i].price;
            checked++;
            if(checked >= InpSwingLookback) break;
         }
      }
   }
   if(bestLow == DBL_MAX) return 0;
   return NormalizeDouble(bestLow - InpSwingBuffer, _Digits);
}

// ── หา Swing SL สำหรับ SELL: ใช้ Swing High ที่สูงสุดใน N จุดล่าสุด ──
double GetSwingSL_Sell(double entry)
{
   if(gdx_LastConfirmedCount < 2) return 0;
   double bestHigh = -DBL_MAX;
   int checked = 0;
   for(int i = gdx_LastConfirmedCount - 1; i >= 0 && checked < InpSwingLookback * 2; i--)
   {
      if(gdx_swings[i].isHigh)  // Swing High
      {
         if(gdx_swings[i].price > entry)  // ต้องสูงกว่า Entry
         {
            if(gdx_swings[i].price > bestHigh) bestHigh = gdx_swings[i].price;
            checked++;
            if(checked >= InpSwingLookback) break;
         }
      }
   }
   if(bestHigh == -DBL_MAX) return 0;
   return NormalizeDouble(bestHigh + InpSwingBuffer, _Digits);
}

// ── หา Swing TP สำหรับ BUY: ใช้ Swing High ที่ใกล้ที่สุดเหนือ Entry ──
// ── Session TP Cap: Entry ± Remaining × Factor ─────────────────────
double GetSessionTPCap(bool isBuy, double entry)
{
   MqlDateTime dt; TimeCurrent(dt); int hr = dt.hour;
   bool inAsia   = (hr >= InpAsiaStartHr   && hr < InpAsiaEndHr);
   bool inLondon = (hr >= InpLondonStartHr && hr < InpLondonEndHr);
   bool inNY     = (hr >= InpNYStartHr     && hr < InpNYEndHr);

   double factor = inAsia ? InpTP_Asia_Factor : inLondon ? InpTP_London_Factor : inNY ? InpTP_NY_Factor : InpTP_Asia_Factor;

   // V.20 GroupE: London Breakout Boost — TP factor → 1.0 เมื่อ strong breakout
   if(inLondon && g_lon_breakout_boost)
   {
      factor = InpTP_NY_Factor;   // full factor (1.0 default)
      Print(StringFormat("[V.20-E] London Breakout Boost — TP factor → %.2f", factor));
   }

   double atr1d     = GDEA_GetATRDaily(InpATRLevelsPeriod);
   double todayHigh = iHigh(_Symbol, PERIOD_D1, 0);
   double todayLow  = iLow (_Symbol, PERIOD_D1, 0);
   double todayRange = todayHigh - todayLow;
   double remaining  = MathMax(atr1d - todayRange, atr1d * 0.20);

   return isBuy
          ? NormalizeDouble(entry + remaining * factor, _Digits)
          : NormalizeDouble(entry - remaining * factor, _Digits);
}

// ── Fib TP BUY: 161.8% จาก gdx_swings (p26) ───────────────────────
double GetFibTP_Buy(double entry)
{
   if(gdx_LastConfirmedCount < 2) return 0;
   GDX_SwingPoint s0 = gdx_swings[gdx_LastConfirmedCount - 2];
   GDX_SwingPoint s1 = gdx_swings[gdx_LastConfirmedCount - 1];
   double hi = s0.isHigh ? s0.price : s1.price;
   double lo = s0.isHigh ? s1.price : s0.price;
   if(hi <= lo) return 0;
   double fib1618 = NormalizeDouble(hi + (hi - lo) * 0.618, _Digits);
   return (fib1618 > entry) ? fib1618 : 0;
}

// ── Fib TP SELL: -61.8% จาก gdx_swings (p26) ──────────────────────
double GetFibTP_Sell(double entry)
{
   if(gdx_LastConfirmedCount < 2) return 0;
   GDX_SwingPoint s0 = gdx_swings[gdx_LastConfirmedCount - 2];
   GDX_SwingPoint s1 = gdx_swings[gdx_LastConfirmedCount - 1];
   double hi = s0.isHigh ? s0.price : s1.price;
   double lo = s0.isHigh ? s1.price : s0.price;
   if(hi <= lo) return 0;
   double fibN618 = NormalizeDouble(lo - (hi - lo) * 0.618, _Digits);
   return (fibN618 < entry) ? fibN618 : 0;
}

// ── เลือก TP ที่ดีที่สุด — Conservative (ใกล้สุดที่ผ่าน MinRR) ────
double SelectBestTP_Buy(double entry, double rawSL)
{
   double minTarget = entry + MathAbs(entry - rawSL) * InpMinRR;
   double candidates[4];
   int    count = 0;

   // A: Swing TP
   double a = GetSwingTP_Buy(entry, rawSL);
   if(a > minTarget) candidates[count++] = a;

   // B: Fib 161.8%
   if(InpTP_UseFib) {
      double b = GetFibTP_Buy(entry);
      if(b > minTarget) candidates[count++] = b;
   }

   // C: Session Cap
   if(InpTP_UseSession) {
      double c = GetSessionTPCap(true, entry);
      if(c > minTarget) candidates[count++] = c;
   }

   // D: Fixed RR fallback
   double d = NormalizeDouble(entry + MathAbs(entry - rawSL) * InpRR, _Digits);
   candidates[count++] = d;

   // เลือกค่าที่ใกล้ Entry ที่สุด (ต่ำสุดสำหรับ BUY = conservative)
   double best = candidates[0];
   for(int i = 1; i < count; i++)
      if(candidates[i] < best) best = candidates[i];

   // Log candidates
   string log = StringFormat("[TP Select BUY] Swing=%.2f Fib=%.2f Cap=%.2f RR=%.2f → %.2f",
                              a, GetFibTP_Buy(entry), GetSessionTPCap(true,entry), d, best);
   Print(log);
   return best;
}

double SelectBestTP_Sell(double entry, double rawSL)
{
   double minTarget = entry - MathAbs(rawSL - entry) * InpMinRR;
   double candidates[4];
   int    count = 0;

   // A: Swing TP
   double a = GetSwingTP_Sell(entry, rawSL);
   if(a > 0 && a < minTarget) candidates[count++] = a;

   // B: Fib -61.8%
   if(InpTP_UseFib) {
      double b = GetFibTP_Sell(entry);
      if(b > 0 && b < minTarget) candidates[count++] = b;
   }

   // C: Session Cap
   if(InpTP_UseSession) {
      double c = GetSessionTPCap(false, entry);
      if(c > 0 && c < minTarget) candidates[count++] = c;
   }

   // D: Fixed RR fallback
   double d = NormalizeDouble(entry - MathAbs(rawSL - entry) * InpRR, _Digits);
   candidates[count++] = d;

   // เลือกค่าที่ใกล้ Entry ที่สุด (สูงสุดสำหรับ SELL = conservative)
   double best = candidates[0];
   for(int i = 1; i < count; i++)
      if(candidates[i] > best) best = candidates[i];

   string log = StringFormat("[TP Select SELL] Swing=%.2f Fib=%.2f Cap=%.2f RR=%.2f → %.2f",
                              a, GetFibTP_Sell(entry), GetSessionTPCap(false,entry), d, best);
   Print(log);
   return best;
}

double GetSwingTP_Buy(double entry, double rawSL)
{
   if(gdx_LastConfirmedCount < 2) return 0;
   double minRRTarget = entry + MathAbs(entry - rawSL) * InpMinRR;
   double bestTP = 0;
   double bestDist = DBL_MAX;
   for(int i = gdx_LastConfirmedCount - 1; i >= 0; i--)
   {
      if(gdx_swings[i].isHigh)  // Swing High
      {
         double tp = NormalizeDouble(gdx_swings[i].price - InpSwingBuffer, _Digits);
         if(tp > minRRTarget)   // ต้องถึง MinRR อย่างน้อย
         {
            double dist = tp - entry;
            if(dist < bestDist) { bestDist = dist; bestTP = tp; }
         }
      }
   }
   return bestTP;
}

// ── หา Swing TP สำหรับ SELL: ใช้ Swing Low ที่ใกล้ที่สุดใต้ Entry ──
double GetSwingTP_Sell(double entry, double rawSL)
{
   if(gdx_LastConfirmedCount < 2) return 0;
   double minRRTarget = entry - MathAbs(rawSL - entry) * InpMinRR;
   double bestTP = 0;
   double bestDist = DBL_MAX;
   for(int i = gdx_LastConfirmedCount - 1; i >= 0; i--)
   {
      if(!gdx_swings[i].isHigh)  // Swing Low
      {
         double tp = NormalizeDouble(gdx_swings[i].price + InpSwingBuffer, _Digits);
         if(tp < minRRTarget)    // ต้องถึง MinRR อย่างน้อย
         {
            double dist = entry - tp;
            if(dist < bestDist) { bestDist = dist; bestTP = tp; }
         }
      }
   }
   return bestTP;
}

// ── ตรวจ LiqZone ที่กีดขวางทิศ TP ────────────────────────────────
// isSell=true  → ตรวจ BUY STOPS Zone ใต้ Entry
// isSell=false → ตรวจ SELL STOPS Zone เหนือ Entry
// return true = Block, false = อนุญาต
bool CheckLiqZoneFilter(bool isSell, double entry)
{
   if(!InpLiqZone_Filter) return false;

   int n = ArraySize(g_liqZones);
   if(n == 0) return false;

   // ── เก็บ Zone ที่ตรงทิศ พร้อม distance ──────────────────────
   double dists[];
   int    idxs[];
   int    found = 0;

   for(int i = 0; i < n; i++)
   {
      LiqZoneState z = g_liqZones[i];

      // ถ้า Raided แล้วและอนุญาต → ข้าม
      if(InpLiqZone_AllowRaid && z.raidNotified) continue;

      double dist = -1;
      if(isSell)
      {
         // SELL → หา BUY STOPS ใต้ Entry
         if(!z.isBuyStopsZone) continue;
         if(z.zoneHigh >= entry) continue;
         dist = entry - z.zoneHigh;
      }
      else
      {
         // BUY → หา SELL STOPS เหนือ Entry
         if(z.isBuyStopsZone) continue;
         if(z.zoneLow <= entry) continue;
         dist = z.zoneLow - entry;
      }

      if(dist < 0) continue;

      // เก็บไว้ sort ทีหลัง
      int sz = ArraySize(dists);
      ArrayResize(dists, sz + 1);
      ArrayResize(idxs,  sz + 1);
      dists[sz] = dist;
      idxs[sz]  = i;
      found++;
   }

   if(found == 0) return false;

   // ── Sort ascending (ใกล้สุดก่อน) — Bubble sort ──────────────
   for(int a = 0; a < found - 1; a++)
      for(int b = a + 1; b < found; b++)
         if(dists[b] < dists[a])
         {
            double td = dists[a]; dists[a] = dists[b]; dists[b] = td;
            int    ti = idxs[a];  idxs[a]  = idxs[b];  idxs[b]  = ti;
         }

   // ── ตรวจเฉพาะ InpLiqZone_MaxCheck Zone ที่ใกล้สุด ───────────
   int checkCount = MathMin(found, InpLiqZone_MaxCheck);
   for(int k = 0; k < checkCount; k++)
   {
      double dist = dists[k];
      LiqZoneState z = g_liqZones[idxs[k]];

      if(dist < InpLiqZone_MinDist)
      {
         datetime _bar = iTime(_Symbol,PERIOD_M1,0);
         if(isSell) {
            if(g_blk_liqflt_sell_bar != _bar) {
               g_blk_liqflt_sell_bar = _bar;
               string zone = "BUY STOPS";
               double lvl  = z.zoneHigh;
               Print(StringFormat("[LiqFilter] SELL blocked — %s at %.2f  dist=%.1f < min=%.1f",
                                  zone, lvl, dist, InpLiqZone_MinDist));
            }
         } else {
            if(g_blk_liqflt_buy_bar != _bar) {
               g_blk_liqflt_buy_bar = _bar;
               string zone = "SELL STOPS";
               double lvl  = z.zoneLow;
               Print(StringFormat("[LiqFilter] BUY blocked — %s at %.2f  dist=%.1f < min=%.1f",
                                  zone, lvl, dist, InpLiqZone_MinDist));
            }
         }
         return true;  // Block
      }
   }

   // ── อนุญาต: Log Zone ที่ใกล้สุด ─────────────────────────────
   if(found > 0)
   {
      string side = isSell ? "SELL" : "BUY";
      LiqZoneState zn = g_liqZones[idxs[0]];
      double lvl = isSell ? zn.zoneHigh : zn.zoneLow;
      Print(StringFormat("[LiqFilter] %s ok — nearest Zone at %.2f  dist=%.1f",
                         side, lvl, dists[0]));
   }
   return false;
}

// ── V.15: Session name helper ─────────────────────────────────────────
string GetSessionName(ENUM_SF_SESSION s)
{
   switch(s) {
      case SESSION_ASIA:         return "ASIA";
      case SESSION_LONDON:       return "LONDON";
      case SESSION_NY_MORNING:   return "NYM";
      case SESSION_NY_AFTERNOON: return "NYPM";
      default:                   return "OFF";
   }
}

//// ── V.15: Log trade open — 2 บรรทัด + เก็บ context สำหรับ CLOSE ─────
//void LogTradeOpen(bool isBuy, double entry, double sl, double tp, double lots)
//{
//   ENUM_SF_SESSION sess = GetCurrentSession();
//   string sessStr = GetSessionName(sess);
//
//   int    htfDir = (g_hullLastWrittenIdx >= 0 && g_hullLastWrittenIdx < ArraySize(gdx_HullTrend))
//                  ? (int)gdx_HullTrend[g_hullLastWrittenIdx] : 0;
//   string htfStr = (htfDir == 1) ? "UP" : (htfDir == -1 ? "DN" : "--");
//
//   double gc[]; double zg = 0;
//   if(GetSeries(_Symbol, 0, InpZPeriod, gc)) zg = ZScore(gc, InpZPeriod);
//
//   double atrPct   = GetDailyATRConsumption() * 100.0;
//   double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
//   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
//   double slRiskUSD = (tickSize > 0) ? MathAbs(entry - sl) / tickSize * tickVal * lots : 0;
//   double actualRR  = MathAbs(tp - entry) / MathMax(MathAbs(entry - sl), _Point);
//
//   string side = isBuy ? "BUY " : "SELL";
//   Print(StringFormat("[OPEN %s] Entry=%.2f  SL=%.2f(%.2f pts / -$%.2f)  TP=%.2f  RR=%.2f  Lots=%.2f",
//         side, entry, sl, MathAbs(entry-sl), slRiskUSD, tp, actualRR, lots));
//   Print(StringFormat("         Session=%-6s  HTF=%-2s  Z=%+.2f  ATR=%.0f%%",
//         sessStr, htfStr, zg, atrPct));
//
//   // เก็บ context สำหรับ CLOSE log
//   if(isBuy) {
//      g_buyOpenPrice = entry; g_buyOpenTime = TimeCurrent();
//      g_buyOpenSess  = sessStr; g_buyOpenHTF = htfStr;
//      g_buyOpenZ     = zg; g_buyOpenATR = atrPct;
//   } else {
//      g_sellOpenPrice = entry; g_sellOpenTime = TimeCurrent();
//      g_sellOpenSess  = sessStr; g_sellOpenHTF = htfStr;
//      g_sellOpenZ     = zg; g_sellOpenATR = atrPct;
//   }
//}
// ── V.1.22: Enhanced Detailed Signal Log ─────────────────────────────────────
void LogTradeOpen(bool isBuy, double entry, double sl, double tp, double lots)
{
   // 1. เตรียมข้อมูลพื้นฐาน
   ENUM_SF_SESSION sess = GetCurrentSession();
   string sessStr = GetSessionName(sess);

   // 2. ดึงค่า Z-Score (Step 4a)
   double gc[]; double zg = 0;
   if(GetSeries(_Symbol, 0, InpZPeriod, gc)) zg = ZScore(gc, InpZPeriod);

   // 3. ดึงค่า ATR Consumption (Step 4c)
   double atrPct = GetDailyATRConsumption() * 100.0;

   // 4. ดึงค่า MACD Gap (Step 5)
   double dm[], ds[]; double macdGap = 0;
   if(CopyBuffer(g_macd_handle, 0, 0, 1, dm) > 0 && CopyBuffer(g_macd_handle, 1, 0, 1, ds) > 0)
      macdGap = dm[0] - ds[0];

   // 5. ดึงค่า Hull & HTF Hull (Step 6 & 6b)
   int hullDir = (g_hullLastWrittenIdx >= 0 && g_hullLastWrittenIdx < ArraySize(gdx_HullTrend)) 
                 ? (int)gdx_HullTrend[g_hullLastWrittenIdx] : 0;
   string htfStr = (g_htf_hull_trend == 1.0) ? "UP" : (g_htf_hull_trend == -1.0 ? "DN" : "--");

   // 6. ดึงค่า OFA (Step 7)
   bool p26bull = (gdx_LastConfirmedCount > 0) ? !gdx_swings[gdx_LastConfirmedCount-1].isHigh : false;
   bool p50bull = (gdx_LastConfirmedCount2 > 0) ? !gdx_swings2[gdx_LastConfirmedCount2-1].isHigh : false;

   // 7. คำนวณความเสี่ยง USD
   double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double slRiskUSD = (tickSize > 0) ? MathAbs(entry - sl) / tickSize * tickVal * lots : 0;

   // --- เริ่มพิมพ์ Log แยกเป็นหมวดหมู่ ---
   string side = isBuy ? "BUY " : "SELL";
   
   Print("================================================================");
   Print(StringFormat("[PASSED ALL STEPS] %s %s at %.2f | Lots: %.2f | Risk: -$%.2f", side, _Symbol, entry, lots, slRiskUSD));
   
   // บรรทัดที่ 1: Trends & Triggers (Steps 1, 2, 3)
   Print(StringFormat(" > STEP 1-3 | HTF_Hull: %s | Session: %s", htfStr, sessStr));

   // บรรทัดที่ 2: Statistics & Math (Steps 4, 5)
   Print(StringFormat(" > STEP 4-5 | Z-Score: %.2f (Lim: %.2f) | ATR_Used: %.0f%% | MACD_Gap: %.4f", 
                      zg, (isBuy ? g_sp.zLimit : -g_sp.zLimit), atrPct, macdGap));

   // บรรทัดที่ 3: Hull & Order Flow (Steps 6, 7)
   Print(StringFormat(" > STEP 6-7 | Hull_M1: %s | OFA_p26: %s | OFA_p50: %s", 
                      (hullDir > 0 ? "UP" : "DN"), 
                      (p26bull ? "BULL" : "BEAR"), 
                      (p50bull ? "BULL" : "BEAR")));

   Print(StringFormat(" > EXIT PLANNED | SL: %.2f (%.1f pts) | TP: %.2f | RR: %.2f", 
                      sl, MathAbs(entry-sl), tp, MathAbs(tp-entry)/MathMax(MathAbs(entry-sl), 0.01)));
   Print("================================================================");

   // เก็บ context สำหรับ CLOSE log เหมือนเดิม
   if(isBuy) {
      g_buyOpenPrice = entry; g_buyOpenTime = TimeCurrent();
      g_buyOpenSess  = sessStr; g_buyOpenHTF = htfStr;
      g_buyOpenZ     = zg; g_buyOpenATR = atrPct;
   } else {
      g_sellOpenPrice = entry; g_sellOpenTime = TimeCurrent();
      g_sellOpenSess  = sessStr; g_sellOpenHTF = htfStr;
      g_sellOpenZ     = zg; g_sellOpenATR = atrPct;
   }
}
//+------------------------------------------------------------------+
bool OpenBuyPosition()
{
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED)) return false;

   // ── [V.1.42] Z-Score Re-Check at Execute Time ─────────────────
   // ป้องกัน race condition: signal ผ่านที่ bar open แต่ Z กระโดดก่อน execute
   if(InpSF_Enable)
   {
      double _gc[]; double _zExec = 0;
      if(GetSeries(_Symbol, 0, InpZPeriod, _gc)) _zExec = ZScore(_gc, InpZPeriod);
      if(_zExec >= g_sp.zLimit)
      {
         datetime _b = iTime(_Symbol, PERIOD_M1, 0);
         if(g_blk_zscore_buy_bar != _b) { g_blk_zscore_buy_bar = _b;
            Print(StringFormat("[ZReCheck] BUY blocked at execute — z=%.2f >= limit=%.2f", _zExec, g_sp.zLimit)); }
         return false;
      }
   }
   // ──────────────────────────────────────────────────────────────

   // ── [V.1.40] Fib Gate: Block BUY at 127.2% Extension ──────────
   if(InpFibGate_Enable)
   {
      datetime _curBarFG = iTime(_Symbol, PERIOD_CURRENT, 0);
      double   _ask      = currentTick.ask;
      // P26
      if(gdx_LastConfirmedCount >= 2)
      {
         double h26 = gdx_swings[gdx_LastConfirmedCount-2].isHigh ? gdx_swings[gdx_LastConfirmedCount-2].price : gdx_swings[gdx_LastConfirmedCount-1].price;
         double l26 = gdx_swings[gdx_LastConfirmedCount-2].isHigh ? gdx_swings[gdx_LastConfirmedCount-1].price : gdx_swings[gdx_LastConfirmedCount-2].price;
         double rng26 = h26 - l26;
         if(rng26 > 0)
         {
            double fib1272_p26 = h26 + rng26 * 0.272;
            if(_ask >= fib1272_p26)
            {
               if(_curBarFG != g_blk_fibgate_buy_bar) {
                  Print("[FibGate] BUY blocked P26 — Ask:", _ask, " >= 127.2%:", fib1272_p26);
                  g_blk_fibgate_buy_bar = _curBarFG;
               }
               return false;
            }
         }
      }
      // P50
      if(gdx_LastConfirmedCount2 >= 2)
      {
         double h50 = gdx_swings2[gdx_LastConfirmedCount2-2].isHigh ? gdx_swings2[gdx_LastConfirmedCount2-2].price : gdx_swings2[gdx_LastConfirmedCount2-1].price;
         double l50 = gdx_swings2[gdx_LastConfirmedCount2-2].isHigh ? gdx_swings2[gdx_LastConfirmedCount2-1].price : gdx_swings2[gdx_LastConfirmedCount2-2].price;
         double rng50 = h50 - l50;
         if(rng50 > 0)
         {
            double fib1272_p50 = h50 + rng50 * 0.272;
            if(_ask >= fib1272_p50)
            {
               if(_curBarFG != g_blk_fibgate_buy_bar) {
                  Print("[FibGate] BUY blocked P50 — Ask:", _ask, " >= 127.2%:", fib1272_p50);
                  g_blk_fibgate_buy_bar = _curBarFG;
               }
               return false;
            }
         }
      }
   }
   // ───────────────────────────────────────────────────────────────

   // ── [NEW] Candle Filter for BUY ────────────────────────────────
   double open0  = iOpen(_Symbol, PERIOD_CURRENT, 0);
   double open1  = iOpen(_Symbol, PERIOD_CURRENT, 1);
   double close1 = iClose(_Symbol, PERIOD_CURRENT, 1);

   bool prevIsGreen = (close1 > open1);
   bool currIsRed   = (currentTick.ask < open0);

   if(prevIsGreen && currIsRed)
   {
      static datetime lastBuyLog = 0;
      if(TimeCurrent() - lastBuyLog > 60) {
         Print("[CandleFilter] BUY blocked — Prev:GREEN, Curr:RED");
         lastBuyLog = TimeCurrent();
      }
      return false;
   }
   // ───────────────────────────────────────────────────────────────

   // ── V.11: Daily Loss Limit ───────────────────────────────────────
   if(!CheckDailyLossLimit()) return false;

   // ── Solution B: Same-SL Cooldown ──────────────────────────────────
   // V.11 Fix: reset counter เมื่อ cooldown หมดแล้ว (ไม่ให้สะสมไม่สิ้นสุด)
   if(InpSameSL_Enable && g_buySameSLCooldownEnd > 0 && TimeCurrent() >= g_buySameSLCooldownEnd)
   {
      g_buySameSLCount       = 0;
      g_lastBuySL            = 0;
      g_buySameSLCooldownEnd = 0;
      Print("[SameSL] BUY cooldown expired → counter reset");
   }
   if(InpSameSL_Enable && TimeCurrent() < g_buySameSLCooldownEnd)
   {
      int minsLeft = (int)((g_buySameSLCooldownEnd - TimeCurrent()) / 60);
      Print(StringFormat("[SameSL] BUY blocked — cooldown %d min remaining (SL=%.2f used %d×)",
            minsLeft, g_lastBuySL, g_buySameSLCount));
      return false;
   }

   // ── V.11: Wick Ratio Filter (Stop Hunt Rejection) ────────────────
   if(!CheckWickFilter(true)) return false;

   // ── LiqZone Filter: ตรวจ SELL STOPS Zone เหนือ Entry ──────
   if(CheckLiqZoneFilter(false, currentTick.ask))
      return false;
   double ask = currentTick.ask;
   datetime entryTime = iTime(_Symbol, PERIOD_CURRENT, 0);

   slPrice = 0; tpPrice = 0;
   DrawTradeHighLowSetup(entryTime, 1, ask, InpRR, InpLotSize, true);   // V.19: isCalcOnly — วาดเฉพาะหลัง Order จริง

   if(slPrice == 0 || slPrice >= ask) {
      double atr[]; ArraySetAsSeries(atr, true);
      if(CopyBuffer(g_atr_handle, 0, 0, 1, atr) > 0 && atr[0] > 0) {
         slPrice = ask - atr[0] * InpATRMulti;
         tpPrice = ask + atr[0] * InpATRMulti * InpRR;
      } else {
         slPrice = ask - InpRR_SlOffset * _Point;
         tpPrice = ask + InpRR_SlOffset * _Point * InpRR;
      }
   }
   slPrice = NormalizeDouble(slPrice, _Digits);
   tpPrice = NormalizeDouble(tpPrice, _Digits);

   // ── Swing SL: ใช้ Swing Low ล่าสุดแทน ATR ──────────────────
   if(InpUseSwingSL && !g_trendmode_active)   // V.19: Trend Mode ใช้ ATR SL แทน
   {
      double swingSL = GetSwingSL_Buy(ask);
      if(swingSL > 0 && swingSL < ask)
      {
         slPrice = swingSL;
         Print(StringFormat("[SwingSL] BUY SL = %.5f (Swing Low)", slPrice));
         // V.20 GroupB: Session SL buffer มาจาก g_sp.slBufferPts
         // (London=+5pts default, session อื่น=0 → ไม่ปรับ)
         if(g_sp.slBufferPts > 0)
         {
            slPrice -= g_sp.slBufferPts;
            slPrice  = NormalizeDouble(slPrice, _Digits);
            Print(StringFormat("[SwingSL] BUY session buffer -%.2f → SL=%.5f", g_sp.slBufferPts, slPrice));
         }
      }
   }

   // ── V.19: Trend Mode SL override — ใช้ ATR(D1)×InpTrend_SLMulti ──
   if(g_trendmode_active)
   {
      double atrD1[]; ArraySetAsSeries(atrD1, true);
      if(g_atr_d1_handle != INVALID_HANDLE &&
         CopyBuffer(g_atr_d1_handle, 0, 1, 1, atrD1) > 0 && atrD1[0] > 0)
      {
         slPrice = NormalizeDouble(ask - atrD1[0] * InpTrend_SLMulti, _Digits);
         { datetime _bar = iTime(_Symbol,PERIOD_M1,0); if(g_blk_trendmode_buy_bar != _bar) { g_blk_trendmode_buy_bar = _bar; Print(StringFormat("[TrendMode] BUY SL = ATR×%.1f → %.5f (atr=%.2f)", InpTrend_SLMulti, slPrice, atrD1[0])); } }
      }
   }

   // ── Liquidity-Aware SL: เลื่อน SL ให้พ้น ATR Zone ก่อนเปิด ──
   if(InpLiqSL_Enable)
   {
      slPrice = AdjustSLForLiquidity(slPrice, ask, true);
      if(slPrice <= 0) {
         datetime _bar = iTime(_Symbol,PERIOD_M1,0);
         if(g_blk_liqsl_buy_bar != _bar) { g_blk_liqsl_buy_bar = _bar; Print("[OpenBuy] SL too wide after LiqAdj, skip trade"); }
         return false;
      }
   }

   // ── TP: เลือก Conservative TP จาก Swing/Fib/Session/RR ────
   if(InpVP_FilterEnable && InpVP_UseTPTarget)
      tpPrice = GetVPTargetTP(true, ask, MathAbs(ask - slPrice));
   else if(InpUseSwingTP || InpTP_UseFib || InpTP_UseSession)
      tpPrice = SelectBestTP_Buy(ask, slPrice);
   else
      tpPrice = NormalizeDouble(ask + MathAbs(ask - slPrice) * InpRR, _Digits);

   // ── V.19: Trend Mode TP = ATR P50 level (PDATr) ──────────────────
   if(g_trendmode_active)
   {
      double atr  = GDEA_GetATRDaily(InpATRLevelsPeriod);
      double base = GetATRBaseline();
      if(atr > 0 && base > 0)
      {
         double tp50 = NormalizeDouble(base + atr * 0.50, _Digits);
         if(tp50 > ask) {   // valid BUY target (above entry)
            tpPrice = tp50;
            Print(StringFormat("[TrendMode] BUY TP = ATR P50 → %.5f (base=%.2f atr=%.2f)", tpPrice, base, atr));
         }
         // เก็บ P25 สำหรับ partial close
         g_buy_atr_tp25   = NormalizeDouble(base + atr * 0.25, _Digits);
         g_buy_partial_done = false;
      }
   }
   else { g_buy_atr_tp25 = 0; }

   // ── Guard MinRR: ถ้า RR ไม่ถึงขั้นต่ำ → ไม่เปิด ───────────
   double actualRR = MathAbs(tpPrice - ask) / MathMax(MathAbs(ask - slPrice), _Point);
   if(actualRR < InpMinRR - 0.001)   // [V.21] float precision fix: 1.4999...== 1.50 ผ่านได้
   {
      Print(StringFormat("[OpenBuy] RR=%.2f < MinRR=%.2f → skip", actualRR, InpMinRR));
      return false;
   }

   double lots = InpLotSize;
   if(!calculateLots(MathAbs(ask - slPrice), lots)) return false;
   // V.20 GroupD: NYPM Half Lot — ลด lot 50% ใน NY Afternoon (fatigue protection)
   if(g_sp.lotMultiplier < 1.0)
   {
      lots = NormalizeDouble(lots * g_sp.lotMultiplier, 2);
      lots = MathMax(lots, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN));
      Print(StringFormat("[V.20-D] BUY NYPM HalfLot → lots=%.2f (×%.1f)", lots, g_sp.lotMultiplier));
   }

   if(!Trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, lots, ask, slPrice, tpPrice,
         "GDEA_BUY Magic:" + IntegerToString(InpMagicnumber))) {
      Print("BUY Error: ", GetLastError());
      return false;
   }
   LogTradeOpen(true, ask, slPrice, tpPrice, lots);   // V.15: enhanced open log
   NotifyOrderOpen(true, ask, slPrice, tpPrice, lots);
   DrawTradeBox(entryTime, ask, slPrice, tpPrice, lots, true);

   // ── Solution B V.3: บันทึก SL ล่าสุดของ BUY ─────────────────
   // counter จะนับเฉพาะเมื่อ Trade ชนะ ใน OnTradeTransaction
   if(InpSameSL_Enable) g_lastBuySL = slPrice;

   return true;
}

//+------------------------------------------------------------------+
//| OpenSellPosition                                                 |
//+------------------------------------------------------------------+
bool OpenSellPosition()
{
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED)) return false;

   // ── [V.1.42] Z-Score Re-Check at Execute Time ─────────────────
   if(InpSF_Enable)
   {
      double _gc[]; double _zExec = 0;
      if(GetSeries(_Symbol, 0, InpZPeriod, _gc)) _zExec = ZScore(_gc, InpZPeriod);
      if(_zExec <= -g_sp.zLimit)
      {
         datetime _b = iTime(_Symbol, PERIOD_M1, 0);
         if(g_blk_zscore_sell_bar != _b) { g_blk_zscore_sell_bar = _b;
            Print(StringFormat("[ZReCheck] SELL blocked at execute — z=%.2f <= limit=%.2f", _zExec, -g_sp.zLimit)); }
         return false;
      }
   }
   // ──────────────────────────────────────────────────────────────

   // ── [V.1.40] Fib Gate: Block SELL at -127.2% Extension ────────
   if(InpFibGate_Enable)
   {
      datetime _curBarFG = iTime(_Symbol, PERIOD_CURRENT, 0);
      double   _bid      = currentTick.bid;
      // P26
      if(gdx_LastConfirmedCount >= 2)
      {
         double h26 = gdx_swings[gdx_LastConfirmedCount-2].isHigh ? gdx_swings[gdx_LastConfirmedCount-2].price : gdx_swings[gdx_LastConfirmedCount-1].price;
         double l26 = gdx_swings[gdx_LastConfirmedCount-2].isHigh ? gdx_swings[gdx_LastConfirmedCount-1].price : gdx_swings[gdx_LastConfirmedCount-2].price;
         double rng26 = h26 - l26;
         if(rng26 > 0)
         {
            double fibN1272_p26 = l26 - rng26 * 0.272;
            if(_bid <= fibN1272_p26)
            {
               if(_curBarFG != g_blk_fibgate_sell_bar) {
                  Print("[FibGate] SELL blocked P26 — Bid:", _bid, " <= -127.2%:", fibN1272_p26);
                  g_blk_fibgate_sell_bar = _curBarFG;
               }
               return false;
            }
         }
      }
      // P50
      if(gdx_LastConfirmedCount2 >= 2)
      {
         double h50 = gdx_swings2[gdx_LastConfirmedCount2-2].isHigh ? gdx_swings2[gdx_LastConfirmedCount2-2].price : gdx_swings2[gdx_LastConfirmedCount2-1].price;
         double l50 = gdx_swings2[gdx_LastConfirmedCount2-2].isHigh ? gdx_swings2[gdx_LastConfirmedCount2-1].price : gdx_swings2[gdx_LastConfirmedCount2-2].price;
         double rng50 = h50 - l50;
         if(rng50 > 0)
         {
            double fibN1272_p50 = l50 - rng50 * 0.272;
            if(_bid <= fibN1272_p50)
            {
               if(_curBarFG != g_blk_fibgate_sell_bar) {
                  Print("[FibGate] SELL blocked P50 — Bid:", _bid, " <= -127.2%:", fibN1272_p50);
                  g_blk_fibgate_sell_bar = _curBarFG;
               }
               return false;
            }
         }
      }
   }
   // ───────────────────────────────────────────────────────────────

   // ── [NEW] Candle Filter for SELL ───────────────────────────────
   double open0  = iOpen(_Symbol, PERIOD_CURRENT, 0);
   double open1  = iOpen(_Symbol, PERIOD_CURRENT, 1);
   double close1 = iClose(_Symbol, PERIOD_CURRENT, 1);

   bool prevIsRed   = (close1 < open1);
   bool currIsGreen = (currentTick.bid > open0);

   if(prevIsRed && currIsGreen)
   {
      static datetime lastSellLog = 0;
      if(TimeCurrent() - lastSellLog > 60) {
         Print("[CandleFilter] SELL blocked — Prev:RED, Curr:GREEN");
         lastSellLog = TimeCurrent();
      }
      return false;
   }
   // ───────────────────────────────────────────────────────────────

   // ── V.11: Daily Loss Limit ───────────────────────────────────────
   if(!CheckDailyLossLimit()) return false;

   // ── Solution B: Same-SL Cooldown ──────────────────────────────────
   // V.11 Fix: reset counter เมื่อ cooldown หมดแล้ว (ไม่ให้สะสมไม่สิ้นสุด)
   if(InpSameSL_Enable && g_sellSameSLCooldownEnd > 0 && TimeCurrent() >= g_sellSameSLCooldownEnd)
   {
      g_sellSameSLCount       = 0;
      g_lastSellSL            = 0;
      g_sellSameSLCooldownEnd = 0;
      Print("[SameSL] SELL cooldown expired → counter reset");
   }
   if(InpSameSL_Enable && TimeCurrent() < g_sellSameSLCooldownEnd)
   {
      int minsLeft = (int)((g_sellSameSLCooldownEnd - TimeCurrent()) / 60);
      Print(StringFormat("[SameSL] SELL blocked — cooldown %d min remaining (SL=%.2f used %d×)",
            minsLeft, g_lastSellSL, g_sellSameSLCount));
      return false;
   }

   // ── V.11: Wick Ratio Filter (Stop Hunt Rejection) ────────────────
   if(!CheckWickFilter(false)) return false;

   // ── LiqZone Filter: ตรวจ BUY STOPS Zone ใต้ Entry ────────
   if(CheckLiqZoneFilter(true, currentTick.bid))
      return false;
   double bid = currentTick.bid;
   datetime entryTime = iTime(_Symbol, PERIOD_CURRENT, 0);

   slPrice = 0; tpPrice = 0;
   DrawTradeHighLowSetup(entryTime, -1, bid, InpRR, InpLotSize, true);  // V.19: isCalcOnly — วาดเฉพาะหลัง Order จริง

   if(slPrice == 0 || slPrice <= bid) {
      double atr[]; ArraySetAsSeries(atr, true);
      if(CopyBuffer(g_atr_handle, 0, 0, 1, atr) > 0 && atr[0] > 0) {
         slPrice = bid + atr[0] * InpATRMulti;
         tpPrice = bid - atr[0] * InpATRMulti * InpRR;
      } else {
         slPrice = bid + InpRR_SlOffset * _Point;
         tpPrice = bid - InpRR_SlOffset * _Point * InpRR;
      }
   }
   slPrice = NormalizeDouble(slPrice, _Digits);
   tpPrice = NormalizeDouble(tpPrice, _Digits);

   // ── Swing SL: ใช้ Swing High ล่าสุดแทน ATR ─────────────────
   if(InpUseSwingSL && !g_trendmode_active)   // V.19: Trend Mode ใช้ ATR SL แทน
   {
      double swingSL = GetSwingSL_Sell(bid);
      if(swingSL > 0 && swingSL > bid)
      {
         slPrice = swingSL;
         Print(StringFormat("[SwingSL] SELL SL = %.5f (Swing High)", slPrice));
         // V.20 GroupB: Session SL buffer มาจาก g_sp.slBufferPts
         // (London=+5pts default, session อื่น=0 → ไม่ปรับ)
         if(g_sp.slBufferPts > 0)
         {
            slPrice += g_sp.slBufferPts;
            slPrice  = NormalizeDouble(slPrice, _Digits);
            Print(StringFormat("[SwingSL] SELL session buffer +%.2f → SL=%.5f", g_sp.slBufferPts, slPrice));
         }
      }
   }

   // ── V.19: Trend Mode SL override — ใช้ ATR(D1)×InpTrend_SLMulti ──
   if(g_trendmode_active)
   {
      double atrD1[]; ArraySetAsSeries(atrD1, true);
      if(g_atr_d1_handle != INVALID_HANDLE &&
         CopyBuffer(g_atr_d1_handle, 0, 1, 1, atrD1) > 0 && atrD1[0] > 0)
      {
         slPrice = NormalizeDouble(bid + atrD1[0] * InpTrend_SLMulti, _Digits);
         { datetime _bar = iTime(_Symbol,PERIOD_M1,0); if(g_blk_trendmode_sell_bar != _bar) { g_blk_trendmode_sell_bar = _bar; Print(StringFormat("[TrendMode] SELL SL = ATR×%.1f → %.5f (atr=%.2f)", InpTrend_SLMulti, slPrice, atrD1[0])); } }
      }
   }

   // ── Liquidity-Aware SL: เลื่อน SL ให้พ้น ATR Zone ก่อนเปิด ──
   if(InpLiqSL_Enable)
   {
      slPrice = AdjustSLForLiquidity(slPrice, bid, false);
      if(slPrice <= 0) {
         datetime _bar = iTime(_Symbol,PERIOD_M1,0);
         if(g_blk_liqsl_sell_bar != _bar) { g_blk_liqsl_sell_bar = _bar; Print("[OpenSell] SL too wide after LiqAdj, skip trade"); }
         return false;
      }
   }

   // ── TP: เลือก Conservative TP จาก Swing/Fib/Session/RR ────
   if(InpVP_FilterEnable && InpVP_UseTPTarget)
      tpPrice = GetVPTargetTP(false, bid, MathAbs(slPrice - bid));
   else if(InpUseSwingTP || InpTP_UseFib || InpTP_UseSession)
      tpPrice = SelectBestTP_Sell(bid, slPrice);
   else
      tpPrice = NormalizeDouble(bid - MathAbs(slPrice - bid) * InpRR, _Digits);

   // ── V.19: Trend Mode TP = ATR M50 level (PDATr) ──────────────────
   if(g_trendmode_active)
   {
      double atr  = GDEA_GetATRDaily(InpATRLevelsPeriod);
      double base = GetATRBaseline();
      if(atr > 0 && base > 0)
      {
         double tp50 = NormalizeDouble(base - atr * 0.50, _Digits);
         if(tp50 < bid) {   // valid SELL target (below entry)
            tpPrice = tp50;
            Print(StringFormat("[TrendMode] SELL TP = ATR M50 → %.5f (base=%.2f atr=%.2f)", tpPrice, base, atr));
         }
         // เก็บ M25 สำหรับ partial close
         g_sell_atr_tp25   = NormalizeDouble(base - atr * 0.25, _Digits);
         g_sell_partial_done = false;
      }
   }
   else { g_sell_atr_tp25 = 0; }

   // ── Guard MinRR: ถ้า RR ไม่ถึงขั้นต่ำ → ไม่เปิด ───────────
   double actualRR = MathAbs(bid - tpPrice) / MathMax(MathAbs(slPrice - bid), _Point);
   if(actualRR < InpMinRR - 0.001)   // [V.21] float precision fix: 1.4999...== 1.50 ผ่านได้
   {
      Print(StringFormat("[OpenSell] RR=%.2f < MinRR=%.2f → skip", actualRR, InpMinRR));
      return false;
   }

   double lots = InpLotSize;
   if(!calculateLots(MathAbs(slPrice - bid), lots)) return false;
   // V.20 GroupD: NYPM Half Lot — ลด lot 50% ใน NY Afternoon (fatigue protection)
   if(g_sp.lotMultiplier < 1.0)
   {
      lots = NormalizeDouble(lots * g_sp.lotMultiplier, 2);
      lots = MathMax(lots, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN));
      Print(StringFormat("[V.20-D] SELL NYPM HalfLot → lots=%.2f (×%.1f)", lots, g_sp.lotMultiplier));
   }

   if(!Trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, lots, bid, slPrice, tpPrice,
         "GDEA_SELL Magic:" + IntegerToString(InpMagicnumber))) {
      Print("SELL Error: ", GetLastError());
      return false;
   }
   LogTradeOpen(false, bid, slPrice, tpPrice, lots);  // V.15: enhanced open log
   NotifyOrderOpen(false, bid, slPrice, tpPrice, lots);
   DrawTradeBox(entryTime, bid, slPrice, tpPrice, lots, false);

   // ── Solution B V.3: บันทึก SL ล่าสุดของ SELL ────────────────
   // counter จะนับเฉพาะเมื่อ Trade ชนะ ใน OnTradeTransaction
   if(InpSameSL_Enable) g_lastSellSL = slPrice;

   return true;
}

//+------------------------------------------------------------------+
//| DrawTradeBox — Green TP / Red SL + USD label                    |
//+------------------------------------------------------------------+
void DrawTradeBox(datetime entryTime, double entry, double sl, double tp,
                  double lots, bool isBuy)
{
   if(!InpRR_DrawEnable) return;

   // ── กว้างแค่ 1 แท่งเทียน ──────────────────────────────────
   datetime endTime = entryTime + PeriodSeconds(PERIOD_CURRENT);
   string   base    = InpRR_ObjPrefix + IntegerToString(entryTime);

   double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickSize == 0) tickSize = _Point;

   // คำนวณ USD ได้/เสีย (ไม่มีทศนิยม)
   double profitUSD = (MathAbs(tp - entry) / tickSize) * tickVal * lots;
   double lossUSD   = (MathAbs(sl - entry) / tickSize) * tickVal * lots;
   string tpUSD     = IntegerToString((int)MathRound(profitUSD));
   string slUSD     = IntegerToString((int)MathRound(lossUSD));

   // ── TP box (green) ──
   string tpObj = base + "_TP";
   if(ObjectFind(0,tpObj)<0)
      ObjectCreate(0, tpObj, OBJ_RECTANGLE, 0, entryTime, entry, endTime, tp);
   ObjectSetInteger(0,tpObj,OBJPROP_COLOR,  InpRR_TPColor);
   ObjectSetInteger(0,tpObj,OBJPROP_FILL,   true);
   ObjectSetInteger(0,tpObj,OBJPROP_BACK,   true);
   ObjectSetInteger(0,tpObj,OBJPROP_STYLE,  STYLE_SOLID);
   ObjectSetInteger(0,tpObj,OBJPROP_WIDTH,  1);
   ObjectSetDouble (0,tpObj,OBJPROP_PRICE,0,entry);
   ObjectSetDouble (0,tpObj,OBJPROP_PRICE,1,tp);
   ObjectSetInteger(0,tpObj,OBJPROP_TIME, 0,entryTime);
   ObjectSetInteger(0,tpObj,OBJPROP_TIME, 1,endTime);
   ObjectSetInteger(0,tpObj,OBJPROP_SELECTABLE,false);

   // ── SL box (red) ──
   string slObj = base + "_SL";
   if(ObjectFind(0,slObj)<0)
      ObjectCreate(0, slObj, OBJ_RECTANGLE, 0, entryTime, entry, endTime, sl);
   ObjectSetInteger(0,slObj,OBJPROP_COLOR,  InpRR_SLColor);
   ObjectSetInteger(0,slObj,OBJPROP_FILL,   true);
   ObjectSetInteger(0,slObj,OBJPROP_BACK,   true);
   ObjectSetInteger(0,slObj,OBJPROP_STYLE,  STYLE_SOLID);
   ObjectSetInteger(0,slObj,OBJPROP_WIDTH,  1);
   ObjectSetDouble (0,slObj,OBJPROP_PRICE,0,entry);
   ObjectSetDouble (0,slObj,OBJPROP_PRICE,1,sl);
   ObjectSetInteger(0,slObj,OBJPROP_TIME, 0,entryTime);
   ObjectSetInteger(0,slObj,OBJPROP_TIME, 1,endTime);
   ObjectSetInteger(0,slObj,OBJPROP_SELECTABLE,false);

   // ── Entry dotted line ──
   string entLine = base + "_Ent";
   if(ObjectFind(0,entLine)<0)
      ObjectCreate(0, entLine, OBJ_TREND, 0, entryTime, entry, endTime, entry);
   ObjectSetInteger(0,entLine,OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0,entLine,OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0,entLine,OBJPROP_RAY_RIGHT, false);
   ObjectSetDouble (0,entLine,OBJPROP_PRICE,0,entry);
   ObjectSetDouble (0,entLine,OBJPROP_PRICE,1,entry);
   ObjectSetInteger(0,entLine,OBJPROP_TIME, 0,entryTime);
   ObjectSetInteger(0,entLine,OBJPROP_TIME, 1,endTime);

   // ── Labels: USD อย่างเดียว ─────────────────────────────────
   if(InpRR_ShowText)
   {
      color tpTxtClr = InpRR_TPColor;
      color slTxtClr = InpRR_SLColor;

      // ── TP USD ────────────────────────────────────────────────
      // BUY:  TP อยู่บน → Label อยู่เหนือกล่อง TP → ANCHOR_LEFT_LOWER
      // SELL: TP อยู่ล่าง → Label อยู่ใต้กล่อง TP → ANCHOR_LEFT_UPPER
      string tpLbl   = base + "_TP_USD";
      double tpEdge  = isBuy ? tp : tp;   // ขอบกล่อง TP (ทั้งคู่ใช้ tp)
      ENUM_ANCHOR_POINT tpAnchor = isBuy ? ANCHOR_LEFT_LOWER : ANCHOR_LEFT_UPPER;

      if(ObjectFind(0, tpLbl) < 0)
         ObjectCreate(0, tpLbl, OBJ_TEXT, 0, entryTime, tpEdge);
      ObjectSetInteger(0, tpLbl, OBJPROP_TIME,       entryTime);
      ObjectSetDouble (0, tpLbl, OBJPROP_PRICE,      tpEdge);
      ObjectSetString (0, tpLbl, OBJPROP_TEXT,       tpUSD);
      ObjectSetInteger(0, tpLbl, OBJPROP_COLOR,      tpTxtClr);
      ObjectSetInteger(0, tpLbl, OBJPROP_FONTSIZE,   9);
      ObjectSetString (0, tpLbl, OBJPROP_FONT,       "Arial Bold");
      ObjectSetInteger(0, tpLbl, OBJPROP_ANCHOR,     tpAnchor);
      ObjectSetInteger(0, tpLbl, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, tpLbl, OBJPROP_BACK,       false);

      // ── SL USD ────────────────────────────────────────────────
      // BUY:  SL อยู่ล่าง → Label อยู่ใต้กล่อง SL → ANCHOR_LEFT_UPPER
      // SELL: SL อยู่บน → Label อยู่เหนือกล่อง SL → ANCHOR_LEFT_LOWER
      string slLbl   = base + "_SL_USD";
      double slEdge  = sl;   // ขอบกล่อง SL (ทั้งคู่ใช้ sl)
      ENUM_ANCHOR_POINT slAnchor = isBuy ? ANCHOR_LEFT_UPPER : ANCHOR_LEFT_LOWER;

      if(ObjectFind(0, slLbl) < 0)
         ObjectCreate(0, slLbl, OBJ_TEXT, 0, entryTime, slEdge);
      ObjectSetInteger(0, slLbl, OBJPROP_TIME,       entryTime);
      ObjectSetDouble (0, slLbl, OBJPROP_PRICE,      slEdge);
      ObjectSetString (0, slLbl, OBJPROP_TEXT,       slUSD);
      ObjectSetInteger(0, slLbl, OBJPROP_COLOR,      slTxtClr);
      ObjectSetInteger(0, slLbl, OBJPROP_FONTSIZE,   9);
      ObjectSetString (0, slLbl, OBJPROP_FONT,       "Arial Bold");
      ObjectSetInteger(0, slLbl, OBJPROP_ANCHOR,     slAnchor);
      ObjectSetInteger(0, slLbl, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, slLbl, OBJPROP_BACK,       false);
   }
   ChartRedraw();
}

// DrawHullLine replaced by GdxUpdateHull + GdxDrawHullLine

//+------------------------------------------------------------------+
//| checkTradeTime                                                   |
//+------------------------------------------------------------------+
bool checkTradeTime(string startTime, string endTime)
{
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   string cur = StringFormat("%02d:%02d", dt.hour, dt.min);
   if(startTime <= endTime) return (cur >= startTime && cur <= endTime);
   return (cur >= startTime || cur <= endTime);
}


// ── GetAlphaColor ──
color GetAlphaColor(color clr, int alpha)
{
   int a = (int)(255 * (100 - alpha) / 100.0);
   return (color)((a << 24) | clr);
}

// ── CreateRRLabel ──
void CreateRRLabel(string name, datetime t, double price, string text, color clr, ENUM_ANCHOR_POINT anchor)
{
   if(ObjectFind(0, name) < 0) {
      ObjectCreate(0, name, OBJ_TEXT, 0, t, price);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
      ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
   }
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, anchor);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetDouble(0, name, OBJPROP_PRICE, price);
   ObjectSetInteger(0, name, OBJPROP_TIME, t);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
}

// ── CreateStackedLabel ──
void CreateStackedLabel(string name, datetime t, double price, string text, int size, color clr, int direction)
{
   if(ObjectFind(0, name) < 0) ObjectCreate(0, name, OBJ_TEXT, 0, t, price);

   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetDouble(0, name, OBJPROP_ANGLE, 0.0);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);

   if(direction == 1) ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
   else ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);

   ObjectSetDouble(0, name, OBJPROP_PRICE, 0, price);
   ObjectSetInteger(0, name, OBJPROP_TIME, 0, t);
}

// ── GetLatestSwingHigh ──
double GetLatestSwingHigh(string sym, ENUM_TIMEFRAMES tf, int startIdx, int maxLookback)
{

   for(int i = startIdx + 1; i <= startIdx + maxLookback; i++)
   {
      double hCurrent = iHigh(sym, tf, i);
      double hPrev    = iHigh(sym, tf, i+1);
      double hNext    = iHigh(sym, tf, i-1);

      if(hCurrent >= hPrev && hCurrent > hNext)
         return hCurrent;
   }

   int highestIdx = iHighest(sym, tf, MODE_HIGH, maxLookback, startIdx + 1);
   if(highestIdx < 0) return iHigh(sym, tf, startIdx);
   return iHigh(sym, tf, highestIdx);
}

// ── GetLatestSwingLow ──
double GetLatestSwingLow(string sym, ENUM_TIMEFRAMES tf, int startIdx, int maxLookback)
{

   for(int i = startIdx + 1; i <= startIdx + maxLookback; i++)
   {
      double lCurrent = iLow(sym, tf, i);
      double lPrev    = iLow(sym, tf, i+1);
      double lNext    = iLow(sym, tf, i-1);

      if(lCurrent <= lPrev && lCurrent < lNext)
         return lCurrent;
   }

   int lowestIdx = iLowest(sym, tf, MODE_LOW, maxLookback, startIdx + 1);
   if(lowestIdx < 0) return iLow(sym, tf, startIdx);
   return iLow(sym, tf, lowestIdx);
}

// ── GetDailyData ──
void GetDailyData(string sym, double &outATR, double &outPrevClose)
{
   outATR = 0; outPrevClose = 0;

   // Phase1Fix: ใช้ global g_atr_d1_handle แทนการเปิด handle ใหม่ทุกครั้ง
   // ป้องกัน MT5 handle limit (~512) หมดเมื่อ EA run นานหลายวัน
   if(g_atr_d1_handle != INVALID_HANDLE) {
      double buf[]; ArraySetAsSeries(buf, true);
      if(CopyBuffer(g_atr_d1_handle, 0, 1, 1, buf) > 0) outATR = buf[0];
   }

   double closeBuf[];
   if(CopyClose(sym, PERIOD_D1, 1, 1, closeBuf) > 0) outPrevClose = closeBuf[0];
}

// ── GetMaxWickLength ──
double GetMaxWickLength(string sym, ENUM_TIMEFRAMES tf, int startBar, int count, int signal)
{
   double maxWick = 0;

   double highBuf[], lowBuf[], openBuf[], closeBuf[];
   if(CopyHigh(sym, tf, startBar, count, highBuf) == count &&
      CopyLow(sym, tf, startBar, count, lowBuf) == count &&
      CopyOpen(sym, tf, startBar, count, openBuf) == count &&
      CopyClose(sym, tf, startBar, count, closeBuf) == count)
   {
      for(int i=0; i<count; i++) {
         double bodyTop = MathMax(openBuf[i], closeBuf[i]);
         double bodyBot = MathMin(openBuf[i], closeBuf[i]);
         double wick = 0;

         if(signal == 1) {
            wick = bodyBot - lowBuf[i];
         } else {
            wick = highBuf[i] - bodyTop;
         }

         if(wick > maxWick) maxWick = wick;
      }
   }
   return maxWick;
}

// ── FindSupportShield ──
double FindSupportShield(string sym, double belowPrice, double dClose, double dATR)
{
   double bestShield = 0;
   double minDiff = DBL_MAX;

   double levels[6];
   levels[0] = dClose;
   levels[1] = dClose - (dATR * 0.25);
   levels[2] = dClose - (dATR * 0.50);
   levels[3] = dClose - (dATR * 0.75);
   levels[4] = dClose - (dATR * 1.00);
   levels[5] = dClose - (dATR * 1.50);

   for(int i=0; i<6; i++) {
      if(levels[i] < belowPrice) {
         double diff = belowPrice - levels[i];
         if(diff < minDiff) {
            minDiff = diff;
            bestShield = levels[i];
         }
      }
   }

   double roundNum = MathFloor(belowPrice / 0.50) * 0.50;
   if(roundNum < belowPrice && (belowPrice - roundNum) < minDiff) {
       bestShield = roundNum;
   }

   return bestShield;
}

// ── FindResistShield ──
double FindResistShield(string sym, double abovePrice, double dClose, double dATR)
{
   double bestShield = 0;
   double minDiff = DBL_MAX;

   double levels[6];
   levels[0] = dClose;
   levels[1] = dClose + (dATR * 0.25);
   levels[2] = dClose + (dATR * 0.50);
   levels[3] = dClose + (dATR * 0.75);
   levels[4] = dClose + (dATR * 1.00);
   levels[5] = dClose + (dATR * 1.50);

   for(int i=0; i<6; i++) {
      if(levels[i] > abovePrice) {
         double diff = levels[i] - abovePrice;
         if(diff < minDiff) {
            minDiff = diff;
            bestShield = levels[i];
         }
      }
   }

   double roundNum = MathCeil(abovePrice / 0.50) * 0.50;
   if(roundNum > abovePrice && (roundNum - abovePrice) < minDiff) {
       bestShield = roundNum;
   }

   return bestShield;
}

// ── FindNearestResistObstacle ──
double FindNearestResistObstacle(double entry, double rawTP, double dClose, double dATR)
{

   double levels[6];
   levels[0] = dClose;
   levels[1] = dClose + (dATR * 0.25);
   levels[2] = dClose + (dATR * 0.50);
   levels[3] = dClose + (dATR * 0.75);
   levels[4] = dClose + (dATR * 1.00);
   levels[5] = dClose + (dATR * 1.50);

   double nearest = 0;
   double minDist = DBL_MAX;

   for(int i=0; i<6; i++) {
      if(levels[i] > entry && levels[i] < rawTP) {

         return levels[i];
      }
   }
   return 0;
}

// ── FindNearestSupportObstacle ──
double FindNearestSupportObstacle(double entry, double rawTP, double dClose, double dATR)
{
   double levels[6];
   levels[0] = dClose;
   levels[1] = dClose - (dATR * 0.25);
   levels[2] = dClose - (dATR * 0.50);
   levels[3] = dClose - (dATR * 0.75);
   levels[4] = dClose - (dATR * 1.00);
   levels[5] = dClose - (dATR * 1.50);

   for(int i=0; i<6; i++) {
      if(levels[i] < entry && levels[i] > rawTP) {
         return levels[i];
      }
   }
   return 0;
}

// ── CheckClusterAdjustment ──
double CheckClusterAdjustment(string sym, double inputSL, int signal, double checkDist)
{

   double adjustedSL = inputSL;
   double scanHigh[], scanLow[];
   int bars = 20;

   ArraySetAsSeries(scanHigh, true);
   ArraySetAsSeries(scanLow, true);

   if(CopyHigh(sym, PERIOD_M15, 0, bars, scanHigh) == bars &&
      CopyLow(sym, PERIOD_M15, 0, bars, scanLow) == bars)
   {
      for(int i=0; i<bars; i++) {
         if(signal == 1) {

            if(MathAbs(scanLow[i] - inputSL) < checkDist) {

               double newSL = scanLow[i] - (checkDist * 0.5);

               if(newSL < adjustedSL) adjustedSL = newSL;
            }
         } else {

            if(MathAbs(scanHigh[i] - inputSL) < checkDist) {

               double newSL = scanHigh[i] + (checkDist * 0.5);

               if(newSL > adjustedSL) adjustedSL = newSL;
            }
         }
      }
   }
   return adjustedSL;
}

// ── GetHighOnPeriodTF ──
double GetHighOnPeriodTF(string sym, ENUM_TIMEFRAMES tf, datetime t1, datetime t2) {
   double buf[];
   if(CopyHigh(sym, tf, t1, t2, buf) > 0) return buf[ArrayMaximum(buf)];
   return 0;
}

// ── GetLowOnPeriodTF ──
double GetLowOnPeriodTF(string sym, ENUM_TIMEFRAMES tf, datetime t1, datetime t2) {
   double buf[];
   if(CopyLow(sym, tf, t1, t2, buf) > 0) return buf[ArrayMinimum(buf)];
   return 0;
}

// ── GetHighOnPeriod ──
double GetHighOnPeriod(string sym, datetime t1, datetime t2) {
   return GetHighOnPeriodTF(sym, PERIOD_M1, t1, t2);
}

// ── GetLowOnPeriod ──
double GetLowOnPeriod(string sym, datetime t1, datetime t2) {
   return GetLowOnPeriodTF(sym, PERIOD_M1, t1, t2);
}

// ── GetTimeWithHour ──
datetime GetTimeWithHour(datetime refTime, int hour) {
   MqlDateTime dt; TimeToStruct(refTime, dt);
   dt.hour = hour; dt.min = 0; dt.sec = 0;
   return StructToTime(dt);
}


// ── GetSessionFuelData ──
void GetSessionFuelData(string sym, datetime time, string &outName, double &outAvgRange, double &outUsedRange)
{
   MqlDateTime dt;
   TimeToStruct(time, dt);
   int hour = dt.hour;

   int startH = 0, endH = 0;

   // กำหนด session จาก input hours (server time)
   if(hour >= InpAsiaStartHr && hour < InpAsiaEndHr) {
      outName = "Asia";   startH = InpAsiaStartHr;   endH = InpAsiaEndHr;
   }
   else if(hour >= InpLondonStartHr && hour < InpLondonEndHr) {
      outName = "London"; startH = InpLondonStartHr; endH = InpLondonEndHr;
   }
   else if(hour >= InpNYStartHr && hour < InpNYEndHr) {
      outName = "NY";     startH = InpNYStartHr;     endH = InpNYEndHr;
   }
   else {
      // นอก session หลัก — fallback Asia
      outName = "Asia";   startH = InpAsiaStartHr;   endH = InpAsiaEndHr;
   }

   double pointVal  = SymbolInfoDouble(sym, SYMBOL_POINT);
   int    sessBars  = (endH - startH);   // จำนวน H1 bars ต่อ session (เช่น London=5)

   // ── คำนวณ avgRange จาก 5 วันย้อนหลัง โดยใช้ H1 bars ──────────
   //    H1 ต้องการแค่ sessBars × 5 = ไม่เกิน 40 bars  << 1000 limit
   double sumRange = 0;
   int    count    = 0;
   int    daysBack = 1;

   while(count < 5 && daysBack < 20)
   {
      datetime dTime = time - (daysBack * 86400);

      MqlDateTime checkDt;
      TimeToStruct(dTime, checkDt);

      // ข้ามวันหยุด
      if(checkDt.day_of_week == 0 || checkDt.day_of_week == 6) {
         daysBack++;
         continue;
      }

      datetime t1 = GetTimeWithHour(dTime, startH);
      datetime t2 = GetTimeWithHour(dTime, endH);

      // ใช้ H1 แทน M1 — ประหยัด bars 60 เท่า
      double h = GetHighOnPeriodTF(sym, PERIOD_H1, t1, t2);
      double l = GetLowOnPeriodTF(sym, PERIOD_H1, t1, t2);

      if(h > 0 && l > 0 && h > l) {
         sumRange += (h - l);
         count++;
      }

      daysBack++;
   }

   // fallback: ถ้าหาข้อมูลไม่ได้เลย ใช้ D1 ATR เป็น base แทน hardcode 500 pts
   // Phase1Fix: ใช้ global g_atr_d1_handle แทน iATR() ชั่วคราว
   if(count == 0) {
      double atrFallback[];
      if(g_atr_d1_handle != INVALID_HANDLE && CopyBuffer(g_atr_d1_handle, 0, 1, 1, atrFallback) > 0)
         outAvgRange = atrFallback[0] * 0.35;   // ~35% ของ Daily ATR เป็น session range
      else
         outAvgRange = 1500 * pointVal;           // fallback สุดท้าย Gold ~1500 pts
   }
   else {
      outAvgRange = sumRange / count;
   }

   // ── คำนวณ usedRange ของ session วันนี้ ────────────────────────
   datetime todayStart = GetTimeWithHour(time, startH);

   // Guard: ถ้า session ยังไม่เริ่ม (เช่น time < todayStart) → usedRange = 0
   if(time < todayStart) {
      outUsedRange = 0;
   }
   else {
      // ใช้ M1 สำหรับ session วันนี้เท่านั้น — bars ไม่เกิน endH-startH×60 bars
      // ภายใน 1000 bars limit: London 5h=300 bars, NY 8h=480 bars, Asia 8h=480 bars ✓
      double currH = GetHighOnPeriodTF(sym, PERIOD_M1, todayStart, time);
      double currL = GetLowOnPeriodTF(sym, PERIOD_M1, todayStart, time);

      if(currH > 0 && currL > 0 && currH > currL)
         outUsedRange = currH - currL;
      else
         outUsedRange = 0;
   }

   // Cap: usedRange ห้ามเกิน avgRange (ป้องกัน Fuel Left ติดลบ)
   if(outUsedRange > outAvgRange && outAvgRange > 0)
      outUsedRange = outAvgRange;

   // ── NY special: ถ้า daily range วิ่งเกิน ATR แล้ว ลด avgRange ลง ──
   if(outName == "NY")
   {
      datetime dayStart = GetTimeWithHour(time, 0);
      double dayH = GetHighOnPeriodTF(sym, PERIOD_H1, dayStart, time);
      double dayL = GetLowOnPeriodTF(sym, PERIOD_H1, dayStart, time);
      double dailyUsed = (dayH > 0 && dayL > 0) ? (dayH - dayL) : 0;

      double dailyATR = 0;
      double atrBuf[];
      int atrIndex = 1;
      datetime tIdx1 = iTime(sym, PERIOD_D1, 1);
      MqlDateTime dt1; TimeToStruct(tIdx1, dt1);
      if(dt1.day_of_week == 0) atrIndex = 2;

      // Phase1Fix: ใช้ global g_atr_d1_handle แทน iATR() ชั่วคราว
      if(g_atr_d1_handle != INVALID_HANDLE && CopyBuffer(g_atr_d1_handle, 0, atrIndex, 1, atrBuf) > 0)
         dailyATR = atrBuf[0];

      if(dailyATR == 0) dailyATR = outAvgRange * 2.0;

      if(dailyATR > 0 && dailyUsed > dailyATR)
         outAvgRange = outAvgRange * 0.5;
   }
}

// ── CountOpenPositions ──
bool CountOpenPositions(int &cntBuy1, int &cntSell1)
  {

   cntBuy1 = 0;
   cntSell1 = 0;
   totalLotBuy = 0;
   totalLotSell = 0;
   totalBuy = 0;
   totalSell = 0;
   int total = PositionsTotal();
   for(int i = total - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0)
        {
         Print("Failed to get position ticket");
         return false;
        }
      if(!PositionSelectByTicket(ticket))
        {
         Print("Failed to select postion");
         return false;
        }
      long magic;
      if(!PositionGetInteger(POSITION_MAGIC, magic))
        {
         Print("Failed to select postion Magicnumber");
         return false;
        }
      if(magic == InpMagicnumber)
        {
         long type;
         if(!PositionGetInteger(POSITION_TYPE, type))
           {
            Print("Failed to get postion type");
            return false;
           }

         double profit;
         if(!PositionGetDouble(POSITION_PROFIT, profit))
           {
            Print("Failed to get position profit");
            return false;
           }

         if(type == POSITION_TYPE_BUY)
           {
            cntBuy1++;
            totalLotBuy = totalLotBuy + InpLotSize;
            totalBuy = totalBuy + profit;
           }
         if(type == POSITION_TYPE_SELL)
           {
            cntSell1++;
            totalLotSell = totalLotSell + InpLotSize;
            totalSell = totalSell + profit;
           }
        }
     }
   return true;
  }

// ── NormalizePrice ──
bool NormalizePrice(double &price)
  {

   double tickSize = 0;

   if(!SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE, tickSize))
     {
      Print("Failed to get tick size");
      return false;
     }
   price = NormalizeDouble(MathRound(price / tickSize) * tickSize, _Digits);

   return true;
  }

// ── calculateLots ──
bool calculateLots(double slDistance, double &lots)
  {

   lots = 0.0;
   
   // [แก้ไขข้อ 1] ป้องกัน slDistance เป็น 0 หรือติดลบ (ป้องกัน Error: Zero Divide)
   slDistance = MathMax(slDistance, _Point);

   if(InpLotMode == LOT_MODE_FIXED)
     {
      lots = InpLotSize;
     }
   else
     {
      double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      double VolumeStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

      // ดักป้องกันเพิ่มเติม กรณีดึงค่า Tick Size จาก Broker ไม่ได้ (ให้มีค่าขั้นต่ำ)
      if(tickSize <= 0) tickSize = _Point;

      double riskMoney = InpLotMode == LOT_MODE_MONEY ? InpLotSize : AccountInfoDouble(ACCOUNT_EQUITY) * InpLotSize * 0.01;
      double moneyVolumeStep = (slDistance / tickSize) * tickValue * VolumeStep;

      // [แก้ไขข้อ 1] ดักการหารด้วย 0 อีกชั้น ก่อนนำไปใช้คำนวณ Lot
      if(moneyVolumeStep > 0)
        {
         lots = MathFloor(riskMoney / moneyVolumeStep) * VolumeStep;
        }
      else
        {
         lots = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN); // ถ้ามีปัญหา ให้ใช้ Lot ขั้นต่ำสุดแทน
        }
     }

   if(!CheckLots(lots))
     {
      return false;
     }

   return true;
  }

// ── CheckLots ──
bool CheckLots(double &lots)
  {

   double min = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(lots < min)
     {
      Print("Lot size will be set to the minimum allowable volume");
      lots = min;
      return true;
     }
   if(lots > max)
     {
      Print("Lot size greater than the maximum allowable volume lots:", lots, ": max:", max);
      return false;
     }
   lots = (int)MathFloor(lots / step) * step;

   return true;
  }

// ── DrawTradeHighLowSetup ──
void DrawTradeHighLowSetup(datetime entryTime, int signal, double entryPrice, double rr, double lotSize, bool isCalcOnly = false)
{
   if(!InpRR_DrawEnable && !isCalcOnly) return;

   string sym = _Symbol;
   ENUM_TIMEFRAMES tf = PERIOD_CURRENT;
   int barIndex = iBarShift(sym, tf, entryTime);
   if(barIndex < 0) return;

   slPrice = 0;
   tpPrice = 0;
   string strategyLog = "\nStruct";

   double pointVal = SymbolInfoDouble(sym, SYMBOL_POINT);
   long   digits   = SymbolInfoInteger(sym, SYMBOL_DIGITS);
   double tickValue = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_SIZE);
   if(tickSize == 0) tickSize = pointVal;

   double pCorr = (digits == 3 || digits == 5) ? 10.0 : 1.0;

   bool isGold = (StringFind(sym,"XAU") >= 0 || StringFind(sym,"GOLD") >= 0);

   double minFuelPrice   = isGold ? 2.0 : (200 * pointVal * pCorr);
   double minSafetyPrice = isGold ? 1.0 : (100 * pointVal * pCorr);
   double minBufferPrice = isGold ? 1.5 : (200 * pointVal * pCorr);

   double sessAvgRange = 0, sessUsed = 0;
   string sessName = "";
   GetSessionFuelData(sym, entryTime, sessName, sessAvgRange, sessUsed);

   double fuelRemaining = sessAvgRange - sessUsed;
   strategyLog += "|" + sessName;

   double atrVal = 0, bufferDist = 0;
   // Phase1Fix: ใช้ global g_atr_handle แทนการเปิด handle ใหม่ทุกครั้ง
   if(g_atr_handle != INVALID_HANDLE) {
      double atrBuf[]; ArraySetAsSeries(atrBuf, true);
      if(CopyBuffer(g_atr_handle, 0, barIndex + 1, 1, atrBuf) > 0) atrVal = atrBuf[0];
   }

   double volLimit = 200 * pointVal * pCorr;
   double volFactor = (atrVal > volLimit) ? 1.5 : 1.0;
   double baseBuffer = (InpUseATR_SL) ? (atrVal * InpATRMulti * volFactor) : (InpRR_SlOffset * pointVal * pCorr * volFactor);
   if(volFactor > 1.0) strategyLog += "+Vol";

   double extraUSD_Dist = (lotSize > 0 && tickValue > 0) ? (4.0 / (tickValue * lotSize)) * tickSize : 0;
   double asiaPad_Dist = (sessName == "Asia") ? (sessAvgRange * 0.10) : 0;
   double wickLen = GetMaxWickLength(sym, tf, barIndex, 3, signal);
   double wickBuffer = wickLen * 1.5;
   if(wickBuffer > 0) strategyLog += "+Wick";

   double maxPad = (asiaPad_Dist > extraUSD_Dist) ? asiaPad_Dist : extraUSD_Dist;
   if(maxPad == asiaPad_Dist && maxPad > 0) strategyLog += "+AsPad";
   else if(maxPad > 0) strategyLog += "+$4";

   bufferDist = baseBuffer + maxPad + wickBuffer;
   if(bufferDist < minBufferPrice) bufferDist = minBufferPrice;

   double minSafeDistance = (atrVal > 0) ? (atrVal * 0.8) : minBufferPrice;
   double safetyPad = (atrVal > 0) ? (atrVal * 0.2) : (minSafetyPrice * 0.5);

   double dayATR = 0, dayPrevClose = 0;
   GetDailyData(sym, dayATR, dayPrevClose);

   double rawSL = 0;

   if(signal == 1) {
      double swingM5  = GetLatestSwingLow(sym, tf, barIndex, InpRR_LookbackSwing);
      double swingM15 = GetLatestSwingLow(sym, PERIOD_M15, 0, InpRR_LookbackSwing);

      double baseSwing = swingM5;
      double distM15 = MathAbs(entryPrice - swingM15);
      double limitDist = MathMax(bufferDist * 3, 10.0 * 100 * pointVal * pCorr);

      if(swingM15 > 0 && swingM15 != EMPTY_VALUE && swingM15 < entryPrice && distM15 < limitDist) {
         if(swingM5 > entryPrice - minSafeDistance || swingM15 < swingM5) {
             baseSwing = swingM15; strategyLog += "|HTF";
         }
      }

      if(baseSwing <= 0 || baseSwing == EMPTY_VALUE) {
         double lowBuf[]; CopyLow(sym, tf, barIndex, 20, lowBuf);
         baseSwing = lowBuf[ArrayMinimum(lowBuf)];
      }

      double baseSL = baseSwing - bufferDist;
      double shieldPrice = FindSupportShield(sym, baseSL, dayPrevClose, dayATR);

      double preSL = baseSL;
      if(shieldPrice > 0 && (baseSL - shieldPrice) < bufferDist * 2) {
         preSL = shieldPrice - safetyPad; strategyLog += "|Shield";
      }

      rawSL = CheckClusterAdjustment(sym, preSL, signal, 200 * pointVal * pCorr);
      if(rawSL != preSL) strategyLog += "|Clust";

      if((entryPrice - rawSL) < minSafeDistance) rawSL = entryPrice - minSafeDistance;
   }
   else if(signal == -1) {
      double swingM5  = GetLatestSwingHigh(sym, tf, barIndex, InpRR_LookbackSwing);
      double swingM15 = GetLatestSwingHigh(sym, PERIOD_M15, 0, InpRR_LookbackSwing);

      double baseSwing = swingM5;
      double distM15 = MathAbs(swingM15 - entryPrice);
      double limitDist = MathMax(bufferDist * 3, 10.0 * 100 * pointVal * pCorr);

      if(swingM15 > 0 && swingM15 != EMPTY_VALUE && swingM15 > entryPrice && distM15 < limitDist) {
         if(swingM5 < entryPrice + minSafeDistance || swingM15 > swingM5) {
             baseSwing = swingM15; strategyLog += "|HTF";
         }
      }

      if(baseSwing <= 0 || baseSwing == EMPTY_VALUE) {
         double highBuf[]; CopyHigh(sym, tf, barIndex, 20, highBuf);
         baseSwing = highBuf[ArrayMaximum(highBuf)];
      }

      double baseSL = baseSwing + bufferDist;
      double shieldPrice = FindResistShield(sym, baseSL, dayPrevClose, dayATR);

      double preSL = baseSL;
      if(shieldPrice > 0 && (shieldPrice - baseSL) < bufferDist * 2) {
         preSL = shieldPrice + safetyPad; strategyLog += "|Shield";
      }

      rawSL = CheckClusterAdjustment(sym, preSL, signal, 200 * pointVal * pCorr);
      if(rawSL != preSL) strategyLog += "|Clust";

      if((rawSL - entryPrice) < minSafeDistance) rawSL = entryPrice + minSafeDistance;
   }
   else return;

   double baseLotForCalc = 0.01;
   double targetDist = (InpMinProfitUSD / (tickValue * baseLotForCalc)) * tickSize;

   bool isExpansion = false;

   if(fuelRemaining <= minFuelPrice)
   {

      datetime dayStart = iTime(sym, PERIOD_D1, 0);
      double dHigh = iHigh(sym, PERIOD_D1, 0);
      double dLow  = iLow(sym, PERIOD_D1, 0);

      double rangeTolerance = (dHigh - dLow) * 0.10;

      if(signal == 1 && (dHigh - entryPrice) < rangeTolerance) isExpansion = true;
      if(signal == -1 && (entryPrice - dLow) < rangeTolerance) isExpansion = true;

      if(isExpansion) {

         double turboDist = sessAvgRange * 0.3;

         if(targetDist > turboDist) targetDist = turboDist;

         strategyLog += "|Fuel_Turbo";
      }
      else {

         targetDist = minFuelPrice;
         strategyLog += "|Fuel_Empty";
      }
   }
   else
   {

      if(targetDist > fuelRemaining) {
         targetDist = fuelRemaining;
         strategyLog += "|Fuel";
      }
   }

   double rawTP = (signal == 1) ? entryPrice + targetDist : entryPrice - targetDist;

   double obstaclePrice = 0;
   double minMagnetDist = 300 * pointVal * pCorr;

   if(signal == 1) {
      obstaclePrice = FindNearestResistObstacle(entryPrice, rawTP, dayPrevClose, dayATR);
      if(obstaclePrice > 0) {
         double safeTP = obstaclePrice - minSafetyPrice;
         if(safeTP > entryPrice + minMagnetDist) { tpPrice = safeTP; strategyLog += "|Mag"; }
         else { tpPrice = rawTP; }
      } else { tpPrice = rawTP; }
   }
   else {
      obstaclePrice = FindNearestSupportObstacle(entryPrice, rawTP, dayPrevClose, dayATR);
      if(obstaclePrice > 0) {
         double safeTP = obstaclePrice + minSafetyPrice;
         if(safeTP < entryPrice - minMagnetDist) { tpPrice = safeTP; strategyLog += "|Mag"; }
         else { tpPrice = rawTP; }
      } else { tpPrice = rawTP; }
   }
   slPrice = rawSL;

   g_LatestSL = slPrice;
   g_LatestTP = tpPrice;

   if(!isCalcOnly)
   {
      double distTP = MathAbs(tpPrice - entryPrice);
      double distSL = MathAbs(entryPrice - slPrice);
      double profitMoney = (distTP / tickSize) * tickValue * lotSize;
      double lossMoney   = (distSL / tickSize) * tickValue * lotSize;
      string currency = AccountInfoString(ACCOUNT_CURRENCY);

      string baseName = InpRR_ObjPrefix + IntegerToString(entryTime);
      datetime endTime = entryTime + PeriodSeconds(tf);  // กว้างแค่ 1 แท่ง
      int fontSize = 9;

      string tpObj = baseName + "_TP";
      if(ObjectFind(0, tpObj) < 0) ObjectCreate(0, tpObj, OBJ_RECTANGLE, 0, entryTime, entryPrice, endTime, tpPrice);
      ObjectSetInteger(0, tpObj, OBJPROP_COLOR, InpRR_TPColor);
      ObjectSetInteger(0, tpObj, OBJPROP_FILL, true);
      ObjectSetInteger(0, tpObj, OBJPROP_BACK, true);
      ObjectSetDouble(0, tpObj, OBJPROP_PRICE, 0, entryPrice);
      ObjectSetDouble(0, tpObj, OBJPROP_PRICE, 1, tpPrice);
      ObjectSetInteger(0, tpObj, OBJPROP_TIME, 0, entryTime);
      ObjectSetInteger(0, tpObj, OBJPROP_TIME, 1, endTime);

      string slObj = baseName + "_SL";
      if(ObjectFind(0, slObj) < 0) ObjectCreate(0, slObj, OBJ_RECTANGLE, 0, entryTime, entryPrice, endTime, slPrice);
      ObjectSetInteger(0, slObj, OBJPROP_COLOR, InpRR_SLColor);
      ObjectSetInteger(0, slObj, OBJPROP_FILL, true);
      ObjectSetInteger(0, slObj, OBJPROP_BACK, true);
      ObjectSetDouble(0, slObj, OBJPROP_PRICE, 0, entryPrice);
      ObjectSetDouble(0, slObj, OBJPROP_PRICE, 1, slPrice);
      ObjectSetInteger(0, slObj, OBJPROP_TIME, 0, entryTime);
      ObjectSetInteger(0, slObj, OBJPROP_TIME, 1, endTime);

      if(InpRR_ShowText)
      {
         bool isBuy = (tpPrice > entryPrice);

         // USD ที่ได้ — BUY: เหนือกล่อง TP | SELL: ใต้กล่อง TP
         string tpUSD  = IntegerToString((int)MathRound(profitMoney));
         double tpEdge = tpPrice;
         ENUM_ANCHOR_POINT tpAnch = isBuy ? ANCHOR_LEFT_LOWER : ANCHOR_LEFT_UPPER;
         string tpLbl  = baseName + "_TP_USD";
         if(ObjectFind(0, tpLbl) < 0) ObjectCreate(0, tpLbl, OBJ_TEXT, 0, entryTime, tpEdge);
         ObjectSetInteger(0, tpLbl, OBJPROP_TIME,       entryTime);
         ObjectSetDouble (0, tpLbl, OBJPROP_PRICE,      tpEdge);
         ObjectSetString (0, tpLbl, OBJPROP_TEXT,       tpUSD);
         ObjectSetInteger(0, tpLbl, OBJPROP_COLOR,      InpRR_TPColor);
         ObjectSetInteger(0, tpLbl, OBJPROP_FONTSIZE,   fontSize);
         ObjectSetString (0, tpLbl, OBJPROP_FONT,       "Arial Bold");
         ObjectSetInteger(0, tpLbl, OBJPROP_ANCHOR,     tpAnch);
         ObjectSetInteger(0, tpLbl, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, tpLbl, OBJPROP_BACK,       false);

         // USD ที่เสีย — BUY: ใต้กล่อง SL | SELL: เหนือกล่อง SL
         string slUSD  = IntegerToString((int)MathRound(lossMoney));
         double slEdge = slPrice;
         ENUM_ANCHOR_POINT slAnch = isBuy ? ANCHOR_LEFT_UPPER : ANCHOR_LEFT_LOWER;
         string slLbl  = baseName + "_SL_USD";
         if(ObjectFind(0, slLbl) < 0) ObjectCreate(0, slLbl, OBJ_TEXT, 0, entryTime, slEdge);
         ObjectSetInteger(0, slLbl, OBJPROP_TIME,       entryTime);
         ObjectSetDouble (0, slLbl, OBJPROP_PRICE,      slEdge);
         ObjectSetString (0, slLbl, OBJPROP_TEXT,       slUSD);
         ObjectSetInteger(0, slLbl, OBJPROP_COLOR,      InpRR_SLColor);
         ObjectSetInteger(0, slLbl, OBJPROP_FONTSIZE,   fontSize);
         ObjectSetString (0, slLbl, OBJPROP_FONT,       "Arial Bold");
         ObjectSetInteger(0, slLbl, OBJPROP_ANCHOR,     slAnch);
         ObjectSetInteger(0, slLbl, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, slLbl, OBJPROP_BACK,       false);
      }
      ChartRedraw();
   }
}



//+------------------------------------------------------------------+
//| TRENDLINE FUNCTIONS                                              |
//| เส้นเทรน S1 (Macro 30 bars) และ S2 (Recent 10 bars)            |
//| Main chart = Gold | Sub-window = DXY                             |
//+------------------------------------------------------------------+
void DelObj(string n) { if(ObjectFind(0, n) >= 0) ObjectDelete(0, n); }

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
      ObjectSetString (0, lbl_name, OBJPROP_TEXT,      lbl_txt);
      ObjectSetString (0, lbl_name, OBJPROP_FONT,      "Courier New");
      ObjectSetInteger(0, lbl_name, OBJPROP_FONTSIZE,  7);
      ObjectSetInteger(0, lbl_name, OBJPROP_COLOR,     clr);
      ObjectSetInteger(0, lbl_name, OBJPROP_ANCHOR,    ANCHOR_RIGHT_LOWER);
      ObjectSetInteger(0, lbl_name, OBJPROP_SELECTABLE,false);
   }
}

void DeleteTrendLines()
{
   DelObj(TL_S1_GOLD); DelObj(TL_S1_DXY); DelObj(TL_S2_GOLD); DelObj(TL_S2_DXY);
   DelObj(TL_S1_GOLD_LBL); DelObj(TL_S1_DXY_LBL);
   DelObj(TL_S2_GOLD_LBL); DelObj(TL_S2_DXY_LBL);
   DelObj(OBJ_DXY_LBL);
}

void UpdateTrendLines()
{
   if(!InpShowTL_Step1 && !InpShowTL_Step2) { DeleteTrendLines(); return; }
   int rates_total = Bars(_Symbol, _Period);
   if(rates_total < MathMax(InpMacroBars, InpRecentBars) + 5) return;

   // DXY sub-window index
   if(g_subwin < 0) {
      // EA has no sub-window — DXY TL draws on main chart window 0
      g_subwin = 0;
   }

   datetime t_now[]; ArraySetAsSeries(t_now, true);
   if(CopyTime(_Symbol, _Period, 0, 1, t_now) < 1) return;

   datetime t_s1[]; ArraySetAsSeries(t_s1, true);
   if(CopyTime(_Symbol, _Period, InpMacroBars-1, 1, t_s1) < 1) return;

   datetime t_s2[]; ArraySetAsSeries(t_s2, true);
   if(CopyTime(_Symbol, _Period, InpRecentBars-1, 1, t_s2) < 1) return;

   // Gold prices
   double g_now[]; ArraySetAsSeries(g_now, true);
   if(CopyClose(_Symbol, _Period, 0, 1, g_now) < 1) return;

   double g_s1[]; ArraySetAsSeries(g_s1, true);
   if(CopyClose(_Symbol, _Period, InpMacroBars-1, 1, g_s1) < 1) return;

   double g_s2[]; ArraySetAsSeries(g_s2, true);
   if(CopyClose(_Symbol, _Period, InpRecentBars-1, 1, g_s2) < 1) return;

   // DXY prices
   double d_now[]; ArraySetAsSeries(d_now, true);
   if(CopyClose(InpDXY_Symbol, _Period, 0, 1, d_now) < 1) return;

   double d_s1[]; ArraySetAsSeries(d_s1, true);
   if(CopyClose(InpDXY_Symbol, _Period, InpMacroBars-1, 1, d_s1) < 1) return;

   double d_s2[]; ArraySetAsSeries(d_s2, true);
   if(CopyClose(InpDXY_Symbol, _Period, InpRecentBars-1, 1, d_s2) < 1) return;

   int wm = 0;   // Main chart window for Gold TL
   int ws = 0;   // EA draws DXY TL on main chart too (no sub-window in EA)

   // ── Step 1: Macro Trendline (30 bars) ──
   if(InpShowTL_Step1) {
      DrawTL(TL_S1_GOLD, wm,
             t_s1[0], g_s1[0], t_now[0], g_now[0],
             InpColorTL_S1_Gold, InpWidthTL_Step1, InpStyleTL_S1,
             TL_S1_GOLD_LBL, StringFormat("S1 Gold(%d)", InpMacroBars));
      // DXY TL S1: disabled
   } else {
      DelObj(TL_S1_GOLD); DelObj(TL_S1_DXY);
      DelObj(TL_S1_GOLD_LBL); DelObj(TL_S1_DXY_LBL);
   }

   // ── Step 2: Recent Trendline (10 bars) ──
   if(InpShowTL_Step2) {
      DrawTL(TL_S2_GOLD, wm,
             t_s2[0], g_s2[0], t_now[0], g_now[0],
             InpColorTL_S2_Gold, InpWidthTL_Step2, InpStyleTL_S2,
             TL_S2_GOLD_LBL, StringFormat("S2 Gold(%d)", InpRecentBars));
      // DXY TL S2: disabled
   } else {
      DelObj(TL_S2_GOLD); DelObj(TL_S2_DXY);
      DelObj(TL_S2_GOLD_LBL); DelObj(TL_S2_DXY_LBL);
   }

   DelObj(OBJ_DXY_LBL); // DXY label disabled

   ChartRedraw(0);
}


//+------------------------------------------------------------------+
//| SIGNAL ARROW DRAWING                                             |
//+------------------------------------------------------------------+
void DrawBuyArrow(datetime bar_time, double low_price)
{
   string name = OBJ_PREFIX + "ARW_BUY_" + IntegerToString((int)bar_time);
   if(ObjectFind(0, name) >= 0) return;
   double y_pos = low_price - InpArrowPoints * _Point;
   ObjectCreate(0, name, OBJ_ARROW, 0, bar_time, y_pos);
   ObjectSetInteger(0, name, OBJPROP_ARROWCODE,  233);   // up arrow
   ObjectSetInteger(0, name, OBJPROP_ANCHOR,     ANCHOR_TOP);   // anchor at top → arrow tip points up toward candle
   ObjectSetInteger(0, name, OBJPROP_COLOR,      clrYellow);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,      1);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_BACK,       false);
}

void DrawSellArrow(datetime bar_time, double high_price)
{
   string name = OBJ_PREFIX + "ARW_SELL_" + IntegerToString((int)bar_time);
   if(ObjectFind(0, name) >= 0) return;
   double y_pos = high_price + InpArrowPoints * _Point;
   ObjectCreate(0, name, OBJ_ARROW, 0, bar_time, y_pos);
   ObjectSetInteger(0, name, OBJPROP_ARROWCODE,  234);   // down arrow
   ObjectSetInteger(0, name, OBJPROP_ANCHOR,     ANCHOR_BOTTOM); // anchor at bottom → arrow tip points down toward candle
   ObjectSetInteger(0, name, OBJPROP_COLOR,      clrYellow);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,      1);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_BACK,       false);
}

// OFA×Hull cross Buy arrow — OFA P26 ตัดขึ้น Hull Suite (prefix GDEA_HARW_)
void DrawHullBuyArrow(datetime bar_time, double low_price)
{
   string name = "GDEA_HARW_" + IntegerToString((int)bar_time);
   if(ObjectFind(0, name) >= 0) return;
   double y_pos = low_price - InpArrowPoints * _Point;
   ObjectCreate(0, name, OBJ_ARROW, 0, bar_time, y_pos);
   ObjectSetInteger(0, name, OBJPROP_ARROWCODE,  233);   // up arrow
   ObjectSetInteger(0, name, OBJPROP_ANCHOR,     ANCHOR_TOP);
   ObjectSetInteger(0, name, OBJPROP_COLOR,      clrYellow);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,      1);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_BACK,       false);
}

// OFA×Hull cross Sell arrow — OFA P26 ตัดลง Hull Suite (prefix GDEA_HARWS_)
void DrawHullSellArrow(datetime bar_time, double high_price)
{
   string name = "GDEA_HARWS_" + IntegerToString((int)bar_time);
   if(ObjectFind(0, name) >= 0) return;
   double y_pos = high_price + InpArrowPoints * _Point;
   ObjectCreate(0, name, OBJ_ARROW, 0, bar_time, y_pos);
   ObjectSetInteger(0, name, OBJPROP_ARROWCODE,  234);   // down arrow
   ObjectSetInteger(0, name, OBJPROP_ANCHOR,     ANCHOR_BOTTOM);
   ObjectSetInteger(0, name, OBJPROP_COLOR,      clrYellow);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,      1);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_BACK,       false);
}

// ตรวจ OFA P26 swing ล่าสุด ตัดกับ Hull Suite value
// cross up  (OFA เคยต่ำกว่า → ตอนนี้สูงกว่า Hull) = BUY arrow
// cross down(OFA เคยสูงกว่า → ตอนนี้ต่ำกว่า Hull) = SELL arrow
void CheckHullOFACross(bool isNewBar)
{
   if(!InpHL_ColorArrow || !isNewBar) return;
   if(g_hullLastWrittenIdx < 0) return;
   if(gdx_swingCount < 1) return;

   int    hullIdx  = g_hullLastWrittenIdx;
   if(hullIdx >= ArraySize(gdx_HullValue)) return;

   double hullVal  = gdx_HullValue[hullIdx];
   double ofaPrice = gdx_swings[gdx_swingCount - 1].price;
   if(hullVal <= 0 || ofaPrice <= 0) return;

   int newState = (ofaPrice > hullVal) ? 1 : -1;

   if(g_hullOfaCrossState != 0 && newState != g_hullOfaCrossState) {
      // Cross detected — draw arrow at current bar
      datetime barTime = (datetime)SeriesInfoInteger(_Symbol, PERIOD_CURRENT, SERIES_LASTBAR_DATE);
      double   barHigh = iHigh(_Symbol, PERIOD_CURRENT, 0);
      double   barLow  = iLow (_Symbol, PERIOD_CURRENT, 0);
      if(newState == 1) {
         DrawHullBuyArrow (barTime, barLow);   // OFA crossed above Hull → UP arrow
         if(InpHL_ColorArrow_Trade)
            TryOpenHullArrowTrade(true, barTime, g_hullCross_LastBuyBarTime, g_hullCross_LastSellBarTime);
      } else {
         DrawHullSellArrow(barTime, barHigh);  // OFA crossed below Hull → DOWN arrow
         if(InpHL_ColorArrow_Trade)
            TryOpenHullArrowTrade(false, barTime, g_hullCross_LastBuyBarTime, g_hullCross_LastSellBarTime);
      }
   }

   g_hullOfaCrossState = newState;
}

// ─── Hull Color-Change Arrows ──────────────────────────────────────────────
// Hull แดง→เขียว (trend: -1→+1) = ลูกศรขึ้นสีเขียว   prefix GDEA_HARWT_
// Hull เขียว→แดง (trend: +1→-1) = ลูกศรลงสีแดง       prefix GDEA_HARWTS_

void DrawHullTrendBuyArrow(datetime bar_time, double low_price)
{
   string name = "GDEA_HARWT_" + IntegerToString((int)bar_time);
   if(ObjectFind(0, name) >= 0) return;
   double y_pos = low_price - InpArrowPoints * _Point;
   ObjectCreate(0, name, OBJ_ARROW, 0, bar_time, y_pos);
   ObjectSetInteger(0, name, OBJPROP_ARROWCODE,  233);   // up arrow
   ObjectSetInteger(0, name, OBJPROP_ANCHOR,     ANCHOR_TOP);
   ObjectSetInteger(0, name, OBJPROP_COLOR,      clrYellow);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,      1);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_BACK,       false);
}

void DrawHullTrendSellArrow(datetime bar_time, double high_price)
{
   string name = "GDEA_HARWTS_" + IntegerToString((int)bar_time);
   if(ObjectFind(0, name) >= 0) return;
   double y_pos = high_price + InpArrowPoints * _Point;
   ObjectCreate(0, name, OBJ_ARROW, 0, bar_time, y_pos);
   ObjectSetInteger(0, name, OBJPROP_ARROWCODE,  234);   // down arrow
   ObjectSetInteger(0, name, OBJPROP_ANCHOR,     ANCHOR_BOTTOM);
   ObjectSetInteger(0, name, OBJPROP_COLOR,      clrYellow);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,      1);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_BACK,       false);
}

//// เรียกทุก new bar ก่อน gdx_LastHullTrend ถูก update
//// curTrend = trend ที่เพิ่งคำนวณได้; gdx_LastHullTrend = trend บาร์ก่อน
//void CheckHullTrendChange(int curTrend)
//{
//   if(!InpHL_TrendArrow) return;
//   if(gdx_LastHullTrend == 0 || curTrend == gdx_LastHullTrend) return;
//
//   // ── Hull Slope Confirmation (2 bars) ────────────────────────────
//   int idx = g_hullLastWrittenIdx;
//   if(idx < 2) return;  // ต้องมีข้อมูลอย่างน้อย 3 bars
//   double hullCur  = gdx_HullValue[idx];
//   double hullPrev = gdx_HullValue[idx - 1];
//   double hullPrev2= gdx_HullValue[idx - 2];
//   if(curTrend > 0) {
//      // Hull flip เขียว: ทั้งแท่งปัจจุบันและแท่งก่อนต้อง slope ขึ้น
//      if(hullCur <= hullPrev || hullPrev <= hullPrev2) {
//         Print("[HULL-TREND BLOCKED] BUY slope not confirmed — Hull[0]=", DoubleToString(hullCur,5),
//               " Hull[-1]=", DoubleToString(hullPrev,5), " Hull[-2]=", DoubleToString(hullPrev2,5));
//         return;
//      }
//   } else {
//      // Hull flip แดง: ทั้งแท่งปัจจุบันและแท่งก่อนต้อง slope ลง
//      if(hullCur >= hullPrev || hullPrev >= hullPrev2) {
//         Print("[HULL-TREND BLOCKED] SELL slope not confirmed — Hull[0]=", DoubleToString(hullCur,5),
//               " Hull[-1]=", DoubleToString(hullPrev,5), " Hull[-2]=", DoubleToString(hullPrev2,5));
//         return;
//      }
//   }
//   // ────────────────────────────────────────────────────────────────
//
//   // ────────────────────────────────────────────────────────────────
//
//   datetime barTime = (datetime)SeriesInfoInteger(_Symbol, PERIOD_CURRENT, SERIES_LASTBAR_DATE);
//   double   barHigh = iHigh(_Symbol, PERIOD_CURRENT, 0);
//   double   barLow  = iLow (_Symbol, PERIOD_CURRENT, 0);
//   if(curTrend > 0) {
//      DrawHullTrendBuyArrow (barTime, barLow);   // Hull แดง→เขียว → ลูกศรขึ้น
//      if(InpHL_TrendArrow_Trade) {
//         if(InpHL_BreakoutConfirm)
//            g_hullTrend_PendingBuy = true;       // รอ bar ถัดไปปิดก่อน check
//         else
//            TryOpenHullArrowTrade(true, barTime, g_hullTrend_LastBuyBarTime, g_hullTrend_LastSellBarTime);
//      }
//   } else {
//      DrawHullTrendSellArrow(barTime, barHigh);  // Hull เขียว→แดง → ลูกศรลง
//      if(InpHL_TrendArrow_Trade) {
//         if(InpHL_BreakoutConfirm)
//            g_hullTrend_PendingSell = true;      // รอ bar ถัดไปปิดก่อน check
//         else
//            TryOpenHullArrowTrade(false, barTime, g_hullTrend_LastBuyBarTime, g_hullTrend_LastSellBarTime);
//      }
//   }
//}
// เรียกทุก new bar ก่อน gdx_LastHullTrend ถูก update
void CheckHullTrendChange(int curTrend)
{
   if(!InpHL_TrendArrow) return;
   if(gdx_LastHullTrend == 0 || curTrend == gdx_LastHullTrend) return;

   // ── Hull Slope Confirmation (ปรับเหลือ 1 bar เพื่อความไว) ──────────
   int idx = g_hullLastWrittenIdx;
   if(idx < 1) return; 
   
   double hullCur  = gdx_HullValue[idx];
   double hullPrev = gdx_HullValue[idx - 1];

   double thr = InpHL_SlopeThreshold * _Point;  // V.1.39: consistent กับ GdxUpdateHull
   if(curTrend > 0) {
      if(hullCur - hullPrev <= thr) return; // slope ไม่แรงพอ → ไม่ยิง BUY
   } else {
      if(hullPrev - hullCur <= thr) return; // slope ไม่แรงพอ → ไม่ยิง SELL
   }
   // ────────────────────────────────────────────────────────────────

   // ใช้ชื่อ h_ นำหน้าเพื่อไม่ให้ซ้ำกับตัวแปร Global ของระบบ
   datetime h_barTime = (datetime)SeriesInfoInteger(_Symbol, PERIOD_CURRENT, SERIES_LASTBAR_DATE);
   double   h_barHigh = iHigh(_Symbol, PERIOD_CURRENT, 0);
   double   h_barLow  = iLow (_Symbol, PERIOD_CURRENT, 0);
   
   if(curTrend > 0)
   {
      DrawHullTrendBuyArrow(h_barTime, h_barLow);
      if(InpHL_TrendArrow_Trade)
         TryOpenHullArrowTrade(true, h_barTime, g_hullTrend_LastBuyBarTime, g_hullTrend_LastSellBarTime);
   }
   else
   {
      DrawHullTrendSellArrow(h_barTime, h_barHigh);
      if(InpHL_TrendArrow_Trade)
         TryOpenHullArrowTrade(false, h_barTime, g_hullTrend_LastBuyBarTime, g_hullTrend_LastSellBarTime);
   }
}
//// ── เปิด Trade จริงจาก Hull arrow signals ──────────────────────────────────
//// ใช้ OpenBuyPosition()/OpenSellPosition() ครบ: ATR SL, Swing SL/TP, Session TP
//void TryOpenHullArrowTrade(bool isBuy, datetime barTime,
//                            datetime &lastBuyTime, datetime &lastSellTime)
//{
//   int cntBuy = 0, cntSell = 0;
//   CountOpenPositions(cntBuy, cntSell);
//   if(isBuy) {
//      if(!InpBuyPosition) return;
//      if(barTime == lastBuyTime) return;         // same-bar guard
//      if(cntBuy >= InpTotalPosition) return;
//      if(OpenBuyPosition()) lastBuyTime = barTime;
//   } else {
//      if(!InpSellPosition) return;
//      if(barTime == lastSellTime) return;        // same-bar guard
//      if(cntSell >= InpTotalPosition) return;
//      if(OpenSellPosition()) lastSellTime = barTime;
//   }
//}
//+------------------------------------------------------------------+
//| V.1.23: Updated HullArrow Trade with Z-Score Filter & Detailed Log |
//+------------------------------------------------------------------+
void TryOpenHullArrowTrade(bool isBuy, datetime barTime,
                            datetime &lastBuyTime, datetime &lastSellTime)
{
   // 1. เบรกด่วนถ้าไม่ได้เปิดระบบ Trade จากลูกศร หรือ ออเดอร์เต็ม
   int cntBuy = 0, cntSell = 0;
   CountOpenPositions(cntBuy, cntSell);
   if(isBuy && (!InpBuyPosition || cntBuy >= InpTotalPosition)) return;
   if(!isBuy && (!InpSellPosition || cntSell >= InpTotalPosition)) return;
   if(barTime == (isBuy ? lastBuyTime : lastSellTime)) return;

   // 2. คำนวณ Z-Score ณ วินาทีปัจจุบัน
   double gc[]; double zg = 0;
   if(!GetSeries(_Symbol, 0, InpZPeriod, gc)) return;
   zg = ZScore(gc, InpZPeriod);

   // 3. ตรวจสอบเงื่อนไข Z-Score ตาม Session ปัจจุบัน (Sync กับระบบหลัก)
   ENUM_SF_SESSION curSess = GetCurrentSession();
   SessionProfile arrow_sp = GetSessionProfile(curSess);
   double zLimit = arrow_sp.zLimit;

   bool z_ok = isBuy ? (zg < zLimit) : (zg > -zLimit);

   if(!z_ok) {
      // บันทึก Log เฉพาะตอนที่สัญญาณมาแต่โดนบล็อคสถิติ
      static datetime lastBlkLog = 0;
      if(TimeCurrent() - lastBlkLog > 60) {
         Print(StringFormat("[HULL-ARROW BLOCKED] %s at %.2f | Z-Score: %.2f (Limit: %.2f) -> Too %s", 
               (isBuy?"BUY":"SELL"), currentTick.bid, zg, zLimit, (isBuy?"High/Overbought":"Low/Oversold")));
         lastBlkLog = TimeCurrent();
      }
      return; 
   }

   // 4. HTF Hull gate — ต้อง align กับ Trend ก่อนเปิด order
   if(InpHTF_Enable)
   {
      if(g_htf_hull_trend == 0) {
         Print("[HULL-ARROW BLOCKED] HTF Hull not ready (warmup)");
         return;
      }
      if(isBuy && g_htf_hull_trend == -1.0) {
         Print(StringFormat("[HULL-ARROW BLOCKED] BUY blocked — HTF %s Hull = DN",
               EnumToString(InpHTF_Timeframe)));
         return;
      }
      if(!isBuy && g_htf_hull_trend == 1.0) {
         Print(StringFormat("[HULL-ARROW BLOCKED] SELL blocked — HTF %s Hull = UP",
               EnumToString(InpHTF_Timeframe)));
         return;
      }
   }

   // 4b. OFA Conflict filter — block ถ้า p26+p50 ขัดกับ direction
   if(gdx_LastConfirmedCount > 0)
   {
      bool ofa26bull = !gdx_swings[gdx_LastConfirmedCount-1].isHigh;
      bool ofa50bull = (gdx_LastConfirmedCount2 > 0)
                       ? !gdx_swings2[gdx_LastConfirmedCount2-1].isHigh
                       : ofa26bull;
      if(!isBuy && ofa26bull && ofa50bull) {
         Print("[HULL-ARROW BLOCKED] SELL blocked — OFA p26+p50 both BULL");
         return;
      }
      if(isBuy && !ofa26bull && !ofa50bull) {
         Print("[HULL-ARROW BLOCKED] BUY blocked — OFA p26+p50 both BEAR");
         return;
      }
   }

   // 5. ผ่านการกรองสถิติ -> พิมพ์ Detailed Log (PASSED BANNER) เหมือน EA หลัก
   string side = isBuy ? "BUY" : "SELL";
   int hullDir = (g_hullLastWrittenIdx >= 0) ? (int)gdx_HullTrend[g_hullLastWrittenIdx] : 0;
   string htfStr = (g_htf_hull_trend == 1.0) ? "UP" : (g_htf_hull_trend == -1.0 ? "DN" : "--");
   double atrPct = GetDailyATRConsumption() * 100.0;

   Print("================================================================");
   Print(StringFormat("[HULL-ARROW SIGNAL PASSED] %s %s at %.2f", side, _Symbol, (isBuy?currentTick.ask:currentTick.bid)));
   Print(StringFormat(" > STATISTICS | Z-Score: %.2f (Limit: %.2f) | ATR_Used: %.0f%%", zg, zLimit, atrPct));
   Print(StringFormat(" > CONTEXT    | HTF_Hull: %s | Hull_M1: %s | Session: %s", htfStr, (hullDir>0?"UP":"DN"), GetSessionName(curSess)));
   Print("================================================================");

   // 5. สั่งเปิดออเดอร์
   if(isBuy) {
      if(OpenBuyPosition()) lastBuyTime = barTime;
   } else {
      if(OpenSellPosition()) lastSellTime = barTime;
   }
}

//+------------------------------------------------------------------+
//| OFA ENGINE FUNCTIONS                                             |
//+------------------------------------------------------------------+
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

string GdxGetVMStatus(bool isBull, double vel, double mag, double pVel, double pMag) {
   if(pVel <= 0 || pMag <= 0) return isBull ? "v+ m+" : "v- m-";
   string vS = (vel/pVel >= 1.5) ? "v++" : (vel/pVel > 1.0) ? "v+" : (vel/pVel <= 0.67) ? "v--" : "v-";
   string mS = (mag/pMag >= 1.5) ? "m++" : (mag/pMag > 1.0) ? "m+" : (mag/pMag <= 0.5)  ? "m--" : "m-";
   return vS + " " + mS;
}

// [V.20e] คำนวณว่า curPrice อยู่ที่ Fib level ไหนของ swing hi→lo
string GdxGetFibLevelStr(double hi, double lo, double curPrice)
{
   double range = hi - lo;
   if(range < 0.5) return "";
   double ret = (hi - curPrice) / range;  // 0.0=atHigh, 1.0=atLow

   double fibs[]     = {0.0, 0.236, 0.382, 0.500, 0.618, 0.786, 0.887, 1.000};
   string fibNames[] = {"0%","23.6%","38.2%","50%","61.8%","78.6%","88.7%","100%"};

   if(ret < -0.05) return StringFormat("Fibo +%.1f%%", -ret * 100); // above High (extension)
   if(ret >  1.05) return StringFormat("Fibo +%.1f%%",  ret * 100); // below Low  (extension)

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
   // [V.20e] Fib level: swing นี้อยู่ที่ Fib เท่าไรของ leg ก่อนหน้า (previous pair idx-2, idx-1)
   if(InpOFA_ShowFibLabel && idx >= 2) {
      GDX_SwingPoint s1 = gdx_swings[idx - 1];
      GDX_SwingPoint s0 = gdx_swings[idx - 2];
      double hi = s1.isHigh ? s1.price : s0.price;
      double lo = s1.isHigh ? s0.price : s1.price;
      txt += "\n" + GdxGetFibLevelStr(hi, lo, s2.price);
   }
   return txt;
}

string GdxBuildOFANotifyMsg(string sym, string tf, bool bull, double p, double m, double v,
                             double pV, double pM, datetime t, string tag)
{
   int digs = (_Digits > 3) ? 2 : _Digits;
   string sign = bull ? "+" : "-"; string emo = bull ? "BULL" : "BEAR";
   string vS = (pV > 0 && pM > 0) ? GdxGetVMStatus(bull, v, m, pV, pM) : (bull ? "v+ m+" : "v- m-");
   return emo + tag + " " + sym + " " + tf + " | " +
          DoubleToString(p, digs) + " | " + vS + " | " + sign + DoubleToString(m, digs) +
          " | " + DoubleToString(v, 0) + "bars | " + TimeToString(t, TIME_MINUTES);
}

int GdxShouldSendOFAUpdate(double curM, double lastM, int lastN) {
   if(curM <= 0 || lastM <= 0) return 0;
   double g = curM - lastM; double gP = (lastM > 0) ? (g / lastM) * 100.0 : 0;
   if((InpOFA_NotifyUpdatePts > 0 && g >= InpOFA_NotifyUpdatePts) ||
      (InpOFA_NotifyUpdatePct > 0 && gP >= InpOFA_NotifyUpdatePct))
      return lastN + 1;
   return 0;
}

int GdxGetOFATrendAtBar(int bar)
{
   if(gdx_swingCount > gdx_LastConfirmedCount && gdx_LastConfirmedCount > 0) {
      if(bar > gdx_swings[gdx_LastConfirmedCount-1].bar)
         return gdx_swings[gdx_swingCount-1].isHigh ? 1 : -1;
   }
   for(int i = 1; i < gdx_LastConfirmedCount; i++)
      if(bar >= gdx_swings[i-1].bar && bar <= gdx_swings[i].bar)
         return gdx_swings[i].isHigh ? 1 : -1;
   if(gdx_LastConfirmedCount > 0 && bar >= gdx_swings[gdx_LastConfirmedCount-1].bar)
      return gdx_swings[gdx_LastConfirmedCount-1].isHigh ? 1 : -1;
   return 0;
}

int GdxGetOFATrendAtBar2(int bar)
{
   if(gdx_swingCount2 > gdx_LastConfirmedCount2 && gdx_LastConfirmedCount2 > 0) {
      if(bar > gdx_swings2[gdx_LastConfirmedCount2-1].bar)
         return gdx_swings2[gdx_swingCount2-1].isHigh ? 1 : -1;
   }
   for(int i = 1; i < gdx_LastConfirmedCount2; i++)
      if(bar >= gdx_swings2[i-1].bar && bar <= gdx_swings2[i].bar)
         return gdx_swings2[i].isHigh ? 1 : -1;
   if(gdx_LastConfirmedCount2 > 0 && bar >= gdx_swings2[gdx_LastConfirmedCount2-1].bar)
      return gdx_swings2[gdx_LastConfirmedCount2-1].isHigh ? 1 : -1;
   return 0;
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
   for(int i=1;i<frCount;i++) { GDX_Fractal k=fr[i]; int j=i-1; while(j>=0&&fr[j].bar>k.bar){fr[j+1]=fr[j];j--;} fr[j+1]=k; }
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
      // บันทึก Volume และ OHLC ของแท่ง Swing
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

void GdxUpdateLiveSwing(int total, const datetime &time[],
                     const double &high[], const double &low[])
{
   if(gdx_LastConfirmedCount < 1) return;
   gdx_swingCount=gdx_LastConfirmedCount;
   ArrayResize(gdx_swings,gdx_swingCount);
   int lastB=total-1;
   GDX_SwingPoint last=gdx_swings[gdx_swingCount-1], cur;

   // ── Guard: last.bar ต้องอยู่ในช่วง array ──────────────────
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
   int lastB=total-1;
   GDX_SwingPoint last2=gdx_swings2[gdx_swingCount2-1], cur2;

   // ── Guard: last2.bar ต้องอยู่ในช่วง array ─────────────────
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
   }
   string txt=GdxBuildLabelText(gdx_swingCount-1);
   if(txt!=""&&InpOFA_ShowLabels) {
      if(ObjectFind(0,tn)<0) ObjectCreate(0,tn,OBJ_TEXT,0,s2.time,s2.price);
      ObjectSetInteger(0,tn,OBJPROP_TIME,0,s2.time); ObjectSetDouble(0,tn,OBJPROP_PRICE,0,s2.price);
      ObjectSetString(0,tn,OBJPROP_TEXT,txt); ObjectSetInteger(0,tn,OBJPROP_COLOR,c);
      ObjectSetInteger(0,tn,OBJPROP_FONTSIZE,InpOFA_LabelFontSize);
      ObjectSetInteger(0,tn,OBJPROP_ANCHOR,s2.isHigh?ANCHOR_LEFT_LOWER:ANCHOR_LEFT_UPPER);
   }
   // [V.20e] Confirmed swing Fib% is static (uses swing price, not BID) — no real-time update needed
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
         // [V.20e] Fib level: swing [i+1] อยู่ที่ Fib เท่าไรของ leg ก่อนหน้า (pair i-1, i)
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

void GdxHandleOFANotifications(int total)
{
   if(GDEA_IsQuietHour()) return;
   string tf=GdxGetTFString(), sym=_Symbol;
   datetime lastConfTime=0; bool lastConfIsHigh=false; double lastConfPrice=0;
   if(gdx_LastConfirmedCount>0) {
      lastConfTime  =gdx_swings[gdx_LastConfirmedCount-1].time;
      lastConfPrice =gdx_swings[gdx_LastConfirmedCount-1].price;
      lastConfIsHigh=gdx_swings[gdx_LastConfirmedCount-1].isHigh;
   }
   double livePrice=0; datetime liveTime=0; double liveVel=0,liveMag=0;
   if(InpOFA_DisplayCurrentSwing&&gdx_swingCount>gdx_LastConfirmedCount&&gdx_swingCount>0) {
      livePrice=gdx_swings[gdx_swingCount-1].price; liveTime=gdx_swings[gdx_swingCount-1].time;
      liveVel=MathAbs((double)(gdx_swings[gdx_swingCount-1].bar-gdx_swings[gdx_LastConfirmedCount-1].bar));
      liveMag=MathAbs(gdx_swings[gdx_swingCount-1].price-gdx_swings[gdx_LastConfirmedCount-1].price);
   }
   bool liveLegIsBull=!lastConfIsHigh;
   double prevVel=0,prevMag=0;
   for(int si=gdx_LastConfirmedCount-2;si>=0;si--)
      if(gdx_swings[si].isHigh==liveLegIsBull){prevVel=gdx_swings[si].velocity;prevMag=gdx_swings[si].magnitude;break;}
   string liveTag=InpOFA_NotifyOnLiveSwing?"[live]":"[conf]";
   if(InpOFA_NotifyOnLiveSwing&&lastConfTime>0) {
      if(liveLegIsBull&&!InpOFA_NotifyBearOnly) {
         bool isNew=(lastConfTime!=gdx_LastNotifyBullTime);
         int updN=(!isNew)?GdxShouldSendOFAUpdate(liveMag,gdx_LastNotifyBullMag,gdx_LastNotifyBullUpdateN):0;
         if(isNew||updN>0) {
            string tag=isNew?liveTag:(liveTag+"UP"+IntegerToString(updN));
            string msg=GdxBuildOFANotifyMsg(sym,tf,true,livePrice>0?livePrice:lastConfPrice,liveMag,liveVel,prevVel,prevMag,lastConfTime,tag);
            if(InpOFA_SendNotification) SendNotification(msg); if(InpOFA_SendAlert2) Alert(msg);
            gdx_LastNotifyBullTime=lastConfTime; gdx_LastNotifyBullMag=liveMag; gdx_LastNotifyBullUpdateN=isNew?0:updN;
         }
      } else if(!liveLegIsBull&&!InpOFA_NotifyBullOnly) {
         bool isNew=(lastConfTime!=gdx_LastNotifyBearTime);
         int updN=(!isNew)?GdxShouldSendOFAUpdate(liveMag,gdx_LastNotifyBearMag,gdx_LastNotifyBearUpdateN):0;
         if(isNew||updN>0) {
            string tag=isNew?liveTag:(liveTag+"DN"+IntegerToString(updN));
            string msg=GdxBuildOFANotifyMsg(sym,tf,false,livePrice>0?livePrice:lastConfPrice,liveMag,liveVel,prevVel,prevMag,lastConfTime,tag);
            if(InpOFA_SendNotification) SendNotification(msg); if(InpOFA_SendAlert2) Alert(msg);
            gdx_LastNotifyBearTime=lastConfTime; gdx_LastNotifyBearMag=liveMag; gdx_LastNotifyBearUpdateN=isNew?0:updN;
         }
      }
   }
}

void RunOFAUpdate()
{
   int total=Bars(_Symbol,PERIOD_CURRENT);
   int need=InpOFA_FractalPeriod*2+2;
   if(total<need) return;

   double arr_high[], arr_low[], arr_close[], arr_open[];
   long   arr_volume[];
   datetime arr_time[];
   ArraySetAsSeries(arr_high,   false); ArraySetAsSeries(arr_low,    false);
   ArraySetAsSeries(arr_close,  false); ArraySetAsSeries(arr_open,   false);
   ArraySetAsSeries(arr_volume, false); ArraySetAsSeries(arr_time,   false);
   if(CopyHigh       (_Symbol,PERIOD_CURRENT,0,total,arr_high)        < total) return;
   if(CopyLow        (_Symbol,PERIOD_CURRENT,0,total,arr_low)         < total) return;
   if(CopyClose      (_Symbol,PERIOD_CURRENT,0,total,arr_close)       < total) return;
   if(CopyOpen       (_Symbol,PERIOD_CURRENT,0,total,arr_open)        < total) return;
   if(CopyTickVolume (_Symbol,PERIOD_CURRENT,0,total,arr_volume)      < total) return;
   if(CopyTime       (_Symbol,PERIOD_CURRENT,0,total,arr_time)        < total) return;

   bool isNewBar  = (arr_time[total-1] != gdx_LastBarTime);
   bool isNewBar2 = (arr_time[total-1] != gdx_LastBarTime2);

   if(isNewBar) {
      GdxUpdateOFACore(total,arr_time,arr_high,arr_low,arr_close,
                       gdx_LastConfirmedCount==0,arr_open,arr_volume);
      GdxDrawOFALegs();
      gdx_LastBarTime=arr_time[total-1];
   }
   GdxUpdateLiveSwing(total,arr_time,arr_high,arr_low);

   if(InpOFA_FractalPeriod2>InpOFA_FractalPeriod) {
      if(isNewBar2) {
         GdxUpdateOFACore2(total,arr_time,arr_high,arr_low,arr_close,
                           gdx_LastConfirmedCount2==0);
         GdxDrawOFALegs2();
         gdx_LastBarTime2=arr_time[total-1];
      }
      GdxUpdateLiveSwing2(total,arr_time,arr_high,arr_low);
   }

   GdxHandleOFANotifications(total);
}



//+------------------------------------------------------------------+
//| DASHBOARD HELPERS                                                |
//+------------------------------------------------------------------+
// ── วาด Background Rectangle สำหรับ Panel ──────────────────────────
void DrawPanelBG(string id, int x, int y, int w, int h,
                 color bgClr, ENUM_BASE_CORNER corner = CORNER_LEFT_UPPER)
{
   string name = OBJ_PREFIX + "BG_" + id;
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE,  x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE,  y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE,      w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE,      h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR,    bgClr);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_COLOR,      C'40,40,40');
   ObjectSetInteger(0, name, OBJPROP_CORNER,     corner);
   ObjectSetInteger(0, name, OBJPROP_BACK,       false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_ZORDER,     0);
}

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
   ObjectSetInteger(0, name, OBJPROP_ZORDER,    1);
}

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
   double sg=0,sd2=0,sgd=0,sg2=0,sdd=0;
   for(int j=0;j<period;j++){sg+=g[j];sd2+=d[j];sgd+=g[j]*d[j];sg2+=g[j]*g[j];sdd+=d[j]*d[j];}
   double den=MathSqrt(((period*sg2)-(sg*sg))*((period*sdd)-(sd2*sd2)));
   return (den<1e-10)?0:((period*sgd)-(sg*sd2))/den;
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
//| COMBINED PANEL V.5 — Helper + Button + Main Draw                 |
//+------------------------------------------------------------------+

// ── DP: Label helper สำหรับ Combined Panel ──────────────────────────
void DP(string id, string txt, int x, int y, int fs, color clr)
{
   string name = g_DP_PREFIX + id;
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetString (0, name, OBJPROP_TEXT,      txt);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE,  fs);
   ObjectSetString (0, name, OBJPROP_FONT,      "Courier New");
   ObjectSetInteger(0, name, OBJPROP_COLOR,     clr);
   ObjectSetInteger(0, name, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_ZORDER,    2);
}

// ── HTF Timeframe short name ─────────────────────────────────────────
string HTFShortName(ENUM_TIMEFRAMES tf)
{
   switch(tf) {
      case PERIOD_M15: return "M15";
      case PERIOD_M30: return "M30";
      case PERIOD_H1:  return "H1";
      case PERIOD_H4:  return "H4";
      case PERIOD_D1:  return "D1";
      default:         return EnumToString(tf);
   }
}


// ── MODERN UI HELPERS ────────────────────────────────────────────────
void DrawBox(string id, int x, int y, int w, int h, color bg, color border, int bw=1)
{
   string name = g_DP_PREFIX + "_BOX_" + id;
   if(ObjectFind(0, name) < 0) ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE,     w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE,     h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR,   bg);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, border);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE,  BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,     bw);
   ObjectSetInteger(0, name, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_ZORDER,    1);
}

void DrawStatus(string id, string label, int val, int x, int y, color txtClr=clrWhite)
{
   color dotClr = (val==1) ? clrLime : (val==-1 ? clrRed : (val==2 ? clrGold : clrGray));
   DP(id+"_L", label, x, y, 8, txtClr);
   DP(id+"_D", "●", x+70, y-1, 10, dotClr);
}

// ── DrawDashBtn: Toggle Button ──────────────────────────────────────
void DrawDashBtn()
{
   if(ObjectFind(0, g_DP_BTN) < 0) {
      ObjectCreate(0, g_DP_BTN, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, g_DP_BTN, OBJPROP_CORNER,     CORNER_LEFT_UPPER);
      ObjectSetInteger(0, g_DP_BTN, OBJPROP_XDISTANCE,  InpDashX);
      ObjectSetInteger(0, g_DP_BTN, OBJPROP_YDISTANCE,  InpDashY);
      ObjectSetInteger(0, g_DP_BTN, OBJPROP_XSIZE,      334);
      ObjectSetInteger(0, g_DP_BTN, OBJPROP_YSIZE,      18);
      ObjectSetInteger(0, g_DP_BTN, OBJPROP_FONTSIZE,   8);
      ObjectSetString (0, g_DP_BTN, OBJPROP_FONT,       "Courier New");
      ObjectSetInteger(0, g_DP_BTN, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, g_DP_BTN, OBJPROP_ZORDER,     10);
   }

   ENUM_SF_SESSION curSess = GetCurrentSession();
   string sessStr = "---";
   if(curSess==SESSION_ASIA) sessStr="ASIA";
   else if(curSess==SESSION_LONDON) sessStr="LON";
   else if(curSess==SESSION_NY_MORNING) sessStr="NY(AM)";
   else if(curSess==SESSION_NY_AFTERNOON) sessStr="NY(PM)";

   bool hb = (GoldDXYBuy != EMPTY_VALUE && GoldDXYBuy > 0);
   bool hs = (GoldDXYSell != EMPTY_VALUE && GoldDXYSell > 0);
   string sS = hb ? "BUY OK" : (hs ? "SELL OK" : "SCAN");
   color bC = hb ? clrLime : (hs ? clrRed : clrGold);

   string title = StringFormat(" %s | %s | %s | ATR:%.0f%% %s", inpEaObject, sessStr, sS, GetDailyATRConsumption()*100, (g_dashVisible ? "[^]" : "[v]"));
   ObjectSetString (0, g_DP_BTN, OBJPROP_TEXT, title);
   ObjectSetInteger(0, g_DP_BTN, OBJPROP_COLOR, bC);
   ObjectSetInteger(0, g_DP_BTN, OBJPROP_BGCOLOR, C'20,20,35');
   ObjectSetInteger(0, g_DP_BTN, OBJPROP_BORDER_COLOR, C'60,60,100');
}

// ── DrawCombinedPanel: Bento Layout V.6 ─────────────────────────────
void DrawCombinedPanel()
{
   if(!g_dashVisible) return;
   
   ENUM_SF_SESSION curSess = GetCurrentSession();
   SessionProfile dp_sp = GetSessionProfile(curSess);
   double atrConsumedP = GetDailyATRConsumption() * 100.0;
   
   double zScoreVal = 0;
   double gc[];
   if(GetSeries(_Symbol, 0, InpZPeriod, gc)) zScoreVal = ZScore(gc, InpZPeriod);

   int valS1=0, valS2=0, valS3=0, valS4=0, valS5=0, valS6=0, valS7=0;
   
   double dxy_m[], gold_m[], dxy_r[], gold_r[], dxy_t[];
   if(GetSeries(InpDXY_Symbol, 0, InpMacroBars, dxy_m) && GetSeries(_Symbol, 0, InpMacroBars, gold_m)) {
      int md = TrendDir(dxy_m, InpMacroBars), mg = TrendDir(gold_m, InpMacroBars);
      if((md==-1 && mg==+1) || (md==+1 && mg==-1)) valS1=1; else valS1=-1;
   }
   if(GetSeries(InpDXY_Symbol, 0, InpRecentBars, dxy_r) && GetSeries(_Symbol, 0, InpRecentBars, gold_r)) {
      int rd = TrendDir(dxy_r, InpRecentBars), rg = TrendDir(gold_r, InpRecentBars);
      if(valS1==1) { if((dxy_m[0]<dxy_m[1] && dxy_r[0]<dxy_r[1]) || (dxy_m[0]>dxy_m[1] && dxy_r[0]>dxy_r[1])) valS2=1; else valS2=-1; }
   }
   if(GetSeries(InpDXY_Symbol, 0, dp_sp.trigBars+1, dxy_t)) valS3=1;
   
   valS4 = (atrConsumedP < dp_sp.atrCap*100) ? 1 : -1;
   valS5 = 1;

   int hullNow = (g_hullLastWrittenIdx >= 0 && g_hullLastWrittenIdx < ArraySize(gdx_HullTrend)) ? (int)gdx_HullTrend[g_hullLastWrittenIdx] : 0;
   valS6 = (hullNow != 0) ? 1 : -1;
   valS7 = (GdxGetOFATrendAtBar(0) != 0) ? 1 : -1;

   int x = InpDashX, y = InpDashY + 20, w = 334, h = 100;
   DrawBox("MAIN", x, y, w, h, C'15,15,25', C'45,45,70', 1);

   int mx = x + 10, my = y + 10;
   DP("HDR_SIG", "SIGNAL MATRIX", mx, my, 8, clrCyan);
   DrawStatus("S1", "1.Macro",  valS1, mx, my+15);
   DrawStatus("S2", "2.Recent", valS2, mx, my+27);
   DrawStatus("S3", "3.Trigger",valS3, mx, my+39);
   DrawStatus("S4", "4.Gold",   valS4, mx, my+51);
   DrawStatus("S5", "5.MACD",   valS5, mx, my+63);

   int cx = x + 115;
   DP("HDR_MKT", "MARKET CONTEXT", cx, my, 8, clrCyan);
   DrawStatus("S6", "6.Hull", valS6, cx, my+15);
   DrawStatus("S7", "7.OFA",  valS7, cx, my+27);
   DP("VAL_ATR", StringFormat("ATR Use: %.1f%%", atrConsumedP), cx, my+45, 8, clrWhite);
   DP("VAL_Z",   StringFormat("Z-Score: %.2f", zScoreVal), cx, my+57, 8, clrWhite);
   DP("VAL_CAP", StringFormat("Limit: %.0f%%", dp_sp.atrCap*100), cx, my+69, 8, clrGray);

   int rx = x + 225;
   DP("HDR_ACC", "PERFORMANCE", rx, my, 8, clrCyan);
   double pnl = AccountInfoDouble(ACCOUNT_PROFIT);
   DP("VAL_PNL", StringFormat("PnL: $%.2f", pnl), rx, my+15, 8, (pnl>=0?clrLime:clrTomato));
   DP("VAL_DD",  StringFormat("Used: %.2f%%", AccountInfoDouble(ACCOUNT_MARGIN_LEVEL)), rx, my+27, 7, clrGray);

   string blocker = (g_lastBlockReason=="") ? "SCANNING..." : g_lastBlockReason;
   DP("VAL_BLOCK", "[!] " + blocker, mx, my+80, 8, (g_lastBlockReason=="SCAN"?clrGold:clrTomato));

   ChartRedraw();
}


//+------------------------------------------------------------------+
//| SESSION VP MONITOR                                               |
//+------------------------------------------------------------------+
bool CalcSessionVP(ENUM_TIMEFRAMES tf, datetime sessionStart, datetime sessionEnd, SessionVP &vp)
{
   MqlRates rates[];
   ArraySetAsSeries(rates, false);
   int copied = CopyRates(_Symbol, tf, sessionStart, sessionEnd, rates);
   if(copied < 3) return false;
   double maxH=-DBL_MAX, minL=DBL_MAX;
   for(int i=0;i<copied;i++) { if(rates[i].high>maxH) maxH=rates[i].high; if(rates[i].low<minL) minL=rates[i].low; }
   if(maxH<=minL) return false;
   double step = (maxH-minL)/InpVpRowSize;
   if(step<=0) return false;
   VP_Row rows[];
   if(ArrayResize(rows,InpVpRowSize)!=InpVpRowSize) return false;
   for(int k=0;k<InpVpRowSize;k++) { rows[k].priceByRow=minL+k*step; rows[k].volBuy=0; rows[k].volSell=0; rows[k].volTotal=0; }
   for(int i=0;i<copied;i++) {
      double avgP=(rates[i].high+rates[i].low)/2.0;
      int idx=(int)((avgP-minL)/step);
      if(idx>=InpVpRowSize) idx=InpVpRowSize-1; if(idx<0) idx=0;
      long vol=rates[i].tick_volume;
      bool bull=(rates[i].close>=rates[i].open);
      if(bull) rows[idx].volBuy+=(double)vol; else rows[idx].volSell+=(double)vol;
      rows[idx].volTotal+=(double)vol;
   }
   double maxVol=0, totalVol=0; int pocIdx=0;
   for(int k=0;k<InpVpRowSize;k++) { if(rows[k].volTotal>maxVol){maxVol=rows[k].volTotal;pocIdx=k;} totalVol+=rows[k].volTotal; }
   double targetVA=totalVol*InpVpValueArea, curVA=rows[pocIdx].volTotal;
   int upIdx=pocIdx, dnIdx=pocIdx;
   while(curVA<targetVA) {
      if(upIdx>=InpVpRowSize-1&&dnIdx<=0) break;
      double nu=(upIdx<InpVpRowSize-1)?rows[upIdx+1].volTotal:0;
      double nd=(dnIdx>0)?rows[dnIdx-1].volTotal:0;
      if(nu>=nd&&upIdx<InpVpRowSize-1){upIdx++;curVA+=nu;}
      else if(dnIdx>0){dnIdx--;curVA+=nd;}
      else if(upIdx<InpVpRowSize-1){upIdx++;curVA+=nu;} else break;
   }
   vp.poc=rows[pocIdx].priceByRow+(step/2.0); vp.vah=rows[upIdx].priceByRow+step; vp.val=rows[dnIdx].priceByRow;
   vp.sessionHigh=maxH; vp.sessionLow=minL; vp.sessionStart=sessionStart; vp.sessionEnd=sessionEnd; vp.isFormed=true;
   return true;
}

void DrawVPLines(string prefix, SessionVP &vp, color clrPOC, color clrVAH, color clrVAL)
{
   if(!vp.isFormed) return;
   datetime t2;
   if(InpExtendNYtoAsia && StringFind(prefix,"GDEA_SVPN_")==0) {
      MqlDateTime d; TimeToStruct(vp.sessionEnd,d);
      datetime nm=(datetime)(vp.sessionEnd-(d.hour*3600+d.min*60+d.sec)+86400);
      t2=nm+InpAsiaEndHr*3600;
   } else { t2=(datetime)(vp.sessionEnd+PeriodSeconds(PERIOD_H1)*8); }
   string nP=prefix+"POC", nH=prefix+"VAH", nL=prefix+"VAL";
   ObjectDelete(0,nP); ObjectCreate(0,nP,OBJ_TREND,0,vp.sessionStart,vp.poc,t2,vp.poc);
   ObjectSetInteger(0,nP,OBJPROP_RAY_RIGHT,false); ObjectSetInteger(0,nP,OBJPROP_COLOR,clrPOC); ObjectSetInteger(0,nP,OBJPROP_WIDTH,2); ObjectSetInteger(0,nP,OBJPROP_STYLE,STYLE_SOLID); ObjectSetInteger(0,nP,OBJPROP_BACK,true);
   ObjectSetInteger(0,nP,OBJPROP_TIME,0,vp.sessionStart); ObjectSetDouble(0,nP,OBJPROP_PRICE,0,vp.poc); ObjectSetInteger(0,nP,OBJPROP_TIME,1,t2); ObjectSetDouble(0,nP,OBJPROP_PRICE,1,vp.poc);
   ObjectDelete(0,nH); ObjectCreate(0,nH,OBJ_TREND,0,vp.sessionStart,vp.vah,t2,vp.vah);
   ObjectSetInteger(0,nH,OBJPROP_RAY_RIGHT,false); ObjectSetInteger(0,nH,OBJPROP_COLOR,clrVAH); ObjectSetInteger(0,nH,OBJPROP_WIDTH,1); ObjectSetInteger(0,nH,OBJPROP_STYLE,STYLE_DOT);  ObjectSetInteger(0,nH,OBJPROP_BACK,true);
   ObjectSetInteger(0,nH,OBJPROP_TIME,0,vp.sessionStart); ObjectSetDouble(0,nH,OBJPROP_PRICE,0,vp.vah); ObjectSetInteger(0,nH,OBJPROP_TIME,1,t2); ObjectSetDouble(0,nH,OBJPROP_PRICE,1,vp.vah);
   ObjectDelete(0,nL); ObjectCreate(0,nL,OBJ_TREND,0,vp.sessionStart,vp.val,t2,vp.val);
   ObjectSetInteger(0,nL,OBJPROP_RAY_RIGHT,false); ObjectSetInteger(0,nL,OBJPROP_COLOR,clrVAL); ObjectSetInteger(0,nL,OBJPROP_WIDTH,1); ObjectSetInteger(0,nL,OBJPROP_STYLE,STYLE_DOT);  ObjectSetInteger(0,nL,OBJPROP_BACK,true);
   ObjectSetInteger(0,nL,OBJPROP_TIME,0,vp.sessionStart); ObjectSetDouble(0,nL,OBJPROP_PRICE,0,vp.val); ObjectSetInteger(0,nL,OBJPROP_TIME,1,t2); ObjectSetDouble(0,nL,OBJPROP_PRICE,1,vp.val);
   ChartRedraw();
}

void ResetVPState(VP_STATE &state) { state=VP_WAITING; }

void CheckVPSignal(string sName, SessionVP &vp, VP_STATE &state, datetime &lastNotify,
                   color clrPOC, bool &boNotified, bool &retNotified)
{
   if(!vp.isFormed) return;
   MqlTick tk; SymbolInfoTick(_Symbol,tk);
   double ask=tk.ask, bid=tk.bid;
   double retTol=InpRetestTolerancePts, boBuf=InpBreakoutBufferPts;
   if(state==VP_WAITING) {
      if(ask>vp.vah+boBuf){state=VP_BROKEN_UP;boNotified=false;retNotified=false;}
      else if(bid<vp.val-boBuf){state=VP_BROKEN_DN;boNotified=false;retNotified=false;}
   }
   if(ask>vp.vah+boBuf&&(state==VP_BROKEN_DN||state==VP_RETESTING_VAL)){state=VP_BROKEN_UP;boNotified=false;retNotified=false;}
   else if(bid<vp.val-boBuf&&(state==VP_BROKEN_UP||state==VP_RETESTING_VAH)){state=VP_BROKEN_DN;boNotified=false;retNotified=false;}
   if(state==VP_BROKEN_UP&&bid<=vp.vah+retTol&&bid>=vp.vah-retTol){state=VP_RETESTING_VAH;retNotified=false;}
   if(state==VP_BROKEN_DN&&ask>=vp.val-retTol&&ask<=vp.val+retTol){state=VP_RETESTING_VAL;retNotified=false;}
   if(state==VP_RETESTING_VAH&&bid<vp.val-boBuf){state=VP_BROKEN_DN;boNotified=false;retNotified=false;}
   if(state==VP_RETESTING_VAL&&ask>vp.vah+boBuf){state=VP_BROKEN_UP;boNotified=false;retNotified=false;}
   // ── Quiet Hours + Init Cooldown ────────────────────────────────
   if(GDEA_IsQuietHour()) return;
   // ── Cooldown 5 นาที — ป้องกัน EA re-init ส่งซ้ำ ─────────────────
   if(TimeCurrent() - lastNotify < 300) return;
   bool notified=false;
   if(InpVpNotifyBreakout) {
      if(state==VP_BROKEN_UP&&!boNotified&&ask>vp.vah) {
         string m=StringFormat("📈 VP BREAK UP [%s] %s VAH:%s +%.2f → SELL ready",sName,_Symbol,DoubleToString(vp.vah,_Digits),(ask-vp.vah));
         Print(m); if(InpSendPush) SendNotification(m); boNotified=true; notified=true;
      } else if(state==VP_BROKEN_DN&&!boNotified&&bid<vp.val) {
         string m=StringFormat("📉 VP BREAK DN [%s] %s VAL:%s -%.2f → BUY ready",sName,_Symbol,DoubleToString(vp.val,_Digits),(vp.val-bid));
         Print(m); if(InpSendPush) SendNotification(m); boNotified=true; notified=true;
      }
   }
   if(InpVpNotifyRetest) {
      if(state==VP_RETESTING_VAH&&!retNotified&&bid<=vp.vah) {
         string m=StringFormat("↩ VP RETEST VAH [%s] %s %s≈%s → BUY setup",sName,_Symbol,DoubleToString(bid,_Digits),DoubleToString(vp.vah,_Digits));
         Print(m); if(InpSendPush) SendNotification(m); retNotified=true; notified=true;
      } else if(state==VP_RETESTING_VAL&&!retNotified&&ask>=vp.val) {
         string m=StringFormat("↩ VP RETEST VAL [%s] %s %s≈%s → SELL setup",sName,_Symbol,DoubleToString(ask,_Digits),DoubleToString(vp.val,_Digits));
         Print(m); if(InpSendPush) SendNotification(m); retNotified=true; notified=true;
      }
   }
   if(notified) lastNotify=TimeCurrent();
}

void RunSessionVP()
{
   if(!InpVpSession) return;
   MqlDateTime dt; TimeCurrent(dt); int hr=dt.hour;
   datetime today=(datetime)(TimeCurrent()-(hr*3600+dt.min*60+dt.sec));
   datetime yesterday=today-86400;
   datetime asiaStart=today+InpAsiaStartHr*3600, asiaEnd=today+InpAsiaEndHr*3600;
   datetime lndStart=today+InpLondonStartHr*3600, lndEnd=today+InpLondonEndHr*3600;
   datetime nyStart=today+InpNYStartHr*3600, nyEnd=today+InpNYEndHr*3600;
   datetime prevNyS=yesterday+InpNYStartHr*3600, prevNyE=yesterday+InpNYEndHr*3600;
   bool inAsia=(hr>=InpAsiaStartHr&&hr<InpAsiaEndHr);
   bool inLnd=(hr>=InpLondonStartHr&&hr<InpLondonEndHr);
   bool inNY=(hr>=InpNYStartHr&&hr<InpNYEndHr);
   static int lastA=-1,lastL=-1,lastN=-1;
   static datetime lastDay=0;
   int curBar=Bars(_Symbol,PERIOD_M1);
   datetime todayD=(datetime)(TimeCurrent()-(hr*3600+dt.min*60+dt.sec));
   if(todayD!=lastDay) {
      lastDay=todayD; lastA=-1;lastL=-1;lastN=-1;
      VpAsia.isFormed=false;VpLondon.isFormed=false;VpNY.isFormed=false;
      VpBreakoutNotifiedAsia=false;VpBreakoutNotifiedLondon=false;VpBreakoutNotifiedNY=false;
      VpRetestNotifiedAsia=false;VpRetestNotifiedLondon=false;VpRetestNotifiedNY=false;
      if(InpExtendNYtoAsia&&inAsia&&CalcSessionVP(PERIOD_M1,prevNyS,prevNyE,VpPrevNY)) {
         ResetVPState(VpStatePrevNY); VpBreakoutNotifiedPrevNY=false; VpRetestNotifiedPrevNY=false;
         DrawVPLines("GDEA_SVPN_",VpPrevNY,InpColorPOC_NY,InpColorVAH,InpColorVAL);
      }
   }
   static bool asiaFrozen=false;
   if(inAsia){asiaFrozen=false;}
   else if(VpAsia.isFormed&&!asiaFrozen){
      asiaFrozen=true;
      if(InpExtendNYtoAsia&&VpPrevNY.isFormed){VpPrevNY.isFormed=false;ResetVPState(VpStatePrevNY);ObjectDelete(0,"GDEA_SVPN_POC");ObjectDelete(0,"GDEA_SVPN_VAH");ObjectDelete(0,"GDEA_SVPN_VAL");}
   }
   if(!asiaFrozen&&(inAsia||hr>=InpAsiaEndHr)&&curBar!=lastA) {
      if(CalcSessionVP(PERIOD_M1,asiaStart,inAsia?TimeCurrent():asiaEnd,VpAsia)) {
         DrawVPLines("GDEA_SVPA_",VpAsia,InpColorPOC_Asia,InpColorVAH,InpColorVAL);
         if(inAsia&&lastA==-1){ResetVPState(VpStateAsia);VpBreakoutNotifiedAsia=false;VpRetestNotifiedAsia=false;}
      }
      lastA=curBar;
   }
   if(!(!inLnd&&VpLondon.isFormed)&&(inLnd||hr>=InpLondonEndHr)&&curBar!=lastL) {
      if(CalcSessionVP(PERIOD_M1,lndStart,inLnd?TimeCurrent():lndEnd,VpLondon)) {
         DrawVPLines("GDEA_SVPL_",VpLondon,InpColorPOC_London,InpColorVAH,InpColorVAL);
         if(inLnd&&lastL==-1){ResetVPState(VpStateLondon);VpBreakoutNotifiedLondon=false;VpRetestNotifiedLondon=false;}
      }
      lastL=curBar;
   }
   if(!(!inNY&&VpNY.isFormed)&&(inNY||hr>=InpNYEndHr)&&curBar!=lastN) {
      if(CalcSessionVP(PERIOD_M1,nyStart,inNY?TimeCurrent():nyEnd,VpNY)) {
         DrawVPLines("GDEA_SVPN_",VpNY,InpColorPOC_NY,InpColorVAH,InpColorVAL);
         if(inNY&&lastN==-1){ResetVPState(VpStateNY);VpBreakoutNotifiedNY=false;VpRetestNotifiedNY=false;}
      }
      lastN=curBar;
   }
   if(VpAsia.isFormed)   CheckVPSignal("Asia",  VpAsia,  VpStateAsia,  VpLastNotifyAsia,  InpColorPOC_Asia,  VpBreakoutNotifiedAsia,  VpRetestNotifiedAsia);
   if(VpLondon.isFormed) CheckVPSignal("London",VpLondon,VpStateLondon,VpLastNotifyLondon,InpColorPOC_London,VpBreakoutNotifiedLondon,VpRetestNotifiedLondon);
   if(VpNY.isFormed)     CheckVPSignal("NY",    VpNY,    VpStateNY,    VpLastNotifyNY,    InpColorPOC_NY,    VpBreakoutNotifiedNY,    VpRetestNotifiedNY);
   if(InpExtendNYtoAsia&&VpPrevNY.isFormed&&inAsia) {
      static int lastPrevNY=-1;
      if(curBar!=lastPrevNY){DrawVPLines("GDEA_SVPN_",VpPrevNY,InpColorPOC_NY,InpColorVAH,InpColorVAL);lastPrevNY=curBar;}
      static datetime prevNyNotify=0;
      CheckVPSignal("NY(prev)",VpPrevNY,VpStatePrevNY,prevNyNotify,InpColorPOC_NY,VpBreakoutNotifiedPrevNY,VpRetestNotifiedPrevNY);
   }
   if(InpVpNotifyConfl&&VpAsia.isFormed&&VpLondon.isFormed) {
      double diff=MathAbs(VpAsia.poc-VpLondon.poc);
      if(diff<=InpVpConfluenceRange) {
         // ใช้ datetime cooldown แทน bar count — ส่งได้ครั้งเดียวต่อ 30 นาที
         static datetime lastConflTime = 0;
         datetime now = TimeCurrent();
         if(!GDEA_IsQuietHour() && now - lastConflTime >= 1800) {
            string m=StringFormat("🔷 VP CONFLUENCE Asia≈London %s POC:%s/%s gap:%.2f",
                                  _Symbol,
                                  DoubleToString(VpAsia.poc,_Digits),
                                  DoubleToString(VpLondon.poc,_Digits),
                                  diff);
            Print(m); if(InpSendPush) SendNotification(m);
            lastConflTime = now;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| SESSION BOX                                                      |
//+------------------------------------------------------------------+
void DrawOneSessionBox(string tag, datetime tS, datetime tE, double hi, double lo,
   color clrBox, string lbl, bool showBrd, int brdW, bool showLbl, int lblSz, bool showHL, int hlW)
{
   string bg=SB_Prefix+tag+"_BG", brd=SB_Prefix+tag+"_BRD";
   string tx=SB_Prefix+tag+"_LBL", hn=SB_Prefix+tag+"_HI", ln2=SB_Prefix+tag+"_LO";
   int r=(int)((clrBox>>16)&0xFF),g=(int)((clrBox>>8)&0xFF),b=(int)(clrBox&0xFF);
   int rb=MathMin(255,(int)(r*1.6+40)),gb2=MathMin(255,(int)(g*1.6+40)),bb=MathMin(255,(int)(b*1.6+40));
   color bright=(color)((rb<<16)|(gb2<<8)|bb);
   // Always delete & recreate — ensures hour/color changes from Inputs take effect immediately
   ObjectDelete(0,bg); ObjectCreate(0,bg,OBJ_RECTANGLE,0,tS,hi,tE,lo);
   ObjectSetInteger(0,bg,OBJPROP_TIME,0,tS);ObjectSetDouble(0,bg,OBJPROP_PRICE,0,hi);
   ObjectSetInteger(0,bg,OBJPROP_TIME,1,tE);ObjectSetDouble(0,bg,OBJPROP_PRICE,1,lo);
   ObjectSetInteger(0,bg,OBJPROP_COLOR,clrBox);ObjectSetInteger(0,bg,OBJPROP_BACK,true);ObjectSetInteger(0,bg,OBJPROP_FILL,true);ObjectSetInteger(0,bg,OBJPROP_SELECTABLE,false);
   ObjectDelete(0,brd);
   if(showBrd){
      ObjectCreate(0,brd,OBJ_RECTANGLE,0,tS,hi,tE,lo);
      ObjectSetInteger(0,brd,OBJPROP_TIME,0,tS);ObjectSetDouble(0,brd,OBJPROP_PRICE,0,hi);
      ObjectSetInteger(0,brd,OBJPROP_TIME,1,tE);ObjectSetDouble(0,brd,OBJPROP_PRICE,1,lo);
      ObjectSetInteger(0,brd,OBJPROP_COLOR,bright);ObjectSetInteger(0,brd,OBJPROP_BACK,false);ObjectSetInteger(0,brd,OBJPROP_FILL,false);ObjectSetInteger(0,brd,OBJPROP_WIDTH,brdW);ObjectSetInteger(0,brd,OBJPROP_SELECTABLE,false);
   }
   ObjectDelete(0,tx);
   if(showLbl){
      ObjectCreate(0,tx,OBJ_TEXT,0,tS,hi);
      ObjectSetInteger(0,tx,OBJPROP_TIME,tS);ObjectSetDouble(0,tx,OBJPROP_PRICE,hi);
      ObjectSetString(0,tx,OBJPROP_TEXT,lbl);ObjectSetInteger(0,tx,OBJPROP_COLOR,bright);
      ObjectSetInteger(0,tx,OBJPROP_FONTSIZE,lblSz);ObjectSetString(0,tx,OBJPROP_FONT,"Arial Bold");
      ObjectSetInteger(0,tx,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);ObjectSetInteger(0,tx,OBJPROP_SELECTABLE,false);
   }
   ObjectDelete(0,hn); ObjectDelete(0,ln2);
   if(showHL){
      ObjectCreate(0,hn,OBJ_TREND,0,tS,hi,tE,hi);
      ObjectSetInteger(0,hn,OBJPROP_TIME,0,tS);ObjectSetDouble(0,hn,OBJPROP_PRICE,0,hi);
      ObjectSetInteger(0,hn,OBJPROP_TIME,1,tE);ObjectSetDouble(0,hn,OBJPROP_PRICE,1,hi);
      ObjectSetInteger(0,hn,OBJPROP_COLOR,bright);ObjectSetInteger(0,hn,OBJPROP_WIDTH,hlW);ObjectSetInteger(0,hn,OBJPROP_STYLE,STYLE_DASH);ObjectSetInteger(0,hn,OBJPROP_RAY_RIGHT,false);ObjectSetInteger(0,hn,OBJPROP_SELECTABLE,false);
      ObjectCreate(0,ln2,OBJ_TREND,0,tS,lo,tE,lo);
      ObjectSetInteger(0,ln2,OBJPROP_TIME,0,tS);ObjectSetDouble(0,ln2,OBJPROP_PRICE,0,lo);
      ObjectSetInteger(0,ln2,OBJPROP_TIME,1,tE);ObjectSetDouble(0,ln2,OBJPROP_PRICE,1,lo);
      ObjectSetInteger(0,ln2,OBJPROP_COLOR,bright);ObjectSetInteger(0,ln2,OBJPROP_WIDTH,hlW);ObjectSetInteger(0,ln2,OBJPROP_STYLE,STYLE_DASH);ObjectSetInteger(0,ln2,OBJPROP_RAY_RIGHT,false);ObjectSetInteger(0,ln2,OBJPROP_SELECTABLE,false);
   }
}

void DrawSessionBoxes()
{
   if(!InpShowSessionBox) return;
   int lb=MathMax(1,MathMin(7,InpSessionBoxLookbackDays));
   for(int d=0;d<lb;d++) {
      datetime bt=TimeCurrent()-d*86400;
      MqlDateTime md2; TimeToStruct(bt,md2); md2.hour=0;md2.min=0;md2.sec=0;
      datetime ds=StructToTime(md2);
      string sf=TimeToString(ds,TIME_DATE);
      StringReplace(sf,".","");StringReplace(sf,"-","");StringReplace(sf," ","");
      if(InpSessionBoxAsiaEnable){
         datetime aS=ds+InpAsiaStartHr*3600,aE=ds+InpAsiaEndHr*3600;
         if(aE>aS){int s1=iBarShift(_Symbol,PERIOD_M1,aS,false),s2=iBarShift(_Symbol,PERIOD_M1,aE,false);
            if(s1>=s2&&s2>=0){double hi=-DBL_MAX,lo=DBL_MAX;for(int bx=s2;bx<=s1;bx++){hi=MathMax(hi,iHigh(_Symbol,PERIOD_M1,bx));lo=MathMin(lo,iLow(_Symbol,PERIOD_M1,bx));}
               if(hi>lo&&hi>0) DrawOneSessionBox("ASIA_"+sf,aS,aE,hi,lo,InpSessionBoxAsiaColor,"Asia",InpSessionBoxBorder,InpSessionBoxBorderWidth,InpSessionBoxLabel,InpSessionBoxLabelSize,InpSessionBoxShowHL,InpSessionBoxHLWidth);}}
      }
      if(InpSessionBoxLondonEnable){
         datetime lS=ds+InpLondonStartHr*3600,lE=ds+InpLondonEndHr*3600;
         if(lE>lS){int s1=iBarShift(_Symbol,PERIOD_M1,lS,false),s2=iBarShift(_Symbol,PERIOD_M1,lE,false);
            if(s1>=s2&&s2>=0){double hi=-DBL_MAX,lo=DBL_MAX;for(int bx=s2;bx<=s1;bx++){hi=MathMax(hi,iHigh(_Symbol,PERIOD_M1,bx));lo=MathMin(lo,iLow(_Symbol,PERIOD_M1,bx));}
               if(hi>lo&&hi>0) DrawOneSessionBox("LDN_"+sf,lS,lE,hi,lo,InpSessionBoxLondonColor,"London",InpSessionBoxBorder,InpSessionBoxBorderWidth,InpSessionBoxLabel,InpSessionBoxLabelSize,InpSessionBoxShowHL,InpSessionBoxHLWidth);}}
      }
      if(InpSessionBoxNYEnable){
         datetime nS=ds+InpNYStartHr*3600,nE=ds+InpNYEndHr*3600;
         if(nE>nS){int s1=iBarShift(_Symbol,PERIOD_M1,nS,false),s2=iBarShift(_Symbol,PERIOD_M1,nE,false);
            if(s1>=s2&&s2>=0){double hi=-DBL_MAX,lo=DBL_MAX;for(int bx=s2;bx<=s1;bx++){hi=MathMax(hi,iHigh(_Symbol,PERIOD_M1,bx));lo=MathMin(lo,iLow(_Symbol,PERIOD_M1,bx));}
               if(hi>lo&&hi>0) DrawOneSessionBox("NY_"+sf,nS,nE,hi,lo,InpSessionBoxNYColor,"New York",InpSessionBoxBorder,InpSessionBoxBorderWidth,InpSessionBoxLabel,InpSessionBoxLabelSize,InpSessionBoxShowHL,InpSessionBoxHLWidth);}}
      }
   }
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| ATR PREVIOUS DAY LEVELS                                          |
//+------------------------------------------------------------------+

// คืนค่า ATR ของ D1 bar ก่อนหน้า (index 1)
// Phase1Fix: ใช้ global g_atr_d1_handle แทนการเปิด handle ใหม่ทุกครั้งที่เรียก
double GDEA_GetATRDaily(int period)
{
   if(g_atr_d1_handle == INVALID_HANDLE) return 0;
   double buf[];
   if(CopyBuffer(g_atr_d1_handle, 0, 1, 1, buf) != 1) return 0;
   return buf[0];
}

// ── V.19: GetATRBaseline — คืน Asia Open price สำหรับ PDATr levels ──
// ใช้ Logic เดียวกับ DrawATRLevels() เพื่อให้ baseline ตรงกัน
double GetATRBaseline()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   dt.hour = 0; dt.min = 0; dt.sec = 0;
   datetime tStart = StructToTime(dt) + InpAsiaStartHr * 3600;
   if(TimeCurrent() >= tStart)
   {
      int barIdx = iBarShift(_Symbol, PERIOD_M1, tStart, false);
      if(barIdx >= 0) {
         double b = iOpen(_Symbol, PERIOD_M1, barIdx);
         if(b > 0) return b;
      }
   }
   return GDEA_GetPrevDayClose();   // fallback
}

// ── V.19: ManageATRPartialClose — ปิด 50% เมื่อถึง PDATr M25/P25 ──
void ManageATRPartialClose()
{
   if(!InpTrendMode_Enable || !InpTrend_PartialTP) return;

   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicnumber) continue;

      int posType = (int)PositionGetInteger(POSITION_TYPE);
      double bid  = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask  = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      // ── SELL partial close ที่ ATR M25 ──
      if(posType == POSITION_TYPE_SELL && g_sell_atr_tp25 > 0 && !g_sell_partial_done)
      {
         if(bid <= g_sell_atr_tp25)
         {
            double lots     = PositionGetDouble(POSITION_VOLUME);
            double halfLots = NormalizeDouble(lots / 2.0, 2);
            double minLot   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
            if(halfLots >= minLot)
            {
               if(Trade.PositionClosePartial(ticket, halfLots))
               {
                  Print(StringFormat("[TrendMode] Partial close 50%% SELL at ATR M25 = %.5f (lots=%.2f)",
                        g_sell_atr_tp25, halfLots));
                  g_sell_partial_done = true;
               }
            }
            else {
               Print("[TrendMode] Partial close SKIP — lots too small");
               g_sell_partial_done = true;   // ไม่ต้องลองซ้ำ
            }
         }
      }

      // ── BUY partial close ที่ ATR P25 ──
      if(posType == POSITION_TYPE_BUY && g_buy_atr_tp25 > 0 && !g_buy_partial_done)
      {
         if(ask >= g_buy_atr_tp25)
         {
            double lots     = PositionGetDouble(POSITION_VOLUME);
            double halfLots = NormalizeDouble(lots / 2.0, 2);
            double minLot   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
            if(halfLots >= minLot)
            {
               if(Trade.PositionClosePartial(ticket, halfLots))
               {
                  Print(StringFormat("[TrendMode] Partial close 50%% BUY at ATR P25 = %.5f (lots=%.2f)",
                        g_buy_atr_tp25, halfLots));
                  g_buy_partial_done = true;
               }
            }
            else {
               Print("[TrendMode] Partial close SKIP — lots too small");
               g_buy_partial_done = true;
            }
         }
      }
   }
}

// คืนค่า Close ของ D1 วันก่อนหน้า (index 1) — เป็น baseline ของทุกเส้น
double GDEA_GetPrevDayClose()
{
   double buf[];
   if(CopyClose(_Symbol, PERIOD_D1, 1, 1, buf) != 1) return 0;
   return buf[0];
}

// วาดเส้นแนวนอน + label  โดยรับ tStart มาจากภายนอก (= Asia Session open time)
void GDEA_DrawATRLine(string name, double price, string text, color clr, datetime tStart, datetime tEnd)
{
   if(price <= 0) return;

   string objLine = "GDEA_ATR_L_" + name;
   string objLbl  = "GDEA_ATR_T_" + name;

   ObjectDelete(0, objLine);
   ObjectCreate(0, objLine, OBJ_TREND, 0, tStart, price, tEnd, price);
   ObjectSetInteger(0, objLine, OBJPROP_COLOR,      clr);
   ObjectSetInteger(0, objLine, OBJPROP_WIDTH,      InpATRLineWidth);
   ObjectSetInteger(0, objLine, OBJPROP_STYLE,      STYLE_DASH);
   ObjectSetInteger(0, objLine, OBJPROP_RAY_RIGHT,  false);
   ObjectSetInteger(0, objLine, OBJPROP_RAY_LEFT,   false);
   ObjectSetInteger(0, objLine, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, objLine, OBJPROP_BACK,       true);

   // Label: แสดงชื่อ + ราคา ด้านขวาของเส้น
   ObjectDelete(0, objLbl);
   ObjectCreate(0, objLbl, OBJ_TEXT, 0, tEnd, price);
   ObjectSetInteger(0, objLbl, OBJPROP_COLOR,    clr);
   ObjectSetInteger(0, objLbl, OBJPROP_FONTSIZE, InpATRLabelSize);
   ObjectSetString(0, objLbl,  OBJPROP_FONT,     "Arial Bold");
   ObjectSetString(0, objLbl,  OBJPROP_TEXT,     text + "  " + DoubleToString(price, _Digits));
   ObjectSetInteger(0, objLbl, OBJPROP_ANCHOR,   ANCHOR_LEFT);
   ObjectSetInteger(0, objLbl, OBJPROP_SELECTABLE, false);
}

// ฟังก์ชันหลัก — วาดครบทุกระดับตาม Input toggle
void DrawATRLevels()
{
   // ── ATR จาก D1 วันก่อน ──────────────────────────────────────────
   double atr = GDEA_GetATRDaily(InpATRLevelsPeriod);
   if(atr <= 0) return;

   // ── คำนวณ tStart = เวลา Asia Session วันนี้ ──────────────────────
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   dt.hour = 0; dt.min = 0; dt.sec = 0;
   datetime tBase  = StructToTime(dt);
   datetime tStart = tBase + InpAsiaStartHr * 3600;   // เช่น ตี 0 หรือ ตี 2
   dt.hour = 23; dt.min = 59; dt.sec = 59;
   datetime tEnd   = StructToTime(dt);

   // ── Baseline = Open ของแท่ง M1 แรกที่ตรงกับ Asia Start ──────────
   // ถ้า session ยังไม่ถึง (tStart > now) ใช้ PrevDayClose แทน
   double baseline = 0;
   if(TimeCurrent() >= tStart)
   {
      // หา bar index ที่ตรงกับ tStart แล้วดึง Open
      int barIdx = iBarShift(_Symbol, PERIOD_M1, tStart, false);
      if(barIdx >= 0)
         baseline = iOpen(_Symbol, PERIOD_M1, barIdx);
   }
   // fallback: ใช้ Close D1 วันก่อน ถ้าหาแท่งไม่ได้หรือ session ยังไม่เริ่ม
   if(baseline <= 0)
      baseline = GDEA_GetPrevDayClose();
   if(baseline <= 0) return;

   // ── คำนวณระดับ ───────────────────────────────────────────────────
   double p25  = atr * 0.25;
   double p50  = atr * 0.50;
   double p75  = atr * 0.75;
   double p100 = atr * 1.00;
   double p150 = atr * 1.50;
   double p200 = atr * 2.00;
   double p250 = atr * 2.50;
   double p300 = atr * 3.00;

   if(InpATRShow300)   GDEA_DrawATRLine("P300", baseline + p300, "ATR+300%", InpATRColorPlus300,  tStart, tEnd);
   if(InpATRShow250)   GDEA_DrawATRLine("P250", baseline + p250, "ATR+250%", InpATRColorPlus250,  tStart, tEnd);
   if(InpATRShow200)   GDEA_DrawATRLine("P200", baseline + p200, "ATR+200%", InpATRColorPlus200,  tStart, tEnd);
   if(InpATRShow150)   GDEA_DrawATRLine("P150", baseline + p150, "ATR+150%", InpATRColorPlus150,  tStart, tEnd);
   if(InpATRShow100)   GDEA_DrawATRLine("P100", baseline + p100, "ATR+100%", InpATRColorPlus100,  tStart, tEnd);
   if(InpATRShow75)    GDEA_DrawATRLine("P75",  baseline + p75,  "ATR+75%",  InpATRColorPlus75,   tStart, tEnd);
   if(InpATRShow50)    GDEA_DrawATRLine("P50",  baseline + p50,  "ATR+50%",  InpATRColorPlus50,   tStart, tEnd);
   if(InpATRShow25)    GDEA_DrawATRLine("P25",  baseline + p25,  "ATR+25%",  InpATRColorPlus25,   tStart, tEnd);

   if(InpATRShowClose) GDEA_DrawATRLine("CD",   baseline,        "AsiaOpen", InpATRColorClose,    tStart, tEnd);

   if(InpATRShow25)    GDEA_DrawATRLine("M25",  baseline - p25,  "ATR-25%",  InpATRColorMinus25,  tStart, tEnd);
   if(InpATRShow50)    GDEA_DrawATRLine("M50",  baseline - p50,  "ATR-50%",  InpATRColorMinus50,  tStart, tEnd);
   if(InpATRShow75)    GDEA_DrawATRLine("M75",  baseline - p75,  "ATR-75%",  InpATRColorMinus75,  tStart, tEnd);
   if(InpATRShow100)   GDEA_DrawATRLine("M100", baseline - p100, "ATR-100%", InpATRColorMinus100, tStart, tEnd);
   if(InpATRShow150)   GDEA_DrawATRLine("M150", baseline - p150, "ATR-150%", InpATRColorMinus150, tStart, tEnd);
   if(InpATRShow200)   GDEA_DrawATRLine("M200", baseline - p200, "ATR-200%", InpATRColorMinus200, tStart, tEnd);
   if(InpATRShow250)   GDEA_DrawATRLine("M250", baseline - p250, "ATR-250%", InpATRColorMinus250, tStart, tEnd);
   if(InpATRShow300)   GDEA_DrawATRLine("M300", baseline - p300, "ATR-300%", InpATRColorMinus300, tStart, tEnd);

   ChartRedraw();
}


//+------------------------------------------------------------------+
//| ORDER NOTIFICATIONS                                              |
//+------------------------------------------------------------------+

// ── Init Cooldown: 60 วินาทีแรกหลัง EA load ไม่ส่ง notification ──
bool GDEA_IsInitCooldown()
{
   return (TimeCurrent() - g_eaStartTime < 60);
}

// ── Quiet Hours + Init Cooldown guard ────────────────────────────
// ทุก notification ผ่านฟังก์ชันนี้ — ครอบคลุมทั้ง quiet hours และ init cooldown
bool GDEA_IsQuietHour()
{
   // Init cooldown 60 วินาทีแรกหลัง EA load — ป้องกัน notification flood
   if(GDEA_IsInitCooldown()) return true;

   if(InpQuietHourStart == InpQuietHourEnd) return false;
   MqlDateTime dt; TimeCurrent(dt);
   if(InpQuietHourStart < InpQuietHourEnd)
      return (dt.hour >= InpQuietHourStart && dt.hour < InpQuietHourEnd);
   return (dt.hour >= InpQuietHourStart || dt.hour < InpQuietHourEnd);
}

// ── เปิด Order ────────────────────────────────────────────────────
void NotifyOrderOpen(bool isBuy, double entry, double sl, double tp, double lots)
{
   if(!InpSendPush || GDEA_IsQuietHour()) return;

   string side   = isBuy ? "🟢 BUY " : "🔴 SELL";
   double slDist = MathAbs(entry - sl);
   double tpDist = MathAbs(tp - entry);
   double rr     = (slDist > 0) ? tpDist / slDist : 0;

   string msg = StringFormat(
      "%s %s %s SL:%s(%.2f) TP:%s(+%.2f) RR1:%.1f Lots:%.2f",
      side, _Symbol,
      DoubleToString(entry, _Digits),
      DoubleToString(sl,    _Digits), slDist,
      DoubleToString(tp,    _Digits), tpDist, rr,
      lots
   );

   Print(msg);
   SendNotification(msg);
}

// ── ปิด Order (TP / SL / Manual) — event-driven จาก broker ──────
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest&     request,
                        const MqlTradeResult&      result)
{
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD) return;

   ulong dealTicket = trans.deal;
   if(!HistoryDealSelect(dealTicket)) return;
   if(HistoryDealGetInteger(dealTicket, DEAL_ENTRY)  != DEAL_ENTRY_OUT) return;
   if(HistoryDealGetString(dealTicket,  DEAL_SYMBOL) != _Symbol)        return;
   if(HistoryDealGetInteger(dealTicket, DEAL_MAGIC)  != InpMagicnumber) return;

   // DEAL_TYPE ของ closing deal เป็น opposite ของ position
   // SELL position ปิดด้วย BUY deal → ต้องกลับทิศ
   long   dealType  = HistoryDealGetInteger(dealTicket, DEAL_TYPE);
   long   reason    = HistoryDealGetInteger(dealTicket, DEAL_REASON);
   long   ticket    = HistoryDealGetInteger(dealTicket, DEAL_ORDER);
   double closePrice= HistoryDealGetDouble(dealTicket,  DEAL_PRICE);
   double profit    = HistoryDealGetDouble(dealTicket,  DEAL_PROFIT);
   double swap      = HistoryDealGetDouble(dealTicket,  DEAL_SWAP);
   double comm      = HistoryDealGetDouble(dealTicket,  DEAL_COMMISSION);
   double netProfit = profit + swap + comm;
   string side = (dealType == DEAL_TYPE_BUY) ? "SELL" : "BUY";

   // ── V.11: อัปเดต Daily Loss Limit ───────────────────────────────
   UpdateDailyLoss(netProfit);

   string closeReason = "";
   string emoji       = "";
   if(reason == DEAL_REASON_TP) {
      closeReason = "TP Hit";
      emoji       = (netProfit >= 0) ? "🏆" : "⚠️";
   } else if(reason == DEAL_REASON_SL) {
      closeReason = "SL Hit";
      emoji       = "🛑";
   } else {
      closeReason = "SmartExit/Manual"; // เปลี่ยนชื่อให้ชัดเจนขึ้นว่า EA ปิดให้
      emoji       = (netProfit >= 0) ? "✅" : "❌"; // ถ้ากำไรใช้ติ๊กถูกสีเขียว ขาดทุนใช้กากบาทสีแดง
   }

   string resultLine = (netProfit >= 0)
      ? StringFormat("WIN  +%.2f %s", netProfit, AccountInfoString(ACCOUNT_CURRENCY))
      : StringFormat("LOSS  %.2f %s", netProfit, AccountInfoString(ACCOUNT_CURRENCY));

   // ── V.15: Enhanced close log — 2 บรรทัด ─────────────────────────
   bool   isBuyPos   = (side == "BUY");
   double openPrice  = isBuyPos ? g_buyOpenPrice  : g_sellOpenPrice;
   datetime openTime = isBuyPos ? g_buyOpenTime   : g_sellOpenTime;
   string openSess   = isBuyPos ? g_buyOpenSess   : g_sellOpenSess;
   string openHTF    = isBuyPos ? g_buyOpenHTF    : g_sellOpenHTF;
   double openZ      = isBuyPos ? g_buyOpenZ      : g_sellOpenZ;
   double openATR    = isBuyPos ? g_buyOpenATR    : g_sellOpenATR;

   int    htfDirC    = (g_hullLastWrittenIdx >= 0 && g_hullLastWrittenIdx < ArraySize(gdx_HullTrend))
                      ? (int)gdx_HullTrend[g_hullLastWrittenIdx] : 0;
   string htfClose   = (htfDirC == 1) ? "UP" : (htfDirC == -1 ? "DN" : "--");
   string sessClose  = GetSessionName(GetCurrentSession());
   long   heldMin    = (openTime > 0) ? (long)(TimeCurrent() - openTime) / 60 : 0;
   bool   htfFlipped = (openHTF != "" && openHTF != "--" && htfClose != "--" && openHTF != htfClose);

   string pnlStr  = (netProfit >= 0)
                  ? StringFormat("+$%.2f ✅", netProfit)
                  : StringFormat("-$%.2f ❌", MathAbs(netProfit));

   string logLine1 = StringFormat("[CLOSE %s] Entry=%.2f → Close=%.2f | PnL=%s | %s",
                                  side, openPrice, closePrice, pnlStr, closeReason);
   string logLine2 = StringFormat("          Held=%dmin | Open:%s(HTF:%s Z:%+.2f ATR:%.0f%%) → Close:%s(HTF:%s%s)",
                                  heldMin, openSess, openHTF, openZ, openATR,
                                  sessClose, htfClose, htfFlipped ? " ⚠️HTF_FLIP" : "");
   Print(logLine1);
   Print(logLine2);

   // ── Notification (short format) ─────────────────────────────────
   string msg = StringFormat("%s %s %s %s Close:%s #%d",
                             emoji, resultLine, _Symbol, side,
                             DoubleToString(closePrice, _Digits), ticket);
   if(InpSendPush && !GDEA_IsQuietHour()) SendNotification(msg);

   // ── Solution B V.3: นับ SameSL เฉพาะ WIN deal ──────────────────
   // นับเฉพาะเมื่อ Trade ปิดด้วยกำไร (netProfit > 0)
   // side = "BUY" หมายถึง position ที่ปิดเป็น BUY (deal type = SELL)
   if(InpSameSL_Enable && netProfit > 0)
   {
      if(side == "BUY")   // BUY position ชนะ
      {
         if(MathAbs(g_lastBuySL - 0) > _Point)  // มี SL บันทึกไว้
         {
            g_buySameSLCount++;
            if(g_buySameSLCount >= InpSameSL_MaxTrades && InpSameSL_Cooldown > 0)
            {
               g_buySameSLCooldownEnd = TimeCurrent() + InpSameSL_Cooldown * 60;
               Print(StringFormat("[SameSL] BUY WIN %d× on SL=%.2f → cooldown %d min",
                     g_buySameSLCount, g_lastBuySL, InpSameSL_Cooldown));
            }
         }
      }
      else  // SELL position ชนะ
      {
         if(MathAbs(g_lastSellSL - 0) > _Point)
         {
            g_sellSameSLCount++;
            if(g_sellSameSLCount >= InpSameSL_MaxTrades && InpSameSL_Cooldown > 0)
            {
               g_sellSameSLCooldownEnd = TimeCurrent() + InpSameSL_Cooldown * 60;
               Print(StringFormat("[SameSL] SELL WIN %d× on SL=%.2f → cooldown %d min",
                     g_sellSameSLCount, g_lastSellSL, InpSameSL_Cooldown));
            }
         }
      }
   }
   // SL hit → reset counter (ทิศเดิมหมด momentum)
   if(InpSameSL_Enable && reason == DEAL_REASON_SL)
   {
      if(side == "BUY")  { g_buySameSLCount  = 0; g_lastBuySL  = 0; g_buySameSLCooldownEnd  = 0; }
      else               { g_sellSameSLCount = 0; g_lastSellSL = 0; g_sellSameSLCooldownEnd = 0; }
   }
}


//+------------------------------------------------------------------+
//| BREAK-EVEN MANAGEMENT                                            |
//| Trigger: 1R — เมื่อราคาวิ่งได้ = SL Distance จาก Entry         |
//+------------------------------------------------------------------+
// ── Stage2 done check — ป้องกัน Stage2 วนซ้ำ ─────────────────────
bool IsStage2Done(ulong ticket)
{
   int n = ArraySize(g_stage2DoneTickets);
   for(int k = 0; k < n; k++)
      if(g_stage2DoneTickets[k] == ticket) return true;
   return false;
}

void MarkStage2Done(ulong ticket)
{
   int n = ArraySize(g_stage2DoneTickets);
   ArrayResize(g_stage2DoneTickets, n + 1);
   ArrayResize(g_stage2NotifyTime,  n + 1);
   g_stage2DoneTickets[n] = ticket;
   g_stage2NotifyTime[n]  = 0;
}

void CleanStage2Done()  // เรียกเมื่อ position ปิด — ล้าง ticket ออก
{
   int total = PositionsTotal();
   int n = ArraySize(g_stage2DoneTickets);
   for(int k = n - 1; k >= 0; k--)
   {
      bool stillOpen = false;
      for(int j = 0; j < total; j++) {
         ulong t = PositionGetTicket(j);
         if(t == g_stage2DoneTickets[k]) { stillOpen = true; break; }
      }
      if(!stillOpen) {
         for(int m = k; m < ArraySize(g_stage2DoneTickets) - 1; m++) {
            g_stage2DoneTickets[m] = g_stage2DoneTickets[m+1];
            g_stage2NotifyTime[m]  = g_stage2NotifyTime[m+1];
         }
         ArrayResize(g_stage2DoneTickets, ArraySize(g_stage2DoneTickets) - 1);
         ArrayResize(g_stage2NotifyTime,  ArraySize(g_stage2NotifyTime)  - 1);
      }
   }

   // ── ล้าง BE Lock done tickets ที่ปิดแล้ว ──────────────────
   int nb = ArraySize(g_beLockDoneTickets);
   for(int k = nb - 1; k >= 0; k--)
   {
      bool stillOpen = false;
      for(int j = 0; j < total; j++) {
         ulong t = PositionGetTicket(j);
         if(t == g_beLockDoneTickets[k]) { stillOpen = true; break; }
      }
      if(!stillOpen) {
         for(int m = k; m < ArraySize(g_beLockDoneTickets) - 1; m++)
            g_beLockDoneTickets[m] = g_beLockDoneTickets[m+1];
         ArrayResize(g_beLockDoneTickets, ArraySize(g_beLockDoneTickets) - 1);
      }
   }
}

bool IsBELockDone(ulong ticket)
{
   int n = ArraySize(g_beLockDoneTickets);
   for(int k = 0; k < n; k++)
      if(g_beLockDoneTickets[k] == ticket) return true;
   return false;
}

void MarkBELockDone(ulong ticket)
{
   int n = ArraySize(g_beLockDoneTickets);
   ArrayResize(g_beLockDoneTickets, n + 1);
   g_beLockDoneTickets[n] = ticket;
}

// ── Close positions by type ─────────────────────────────────────────

//+------------------------------------------------------------------+
//| Solution A: VP Early Exit                                         |
//| V.3 Fix: ตรวจเฉพาะ VP ของ session ที่กำลัง active ณ ปัจจุบัน  |
//| ไม่รวม PrevNY เพราะ state ค้างจากวันก่อนทำให้ false exit        |
//+------------------------------------------------------------------+
void CheckVPEarlyExit()
{
   if(!InpVPExit_Enable) return;
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) return;

   // ตรวจเฉพาะ new bar (ไม่นับซ้ำใน bar เดิม)
   datetime curBar = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(curBar == g_vpExitLastBar) return;
   g_vpExitLastBar = curBar;

   // ── ระบุ session ที่ active ณ ตอนนี้ ────────────────────────
   MqlDateTime dt; TimeCurrent(dt);
   int hr = dt.hour;
   bool inAsia   = (hr >= InpAsiaStartHr   && hr < InpAsiaEndHr);
   bool inLondon = (hr >= InpLondonStartHr && hr < InpLondonEndHr);
   bool inNY     = (hr >= InpNYStartHr     && hr < InpNYEndHr);

   // ── ตรวจ VP State เฉพาะ session ปัจจุบัน ─────────────────────
   // V.3 Fix: ไม่ใช้ PrevNY เพราะ state อาจค้าง BROKEN จากวันก่อน
   bool vpBrokenDn = false;
   bool vpBrokenUp = false;

   if(inAsia && VpAsia.isFormed) {
      if(VpStateAsia == VP_BROKEN_DN) vpBrokenDn = true;
      if(VpStateAsia == VP_BROKEN_UP) vpBrokenUp = true;
   }
   if(inLondon && VpLondon.isFormed) {
      if(VpStateLondon == VP_BROKEN_DN) vpBrokenDn = true;
      if(VpStateLondon == VP_BROKEN_UP) vpBrokenUp = true;
   }
   if(inNY && VpNY.isFormed) {
      if(VpStateNY == VP_BROKEN_DN) vpBrokenDn = true;
      if(VpStateNY == VP_BROKEN_UP) vpBrokenUp = true;
   }
   // ถ้าอยู่นอก session หลัก (เช่น ช่วง NY→Asia รอยต่อ) ไม่ trigger exit
   if(!inAsia && !inLondon && !inNY) {
      g_vpExitDnBars = 0; g_vpExitUpBars = 0;
      return;
   }

   string sesName = inAsia ? "Asia" : (inLondon ? "London" : "NY");

   // ── นับ bar confirm ────────────────────────────────────────────
   // BUY positions: ถ้า VP = BROKEN_DN → นับ bar สะสม
   // SELL positions: ถ้า VP = BROKEN_UP → นับ bar สะสม
   bool hasBuyPos  = false;
   bool hasSellPos = false;
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicnumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      long type = PositionGetInteger(POSITION_TYPE);
      if(type == POSITION_TYPE_BUY)  hasBuyPos  = true;
      if(type == POSITION_TYPE_SELL) hasSellPos = true;
   }

   // ── BUY Exit: VP Breakout DN ────────────────────────────────────
   if(hasBuyPos && vpBrokenDn)
   {
      g_vpExitDnBars++;
      if(g_vpExitDnBars >= InpVPExit_ConfirmBars)
      {
         string msg = StringFormat("📉 VP EXIT BUY %s [%s] Broken DN %dbars → closed", _Symbol, sesName, g_vpExitDnBars);
         Print(msg);
         if(InpVPExit_Notify && InpSendPush && !GDEA_IsQuietHour())
            SendNotification(msg);
         ClosePositionsByType(POSITION_TYPE_BUY);
         g_vpExitDnBars = 0;
         g_smLastEvent    = "📉 VP Exit BUY";
         g_smLastEventClr = clrOrangeRed;
         // reset BuySameSL counter — ทิศทางเปลี่ยน
         g_buySameSLCount = 0; g_lastBuySL = 0; g_buySameSLCooldownEnd = 0;
      }
   }
   else
      g_vpExitDnBars = 0;   // VP ไม่ได้ Broken DN แล้ว → reset

   // ── SELL Exit: VP Breakout UP ────────────────────────────────────
   if(hasSellPos && vpBrokenUp)
   {
      g_vpExitUpBars++;
      if(g_vpExitUpBars >= InpVPExit_ConfirmBars)
      {
         string msg = StringFormat("📈 VP EXIT SELL %s [%s] Broken UP %dbars → closed", _Symbol, sesName, g_vpExitUpBars);
         Print(msg);
         if(InpVPExit_Notify && InpSendPush && !GDEA_IsQuietHour())
            SendNotification(msg);
         ClosePositionsByType(POSITION_TYPE_SELL);
         g_vpExitUpBars = 0;
         g_smLastEvent    = "📈 VP Exit SELL";
         g_smLastEventClr = clrDodgerBlue;
         // reset SellSameSL counter — ทิศทางเปลี่ยน
         g_sellSameSLCount = 0; g_lastSellSL = 0; g_sellSameSLCooldownEnd = 0;
      }
   }
   else
      g_vpExitUpBars = 0;   // VP ไม่ได้ Broken UP แล้ว → reset
}

//+------------------------------------------------------------------+
//| V.16: HTF Hull Exit                                              |
//| เรียกเมื่อ HTF Hull (H1) พลิกทิศ — ปิด position ที่สวนทางทันที  |
//| newHTF = +1 (flip to UP) → ปิด SELL                             |
//| newHTF = -1 (flip to DN) → ปิด BUY                              |
//+------------------------------------------------------------------+
void CheckHTFExit(int newHTF)
{
   if(!InpHTFExit_Enable) return;
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) return;

   ENUM_POSITION_TYPE closeType = (newHTF == 1) ? POSITION_TYPE_SELL : POSITION_TYPE_BUY;
   string side    = (newHTF == 1) ? "SELL" : "BUY";
   string flipDir = (newHTF == 1) ? "DN→UP" : "UP→DN";

   // ตรวจว่ามี position ที่ต้องปิดไหม + คำนวณ floating PnL (รวม Swap+Commission)
   bool   hasTarget = false;
   double floatPnL  = 0;
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicnumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_TYPE) == (long)closeType) {
         hasTarget = true;
         floatPnL += PositionGetDouble(POSITION_PROFIT)
                   + PositionGetDouble(POSITION_SWAP);
      }
   }
   if(!hasTarget) return;

   // V.21: ถ้ายังติดลบอยู่ → Hold ไว้ ไม่ตัดขาดทุน รอจนกว่าจะเสมอตัวหรือกำไร
   if(floatPnL < 0)
   {
      Print(StringFormat("[HTF Exit] FLIP DETECTED but floatPnL=%.2f (Negative). HOLDING.", floatPnL));
      return;
   }

   string pnlStr = (floatPnL >= 0)
                 ? StringFormat("+$%.2f ✅", floatPnL)
                 : StringFormat("-$%.2f ❌", MathAbs(floatPnL));
   string msg = StringFormat("🔄 HTF EXIT %s | HTF %s → close %s | Float:%s",
                             _Symbol, flipDir, side, pnlStr);
   Print(msg);
   if(InpHTFExit_Notify && InpSendPush && !GDEA_IsQuietHour())
      SendNotification(msg);

   ClosePositionsByType(closeType);

   // reset SameSL counter — ทิศทางเปลี่ยนแล้ว
   if(closeType == POSITION_TYPE_BUY) {
      g_buySameSLCount = 0; g_lastBuySL = 0; g_buySameSLCooldownEnd = 0;
   } else {
      g_sellSameSLCount = 0; g_lastSellSL = 0; g_sellSameSLCooldownEnd = 0;
   }
}

void ClosePositionsByType(long posType)
{
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC)  != InpMagicnumber) continue;
      if(PositionGetString(POSITION_SYMBOL)  != _Symbol) continue;
      if(posType != -1 && PositionGetInteger(POSITION_TYPE) != posType) continue;
      Trade.PositionClose(ticket);
   }
}

// ── ตรวจ Floating Profit และปิด Order ถ้าถึงเป้า ───────────────────
void CheckProfitTarget()
{
   if(!InpProfitTarget_Enable) return;
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) return;

   // คำนวณ Floating Profit แยก BUY / SELL / Total
   double profitBuy  = 0;
   double profitSell = 0;

   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicnumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;

      double profit = PositionGetDouble(POSITION_PROFIT)
                    + PositionGetDouble(POSITION_SWAP);
      long   type   = PositionGetInteger(POSITION_TYPE);

      if(type == POSITION_TYPE_BUY)  profitBuy  += profit;
      if(type == POSITION_TYPE_SELL) profitSell += profit;
   }
   double profitTotal = profitBuy + profitSell;

   // ── ตรวจ Total Target ──────────────────────────────────────
   if(InpProfitTarget_Total > 0 && profitTotal >= InpProfitTarget_Total)
   {
      string msg = StringFormat("🎯 TARGET HIT Total:+$%.2f → All closed (B:+$%.2f S:+$%.2f)",
                                profitTotal, profitBuy, profitSell);
      Print(msg);
      if(InpProfitTarget_Notify && InpSendPush && !GDEA_IsQuietHour())
         SendNotification(msg);
      ClosePositionsByType(-1);   // ปิดทั้งหมด
      g_smLastEvent    = "🎯 Profit Target";
      g_smLastEventClr = clrGold;
      return;
   }

   // ── ตรวจ BUY Target ───────────────────────────────────────
   if(InpProfitTarget_Buy > 0 && profitBuy >= InpProfitTarget_Buy)
   {
      string msg = StringFormat("🎯 TARGET HIT BUY:+$%.2f → BUY closed", profitBuy);
      Print(msg);
      if(InpProfitTarget_Notify && InpSendPush && !GDEA_IsQuietHour())
         SendNotification(msg);
      ClosePositionsByType(POSITION_TYPE_BUY);
      g_smLastEvent    = "🎯 BUY Target";
      g_smLastEventClr = clrLimeGreen;
   }

   // ── ตรวจ SELL Target ──────────────────────────────────────
   if(InpProfitTarget_Sell > 0 && profitSell >= InpProfitTarget_Sell)
   {
      string msg = StringFormat("🎯 TARGET HIT SELL:+$%.2f → SELL closed", profitSell);
      Print(msg);
      if(InpProfitTarget_Notify && InpSendPush && !GDEA_IsQuietHour())
         SendNotification(msg);
      ClosePositionsByType(POSITION_TYPE_SELL);
      g_smLastEvent    = "🎯 SELL Target";
      g_smLastEventClr = clrOrangeRed;
   }
}

//+------------------------------------------------------------------+
//| BREAK-EVEN MANAGEMENT                                            |
//| Trigger: ทำงานเร็วขึ้นที่ 0.3R และบวกกำไรหน้าทุนตาม USD ที่ตั้งไว้    |
//+------------------------------------------------------------------+
void ManageBreakEven()
{
   // ── Guard: ถ้า auto trading ปิดอยู่ → ไม่ modify ใดๆ ──────
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) return;
   if(!MQLInfoInteger(MQL_TRADE_ALLOWED)) return;

   int total = PositionsTotal();
   for(int i = total - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicnumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;

      long   posType   = PositionGetInteger(POSITION_TYPE);
      double entry     = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentSL = PositionGetDouble(POSITION_SL);
      double tp        = PositionGetDouble(POSITION_TP);
      double lots      = PositionGetDouble(POSITION_VOLUME);
      double bid       = currentTick.bid;
      double ask       = currentTick.ask;

      // ── คำนวณ SL Distance (1R) ───────────────────────────────────
      double slDist = MathAbs(entry - currentSL);
      if(slDist <= 0) continue;

      // ── คำนวณระยะทางจาก USD ที่ต้องการล็อก ────────────────────────
      double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      if(tickSize <= 0) tickSize = _Point;
      
      double profitOffset = InpBE_BufferPts; // ค่าเริ่มต้น
      if(lots > 0 && tickValue > 0 && InpBE_ProfitUSD > 0)
      {
         // สูตรแปลงจำนวนเงิน USD ให้กลายเป็นระยะทางของราคา (Price Distance)
         profitOffset = (InpBE_ProfitUSD / (tickValue * lots)) * tickSize;
      }

      double bePrice     = 0;
      double trigger     = 0;
      bool   isTriggered = false;

      if(posType == POSITION_TYPE_BUY)
      {
         // ล็อกเป้าหมายที่ Entry + กำไรที่คำนวณได้
         bePrice     = NormalizeDouble(entry + profitOffset, _Digits);
         trigger     = entry + (slDist * InpBE_TriggerRR); 
         isTriggered = (bid >= trigger);

         // Guard BE: SL ถึง bePrice แล้ว (BE lock สำเร็จ) → ข้าม
         if(currentSL >= bePrice - _Point) continue;
      }
      else if(posType == POSITION_TYPE_SELL)
      {
         // ล็อกเป้าหมายที่ Entry - กำไรที่คำนวณได้
         bePrice     = NormalizeDouble(entry - profitOffset, _Digits);
         trigger     = entry - (slDist * InpBE_TriggerRR); 
         isTriggered = (ask <= trigger);

         // Guard BE: SL ถึง bePrice แล้ว (BE lock สำเร็จ) → ข้าม
         if(currentSL <= bePrice + _Point) continue;
      }
      else continue;

      if(!isTriggered) continue;

      // ── ป้องกัน modify ซ้ำ: ถ้า BE Lock ทำแล้ว → ข้าม ────────
      if(IsBELockDone(ticket)) continue;

      // ── ป้องกัน modify ซ้ำ: ถ้า SL ใกล้ bePrice แล้ว → ข้าม ──
      bool slAlreadyAtBE = (posType == POSITION_TYPE_BUY)
                           ? (currentSL >= bePrice - _Point)
                           : (currentSL <= bePrice + _Point);
      if(slAlreadyAtBE) continue;

      // ── [เพิ่มความปลอดภัย] เช็คระยะ Stops Level ของ Broker ──
      long stopsLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
      double minStopDist = (stopsLevel == 0 ? 10 : stopsLevel) * _Point;
      
      if(posType == POSITION_TYPE_BUY && MathAbs(bid - bePrice) < minStopDist) continue;
      if(posType == POSITION_TYPE_SELL && MathAbs(ask - bePrice) < minStopDist) continue;

      // ── ย้าย SL ไปที่ Break-Even + Lock Profit ───────────────────
      if(Trade.PositionModify(ticket, bePrice, tp))
      {
         MarkBELockDone(ticket);   // lock ไม่ให้ modify ซ้ำ
         string side = (posType == POSITION_TYPE_BUY) ? "BUY" : "SELL";
         string msg  = StringFormat(
            "🔒 BE LOCKED %s %s entry:%s SL:%s→%s (+$%.2f)",
            _Symbol, side,
            DoubleToString(entry,     _Digits),
            DoubleToString(currentSL, _Digits),
            DoubleToString(bePrice,   _Digits),
            InpBE_ProfitUSD
         );
         Print(msg);
         if(InpBE_Notify && InpSendPush && !GDEA_IsQuietHour())
            SendNotification(msg);
         g_smLastEvent    = StringFormat("🔒 BE Locked (+$%.0f)", InpBE_ProfitUSD);
         g_smLastEventClr = clrLime;
      }
   }
}


//+------------------------------------------------------------------+
//| LIQUIDITY-AWARE SL                                               |
//| ตรวจว่า SL ตกใกล้ ATR Level ไหนหรือเปล่า                        |
//| ถ้าใกล้ → เลื่อนให้พ้นโซนนั้นไปเพื่อกัน Liquidity Raid          |
//+------------------------------------------------------------------+
double AdjustSLForLiquidity(double rawSL, double entryPrice, bool isBuy)
{
   // ── ดึง ATR และ Baseline เดิมที่ใช้วาดเส้น ────────────────────
   double atr      = GDEA_GetATRDaily(InpATRLevelsPeriod);
   double baseline = GetATRBaseline();   // [V.20 fix] ใช้ Asia Open เหมือน DrawATRLevels()
   if(atr <= 0 || baseline <= 0) return rawSL;

   // ── คำนวณทุก ATR Level ────────────────────────────────────────
   double levels[16];
   levels[0]  = baseline + atr * 3.00;   // +300%
   levels[1]  = baseline + atr * 2.50;   // +250%
   levels[2]  = baseline + atr * 2.00;   // +200%
   levels[3]  = baseline + atr * 1.50;   // +150%
   levels[4]  = baseline + atr * 1.00;   // +100%
   levels[5]  = baseline + atr * 0.75;   // +75%
   levels[6]  = baseline + atr * 0.50;   // +50%
   levels[7]  = baseline + atr * 0.25;   // +25%
   levels[8]  = baseline - atr * 0.25;   // -25%
   levels[9]  = baseline - atr * 0.50;   // -50%
   levels[10] = baseline - atr * 0.75;   // -75%
   levels[11] = baseline - atr * 1.00;   // -100%
   levels[12] = baseline - atr * 1.50;   // -150%
   levels[13] = baseline - atr * 2.00;   // -200%
   levels[14] = baseline - atr * 2.50;   // -250%
   levels[15] = baseline - atr * 3.00;   // -300%

   string levelNames[16] = {
      "ATR+300%","ATR+250%","ATR+200%","ATR+150%","ATR+100%","ATR+75%","ATR+50%","ATR+25%",
      "ATR-25%","ATR-50%","ATR-75%","ATR-100%","ATR-150%","ATR-200%","ATR-250%","ATR-300%"
   };

   double zonePts  = InpLiqSL_Zone;          // price value โดยตรง ไม่ต้อง × _Point
   double atrBuf   = atr * InpLiqSL_Buffer;  // buffer = ATR × 0.3
   double adjustedSL = rawSL;
   string hitLevel   = "";

   // ── ตรวจทุก Level ─────────────────────────────────────────────
   for(int k = 0; k < 16; k++)
   {
      double dist = MathAbs(rawSL - levels[k]);
      if(dist > zonePts) continue;   // ไม่ใกล้ level นี้ — ข้าม

      // SL ตกใกล้ Level นี้ → เลื่อนให้พ้นไปอีกด้าน
      if(isBuy)
      {
         // BUY: SL อยู่ใต้ entry → เลื่อน SL ลงให้ต่ำกว่า Level + buffer
         double candidate = NormalizeDouble(levels[k] - atrBuf, _Digits);
         if(candidate < adjustedSL) adjustedSL = candidate;
      }
      else
      {
         // SELL: SL อยู่เหนือ entry → เลื่อน SL ขึ้นให้สูงกว่า Level + buffer
         double candidate = NormalizeDouble(levels[k] + atrBuf, _Digits);
         if(candidate > adjustedSL) adjustedSL = candidate;
      }
      hitLevel = levelNames[k];
   }

   // ── Cap SL ไม่ให้กว้างเกินกำหนด ──────────────────────────────
   double rawDist      = MathAbs(rawSL - entryPrice);
   double adjustedDist = MathAbs(adjustedSL - entryPrice);

   // Cap 1: Adjusted ต้องไม่เกิน Original × Multiplier
   if(InpMaxSL_Multiplier > 0 && rawDist > 0)
   {
      double maxAllowed = rawDist * InpMaxSL_Multiplier;
      if(adjustedDist > maxAllowed)
      {
         adjustedSL = isBuy
                      ? NormalizeDouble(entryPrice - maxAllowed, _Digits)
                      : NormalizeDouble(entryPrice + maxAllowed, _Digits);
         Print(StringFormat("[LiqSL Cap] SL capped at %.1f× Original: %s → %s",
               InpMaxSL_Multiplier,
               DoubleToString(rawSL, _Digits),
               DoubleToString(adjustedSL, _Digits)));
      }
   }

   // Cap 2: Hard cap distance สูงสุด
   // [V.1.29] TrendMode ใช้ InpTrendMode_MaxSL (400) แทน InpMaxSL_Distance (80)
   //          เพราะ TrendMode SL = ATR(D1)×2 ≈ 370 pts > Normal cap 80 pts
   adjustedDist = MathAbs(adjustedSL - entryPrice);
   double maxSLToUse = (g_trendmode_active && InpTrendMode_MaxSL > 0)
                       ? InpTrendMode_MaxSL
                       : InpMaxSL_Distance;
   if(maxSLToUse > 0 && adjustedDist > maxSLToUse)
   {
      datetime _bar = iTime(_Symbol,PERIOD_M1,0);
      if(isBuy) {
         if(g_blk_liqsl_buy_bar != _bar) {
            g_blk_liqsl_buy_bar = _bar;
            Print(StringFormat("[LiqSL Cap] SL distance %.2f > MaxDistance %.2f → Skip trade",
                  adjustedDist, maxSLToUse));
         }
      } else {
         if(g_blk_liqsl_sell_bar != _bar) {
            g_blk_liqsl_sell_bar = _bar;
            Print(StringFormat("[LiqSL Cap] SL distance %.2f > MaxDistance %.2f → Skip trade",
                  adjustedDist, maxSLToUse));
         }
      }
      return 0;   // คืน 0 = caller ต้องตรวจและไม่เปิด Order
   }

   // ── Log และแจ้งเตือนถ้า SL ถูกปรับ ───────────────────────────
   if(MathAbs(adjustedSL - rawSL) > _Point)
   {
      string side = isBuy ? "BUY" : "SELL";
      string msg  = StringFormat(
         "🛡 SL ADJ %s %s near:%s SL:%s→%s",
         _Symbol, side,
         hitLevel,
         DoubleToString(rawSL,      _Digits),
         DoubleToString(adjustedSL, _Digits)
      );
      Print(msg);
      if(InpLiqSL_Notify && InpSendPush && !GDEA_IsQuietHour())
         SendNotification(msg);
   }

   return adjustedSL;
}


//+------------------------------------------------------------------+
//| LIQUIDITY ZONE BOX SYSTEM                                        |
//+------------------------------------------------------------------+

// ── วาด Rectangle Box + Label (ซ้ายบน, ข้อมูลครบ) ────────────────
void DrawLiqBox(string tag, datetime tS, datetime tE,
                double hi, double lo, color clr, string lbl, int fillAlpha = 255,
                long swingVol = 0, double swingOpen = 0,
                double swingHigh = 0, double swingLow = 0, double swingClose = 0)
{
   string bg  = LIQ_PREFIX + tag + "_BG";
   string brd = LIQ_PREFIX + tag + "_BRD";
   string tx  = LIQ_PREFIX + tag + "_LBL";

   // border color สว่างกว่า fill
   int r = (int)((clr>>16)&0xFF), g2=(int)((clr>>8)&0xFF), b2=(int)(clr&0xFF);
   color bclr = (color)((MathMin(255,r+80)<<16)|(MathMin(255,g2+80)<<8)|MathMin(255,b2+80));

   // fill color ปรับความเข้มตาม fillAlpha (0=ดำ, 255=สีเต็ม)
   double factor = MathMax(0.0, MathMin(1.0, fillAlpha / 255.0));
   color  fclr   = (color)(((int)(r*factor)<<16)|((int)(g2*factor)<<8)|(int)(b2*factor));

   // ── BG Rectangle — update ถ้ามีอยู่แล้ว ──────────────────────
   if(ObjectFind(0, bg) < 0) ObjectCreate(0, bg, OBJ_RECTANGLE, 0, tS, hi, tE, lo);
   ObjectSetInteger(0, bg, OBJPROP_TIME,  0, tS);
   ObjectSetDouble(0,  bg, OBJPROP_PRICE, 0, hi);
   ObjectSetInteger(0, bg, OBJPROP_TIME,  1, tE);
   ObjectSetDouble(0,  bg, OBJPROP_PRICE, 1, lo);
   ObjectSetInteger(0, bg, OBJPROP_COLOR,      fclr);   // ใช้ fclr ที่ปรับ alpha แล้ว
   ObjectSetInteger(0, bg, OBJPROP_BACK,       true);
   ObjectSetInteger(0, bg, OBJPROP_FILL,       true);
   ObjectSetInteger(0, bg, OBJPROP_SELECTABLE, false);

   // ── Border Rectangle ─────────────────────────────────────────
   if(ObjectFind(0, brd) < 0) ObjectCreate(0, brd, OBJ_RECTANGLE, 0, tS, hi, tE, lo);
   ObjectSetInteger(0, brd, OBJPROP_TIME,  0, tS);
   ObjectSetDouble(0,  brd, OBJPROP_PRICE, 0, hi);
   ObjectSetInteger(0, brd, OBJPROP_TIME,  1, tE);
   ObjectSetDouble(0,  brd, OBJPROP_PRICE, 1, lo);
   ObjectSetInteger(0, brd, OBJPROP_COLOR,      bclr);
   ObjectSetInteger(0, brd, OBJPROP_BACK,       false);
   ObjectSetInteger(0, brd, OBJPROP_FILL,       false);
   ObjectSetInteger(0, brd, OBJPROP_WIDTH,      1);
   ObjectSetInteger(0, brd, OBJPROP_SELECTABLE, false);

   // ── Label รวมบรรทัดเดียว: "BUY STOPS (Swing) 4753.00  🟢 1.5K ↑1.2K ↓0.3K Δ+0.9K" ──
   string fullText = lbl + " " + DoubleToString(hi, _Digits);

   if(swingVol > 0)
   {
      // Option A: Tick Volume + Emoji ตามแท่ง
      string volK  = DoubleToString((double)swingVol / 1000.0, 1) + "K";
      string emoji = (swingClose > swingOpen) ? "🟢" : "🔴";

      // Option B: Delta Volume
      string deltaStr = "";
      double range = swingHigh - swingLow;
      if(range > _Point)
      {
         double buyVol  = (double)swingVol * (swingClose - swingLow)  / range;
         double sellVol = (double)swingVol * (swingHigh  - swingClose) / range;
         double delta   = buyVol - sellVol;
         string bK = DoubleToString(buyVol  / 1000.0, 1) + "K";
         string sK = DoubleToString(sellVol / 1000.0, 1) + "K";
         string dK = (delta >= 0 ? "Δ+" : "Δ") + DoubleToString(MathAbs(delta) / 1000.0, 1) + "K";
         if(delta < 0) dK = "Δ-" + DoubleToString(MathAbs(delta) / 1000.0, 1) + "K";
         deltaStr = " ↑" + bK + " ↓" + sK + " " + dK;
      }
      fullText = lbl + " " + DoubleToString(hi, _Digits) + "  " + emoji + " " + volK + deltaStr;
   }
   if(ObjectFind(0, tx) < 0) ObjectCreate(0, tx, OBJ_TEXT, 0, tS, hi);
   ObjectSetInteger(0, tx, OBJPROP_TIME,       tS);
   ObjectSetDouble(0,  tx, OBJPROP_PRICE,      hi);
   ObjectSetString(0,  tx, OBJPROP_TEXT,       fullText);
   ObjectSetInteger(0, tx, OBJPROP_COLOR,      bclr);
   ObjectSetInteger(0, tx, OBJPROP_FONTSIZE,   7);
   ObjectSetString(0,  tx, OBJPROP_FONT,       "Arial Bold");
   ObjectSetInteger(0, tx, OBJPROP_ANCHOR,     ANCHOR_LEFT_LOWER);
   ObjectSetInteger(0, tx, OBJPROP_SELECTABLE, false);
}

// ── ลงทะเบียน Zone — preserve state ถ้า Zone ราคาเดิมยังอยู่ ──────
void RegisterLiqZone(double hi, double lo, string lbl, bool isBuyStops)
{
   // ค้นหาว่ามี Zone นี้อยู่แล้วหรือเปล่า (match ด้วย label + ราคาใกล้กัน)
   int n = ArraySize(g_liqZones);
   for(int k = 0; k < n; k++)
   {
      if(g_liqZones[k].label == lbl &&
         MathAbs(g_liqZones[k].zoneHigh - hi) < _Point * 5 &&
         MathAbs(g_liqZones[k].zoneLow  - lo) < _Point * 5)
      {
         // Zone เดิม — อัปเดตราคาเท่านั้น ไม่รีเซ็ต state
         g_liqZones[k].zoneHigh = hi;
         g_liqZones[k].zoneLow  = lo;
         return;
      }
   }
   // Zone ใหม่ — เพิ่มเข้า array
   ArrayResize(g_liqZones, n + 1);
   g_liqZones[n].zoneHigh        = hi;
   g_liqZones[n].zoneLow         = lo;
   g_liqZones[n].priceWasInside  = false;
   g_liqZones[n].raidNotified    = false;
   g_liqZones[n].enterNotified   = false;
   g_liqZones[n].lastEnterTime   = 0;
   g_liqZones[n].lastExitTime    = 0;
   g_liqZones[n].entryFromPrice  = 0;
   g_liqZones[n].isBuyStopsZone  = isBuyStops;
   g_liqZones[n].label           = lbl;
}

// ── ฟังก์ชันหลัก — วาดทุก Box ────────────────────────────────────
void DrawLiquidityBoxes()
{
   // ไม่ reset g_liqZones[] ทั้งหมด — RegisterLiqZone จะ preserve state เอง
   // แต่ trim Zone เก่าที่ไม่ได้ถูก register รอบนี้ออก
   // (ทำโดย mark ทุก Zone เป็น "pending" ก่อน แล้วลบที่ไม่ถูก touch)

   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   dt.hour = 23; dt.min = 59; dt.sec = 59;
   datetime tEnd = StructToTime(dt);
   dt.hour = 0;  dt.min = 0;  dt.sec = 0;
   datetime tStart = StructToTime(dt);

   // เก็บจำนวน Zone ก่อนรอบนี้เพื่อ trim ภายหลัง
   int prevCount = ArraySize(g_liqZones);

   // ════════════════════════════════════════════════════
   // ชั้นที่ 1 — Swing High/Low Liquidity Box
   // ════════════════════════════════════════════════════
   if(InpLiqBox_ShowSwing && gdx_LastConfirmedCount > 1)
   {
      double atr = GDEA_GetATRDaily(InpATRLevelsPeriod);
      double halfZone = (atr > 0) ? atr * InpLiqBox_SwingFactor : 0.50;
      int startIdx = MathMax(0, gdx_LastConfirmedCount - InpLiqBox_SwingLookback);

      for(int i = startIdx; i < gdx_LastConfirmedCount; i++)
      {
         GDX_SwingPoint sp = gdx_swings[i];
         double hi, lo;
         string lbl;
         color  clr;
         bool   isBuyStops;

         if(sp.isHigh) {
            hi  = sp.price + halfZone;
            lo  = sp.price - halfZone * 0.3;
            lbl = "SELL STOPS (Swing)";
            clr = InpLiqBox_SellStopClr;
            isBuyStops = false;
         } else {
            hi  = sp.price + halfZone * 0.3;
            lo  = sp.price - halfZone;
            lbl = "BUY STOPS (Swing)";
            clr = InpLiqBox_BuyStopClr;
            isBuyStops = true;
         }

         string tag = StringFormat("SW%d_%s", i, sp.isHigh ? "H" : "L");
         DrawLiqBox(tag, sp.time, tEnd, hi, lo, clr, lbl, 255,
                    sp.volume, sp.open, sp.high, sp.low, sp.close);
         RegisterLiqZone(hi, lo, lbl, isBuyStops);
      }
   }

   // ════════════════════════════════════════════════════
   // ชั้นที่ 3 — Equal High / Equal Low Box (EQH/EQL)
   // ════════════════════════════════════════════════════
   if(InpLiqBox_ShowEQHL && gdx_LastConfirmedCount > 2)
   {
      double tolPts = InpLiqBox_EQLTol * _Point;
      int startIdx  = MathMax(0, gdx_LastConfirmedCount - InpLiqBox_SwingLookback);

      for(int i = startIdx; i < gdx_LastConfirmedCount - 1; i++)
      {
         for(int j = i + 1; j < gdx_LastConfirmedCount; j++)
         {
            if(gdx_swings[i].isHigh != gdx_swings[j].isHigh) continue;
            double diff = MathAbs(gdx_swings[i].price - gdx_swings[j].price);
            if(diff > tolPts) continue;

            double midPrice  = (gdx_swings[i].price + gdx_swings[j].price) / 2.0;
            double hi = midPrice + tolPts;
            double lo = midPrice - tolPts;
            bool   isBuyStops = !gdx_swings[i].isHigh;   // EQL=BUY STOPS, EQH=SELL STOPS
            string lbl = gdx_swings[i].isHigh ? "EQH — SELL STOPS" : "EQL — BUY STOPS";
            string tag = StringFormat("EQ%s%d_%d",
                         gdx_swings[i].isHigh ? "H" : "L", i, j);

            DrawLiqBox(tag, gdx_swings[i].time, tEnd, hi, lo,
                       InpLiqBox_EQHLClr, lbl);
            RegisterLiqZone(hi, lo, lbl, isBuyStops);
            break;
         }
      }
   }

   ChartRedraw();
}

// ── ตรวจ Raid ทุก tick ────────────────────────────────────────────
void CheckLiquidityRaid()
{
   if(!InpLiqBox_Notify || GDEA_IsQuietHour()) return;

   double bid = currentTick.bid;
   double ask = currentTick.ask;
   double mid = (bid + ask) / 2.0;
   datetime now = TimeCurrent();

   // ── Dedup + Global Cooldown: ส่ง Enter ได้แค่ 1 ข้อความต่อ 5 นาที ทั้งระบบ ──
   // เลือก Zone ที่ราคาอยู่ใน และใกล้ราคาที่สุด แล้วส่งแค่อันเดียว
   int    closestEnterIdx  = -1;
   double closestEnterDist = DBL_MAX;

   // ถ้า Global cooldown ยังไม่ครบ → ไม่ต้องหา Zone เลย
   bool globalCooldownOK = (now - g_liqLastGlobalEnter >= 300);

   int n = ArraySize(g_liqZones);
   if(globalCooldownOK)
   {
      for(int i = 0; i < n; i++)
      {
         double hi = g_liqZones[i].zoneHigh;
         double lo = g_liqZones[i].zoneLow;
         if(mid < lo || mid > hi) continue;           // ไม่อยู่ใน Zone นี้
         if(now - g_liqZones[i].lastExitTime < 300) continue;  // cooldown หลัง exit

         double center = (hi + lo) / 2.0;
         double dist   = MathAbs(mid - center);
         if(dist < closestEnterDist) {
            closestEnterDist = dist;
            closestEnterIdx  = i;
         }
      }
   }

   // ── จุดที่ 10: Enter — ส่งเฉพาะ Zone ที่ใกล้ที่สุด 1 ข้อความ ──
   if(closestEnterIdx >= 0 && InpLiqBox_NotifyEnter)
   {
      int i = closestEnterIdx;
      double hi = g_liqZones[i].zoneHigh;
      double lo = g_liqZones[i].zoneLow;

      if(!g_liqZones[i].priceWasInside)
         g_liqZones[i].entryFromPrice = mid;

      string msg = StringFormat(
         "⚠️ LIQ ENTER %s %s %s-%s price:%s",
         _Symbol, g_liqZones[i].label,
         DoubleToString(lo, _Digits),
         DoubleToString(hi, _Digits),
         DoubleToString(mid, _Digits)
      );
      Print(msg);
      if(InpSendPush) SendNotification(msg);
      g_liqZones[i].enterNotified  = true;
      g_liqZones[i].lastEnterTime  = now;
      g_liqZones[i].priceWasInside = true;
      g_liqLastGlobalEnter         = now;  // update global cooldown
   }

   // ── track priceWasInside สำหรับทุก Zone (แม้ไม่ส่ง Enter) ──
   for(int i = 0; i < n; i++)
   {
      double hi = g_liqZones[i].zoneHigh;
      double lo = g_liqZones[i].zoneLow;
      if(mid >= lo && mid <= hi)
         g_liqZones[i].priceWasInside = true;
   }

   // ── จุดที่ 11: Raid/Breakout — ตรวจทุก Zone ──────────────────
   for(int i = 0; i < n; i++)
   {
      if(!g_liqZones[i].priceWasInside)  continue;
      if(g_liqZones[i].raidNotified)     continue;
      if(!InpLiqBox_NotifyRaid)          continue;

      double hi     = g_liqZones[i].zoneHigh;
      double lo     = g_liqZones[i].zoneLow;
      bool   inside = (mid >= lo && mid <= hi);
      if(inside) continue;   // ยังอยู่ใน Zone

      bool exitedUp   = (mid > hi);
      bool exitedDown = (mid < lo);
      bool isBuy      = g_liqZones[i].isBuyStopsZone;

      bool isRaid     = (isBuy && exitedUp) || (!isBuy && exitedDown);
      bool isBreakout = (isBuy && exitedDown) || (!isBuy && exitedUp);

      string raidEmoji;
      string raidType;
      if(isRaid && isBuy)        { raidEmoji="🎯"; raidType="RAIDED BUY STOPS"; }
      else if(isRaid && !isBuy)  { raidEmoji="🎯"; raidType="RAIDED SELL STOPS"; }
      else if(isBreakout && isBuy)  { raidEmoji="🔽"; raidType="BREAK BUY STOPS"; }
      else                          { raidEmoji="🔼"; raidType="BREAK SELL STOPS"; }

      string exitDir = exitedUp ? "→↑" : "→↓";
      string msg = StringFormat(
         "%s %s %s %s-%s %s%s",
         raidEmoji, raidType, _Symbol,
         DoubleToString(lo, _Digits),
         DoubleToString(hi, _Digits),
         exitDir,
         DoubleToString(mid, _Digits)
      );
      Print(msg);
      if(InpSendPush) SendNotification(msg);

      // ── Update SM Panel Last Event ──────────────────────────
      g_smLastEvent    = isRaid ? (isBuy ? "🎯 BUY STOPS Raided!" : "🎯 SELL STOPS Raided!")
                                : (isBuy ? "🔽 Breakout BUY STOPS" : "🔼 Breakout SELL STOPS");
      g_smLastEventClr = isRaid ? clrGold : clrDodgerBlue;

      // ── reset state + บันทึก lastExitTime ──────────────────
      g_liqZones[i].raidNotified   = true;
      g_liqZones[i].priceWasInside = false;
      g_liqZones[i].enterNotified  = false;
      g_liqZones[i].lastExitTime   = now;   // cooldown 5 นาที ก่อน Enter ใหม่
   }
}


//+------------------------------------------------------------------+
//| VP SESSION FILTER — STEP 8                                       |
//| Double-confirm ด้วย VP ของ Session ปัจจุบัน + Session ก่อนหน้า  |
//+------------------------------------------------------------------+

// ── หา VP ที่ใช้งาน 2 ตัวตาม Session ปัจจุบัน ───────────────────
// Asia   → vp1=VpAsia,    vp2=VpPrevNY
// London → vp1=VpLondon,  vp2=VpAsia
// NY     → vp1=VpNY,      vp2=VpLondon
void GetActiveSessionVPs(SessionVP &vp1, SessionVP &vp2,
                         VP_STATE  &st1, VP_STATE  &st2)
{
   MqlDateTime dt; TimeCurrent(dt); int hr = dt.hour;
   bool inAsia   = (hr >= InpAsiaStartHr   && hr < InpAsiaEndHr);
   bool inLondon = (hr >= InpLondonStartHr && hr < InpLondonEndHr);
   bool inNY     = (hr >= InpNYStartHr     && hr < InpNYEndHr);

   if(inAsia) {
      vp1 = VpAsia;    st1 = VpStateAsia;
      vp2 = VpPrevNY;  st2 = VpStatePrevNY;
   } else if(inLondon) {
      vp1 = VpLondon;  st1 = VpStateLondon;
      vp2 = VpAsia;    st2 = VpStateAsia;
   } else if(inNY) {
      vp1 = VpNY;      st1 = VpStateNY;
      vp2 = VpLondon;  st2 = VpStateLondon;
   } else {
      // นอก Session หลัก → ใช้ NY + London
      vp1 = VpNY;      st1 = VpStateNY;
      vp2 = VpLondon;  st2 = VpStateLondon;
   }
}

// ── ตรวจ Entry Zone: BUY ต้องอยู่ฝั่ง Discount ─────────────────
// ผ่าน = ราคาอยู่ใกล้ VAL ± zone pts หรือต่ำกว่า POC
bool CheckVPEntryZoneBuy(const SessionVP &vp, double zoneDist)
{
   if(!vp.isFormed) return true;
   double price  = currentTick.ask;
   bool nearVAL  = (price <= vp.val + zoneDist);
   bool belowPOC = (price < vp.poc);
   return (nearVAL || belowPOC);
}

bool CheckVPEntryZoneSell(const SessionVP &vp, double zoneDist)
{
   if(!vp.isFormed) return true;
   double price  = currentTick.bid;
   bool nearVAH  = (price >= vp.vah - zoneDist);
   bool abovePOC = (price > vp.poc);
   return (nearVAH || abovePOC);
}

// ── ตรวจ VP State สำหรับ BUY ────────────────────────────────────
// ผ่าน = VP State เป็น UP หรือ Retesting VAH (กำลัง Retest แนวรับ)
bool CheckVPStateBuy(const SessionVP &vp, VP_STATE st)
{
   if(!vp.isFormed) return true;
   return (st == VP_BROKEN_UP    ||
           st == VP_RETESTING_VAH ||
           st == VP_WAITING);      // ยังไม่ Broken = ยังใน Value Area
}

// ── ตรวจ VP State สำหรับ SELL ───────────────────────────────────
bool CheckVPStateSell(const SessionVP &vp, VP_STATE st)
{
   if(!vp.isFormed) return true;
   return (st == VP_BROKEN_DN    ||
           st == VP_RETESTING_VAL ||
           st == VP_WAITING);
}

// ── ตรวจ Retest สำหรับ BUY ──────────────────────────────────────
// ผ่าน = ราคากำลัง Retest VAH ที่เพิ่ง Break (กลับมาทดสอบ Support)
bool CheckVPRetestBuy(const SessionVP &vp, VP_STATE st)
{
   if(!vp.isFormed) return true;
   bool afterBreakout = (st == VP_BROKEN_UP || st == VP_RETESTING_VAH);
   double dist = MathAbs(currentTick.ask - vp.vah);
   bool nearVAH = (dist <= InpVP_EntryZonePts);   // price value โดยตรง
   if(!afterBreakout) return true;
   return nearVAH;
}

bool CheckVPRetestSell(const SessionVP &vp, VP_STATE st)
{
   if(!vp.isFormed) return true;
   bool afterBreakout = (st == VP_BROKEN_DN || st == VP_RETESTING_VAL);
   double dist = MathAbs(currentTick.bid - vp.val);
   bool nearVAL = (dist <= InpVP_EntryZonePts);   // price value โดยตรง
   if(!afterBreakout) return true;
   return nearVAL;
}

// ── Main Filter: BUY — ตรวจทั้ง vp1 และ vp2 ─────────────────────
bool CheckVPFilterBuy()
{
   SessionVP vp1, vp2;
   VP_STATE  st1, st2;
   GetActiveSessionVPs(vp1, vp2, st1, st2);

   // ตรวจ vp1 (Session ปัจจุบัน) — ถ้าไม่ formed → skip
   bool ok1_zone   = !InpVP_UseEntryZone || CheckVPEntryZoneBuy(vp1, InpVP_EntryZonePts);
   bool ok1_state  = !InpVP_UseBreakout  || CheckVPStateBuy(vp1, st1);
   bool ok1_retest = !InpVP_UseRetest    || CheckVPRetestBuy(vp1, st1);
   bool pass1 = (ok1_zone && ok1_state && ok1_retest);

   // ตรวจ vp2 (Session ก่อนหน้า) — ถ้าไม่ formed → ผ่านอัตโนมัติ
   bool ok2_zone   = !InpVP_UseEntryZone || CheckVPEntryZoneBuy(vp2, InpVP_EntryZonePts);
   bool ok2_state  = !InpVP_UseBreakout  || CheckVPStateBuy(vp2, st2);
   bool ok2_retest = !InpVP_UseRetest    || CheckVPRetestBuy(vp2, st2);
   bool pass2 = (ok2_zone && ok2_state && ok2_retest);

   if(!pass1 || !pass2) {
      Print(StringFormat(
         "[VP Filter] BUY BLOCKED  vp1:%s(zone=%s state=%s retest=%s)"
         "  vp2:%s(zone=%s state=%s retest=%s)",
         vp1.isFormed?"OK":"--", ok1_zone?"✓":"✗", ok1_state?"✓":"✗", ok1_retest?"✓":"✗",
         vp2.isFormed?"OK":"--", ok2_zone?"✓":"✗", ok2_state?"✓":"✗", ok2_retest?"✓":"✗"
      ));
   }
   return (pass1 && pass2);
}

// ── Main Filter: SELL ─────────────────────────────────────────────
bool CheckVPFilterSell()
{
   SessionVP vp1, vp2;
   VP_STATE  st1, st2;
   GetActiveSessionVPs(vp1, vp2, st1, st2);

   bool ok1_zone   = !InpVP_UseEntryZone || CheckVPEntryZoneSell(vp1, InpVP_EntryZonePts);
   bool ok1_state  = !InpVP_UseBreakout  || CheckVPStateSell(vp1, st1);
   bool ok1_retest = !InpVP_UseRetest    || CheckVPRetestSell(vp1, st1);
   bool pass1 = (ok1_zone && ok1_state && ok1_retest);

   bool ok2_zone   = !InpVP_UseEntryZone || CheckVPEntryZoneSell(vp2, InpVP_EntryZonePts);
   bool ok2_state  = !InpVP_UseBreakout  || CheckVPStateSell(vp2, st2);
   bool ok2_retest = !InpVP_UseRetest    || CheckVPRetestSell(vp2, st2);
   bool pass2 = (ok2_zone && ok2_state && ok2_retest);

   if(!pass1 || !pass2) {
      Print(StringFormat(
         "[VP Filter] SELL BLOCKED  vp1:%s(zone=%s state=%s retest=%s)"
         "  vp2:%s(zone=%s state=%s retest=%s)",
         vp1.isFormed?"OK":"--", ok1_zone?"✓":"✗", ok1_state?"✓":"✗", ok1_retest?"✓":"✗",
         vp2.isFormed?"OK":"--", ok2_zone?"✓":"✗", ok2_state?"✓":"✗", ok2_retest?"✓":"✗"
      ));
   }
   return (pass1 && pass2);
}

// ── TP จาก VP Level (ถ้า InpVP_UseTPTarget = true) ───────────────
// เรียกใน OpenBuyPosition / OpenSellPosition แทน Fixed RR
double GetVPTargetTP(bool isBuy, double entry, double slDist)
{
   SessionVP vp1, vp2;
   VP_STATE  st1, st2;
   GetActiveSessionVPs(vp1, vp2, st1, st2);

   double minTP = isBuy ? entry + slDist : entry - slDist; // minimum RR 1:1

   if(isBuy) {
      // TP เป้าหมาย: POC ก่อน แล้ว VAH ถ้าไกลกว่า
      double tp = (vp1.isFormed && vp1.poc > minTP) ? vp1.poc : minTP;
      if(vp1.isFormed && vp1.vah > tp) tp = vp1.vah;
      return NormalizeDouble(tp, _Digits);
   } else {
      double tp = (vp1.isFormed && vp1.poc < minTP) ? vp1.poc : minTP;
      if(vp1.isFormed && vp1.val < tp) tp = vp1.val;
      return NormalizeDouble(tp, _Digits);
   }
}


// ── ดึงข้อมูล SL ของ Position ที่เปิดอยู่ ─────────────────────────
// ── ดึงสถานะ LiqZone Filter สำหรับแสดงใน Panel ────────────────────
// isSell: true=ตรวจฝั่ง SELL, false=ตรวจฝั่ง BUY
// คืน string + สี
string GetLiqFilterStatus(bool isSell, double entry, color &outClr)
{
   if(!InpLiqZone_Filter) { outClr = clrDimGray; return "OFF"; }

   int n = ArraySize(g_liqZones);
   if(n == 0) { outClr = clrLimeGreen; return "No Zone"; }

   // เก็บ Zone ที่ตรงทิศ + distance
   double bestDist  = DBL_MAX;
   double bestLevel = 0;
   bool   bestRaided = false;

   for(int i = 0; i < n; i++)
   {
      LiqZoneState z = g_liqZones[i];
      double dist = -1;

      if(isSell)
      {
         if(!z.isBuyStopsZone) continue;
         if(z.zoneHigh >= entry) continue;
         dist = entry - z.zoneHigh;
         if(dist < bestDist) { bestDist = dist; bestLevel = z.zoneHigh; bestRaided = z.raidNotified; }
      }
      else
      {
         if(z.isBuyStopsZone) continue;
         if(z.zoneLow <= entry) continue;
         dist = z.zoneLow - entry;
         if(dist < bestDist) { bestDist = dist; bestLevel = z.zoneLow; bestRaided = z.raidNotified; }
      }
   }

   if(bestDist == DBL_MAX) { outClr = clrLimeGreen; return "Clear"; }

   string zoneName = isSell ? "BuyStop" : "SellStop";
   string raidTag  = bestRaided ? " ✓Raid" : "";

   // Block: ใกล้กว่า MinDist และยังไม่ Raided
   if(bestDist < InpLiqZone_MinDist && !(InpLiqZone_AllowRaid && bestRaided))
   {
      outClr = clrTomato;
      return StringFormat("⛔ %s %.0f ↕%.0f%s", zoneName, bestLevel, bestDist, raidTag);
   }

   // Warning: ใกล้กว่า MinDist×2
   if(bestDist < InpLiqZone_MinDist * 2.0)
   {
      outClr = clrYellow;
      return StringFormat("⚠️ %s %.0f ↕%.0f%s", zoneName, bestLevel, bestDist, raidTag);
   }

   // Clear
   outClr = clrLimeGreen;
   return StringFormat("✅ %s %.0f ↕%.0f%s", zoneName, bestLevel, bestDist, raidTag);
}

string GetCurrentSLInfo(double &slDist)
{
   slDist = 0;
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicnumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;

      double entry = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl    = PositionGetDouble(POSITION_SL);
      long   type  = PositionGetInteger(POSITION_TYPE);
      slDist = MathAbs(entry - sl);

      // ตรวจว่า SL อยู่ใกล้ Swing ไหม
      string method = "ATR";
      if(InpUseSwingSL)
      {
         if(gdx_LastConfirmedCount >= 2)
         {
            for(int k = gdx_LastConfirmedCount-1; k >= 0; k--)
            {
               double swPrice = gdx_swings[k].price;
               if(MathAbs(sl - (swPrice + (type==POSITION_TYPE_BUY?-1:1)*InpSwingBuffer)) < 1.0)
               {
                  method = "Swing";
                  break;
               }
            }
         }
      }
      return StringFormat("SL   : %s  %.2f  ↕%.2f", method,
                          NormalizeDouble(sl,_Digits), slDist);
   }
   return "SL   : --";
}

// ── ดึงข้อมูล TP Method + Level ตาม Session ────────────────────────
string GetCurrentTPInfo(string &tpMethod, double &tpLevel, double &tpDist)
{
   tpMethod = ""; tpLevel = 0; tpDist = 0;

   // Session ปัจจุบัน
   MqlDateTime dt; TimeCurrent(dt);
   int hr = dt.hour;
   bool inAsia   = (hr >= InpAsiaStartHr   && hr < InpAsiaEndHr);
   bool inLondon = (hr >= InpLondonStartHr && hr < InpLondonEndHr);
   bool inNY     = (hr >= InpNYStartHr     && hr < InpNYEndHr);

   string sessName = inAsia ? "Asia" : inLondon ? "London" : inNY ? "NY" : "Off";

   // ATR Daily
   double atr1d  = GDEA_GetATRDaily(InpATRLevelsPeriod);
   double factor = inAsia ? 0.50 : inLondon ? 0.75 : inNY ? 1.00 : 0.50;
   string factorStr = inAsia ? "×50%" : inLondon ? "×75%" : inNY ? "×100%" : "×50%";

   // AsiaOpen baseline
   double baseline = 0;
   {
      MqlDateTime dtB; TimeToStruct(TimeCurrent(), dtB);
      dtB.hour=0; dtB.min=0; dtB.sec=0;
      datetime tBase = StructToTime(dtB) + InpAsiaStartHr*3600;
      int barIdx = iBarShift(_Symbol, PERIOD_M1, tBase, false);
      if(barIdx >= 0) baseline = iOpen(_Symbol, PERIOD_M1, barIdx);
      if(baseline <= 0) baseline = GDEA_GetPrevDayClose();
   }

   // Today Range ที่วิ่งไปแล้ว
   double todayHigh = iHigh(_Symbol, PERIOD_D1, 0);
   double todayLow  = iLow (_Symbol, PERIOD_D1, 0);
   double todayRange = todayHigh - todayLow;
   double remaining  = MathMax(atr1d - todayRange, atr1d * 0.20);

   // Position ที่เปิดอยู่
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicnumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;

      double entry = PositionGetDouble(POSITION_PRICE_OPEN);
      double tp    = PositionGetDouble(POSITION_TP);
      long   type  = PositionGetInteger(POSITION_TYPE);
      tpDist = MathAbs(tp - entry);

      // TP Method ที่ใช้จริง (ตรวจจาก Input)
      if(InpVP_FilterEnable && InpVP_UseTPTarget)
         tpMethod = StringFormat("%s VP-POC", sessName);
      else if(InpUseSwingTP)
         tpMethod = StringFormat("%s Swing", sessName);
      else
         tpMethod = StringFormat("%s RR×%.1f", sessName, InpRR);

      tpLevel = tp;
      return StringFormat("TP   : %s  %.2f  ↕%.2f", tpMethod,
                          NormalizeDouble(tp,_Digits), tpDist);
   }

   // ไม่มี Position — แสดง Estimate
   double bid = currentTick.bid;
   double estTP = 0;
   if(baseline > 0 && atr1d > 0)
   {
      // BUY estimate
      estTP = baseline + remaining * factor;
      tpLevel = NormalizeDouble(estTP, _Digits);
   }
   tpMethod = StringFormat("%s ATR%s", sessName, factorStr);
   tpDist   = MathAbs(tpLevel - bid);

   return StringFormat("TP   : %s  Est:%.2f", tpMethod,
                       NormalizeDouble(tpLevel,_Digits));
}

// ── ATR Info line ───────────────────────────────────────────────────
string GetATRInfoLine()
{
   double atr1d = GDEA_GetATRDaily(InpATRLevelsPeriod);
   double todayRange = iHigh(_Symbol,PERIOD_D1,0) - iLow(_Symbol,PERIOD_D1,0);
   double remaining  = MathMax(atr1d - todayRange, 0);

   // ตรวจ High Vol Warning
   string warn = "";
   if(atr1d > 0 && todayRange / atr1d > 1.3) warn = " ⚠️HiVol";
   else if(atr1d > 0 && todayRange / atr1d < 0.4) warn = " 💤LoVol";

   return StringFormat("ATR  : $%.0f  Ran:$%.0f  Rem:$%.0f%s",
                       atr1d, todayRange, remaining, warn);
}

// ── ดึงสถานะ LiqZone Filter สำหรับ BUY หรือ SELL ──────────────────
string GetFilterStatusLine(bool isSell, double entry, color &outClr)
{
   string side   = isSell ? "SELL" : "BUY";
   string oppZone = isSell ? "BUY STOPS" : "SELL STOPS";

   if(!InpLiqZone_Filter)
   {
      outClr = clrDimGray;
      return StringFormat("%-4s : Filter OFF", side);
   }

   int n = ArraySize(g_liqZones);
   if(n == 0)
   {
      outClr = clrLimeGreen;
      return StringFormat("%-4s : ✅ No Zone", side);
   }

   // หา Zone ที่ใกล้สุดตรงทิศ
   double bestDist  = DBL_MAX;
   double bestLevel = 0;
   bool   bestRaided = false;

   for(int i = 0; i < n; i++)
   {
      LiqZoneState z = g_liqZones[i];
      double dist = -1;

      if(isSell)
      {
         if(!z.isBuyStopsZone) continue;
         if(z.zoneHigh >= entry) continue;
         dist = entry - z.zoneHigh;
         if(dist < bestDist) { bestDist = dist; bestLevel = z.zoneHigh; bestRaided = z.raidNotified; }
      }
      else
      {
         if(z.isBuyStopsZone) continue;
         if(z.zoneLow <= entry) continue;
         dist = z.zoneLow - entry;
         if(dist < bestDist) { bestDist = dist; bestLevel = z.zoneLow; bestRaided = z.raidNotified; }
      }
   }

   if(bestDist == DBL_MAX)
   {
      outClr = clrLimeGreen;
      return StringFormat("%-4s : ✅ No %s", side, oppZone);
   }

   // Zone Raided แล้ว → อนุญาต
   if(InpLiqZone_AllowRaid && bestRaided)
   {
      outClr = clrLimeGreen;
      return StringFormat("%-4s : ✅ Raided  %.0f ↕%.0f",
                          side, bestLevel, bestDist);
   }

   // Block หรือ Warning
   if(bestDist < InpLiqZone_MinDist)
   {
      outClr = clrTomato;
      return StringFormat("%-4s : ⛔ %s  %.0f ↕%.0f",
                          side, oppZone, bestLevel, bestDist);
   }
   else if(bestDist < InpLiqZone_MinDist * 2)
   {
      outClr = clrYellow;
      return StringFormat("%-4s : ⚠️ %s  %.0f ↕%.0f",
                          side, oppZone, bestLevel, bestDist);
   }
   else
   {
      outClr = clrLimeGreen;
      return StringFormat("%-4s : ✅ %s  %.0f ↕%.0f",
                          side, oppZone, bestLevel, bestDist);
   }
}

//+------------------------------------------------------------------+
//| SMART MONEY STATUS PANEL                                         |
//+------------------------------------------------------------------+

void SMP(string id, string txt, color clr, int x, int &y, int fs=8)
{
   string name = "GDEA_SMP_" + id;
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetString (0, name, OBJPROP_TEXT,      txt);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE,  fs);
   ObjectSetString (0, name, OBJPROP_FONT,      "Courier New");
   ObjectSetInteger(0, name, OBJPROP_COLOR,     clr);
   ObjectSetInteger(0, name, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR,    ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_ZORDER,    1);
   y += (fs + 5);
}

void DrawSMPanel()
{
   MqlDateTime dt; TimeCurrent(dt);
   int hr = dt.hour;
   double bid = currentTick.bid;
   double ask = currentTick.ask;
   double mid = (bid + ask) / 2.0;

   int x = InpSMPanelX;
   int y = InpDashY + 470;   // ต่อจาก Dashboard (460px) + gap 10px

   // ── Background SM Panel ────────────────────────────────────
   {
      string bgName = "GDEA_SMP_BG";
      if(ObjectFind(0, bgName) < 0)
         ObjectCreate(0, bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, bgName, OBJPROP_XDISTANCE,  x - 5);
      ObjectSetInteger(0, bgName, OBJPROP_YDISTANCE,  y - 5);
      ObjectSetInteger(0, bgName, OBJPROP_XSIZE,      275);
      ObjectSetInteger(0, bgName, OBJPROP_YSIZE,      390);   // ขยายจาก 250 → 320
      ObjectSetInteger(0, bgName, OBJPROP_BGCOLOR,    C'15,15,25');
      ObjectSetInteger(0, bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, bgName, OBJPROP_COLOR,      C'50,50,80');
      ObjectSetInteger(0, bgName, OBJPROP_CORNER,     CORNER_LEFT_UPPER);
      ObjectSetInteger(0, bgName, OBJPROP_BACK,       false);
      ObjectSetInteger(0, bgName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, bgName, OBJPROP_ZORDER,     0);
   }

   // ── Session ────────────────────────────────────────────────
   string sessName = "Off-Hours";
   color  sessClr  = clrGray;
   bool inAsia   = (hr >= InpAsiaStartHr   && hr < InpAsiaEndHr);
   bool inLondon = (hr >= InpLondonStartHr && hr < InpLondonEndHr);
   bool inNY     = (hr >= InpNYStartHr     && hr < InpNYEndHr);
   if(inAsia)   { sessName = "Asia";    sessClr = clrDeepSkyBlue; }
   if(inLondon) { sessName = "London";  sessClr = clrOrange; }
   if(inNY)     { sessName = "New York"; sessClr = clrDodgerBlue; }

   // ── Trend (7 Steps) ────────────────────────────────────────
   bool hasBuy  = (GoldDXYBuy  != EMPTY_VALUE && GoldDXYBuy  > 0);
   bool hasSell = (GoldDXYSell != EMPTY_VALUE && GoldDXYSell > 0);
   string trendStr; color trendClr;
   if(hasBuy)       { trendStr = "BUY SETUP  ✓";  trendClr = clrLime; }
   else if(hasSell) { trendStr = "SELL SETUP ✓";  trendClr = clrRed; }
   else             { trendStr = "SCANNING...";    trendClr = clrGold; }

   // ── Smart Money — หาว่ารายใหญ่กำลังทำอะไร ─────────────────
   string smStr  = "Accumulating";
   color  smClr  = clrGray;
   int    n      = ArraySize(g_liqZones);
   double closestDist = DBL_MAX;
   int    closestIdx  = -1;

   for(int i = 0; i < n; i++) {
      double center = (g_liqZones[i].zoneHigh + g_liqZones[i].zoneLow) / 2.0;
      double dist   = MathAbs(mid - center);
      if(dist < closestDist) { closestDist = dist; closestIdx = i; }
   }

   if(closestIdx >= 0) {
      LiqZoneState z = g_liqZones[closestIdx];
      bool inside = (mid >= z.zoneLow && mid <= z.zoneHigh);
      bool nearby = (closestDist <= (z.zoneHigh - z.zoneLow));

      if(z.raidNotified && !z.priceWasInside) {
         // Raid เสร็จแล้ว
         smStr = z.isBuyStopsZone ? "BUY STOPS Raided ✅" : "SELL STOPS Raided ✅";
         smClr = clrGold;
      } else if(inside) {
         smStr = z.isBuyStopsZone ? "Hunting BUY STOPS 🏹" : "Hunting SELL STOPS 🏹";
         smClr = clrOrangeRed;
      } else if(nearby) {
         smStr = z.isBuyStopsZone ? "Near BUY STOPS ⚠️" : "Near SELL STOPS ⚠️";
         smClr = clrYellow;
      }
   }

   // ── VP Status — ใช้ VpStateToStr ────────────────────────────
   string liqStr = "Clear — No Zone";
   color  liqClr = clrSilver;
   if(closestIdx >= 0) {
      LiqZoneState z = g_liqZones[closestIdx];
      bool inside = (mid >= z.zoneLow && mid <= z.zoneHigh);
      if(inside) {
         liqStr = StringFormat("IN: %s [%.0f-%.0f]",
                  z.isBuyStopsZone ? "BUY STOPS" : "SELL STOPS",
                  z.zoneLow, z.zoneHigh);
         liqClr = z.isBuyStopsZone ? clrDeepSkyBlue : clrOrangeRed;
      } else {
         double pct = closestDist / (z.zoneHigh - z.zoneLow) * 100.0;
         liqStr = StringFormat("Near: %s (%.0f%% away)",
                  z.isBuyStopsZone ? "BUY STOPS" : "SELL STOPS", pct);
         liqClr = clrYellow;
      }
   }

   // ── Draw Panel ─────────────────────────────────────────────
   SMP("HDR",  "[ SMART MONEY STATUS ]", clrWhite,   x, y, 9); y+=2;
   SMP("SEP0", "─────────────────────", clrDimGray,  x, y, 8);
   SMP("SESS", StringFormat("SESSION : %s", sessName), sessClr, x, y);
   SMP("SEP1", "─────────────────────", clrDimGray,  x, y, 8);
   SMP("TRND", StringFormat("TREND   : %s", trendStr), trendClr, x, y);
   SMP("SM",   StringFormat("SMART $ : %s", smStr),    smClr,    x, y);
   SMP("LIQ",  StringFormat("LIQ     : %s", liqStr),   liqClr,   x, y);
   SMP("SEP2", "─────────────────────", clrDimGray,  x, y, 8);

   // VP rows
   string vpAStr = VpStateToStr("Asia",   VpAsia,   VpStateAsia);
   string vpLStr = VpStateToStr("London", VpLondon, VpStateLondon);
   string vpNStr = VpStateToStr("NY",     VpNY,     VpStateNY);
   SMP("VPA",  vpAStr, VpAsia.isFormed   ? clrDeepPink    : clrDimGray, x, y);
   SMP("VPL",  vpLStr, VpLondon.isFormed ? clrDarkOrange  : clrDimGray, x, y);
   SMP("VPN",  vpNStr, VpNY.isFormed     ? clrDodgerBlue  : clrDimGray, x, y);
   SMP("SEP3", "─────────────────────", clrDimGray, x, y, 8);
   SMP("EVT",  StringFormat("EVENT   : %s", g_smLastEvent), g_smLastEventClr, x, y);
   SMP("SEP4", "─────────────────────", clrDimGray, x, y, 8);

   // ── LiqZone Filter Status ──────────────────────────────────
   double filterEntry = (bid + ask) / 2.0;
   color  sellFltClr, buyFltClr;
   string sellFltStr = GetLiqFilterStatus(true,  filterEntry, sellFltClr);
   string buyFltStr  = GetLiqFilterStatus(false, filterEntry, buyFltClr);
   SMP("FLT_S", StringFormat("SELL    : %s", sellFltStr), sellFltClr, x, y);
   SMP("FLT_B", StringFormat("BUY     : %s", buyFltStr),  buyFltClr,  x, y);
   SMP("SEP5", "─────────────────────", clrDimGray, x, y, 8);

   // ── SL / TP Info ───────────────────────────────────────────
   double slDist=0, tpLevel=0, tpDist=0;
   string tpMethod="";
   string slLine = GetCurrentSLInfo(slDist);
   string tpLine = GetCurrentTPInfo(tpMethod, tpLevel, tpDist);
   string atrLine = GetATRInfoLine();

   // สี SL — แดงถ้า SL กว้าง (>30 USD) เหลืองถ้าปานกลาง เขียวถ้าแคบ
   color slClr = slDist > 30 ? clrTomato : slDist > 15 ? clrYellow : clrLimeGreen;
   if(slDist == 0) slClr = clrDimGray;

   // สี TP — เขียวถ้า TP ใกล้ (สมเหตุสมผล) เหลืองถ้าไกล
   color tpClr = tpDist > 80 ? clrYellow : tpDist > 40 ? clrLimeGreen : clrAquamarine;
   if(tpDist == 0) tpClr = clrDeepSkyBlue;

   SMP("SL",   slLine,  slClr,          x, y);
   SMP("TP",   tpLine,  tpClr,          x, y);
   SMP("ATR",  atrLine, clrDeepSkyBlue, x, y);

   // ── Profit Target Status ───────────────────────────────────
   if(InpProfitTarget_Enable)
   {
      double pBuy=0, pSell=0;
      for(int i=PositionsTotal()-1; i>=0; i--)
      {
         ulong t = PositionGetTicket(i);
         if(!PositionSelectByTicket(t)) continue;
         if(PositionGetInteger(POSITION_MAGIC) != InpMagicnumber) continue;
         if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
         double p = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)  pBuy  += p;
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL) pSell += p;
      }
      double pTotal = pBuy + pSell;

      string ptLine = StringFormat("B:$%.0f/$%.0f  S:$%.0f/$%.0f  T:$%.0f/$%.0f",
                                   pBuy,  InpProfitTarget_Buy,
                                   pSell, InpProfitTarget_Sell,
                                   pTotal, InpProfitTarget_Total);

      color ptClr = clrDimGray;
      if(InpProfitTarget_Total > 0 && pTotal >= InpProfitTarget_Total * 0.8) ptClr = clrYellow;
      if(InpProfitTarget_Buy   > 0 && pBuy   >= InpProfitTarget_Buy   * 0.8) ptClr = clrYellow;
      if(InpProfitTarget_Sell  > 0 && pSell  >= InpProfitTarget_Sell  * 0.8) ptClr = clrYellow;
      if(InpProfitTarget_Total > 0 && pTotal >= InpProfitTarget_Total)        ptClr = clrGold;

      SMP("PT", StringFormat("TARGET  : %s", ptLine), ptClr, x, y);
   }
}

string VpStateToStr(string sName, const SessionVP &vp, VP_STATE st)
{
   if(!vp.isFormed) return StringFormat("%-6s: --", sName);
   string stStr;
   switch(st) {
      case VP_BROKEN_UP:     stStr = "▲ BROKEN UP";  break;
      case VP_BROKEN_DN:     stStr = "▼ BROKEN DN";  break;
      case VP_RETESTING_VAH: stStr = "↩ RETEST VAH"; break;
      case VP_RETESTING_VAL: stStr = "↪ RETEST VAL"; break;
      default:               stStr = "● WAITING";     break;
   }
   return StringFormat("%-6s: POC=%.0f %s", sName, vp.poc, stStr);
}

//+------------------------------------------------------------------+
//| FIBONACCI RETRACEMENT — OFA p26 (ก่อนสุดท้าย) + p50 (ล่าสุด)   |
//+------------------------------------------------------------------+

// helper: วาด Fib 3 เส้นพร้อม Label สำหรับ Swing คู่หนึ่ง
// ── Zone description ตาม Fib level (ใช้ใน Notification) ────────────
string FibZoneDesc(string pct)
{
   if(pct == "38.2%")  return "⭐⭐ Shallow retrace | Trend strong";
   if(pct == "50.0%")  return "⭐⭐ Decision zone | bull/bear battle";
   if(pct == "61.8%")  return "⭐⭐⭐ Golden Ratio | Reversal zone";
   if(pct == "78.6%")  return "⭐⭐⭐ Deep retrace | Last chance";
   if(pct == "100%")   return "⭐⭐ Full retrace | Double top/bot";
   if(pct == "127.2%") return "⭐⭐⭐ Extension | Breakout confirm";
   if(pct == "161.8%") return "⭐⭐⭐ Golden Extension | Target";
   if(pct == "261.8%") return "⭐⭐ Extended run | Momentum extreme";
   if(pct == "-61.8%") return "⭐⭐⭐ Golden Extension DN | Target";
   if(pct=="-127.2%")  return "⭐⭐⭐ Extension DN | Breakout confirm";
   if(pct=="-261.8%")  return "⭐⭐ Extended run DN | Momentum extreme";
   return "";
}

// ── ตรวจและส่ง Notification เมื่อราคาแตะ Fib level ──────────────────
// [V.20c] fibLabel = "[P26] 50.0%" style | dirCtx = "BUY" / "SELL"
// [V.22]  เพิ่ม FibZoneDesc ใน message | pct = "61.8%" ฯลฯ ตรงกับ FibZoneDesc key
//         tolerance เปลี่ยนเป็น fixed 0.50 USD (เดิม ±0.01% ≈ ±0.44 USD แคบเกินไป)
void CheckFibNotify(double fibLevel, string fibLabel, string pct, string dirCtx,
                    datetime &lastNotify, double &lastLevel)
{
   if(!InpFib_Notify || !InpSendPush) return;
   if(GDEA_IsQuietHour()) return;
   if(fibLevel <= 0) return;

   // ถ้า Level เปลี่ยน = Swing ใหม่ → reset cooldown
   if(MathAbs(fibLevel - lastLevel) > _Point * 10)
   {
      lastLevel  = fibLevel;
      lastNotify = 0;
   }

   // Cooldown 30 นาที ต่อ Level
   datetime now = TimeCurrent();
   if(now - lastNotify < 1800) return;

   double price = currentTick.bid;
   double tolerance = 0.50;

   if(MathAbs(price - fibLevel) <= tolerance)
   {
      string dir  = (price >= fibLevel) ? "↑" : "↓";
      string desc = FibZoneDesc(pct);
      string msg  = StringFormat("📊 %s | %s | %s | %s | Lv:%.2f | Now:%.2f%s",
                                 fibLabel,
                                 dirCtx,
                                 desc,
                                 _Symbol,
                                 fibLevel,
                                 price,
                                 dir);
      Print(msg);
      SendNotification(msg);
      lastNotify = now;
   }
}

void DrawFibSet(string prefix,
                double priceHigh, double priceLow,
                datetime tStart,  datetime tLabelAt,
                color c382, color c50, color c618, color cN618, color c1618,
                int lineWidth, int labelSize, string tag)
{
   if(priceHigh <= priceLow) return;
   double range = priceHigh - priceLow;

   // [V.22] 11 เส้น: Retracement + Extension ครบตามตาราง
   double fib[11];
   fib[0]  = priceHigh + range * 1.618;   // 261.8% Extension บน
   fib[1]  = priceHigh + range * 0.618;   // 161.8% Extension บน
   fib[2]  = priceHigh + range * 0.272;   // 127.2% Extension บน
   fib[3]  = priceHigh - range * 0.382;   // 38.2%  Retracement
   fib[4]  = priceHigh - range * 0.500;   // 50.0%  Retracement
   fib[5]  = priceHigh - range * 0.618;   // 61.8%  Retracement
   fib[6]  = priceHigh - range * 0.786;   // 78.6%  Retracement
   fib[7]  = priceLow;                    // 100%   Full Retracement
   fib[8]  = priceLow  - range * 0.272;   // -127.2% Extension ล่าง
   fib[9]  = priceLow  - range * 0.618;   // -61.8%  Extension ล่าง (เดิม)
   fib[10] = priceLow  - range * 1.618;   // -261.8% Extension ล่าง

   string labels[11] = {"261.8%","161.8%","127.2%","38.2%","50.0%","61.8%","78.6%","100%","-127.2%","-61.8%","-261.8%"};
   // Extension = c1618 โทน, Retracement ใช้สีเดิม, ของใหม่ใช้สีผสม
   color  colors[11] = {c1618, c1618, c1618, c382, c50, c618, c618, c382, cN618, cN618, cN618};

   for(int k = 0; k < 11; k++)
   {
      string lineName = prefix + tag + "L" + IntegerToString(k);
      string txtName  = prefix + tag + "T" + IntegerToString(k);
      double lvl = fib[k];
      color  clr = colors[k];

      if(ObjectFind(0, lineName) < 0)
         ObjectCreate(0, lineName, OBJ_TREND, 0, tStart, lvl, tLabelAt, lvl);
      ObjectSetInteger(0, lineName, OBJPROP_TIME,   0, tStart);
      ObjectSetDouble(0,  lineName, OBJPROP_PRICE,  0, lvl);
      ObjectSetInteger(0, lineName, OBJPROP_TIME,   1, tLabelAt);
      ObjectSetDouble(0,  lineName, OBJPROP_PRICE,  1, lvl);
      ObjectSetInteger(0, lineName, OBJPROP_COLOR,  clr);
      ObjectSetInteger(0, lineName, OBJPROP_WIDTH,  lineWidth);
      // Extension (k<=2 หรือ k>=8) = STYLE_DOT, Retracement = STYLE_DASH
      int style = (k <= 2 || k >= 8) ? STYLE_DOT : STYLE_DASH;
      ObjectSetInteger(0, lineName, OBJPROP_STYLE,  style);
      ObjectSetInteger(0, lineName, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, lineName, OBJPROP_BACK,   true);
      ObjectSetInteger(0, lineName, OBJPROP_SELECTABLE, false);

      string lblText = tag + " " + labels[k] + "  " + DoubleToString(lvl, _Digits);
      if(ObjectFind(0, txtName) < 0)
         ObjectCreate(0, txtName, OBJ_TEXT, 0, tLabelAt, lvl);
      ObjectSetInteger(0, txtName, OBJPROP_TIME,     tLabelAt);
      ObjectSetDouble(0,  txtName, OBJPROP_PRICE,    lvl);
      ObjectSetString(0,  txtName, OBJPROP_TEXT,     " " + lblText);
      ObjectSetInteger(0, txtName, OBJPROP_COLOR,    clr);
      ObjectSetInteger(0, txtName, OBJPROP_FONTSIZE, labelSize);
      ObjectSetString(0,  txtName, OBJPROP_FONT,     "Arial Bold");
      ObjectSetInteger(0, txtName, OBJPROP_ANCHOR,   ANCHOR_LEFT);
      ObjectSetInteger(0, txtName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, txtName, OBJPROP_BACK,     false);
   }
}

void DrawFibRetracement()
{
   datetime tNow = iTime(_Symbol, PERIOD_M1, 0);

   // ══ p26 Fib: Swing ก่อนสุดท้าย (N-2 → N-1) ══════════════════
   if(InpFib_Enable && gdx_LastConfirmedCount >= 2)
   {
      GDX_SwingPoint s0 = gdx_swings[gdx_LastConfirmedCount - 2];  // ก่อนสุดท้าย
      GDX_SwingPoint s1 = gdx_swings[gdx_LastConfirmedCount - 1];  // ล่าสุด
      double hi = s0.isHigh ? s0.price : s1.price;
      double lo = s0.isHigh ? s1.price : s0.price;
      datetime tLbl26 = tNow + InpFib_LabelOffset * 60;
      DrawFibSet(FIB_PREFIX, hi, lo, s0.time, tLbl26,
                 InpFib_Color382, InpFib_Color50, InpFib_Color618,
                 InpFib_ColorN618, InpFib_Color1618,
                 InpFib_LineWidth, InpFib_LabelSize, "p26");

      // ── Notification เมื่อราคาถึง Fib26 levels ──────────────────────
      // [V.22] ครบ 11 levels ตามตาราง | zoneCtx = BUY/SELL direction
      if(hi > lo)
      {
         double range26     = hi - lo;
         double fib26_382   = hi - range26 * 0.382;
         double fib26_50    = hi - range26 * 0.500;
         double fib26_618   = hi - range26 * 0.618;
         double fib26_786   = hi - range26 * 0.786;
         double fib26_100   = lo;
         double fib26_1272  = hi + range26 * 0.272;
         double fib26_1618  = hi + range26 * 0.618;
         double fib26_2618  = hi + range26 * 1.618;
         double fib26_n618  = lo - range26 * 0.618;
         double fib26_n1272 = lo - range26 * 0.272;
         double fib26_n2618 = lo - range26 * 1.618;
         // swing direction: s0.isHigh=true → High→Low (bearish) → retraces = SELL zone
         bool   bull26    = !s0.isHigh;
         string retCtx26  = bull26 ? "BUY"  : "SELL";
         string extUp26   = bull26 ? "BUY"  : "SELL";
         string extDn26   = bull26 ? "SELL" : "BUY";
         CheckFibNotify(fib26_382,   "[P26] 38.2%",   "38.2%",   retCtx26,  g_fib26_382_lastNotify,   g_fib26_382_lastLevel);
         CheckFibNotify(fib26_50,    "[P26] 50.0%",   "50.0%",   retCtx26,  g_fib26_50_lastNotify,    g_fib26_50_lastLevel);
         CheckFibNotify(fib26_618,   "[P26] 61.8%",   "61.8%",   retCtx26,  g_fib26_618_lastNotify,   g_fib26_618_lastLevel);
         CheckFibNotify(fib26_786,   "[P26] 78.6%",   "78.6%",   retCtx26,  g_fib26_786_lastNotify,   g_fib26_786_lastLevel);
         CheckFibNotify(fib26_100,   "[P26] 100%",    "100%",    retCtx26,  g_fib26_100_lastNotify,   g_fib26_100_lastLevel);
         CheckFibNotify(fib26_1272,  "[P26] 127.2%",  "127.2%",  extUp26,   g_fib26_1272_lastNotify,  g_fib26_1272_lastLevel);
         CheckFibNotify(fib26_1618,  "[P26] 161.8%",  "161.8%",  extUp26,   g_fib26_1618_lastNotify,  g_fib26_1618_lastLevel);
         CheckFibNotify(fib26_2618,  "[P26] 261.8%",  "261.8%",  extUp26,   g_fib26_2618_lastNotify,  g_fib26_2618_lastLevel);
         CheckFibNotify(fib26_n618,  "[P26] -61.8%",  "-61.8%",  extDn26,   g_fib26_n618_lastNotify,  g_fib26_n618_lastLevel);
         CheckFibNotify(fib26_n1272, "[P26] -127.2%", "-127.2%", extDn26,   g_fib26_n1272_lastNotify, g_fib26_n1272_lastLevel);
         CheckFibNotify(fib26_n2618, "[P26] -261.8%", "-261.8%", extDn26,   g_fib26_n2618_lastNotify, g_fib26_n2618_lastLevel);
      }
   }

   // ══ p50 Fib: Swing ก่อนล่าสุด (N-3 → N-2 ของ gdx_swings2) = bigger-picture ════════
   // [V.20i] ใช้ [N-3,N-2] เมื่อมี ≥3 swings เพื่อไม่ให้ Fib ซ้ำกับ P26 [N-2,N-1]
   if(InpFib50_Enable && gdx_LastConfirmedCount2 >= 2)
   {
      int p50idx = (gdx_LastConfirmedCount2 >= 3) ? gdx_LastConfirmedCount2 - 3 : gdx_LastConfirmedCount2 - 2;
      GDX_SwingPoint s0 = gdx_swings2[p50idx];
      GDX_SwingPoint s1 = gdx_swings2[p50idx + 1];
      double hi = s0.isHigh ? s0.price : s1.price;
      double lo = s0.isHigh ? s1.price : s0.price;
      datetime tLbl50 = tNow + InpFib50_LabelOffset * 60;  // ต่อจาก p26
      DrawFibSet(FIB_PREFIX, hi, lo, s0.time, tLbl50,
                 InpFib50_Color382, InpFib50_Color50, InpFib50_Color618,
                 InpFib50_ColorN618, InpFib50_Color1618,
                 InpFib_LineWidth, InpFib_LabelSize, "p50");

      // ── Notification เมื่อราคาถึง Fib50 levels ──────────────────────
      // [V.22] ครบ 11 levels ตามตาราง
      if(hi > lo)
      {
         double range50     = hi - lo;
         double fib50_382   = hi - range50 * 0.382;
         double fib50_50    = hi - range50 * 0.500;
         double fib50_618   = hi - range50 * 0.618;
         double fib50_786   = hi - range50 * 0.786;
         double fib50_100   = lo;
         double fib50_1272  = hi + range50 * 0.272;
         double fib50_1618  = hi + range50 * 0.618;
         double fib50_2618  = hi + range50 * 1.618;
         double fib50_n618  = lo - range50 * 0.618;
         double fib50_n1272 = lo - range50 * 0.272;
         double fib50_n2618 = lo - range50 * 1.618;
         GDX_SwingPoint s0p50 = gdx_swings2[p50idx];
         bool   bull50    = !s0p50.isHigh;
         string retCtx50  = bull50 ? "BUY"  : "SELL";
         string extUp50   = bull50 ? "BUY"  : "SELL";
         string extDn50   = bull50 ? "SELL" : "BUY";
         CheckFibNotify(fib50_382,   "[P50] 38.2%",   "38.2%",   retCtx50,  g_fib50_382_lastNotify,   g_fib50_382_lastLevel);
         CheckFibNotify(fib50_50,    "[P50] 50.0%",   "50.0%",   retCtx50,  g_fib50_50_lastNotify,    g_fib50_50_lastLevel);
         CheckFibNotify(fib50_618,   "[P50] 61.8%",   "61.8%",   retCtx50,  g_fib50_618_lastNotify,   g_fib50_618_lastLevel);
         CheckFibNotify(fib50_786,   "[P50] 78.6%",   "78.6%",   retCtx50,  g_fib50_786_lastNotify,   g_fib50_786_lastLevel);
         CheckFibNotify(fib50_100,   "[P50] 100%",    "100%",    retCtx50,  g_fib50_100_lastNotify,   g_fib50_100_lastLevel);
         CheckFibNotify(fib50_1272,  "[P50] 127.2%",  "127.2%",  extUp50,   g_fib50_1272_lastNotify,  g_fib50_1272_lastLevel);
         CheckFibNotify(fib50_1618,  "[P50] 161.8%",  "161.8%",  extUp50,   g_fib50_1618_lastNotify,  g_fib50_1618_lastLevel);
         CheckFibNotify(fib50_2618,  "[P50] 261.8%",  "261.8%",  extUp50,   g_fib50_2618_lastNotify,  g_fib50_2618_lastLevel);
         CheckFibNotify(fib50_n618,  "[P50] -61.8%",  "-61.8%",  extDn50,   g_fib50_n618_lastNotify,  g_fib50_n618_lastLevel);
         CheckFibNotify(fib50_n1272, "[P50] -127.2%", "-127.2%", extDn50,   g_fib50_n1272_lastNotify, g_fib50_n1272_lastLevel);
         CheckFibNotify(fib50_n2618, "[P50] -261.8%", "-261.8%", extDn50,   g_fib50_n2618_lastNotify, g_fib50_n2618_lastLevel);
      }
   }

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| V.20d: M1 SCALP ANALYST — Functions                              |
//+------------------------------------------------------------------+

// ── Label helper (mirrors DP() but uses SA prefix + RIGHT anchor) ──
void SA(string id, string txt, int x, int y, int fs, color clr)
{
   string name = g_SA_PREFIX + id;
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetString (0, name, OBJPROP_TEXT,      txt);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE,  fs);
   ObjectSetString (0, name, OBJPROP_FONT,      "Courier New");
   ObjectSetInteger(0, name, OBJPROP_COLOR,     clr);
   ObjectSetInteger(0, name, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_ZORDER,    2);
}

// ── Toggle button (created once, updated every tick) ───────────────
void DrawScalpBtn()
{
   if(ObjectFind(0, g_SA_BTN) < 0) {
      ObjectCreate(0, g_SA_BTN, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, g_SA_BTN, OBJPROP_CORNER,     CORNER_LEFT_UPPER);
      ObjectSetInteger(0, g_SA_BTN, OBJPROP_XDISTANCE,  InpScalp_X);
      ObjectSetInteger(0, g_SA_BTN, OBJPROP_YDISTANCE,  InpScalp_Y - 20);
      ObjectSetInteger(0, g_SA_BTN, OBJPROP_XSIZE,      148);
      ObjectSetInteger(0, g_SA_BTN, OBJPROP_YSIZE,      18);
      ObjectSetInteger(0, g_SA_BTN, OBJPROP_FONTSIZE,   8);
      ObjectSetString (0, g_SA_BTN, OBJPROP_FONT,       "Courier New");
      ObjectSetInteger(0, g_SA_BTN, OBJPROP_COLOR,      clrWhite);
      ObjectSetInteger(0, g_SA_BTN, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, g_SA_BTN, OBJPROP_ZORDER,     10);
   }
   ObjectSetString (0, g_SA_BTN, OBJPROP_TEXT,
                    g_scalp_visible ? "Scalp Analyst [ON]" : "Scalp Analyst [OFF]");
   ObjectSetInteger(0, g_SA_BTN, OBJPROP_BGCOLOR,
                    g_scalp_visible ? C'0,90,40' : C'80,30,30');
}

// ── Wick rejection check on last 3 closed M1 bars ─────────────────
bool IsScalpWickRejection(bool isBuy)
{
   for(int i = 1; i <= 3; i++) {
      double o = iOpen (_Symbol, PERIOD_M1, i);
      double h = iHigh (_Symbol, PERIOD_M1, i);
      double l = iLow  (_Symbol, PERIOD_M1, i);
      double c = iClose(_Symbol, PERIOD_M1, i);
      double rng = h - l;
      if(rng < _Point) continue;
      if(isBuy) {
         double lowerWick = MathMin(o,c) - l;
         if(lowerWick / rng >= InpScalp_WickRatio && c > o) return true;
      } else {
         double upperWick = h - MathMax(o,c);
         if(upperWick / rng >= InpScalp_WickRatio && c < o) return true;
      }
   }
   return false;
}

// ── Hammer or Bullish/Bearish Engulf rejection candle ─────────────
bool IsScalpRejectionCandle(bool isBuy)
{
   double o1=iOpen(_Symbol,PERIOD_M1,1), h1=iHigh(_Symbol,PERIOD_M1,1);
   double l1=iLow (_Symbol,PERIOD_M1,1), c1=iClose(_Symbol,PERIOD_M1,1);
   double r1 = h1 - l1;
   if(r1 < _Point) return false;
   double o2=iOpen(_Symbol,PERIOD_M1,2), h2=iHigh(_Symbol,PERIOD_M1,2);
   double l2=iLow (_Symbol,PERIOD_M1,2), c2=iClose(_Symbol,PERIOD_M1,2);
   double r2 = h2 - l2;
   if(isBuy) {
      double body1 = MathAbs(c1-o1);
      double lw    = MathMin(o1,c1) - l1;
      bool hammer  = (lw/r1 >= 0.50) && (body1/r1 <= 0.35);
      bool engulf  = (c1>o1) && (c2<o2) && (c1>o2) && (o1<c2) && (r1 >= r2*0.8);
      return hammer || engulf;
   } else {
      double body1 = MathAbs(c1-o1);
      double uw    = h1 - MathMax(o1,c1);
      bool star    = (uw/r1 >= 0.50) && (body1/r1 <= 0.35);
      bool engulf  = (c1<o1) && (c2>o2) && (c1<o2) && (o1>c2) && (r1 >= r2*0.8);
      return star || engulf;
   }
}

// ── Scenario Tracker — detects A/B/C/D and updates step booleans ──
void UpdateScenarioTracker()
{
   if(!InpScalp_Enable) return;
   if(gdx_LastConfirmedCount < 2) return;

   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   GDX_SwingPoint sLast = gdx_swings[gdx_LastConfirmedCount - 1];
   GDX_SwingPoint sPrev = gdx_swings[gdx_LastConfirmedCount - 2];
   double hi    = sLast.isHigh ? sLast.price : sPrev.price;
   double lo    = sLast.isHigh ? sPrev.price : sLast.price;
   double range = hi - lo;
   if(range < _Point) return;

   bool p26bull = !sLast.isHigh;
   bool p50bull = (gdx_LastConfirmedCount2 >= 1)
                  ? !gdx_swings2[gdx_LastConfirmedCount2-1].isHigh : p26bull;

   // Fib levels (direction-aware)
   double fib786, fib618, fib382;
   if(p26bull) {
      fib786 = hi - range * 0.786;   // BUY: deep retracement = price fell near low
      fib618 = hi - range * 0.618;
      fib382 = hi - range * 0.382;
   } else {
      fib786 = lo + range * 0.786;   // SELL: deep rally = price rose near high
      fib618 = lo + range * 0.618;
      fib382 = lo + range * 0.382;
   }

   g_scen_swingHigh  = hi;
   g_scen_swingLow   = lo;
   g_scen_fib786     = fib786;
   g_scen_fib618     = fib618;
   g_scen_fib382     = fib382;
   g_scen_isBuy      = p26bull;
   g_scen_entryPrice = fib618;

   // Reset all state when new swing confirmed
   static datetime lastSwingTime = 0;
   if(sLast.time != lastSwingTime) {
      lastSwingTime  = sLast.time;
      g_scen_active  = 0;
      g_scen_step1   = false;
      g_scen_step2   = false;
      g_scen_step3   = false;
      g_scen_invalid = false;
      g_scen_bExpBar = 0;
   }

   bool ofa_aligned = (p26bull == p50bull);
   bool htf_ok_buy  = (!InpHTF_Enable || g_htf_hull_trend != -1.0);   // BUY ok: HTF not DN
   bool htf_ok_sell = (!InpHTF_Enable || g_htf_hull_trend !=  1.0);   // SELL ok: HTF not UP

   if(p26bull) {
      // ── BUY bias ────────────────────────────────────────────────
      if(price < fib786) {
         // Scenario A: Deep Raid → BUY
         if(g_scen_active != 1) {
            g_scen_active = 1; g_scen_step1=true;
            g_scen_step2=false; g_scen_step3=false; g_scen_invalid=false;
         }
         g_scen_step1 = true;
         if(!g_scen_step2) g_scen_step2 = (price <= lo + InpScalp_RaidBuffer);
         if(g_scen_step2 && !g_scen_step3) g_scen_step3 = IsScalpWickRejection(true) && htf_ok_buy;
      } else {
         // Scenario B: Hold 78.6% → BUY Bounce
         if(g_scen_active == 0) {
            g_scen_active=2; g_scen_step1=true;
            g_scen_step2=false; g_scen_step3=false; g_scen_invalid=false; g_scen_bExpBar=0;
         }
         if(g_scen_active == 2) {
            g_scen_step1 = (price > fib786);
            if(!g_scen_step1) { g_scen_active=0; return; }
            if(!g_scen_step2) g_scen_step2 = IsScalpRejectionCandle(true);
            g_scen_step3 = (ofa_aligned && p26bull && htf_ok_buy);
            g_scen_bExpBar++;
            if(g_scen_bExpBar > InpScalp_BExpireBars) g_scen_invalid = true;
         }
      }
   } else {
      // ── SELL bias ───────────────────────────────────────────────
      if(price > fib786) {
         // Scenario C: Deep Raid → SELL
         if(g_scen_active != 3) {
            g_scen_active=3; g_scen_step1=true;
            g_scen_step2=false; g_scen_step3=false; g_scen_invalid=false;
         }
         g_scen_step1 = true;
         if(!g_scen_step2) g_scen_step2 = (price >= hi - InpScalp_RaidBuffer);
         if(g_scen_step2 && !g_scen_step3) g_scen_step3 = IsScalpWickRejection(false) && htf_ok_sell;
      } else {
         // Scenario D: Hold → SELL Drop
         if(g_scen_active == 0) {
            g_scen_active=4; g_scen_step1=true;
            g_scen_step2=false; g_scen_step3=false; g_scen_invalid=false; g_scen_bExpBar=0;
         }
         if(g_scen_active == 4) {
            g_scen_step1 = (price < fib786);
            if(!g_scen_step1) { g_scen_active=0; return; }
            if(!g_scen_step2) g_scen_step2 = IsScalpRejectionCandle(false);
            g_scen_step3 = (ofa_aligned && !p26bull && htf_ok_sell);
            g_scen_bExpBar++;
            if(g_scen_bExpBar > InpScalp_BExpireBars) g_scen_invalid = true;
         }
      }
   }
}

// ── Draw green/red ellipse circles at entry zone on chart ──────────
void DrawEntryZoneCircles()
{
   string cBuy=g_SA_PREFIX+"CircBuy", cSell=g_SA_PREFIX+"CircSell";
   string lBuy=g_SA_PREFIX+"LblBuy",  lSell=g_SA_PREFIX+"LblSell";
   ObjectDelete(0, cBuy);  ObjectDelete(0, lBuy);
   ObjectDelete(0, cSell); ObjectDelete(0, lSell);

   if(!g_scalp_visible || g_scen_active==0 || g_scen_invalid || !g_scen_step1) return;

   datetime tNow   = iTime(_Symbol, PERIOD_M1, 0);
   int      bSecs  = PeriodSeconds(PERIOD_M1);
   datetime t0     = tNow - (datetime)(InpScalp_CircleBars * bSecs);
   datetime t1     = tNow + (datetime)(InpScalp_CircleBars * bSecs);
   double   ePrice = g_scen_entryPrice;
   double   halfP  = InpScalp_CirclePts;
   bool     isBuy  = g_scen_isBuy;

   string cName = isBuy ? cBuy  : cSell;
   string lName = isBuy ? lBuy  : lSell;
   color  cClr  = isBuy ? clrLime : clrRed;
   string lTxt  = StringFormat("%s? %.2f", isBuy?"BUY":"SELL", ePrice);

   // Draw ellipse (circle-like shape centered on entry price)
   ObjectCreate(0, cName, OBJ_ELLIPSE, 0, t0, ePrice, t1, ePrice, tNow, ePrice+halfP);
   ObjectSetInteger(0, cName, OBJPROP_COLOR,      cClr);
   ObjectSetInteger(0, cName, OBJPROP_STYLE,      STYLE_SOLID);
   ObjectSetInteger(0, cName, OBJPROP_WIDTH,      2);
   ObjectSetInteger(0, cName, OBJPROP_FILL,       false);
   ObjectSetInteger(0, cName, OBJPROP_BACK,       true);
   ObjectSetInteger(0, cName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, cName, OBJPROP_HIDDEN,     true);

   // Price label next to circle
   ObjectCreate(0, lName, OBJ_TEXT, 0, t1, ePrice+halfP+1.0);
   ObjectSetString (0, lName, OBJPROP_TEXT,       lTxt);
   ObjectSetInteger(0, lName, OBJPROP_COLOR,      cClr);
   ObjectSetInteger(0, lName, OBJPROP_FONTSIZE,   8);
   ObjectSetString (0, lName, OBJPROP_FONT,       "Courier New");
   ObjectSetInteger(0, lName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, lName, OBJPROP_HIDDEN,     true);
}

// ── Main Dashboard Draw ─────────────────────────────────────────────
void DrawScalpDashboard()
{
   if(!g_scalp_visible) return;
   if(gdx_LastConfirmedCount < 2) return;

   int x0=InpScalp_X, y0=InpScalp_Y, rh=16, w=320;

   // Background panel
   string bgName = g_SA_PREFIX + "BG";
   if(ObjectFind(0, bgName) < 0)
      ObjectCreate(0, bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, bgName, OBJPROP_CORNER,      CORNER_LEFT_UPPER);
   ObjectSetInteger(0, bgName, OBJPROP_XDISTANCE,   x0);
   ObjectSetInteger(0, bgName, OBJPROP_YDISTANCE,   y0);
   ObjectSetInteger(0, bgName, OBJPROP_XSIZE,       w);
   ObjectSetInteger(0, bgName, OBJPROP_YSIZE,       22*rh + 8);
   ObjectSetInteger(0, bgName, OBJPROP_BGCOLOR,     C'10,10,18');
   ObjectSetInteger(0, bgName, OBJPROP_BORDER_COLOR, C'50,50,80');
   ObjectSetInteger(0, bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, bgName, OBJPROP_BACK,        true);
   ObjectSetInteger(0, bgName, OBJPROP_ZORDER,      0);

   // ── Gather live data ──────────────────────────────────────────
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   ENUM_SF_SESSION curSess = GetCurrentSession();
   string sessStr;
   switch(curSess){
      case SESSION_ASIA:         sessStr="ASIA"; break;
      case SESSION_LONDON:       sessStr="LON";  break;
      case SESSION_NY_MORNING:   sessStr="NYM";  break;
      case SESSION_NY_AFTERNOON: sessStr="NYPM"; break;
      default:                   sessStr="OFF";  break;
   }

   bool   p26bull = !gdx_swings[gdx_LastConfirmedCount-1].isHigh;
   bool   p50bull = (gdx_LastConfirmedCount2>=1)
                    ? !gdx_swings2[gdx_LastConfirmedCount2-1].isHigh : p26bull;

   // ── Fibonacci Expansion from 3 P50 swings ─────────────────────
   double fe618=0, fe100=0, fe161=0, fe261=0;
   bool   hasFE = (gdx_LastConfirmedCount2 >= 3);
   if(hasFE) {
      GDX_SwingPoint swA = gdx_swings2[gdx_LastConfirmedCount2-3];
      GDX_SwingPoint swB = gdx_swings2[gdx_LastConfirmedCount2-2];
      GDX_SwingPoint swC = gdx_swings2[gdx_LastConfirmedCount2-1];
      double feRange = MathAbs(swB.price - swA.price);  // A→B impulse leg
      if(p50bull) {
         fe618 = swC.price + feRange * 0.618;
         fe100 = swC.price + feRange * 1.0;
         fe161 = swC.price + feRange * 1.618;
         fe261 = swC.price + feRange * 2.618;
      } else {
         fe618 = swC.price - feRange * 0.618;
         fe100 = swC.price - feRange * 1.0;
         fe161 = swC.price - feRange * 1.618;
         fe261 = swC.price - feRange * 2.618;
      }
   }

   string htfStr  = (g_htf_hull_trend>0)?"UP":(g_htf_hull_trend<0?"DN":"--");
   color  htfClr  = (g_htf_hull_trend>0)?clrLime:(g_htf_hull_trend<0?clrOrangeRed:clrGray);
   string p26str  = p26bull?"BULL":"BEAR";
   string p50str  = p50bull?"BULL":"BEAR";
   color  p26clr  = p26bull?clrLime:clrOrangeRed;
   color  p50clr  = p50bull?clrLime:clrOrangeRed;

   double atrConsumed = GetDailyATRConsumption();
   double atrUp       = GetDailyATRConsumptionDir(true);   // V.20i directional
   double atrDn       = GetDailyATRConsumptionDir(false);
   double d1buf[]; ArraySetAsSeries(d1buf, true);
   double atrRem = 0;
   if(CopyBuffer(g_atr_d1_handle, 0, 1, 1, d1buf) > 0)
      atrRem = MathMax(0, (d1buf[0]/_Point) * (1.0 - atrConsumed));
   int    scalp_budget = (atrRem>1.0) ? (int)(atrRem/10.0) : 0;
   color  atrClr = (atrConsumed>=0.85)?clrOrangeRed:(atrConsumed>=0.70?clrYellow:clrLime);

   bool   ofa_aligned = (p26bull==p50bull);
   string alignStr    = ofa_aligned?"ALIGNED":"MIXED";
   color  alignClr    = ofa_aligned?(p26bull?clrLime:clrOrangeRed):clrYellow;
   string sessMode;
   if(!ofa_aligned)           sessMode = "BLOCKED-OFA";
   else if(p26bull)           sessMode = "BULL -> BUY";
   else                       sessMode = "BEAR -> SELL";

   // Zone label
   string zoneLabel;
   if(g_scen_swingHigh<=g_scen_swingLow)            zoneLabel="---";
   else if(price>=g_scen_swingHigh)                  zoneLabel="ABOVE SwingH";
   else if(price<=g_scen_swingLow)                   zoneLabel="BELOW SwingL";
   else if(g_scen_isBuy  && price<g_scen_fib786)    zoneLabel="78.6% DEEP";
   else if(!g_scen_isBuy && price>g_scen_fib786)    zoneLabel="78.6% DEEP";
   else if(price>g_scen_fib618 && price<g_scen_fib382) zoneLabel="GOLDEN zone";
   else                                               zoneLabel="Mid zone";

   // Scenario strings
   string scenLabel, scenDir; color scenClr;
   switch(g_scen_active){
      case 1: scenLabel="[A] RAID DEEP"; scenDir="-> BUY";  scenClr=clrLime;        break;
      case 2: scenLabel="[B] HOLD ZONE"; scenDir="-> BUY";  scenClr=clrAquamarine;  break;
      case 3: scenLabel="[C] RAID DEEP"; scenDir="-> SELL"; scenClr=clrOrangeRed;   break;
      case 4: scenLabel="[D] HOLD ZONE"; scenDir="-> SELL"; scenClr=clrOrangeRed;   break;
      default:scenLabel="WATCHING...";   scenDir="";         scenClr=clrGray;       break;
   }
   if(g_scen_invalid){ scenLabel+=" [EXP]"; scenClr=clrGray; }

   // Steps
   bool s1=g_scen_step1, s2=g_scen_step2, s3=g_scen_step3;
   string st1s=s1?"(OK)":"(..)";
   string st2s=s1?(s2?"(OK)":"(..)"):"(--)";
   string st3s=(s1&&s2)?(s3?"(OK)":"(..)"):"(--)";
   color  st1c=s1?clrLime:clrYellow;
   color  st2c=s1?(s2?clrLime:clrYellow):C'70,70,70';
   color  st3c=(s1&&s2)?(s3?clrLime:clrYellow):C'70,70,70';

   string step2desc=(g_scen_active==1)?StringFormat("Near BUY STOPS (%.0f)",g_scen_swingLow)
                   :(g_scen_active==3)?StringFormat("Near SELL STOPS (%.0f)",g_scen_swingHigh)
                   :"Rejection candle (M1)";
   string step3desc=(g_scen_active==1||g_scen_active==3)?"Wick Rejection + HTF align":"OFA P26+P50 + HTF align";

   // Plan — TP1 = nearest FE level beyond entry (fallback: Fib 38.2%)
   double tp1;
   if(hasFE) {
      double e = g_scen_entryPrice;
      if(p50bull)
         tp1 = (e < fe618) ? fe618 : (e < fe100) ? fe100 : fe161;
      else
         tp1 = (e > fe618) ? fe618 : (e > fe100) ? fe100 : fe161;
   } else {
      tp1 = g_scen_isBuy ? g_scen_fib382 : (g_scen_swingLow+(g_scen_swingHigh-g_scen_swingLow)*0.382);
   }
   double slLvl = g_scen_isBuy?(g_scen_swingLow-5.0):(g_scen_swingHigh+5.0);
   double tpPts = MathAbs(tp1-g_scen_entryPrice);
   double slPts = MathAbs(g_scen_entryPrice-slLvl);
   double rr    = (slPts>1.0)?tpPts/slPts:0;
   int    stDone= (s1?1:0)+(s2?1:0)+(s3?1:0);
   string pBar  = StringFormat("[%s%s%s] %d/3",s1?"=":".",s2?"=":".",s3?"=":".",stDone);

   // Decision
   string decision; color decClr;
   if(g_scen_active==0)     { decision="WATCH — รอ Scenario";        decClr=clrGray;     }
   else if(g_scen_invalid)  { decision="SKIP — Scenario หมดอายุ";   decClr=C'90,90,90'; }
   else if(!ofa_aligned)    { decision="BLOCK — OFA MIXED (P26≠P50)"; decClr=clrOrangeRed; }
   else if(s1&&s2&&s3)      { decision=">>> READY — เข้าได้! <<<";   decClr=clrLime;     }
   else                     { decision="WAIT — รอ Steps ครบ";         decClr=clrYellow;   }

   // ── Render all 20 rows ────────────────────────────────────────
   int xi = x0+3;
   string SEP = "- - - - - - - - - - - - - - - - - - - - - -";
   MqlDateTime mdt; TimeToStruct(TimeCurrent(), mdt);

   SA("R00", StringFormat("SCALP ANALYST | %s | %02d:%02d", sessStr, mdt.hour, mdt.min),
      xi, y0+0*rh+3, 9, clrWhite);
   SA("R01", StringFormat("ATR UP:%.0f%% DN:%.0f%%  Rem:%.0fpt ~%d sc",
      atrUp*100, atrDn*100, atrRem, scalp_budget), xi, y0+1*rh+3, 9, atrClr);
   SA("R02", SEP, xi, y0+2*rh+3, 9, C'40,40,60');

   SA("R03a", "TREND M15:", xi,    y0+3*rh+3, 9, clrSilver);
   SA("R03b", htfStr,      xi+76, y0+3*rh+3, 9, htfClr);
   SA("R04a", "OFA  P26:", xi,    y0+4*rh+3, 9, clrSilver);
   SA("R04b", p26str,  xi+78,     y0+4*rh+3, 9, p26clr);
   SA("R04c", "P50:", xi+118,     y0+4*rh+3, 9, clrSilver);
   SA("R04d", p50str,  xi+148,    y0+4*rh+3, 9, p50clr);
   SA("R05a", "ALIGN ", xi,       y0+5*rh+3, 9, clrSilver);
   SA("R05b", alignStr, xi+50,    y0+5*rh+3, 9, alignClr);
   SA("R05c", "Mode:", xi+116,    y0+5*rh+3, 9, clrSilver);
   SA("R05d", sessMode,  xi+158,  y0+5*rh+3, 9, ofa_aligned?(p26bull?clrLime:clrOrangeRed):clrGray);
   SA("R06", SEP, xi, y0+6*rh+3, 9, C'40,40,60');

   SA("R07", StringFormat("SwingH:%.2f  SwingL:%.2f", g_scen_swingHigh, g_scen_swingLow),
      xi, y0+7*rh+3, 9, clrSilver);
   SA("R08a", StringFormat("78.6%%:%.2f  Now:%.2f", g_scen_fib786, price),
      xi, y0+8*rh+3, 9, clrSilver);
   SA("R08b", StringFormat("[%s]", zoneLabel), xi+210, y0+8*rh+3, 9, clrYellow);
   SA("R09", SEP, xi, y0+9*rh+3, 9, C'40,40,60');

   SA("R10a", scenLabel, xi,     y0+10*rh+3, 9, scenClr);
   SA("R10b", scenDir,   xi+140, y0+10*rh+3, 9, g_scen_isBuy?clrLime:clrOrangeRed);

   SA("R11a", StringFormat(" 1.%s", st1s), xi,    y0+11*rh+3, 9, st1c);
   SA("R11b", "Price at 78.6% zone",        xi+52, y0+11*rh+3, 9, clrSilver);
   SA("R12a", StringFormat(" 2.%s", st2s), xi,    y0+12*rh+3, 9, st2c);
   SA("R12b", step2desc,                    xi+52, y0+12*rh+3, 9, clrSilver);
   SA("R13a", StringFormat(" 3.%s", st3s), xi,    y0+13*rh+3, 9, st3c);
   SA("R13b", step3desc,                    xi+52, y0+13*rh+3, 9, clrSilver);
   SA("R14", StringFormat("Progress: %s", pBar), xi, y0+14*rh+3, 9, clrSilver);
   SA("R15", SEP, xi, y0+15*rh+3, 9, C'40,40,60');

   if(ofa_aligned)
      SA("R16", StringFormat("Entry:%.2f  TP1:%.2f  SL:%.2f",
         g_scen_entryPrice, tp1, slLvl), xi, y0+16*rh+3, 9, clrSilver);
   else
      SA("R16", "Entry:---  TP1:---  SL:--- [OFA MIXED]", xi, y0+16*rh+3, 9, clrGray);

   // FE row — show all expansion levels from P50 swings
   if(hasFE) {
      color feClr = p50bull ? clrLime : clrOrangeRed;
      SA("R17a", "FE P50:", xi,     y0+17*rh+3, 9, clrSilver);
      SA("R17b", StringFormat("61.8=%.0f", fe618), xi+56,  y0+17*rh+3, 9, feClr);
      SA("R17c", StringFormat("100=%.0f",  fe100), xi+126, y0+17*rh+3, 9, feClr);
      SA("R17d", StringFormat("161=%.0f",  fe161), xi+188, y0+17*rh+3, 9, feClr);
      SA("R17e", StringFormat("261=%.0f",  fe261), xi+252, y0+17*rh+3, 9, feClr);
   } else {
      SA("R17a", "FE P50: (need ≥3 swings)", xi, y0+17*rh+3, 9, clrGray);
      SA("R17b", "", xi+56,  y0+17*rh+3, 9, clrGray);
      SA("R17c", "", xi+122, y0+17*rh+3, 9, clrGray);
      SA("R17d", "", xi+182, y0+17*rh+3, 9, clrGray);
      SA("R17e", "", xi+244, y0+17*rh+3, 9, clrGray);
   }

   if(ofa_aligned)
      SA("R18", StringFormat("R:R 1:%.1f  |  Budget: ~%d scalps", rr, scalp_budget),
         xi, y0+18*rh+3, 9, clrSilver);
   else
      SA("R18", "R:R ---  |  Budget: ~--- scalps", xi, y0+18*rh+3, 9, clrGray);
   SA("R19", SEP, xi, y0+19*rh+3, 9, C'40,40,60');

   SA("R20a", ">> ",     xi,    y0+20*rh+3, 10, clrSilver);
   SA("R20b", decision,  xi+26, y0+20*rh+3, 10, decClr);
}
//+------------------------------------------------------------------+
//| Smart Fibonacci Exit: ปิดตามเงื่อนไข 161.8% + Hull / Z-Cap / 261.8% |
//+------------------------------------------------------------------+
void CheckSmartFibExit()
{
   if(!InpSmartExit_Enable) return;
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) return;

   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicnumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;

      long   posType = PositionGetInteger(POSITION_TYPE);
      double bid     = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask     = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double price   = (posType == POSITION_TYPE_BUY) ? bid : ask;

      // 1. เช็ค Z-Score Super Cap (ปิดทันทีถ้าสถิติพุ่งเกินขีดจำกัด)
      double gc[]; double zg = 0;
      if(GetSeries(_Symbol, 0, InpZPeriod, gc)) {
         zg = ZScore(gc, InpZPeriod);
         
         //if((posType == POSITION_TYPE_BUY && zg >= InpSmartExit_ZCap) ||
         //   (posType == POSITION_TYPE_SELL && zg <= -InpSmartExit_ZCap)) {
         //   CloseSmartExit(ticket, StringFormat("Z-Cap %.2f Hit", zg));
         //   continue;
         //}
         // เช็คกำไรปัจจุบันก่อน (PnL)
         double positionProfit = PositionGetDouble(POSITION_PROFIT);
         
         if((posType == POSITION_TYPE_BUY && zg >= InpSmartExit_ZCap && positionProfit > 0) ||
            (posType == POSITION_TYPE_SELL && zg <= -InpSmartExit_ZCap && positionProfit > 0)) {
            CloseSmartExit(ticket, StringFormat("Z-Cap %.2f Hit (Profit Safe)", zg));
            continue;
         }
      }

      // 2. คำนวณ Fib Levels จาก P26 และ P50
      double p26_161=0, p26_261=0, p50_161=0, p50_261=0;
      
      // ดึงค่า P26
      if(gdx_LastConfirmedCount >= 2) {
         double h = gdx_swings[gdx_LastConfirmedCount-2].isHigh ? gdx_swings[gdx_LastConfirmedCount-2].price : gdx_swings[gdx_LastConfirmedCount-1].price;
         double l = gdx_swings[gdx_LastConfirmedCount-2].isHigh ? gdx_swings[gdx_LastConfirmedCount-1].price : gdx_swings[gdx_LastConfirmedCount-2].price;
         double rng = h - l;
         if(rng > 0) { // guard: ต้องเป็น H/L สลับกันเท่านั้น
            p26_161 = (posType == POSITION_TYPE_BUY) ? h + rng * 0.618 : l - rng * 0.618;
            p26_261 = (posType == POSITION_TYPE_BUY) ? h + rng * 1.618 : l - rng * 1.618;
         }
      }
      // ดึงค่า P50
      if(gdx_LastConfirmedCount2 >= 2) {
         double h = gdx_swings2[gdx_LastConfirmedCount2-2].isHigh ? gdx_swings2[gdx_LastConfirmedCount2-2].price : gdx_swings2[gdx_LastConfirmedCount2-1].price;
         double l = gdx_swings2[gdx_LastConfirmedCount2-2].isHigh ? gdx_swings2[gdx_LastConfirmedCount2-1].price : gdx_swings2[gdx_LastConfirmedCount2-2].price;
         double rng = h - l;
         if(rng > 0) { // guard: ต้องเป็น H/L สลับกันเท่านั้น
            p50_161 = (posType == POSITION_TYPE_BUY) ? h + rng * 0.618 : l - rng * 0.618;
            p50_261 = (posType == POSITION_TYPE_BUY) ? h + rng * 1.618 : l - rng * 1.618;
         }
      }

      // 3. ตรวจสอบเงื่อนไข Hard TP 261.8% (ปิดทันที)
      double entryPx = PositionGetDouble(POSITION_PRICE_OPEN);
      // Sanity: level ต้องอยู่ฝั่งกำไรเท่านั้น (ป้องกัน rng ผิดทิศทางทำให้ trigger ฝั่งขาดทุน)
      bool p26_validDir = (p26_261 > 0) &&
                          ((posType==POSITION_TYPE_BUY  && p26_261 > entryPx) ||
                           (posType==POSITION_TYPE_SELL && p26_261 < entryPx));
      bool p50_validDir = (p50_261 > 0) &&
                          ((posType==POSITION_TYPE_BUY  && p50_261 > entryPx) ||
                           (posType==POSITION_TYPE_SELL && p50_261 < entryPx));
      if((p26_validDir && ((posType==POSITION_TYPE_BUY && price >= p26_261) || (posType==POSITION_TYPE_SELL && price <= p26_261))) ||
         (p50_validDir && ((posType==POSITION_TYPE_BUY && price >= p50_261) || (posType==POSITION_TYPE_SELL && price <= p50_261)))) {
         CloseSmartExit(ticket, "Hard TP 261.8% Hit");
         continue;
      }

      // 4. ตรวจสอบเงื่อนไข 161.8% + Hull Flip
      bool inFibZone = false;
      if(posType == POSITION_TYPE_BUY) {
         if((p26_161 > 0 && price >= p26_161) || (p50_161 > 0 && price >= p50_161)) inFibZone = true;
      } else {
         if((p26_161 > 0 && price <= p26_161) || (p50_161 > 0 && price <= p50_161)) inFibZone = true;
      }

      // --- ส่วนที่แก้ไข: เพิ่มการเช็คกำไร และ ระยะเวลาถือครอง ---
      if(inFibZone) {
         // เช็คกำไรปัจจุบัน
         double positionProfit = PositionGetDouble(POSITION_PROFIT);
         // เช็คเวลาที่ถือมา (ต้องถืออย่างน้อย 10 วินาที เพื่อป้องกันการปิดซ้อนกันใน Tick เดียว)
         datetime duration = TimeCurrent() - (datetime)PositionGetInteger(POSITION_TIME);

         if(duration > 10 && positionProfit > 0) // <--- ต้องมีกำไรและถือเกิน 10 วิ
         {
            int hullDir = (g_hullLastWrittenIdx >= 0) ? (int)gdx_HullTrend[g_hullLastWrittenIdx] : 0;
            if((posType == POSITION_TYPE_BUY && hullDir == -1) || (posType == POSITION_TYPE_SELL && hullDir == 1)) {
               CloseSmartExit(ticket, "161.8% Hit + Hull Flip (Profit Safe)");
            }
         }
      }
   }
}

// ฟังก์ชันช่วยปิดออเดอร์
void CloseSmartExit(ulong ticket, string reason) {
   if(Trade.PositionClose(ticket)) {
      string msg = StringFormat("🎯 SMART EXIT: %s | %s | Ticket #%d", reason, _Symbol, ticket);
      Print(msg);
      if(InpSmartExit_Notify && InpSendPush && !GDEA_IsQuietHour()) SendNotification(msg);
      g_smLastEvent = "🎯 Smart Exit: " + reason;
      g_smLastEventClr = clrGold;
   }
}