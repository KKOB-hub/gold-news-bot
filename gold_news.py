import os
import requests
from datetime import datetime
from google import genai
from google.genai import types


def get_gold_news() -> str:
    client = genai.Client(api_key=os.environ["GEMINI_API_KEY"])

    today = datetime.now().strftime("%Y-%m-%d")
    prompt = f"""Search the web for the top 5 most important XAUUSD / Gold news from the last 1-2 days.
Focus on: Fed/ECB decisions, US economic data (CPI/NFP), geopolitical tensions, USD moves, central bank gold buying.

Write report in Thai:

# ข่าวทองคำ XAUUSD ประจำวัน {today}
> รวบรวมข่าวสำคัญ 5 อันดับที่ส่งผลต่อราคาทองคำในช่วง 1-2 วันที่ผ่านมา
---
1. [หัวข้อข่าวภาษาไทย]
ผลกระทบ: 🟢 Bullish หรือ 🔴 Bearish หรือ ⚪ Neutral
สรุป: [2-3 ประโยค]
แหล่งข่าว: [ชื่อสำนัก] | [วันเวลา]
(ทำซ้ำจนครบ 5 ข่าว)
---
สรุปภาพรวม: [3-5 ประโยค]
Bias วันนี้: 🟢 Bullish หรือ 🔴 Bearish หรือ ⚪ Mixed"""

    response = client.models.generate_content(
        model="gemini-2.0-flash",
        contents=prompt,
        config=types.GenerateContentConfig(
            tools=[types.Tool(google_search=types.GoogleSearch())]
        ),
    )
    return response.text.strip()


def send_telegram(message: str, token: str, chat_id: str) -> None:
    url = f"https://api.telegram.org/bot{token}/sendMessage"
    chunks = [message[i:i+4000] for i in range(0, len(message), 4000)]
    for chunk in chunks:
        resp = requests.post(url, json={"chat_id": chat_id, "text": chunk}, timeout=10)
        if not resp.ok:
            resp.raise_for_status()


if __name__ == "__main__":
    token = os.environ["TELEGRAM_TOKEN"]
    chat_id = os.environ["TELEGRAM_CHAT_ID"]
    print("Fetching gold news...")
    news = get_gold_news()
    print("Sending to Telegram...")
    send_telegram(news, token, chat_id)
    print("Done!")
