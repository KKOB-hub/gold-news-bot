import os
import time
import requests
import xml.etree.ElementTree as ET
from datetime import datetime, timezone, timedelta
from email.utils import parsedate_to_datetime

# Path ไปยัง MT5 Common Files
MT5_PATH = os.path.join(
    os.environ["APPDATA"],
    "MetaQuotes", "Terminal", "Common", "Files"
)
OUTPUT_FILE = os.path.join(MT5_PATH, "GoldNewsMT5.txt")

RSS_FEEDS = [
    "https://feeds.content.dowjones.io/public/rss/mw_realtimeheadlines",
    "https://finance.yahoo.com/rss/headline?s=GC%3DF",
    "https://finance.yahoo.com/rss/headline?s=DX-Y.NYB",
    "https://www.investing.com/rss/news_14.rss",
]

KEYWORDS = [
    "gold", "xauusd", "bullion",
    "dollar", "usd", "dxy", "dollar index", "greenback",
    "fed", "federal reserve", "interest rate", "inflation",
    "cpi", "nfp", "gdp", "powell", "fomc",
    "geopolit", "safe haven", "central bank", "tariff", "trade"
]


def fetch_rss(url: str) -> list:
    try:
        resp = requests.get(url, timeout=10, headers={"User-Agent": "Mozilla/5.0"})
        resp.raise_for_status()
        root = ET.fromstring(resp.content)
        items = []
        for item in root.findall(".//item")[:15]:
            title = (item.findtext("title") or "").strip()
            pub = (item.findtext("pubDate") or "").strip()
            items.append({"title": title, "pub": pub})
        return items
    except Exception as e:
        print(f"  RSS error: {e}")
        return []


def translate_to_thai(text: str) -> str:
    try:
        url = "https://translate.googleapis.com/translate_a/single"
        params = {"client": "gtx", "sl": "en", "tl": "th", "dt": "t", "q": text}
        resp = requests.get(url, params=params, timeout=10)
        result = resp.json()
        return "".join([item[0] for item in result[0] if item[0]])
    except Exception as e:
        print(f"  Translate error: {e}")
        return text  # คืนค่า original ถ้าแปลไม่ได้


def parse_pub_date(pub_str: str):
    """แปลง pubDate string เป็น datetime (aware) คืน None ถ้า parse ไม่ได้"""
    try:
        return parsedate_to_datetime(pub_str)
    except Exception:
        return None


def get_news() -> list:
    # เวลาท้องถิ่น UTC+7 (ไทย)
    tz_thai = timezone(timedelta(hours=7))
    today_thai = datetime.now(tz_thai).date()
    cutoff = datetime.now(tz_thai) - timedelta(hours=36)  # fallback: 36 ชั่วโมง

    all_items = []
    seen = set()
    for feed in RSS_FEEDS:
        for item in fetch_rss(feed):
            title = item["title"]
            if title in seen or not title:
                continue
            if any(kw in title.lower() for kw in KEYWORDS):
                seen.add(title)
                all_items.append(item)

    # จัดเรียงตาม pubDate ล่าสุดก่อน
    def sort_key(item):
        dt = parse_pub_date(item["pub"])
        return dt if dt else datetime.min.replace(tzinfo=timezone.utc)

    all_items.sort(key=sort_key, reverse=True)

    # กรองเฉพาะข่าว "วันนี้" (เวลาไทย)
    today_items = [
        item for item in all_items
        if (dt := parse_pub_date(item["pub"])) and dt.astimezone(tz_thai).date() == today_thai
    ]

    # ถ้าไม่มีข่าววันนี้เลย ให้ใช้ข่าวใน 36 ชั่วโมงล่าสุดแทน
    if today_items:
        return today_items[:5]
    else:
        print(f"  ไม่พบข่าววันนี้ ({today_thai}) — ใช้ข่าวล่าสุดแทน")
        fallback = [
            item for item in all_items
            if (dt := parse_pub_date(item["pub"])) and dt.astimezone(tz_thai) >= cutoff
        ]
        return fallback[:5] or all_items[:5]


def build_content(items: list, today: str) -> str:
    lines = [f"[ข่าวทอง/USD ประจำวัน {today}]"]
    for i, item in enumerate(items, 1):
        print(f"  Translating {i}/{len(items)}...")
        thai = translate_to_thai(item["title"])
        lines.append(f"{i}. {thai}")
    return "\r\n".join(lines)


def run_job():
    today = datetime.now().strftime("%Y-%m-%d")
    print(f"\n[{datetime.now().strftime('%H:%M:%S')}] Running news job...")

    items = get_news()
    if not items:
        print("No news found.")
        return

    content = build_content(items, today)
    print("\n--- Content ---")
    print(content)
    print("---------------\n")

    os.makedirs(MT5_PATH, exist_ok=True)
    # เขียนเป็น UTF-16 (มี BOM) + CRLF เพื่อให้ MT5 อ่านได้ถูกต้อง
    content_crlf = content.replace("\n", "\r\n")
    with open(OUTPUT_FILE, "w", encoding="utf-16", newline="") as f:
        f.write(content_crlf)
    print(f"Saved: {OUTPUT_FILE}")


if __name__ == "__main__":
    SEND_HOUR = 6
    last_sent_date = ""

    print("=" * 50)
    print("  Gold/USD News Bot — running 24/7")
    print(f"  จะส่งข่าวทุกวัน เวลา {SEND_HOUR:02d}:00 น.")
    print("  กด Ctrl+C เพื่อหยุด")
    print("=" * 50)

    print("Running immediately on startup...")
    run_job()
    last_sent_date = datetime.now().strftime("%Y-%m-%d")

    while True:
        now = datetime.now()
        today = now.strftime("%Y-%m-%d")

        if now.hour == SEND_HOUR and last_sent_date != today:
            run_job()
            last_sent_date = today

        time.sleep(60)
