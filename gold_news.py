import os
import requests
from datetime import datetime
import anthropic


def get_gold_news() -> str:
    client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])

    today = datetime.now().strftime("%Y-%m-%d")

    prompt = f"""Search the web for the top 5 most important XAUUSD / Gold news from the last 1-2 days.

Focus on news that directly impacts gold price movement:
- Central bank decisions (Fed, ECB, BOJ) and interest rate outlook
- US economic data (CPI, NFP, GDP, PMI)
- Geopolitical tensions or safe-haven demand
- USD strength/weakness drivers
- Physical gold demand (China, India central banks)

Write a report in Thai with this exact format (use plain text, avoid markdown links):

# ข่าวทองคำ XAUUSD ประจำวัน {today}

> รวบรวมข่าวสำคัญ 5 อันดับที่ส่งผลต่อราคาทองคำในช่วง 1-2 วันที่ผ่านมา

---

1. [หัวข้อข่าวภาษาไทย]
ผลกระทบ: 🟢 Bullish หรือ 🔴 Bearish หรือ ⚪ Neutral
สรุป: [สรุปเนื้อหา 2-3 ประโยค]
แหล่งข่าว: [ชื่อสำนัก] | [วันเวลา]

(ทำซ้ำจนครบ 5 ข่าว)

---

สรุปภาพรวม:
[วิเคราะห์ทิศทางทองคำรวม 3-5 ประโยค]

Bias วันนี้: 🟢 Bullish หรือ 🔴 Bearish หรือ ⚪ Mixed
"""

    response = client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=4096,
        tools=[
            {
                "type": "web_search_20250305",
                "name": "web_search",
                "max_uses": 5,
            }
        ],
        messages=[{"role": "user", "content": prompt}],
    )

    result = ""
    for block in response.content:
        if hasattr(block, "text"):
            result += block.text

    return result.strip()


def send_telegram(message: str, token: str, chat_id: str) -> None:
    url = f"https://api.telegram.org/bot{token}/sendMessage"

    # Telegram limit is 4096 chars per message — split if needed
    max_len = 4000
    chunks = [message[i : i + max_len] for i in range(0, len(message), max_len)]

    for chunk in chunks:
        resp = requests.post(
            url,
            json={"chat_id": chat_id, "text": chunk},
            timeout=10,
        )
        if not resp.ok:
            print(f"Telegram error: {resp.status_code} {resp.text}")
            resp.raise_for_status()


if __name__ == "__main__":
    token = os.environ["TELEGRAM_TOKEN"]
    chat_id = os.environ["TELEGRAM_CHAT_ID"]

    print("Fetching gold news...")
    news = get_gold_news()

    print("Sending to Telegram...")
    send_telegram(news, token, chat_id)
    print("Done!")
