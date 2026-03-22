//+------------------------------------------------------------------+
//| GoldNewsNotify.mq5                                               |
//| อ่าน GoldNewsMT5.txt จาก GitHub แล้วส่ง push notification       |
//+------------------------------------------------------------------+
#property copyright "KKOB"
#property version   "1.00"

input int    CheckIntervalMinutes = 60;
input string GitHubURL = "https://raw.githubusercontent.com/KKOB-hub/gold-news-bot/main/GoldNewsMT5.txt";

string lastSentFile = "GoldNewsLastSent.txt";
string lastSentLine = "";

//+------------------------------------------------------------------+
int OnInit()
{
   // โหลด last sent จากไฟล์
   int handle = FileOpen(lastSentFile, FILE_READ | FILE_TXT | FILE_ANSI);
   if(handle != INVALID_HANDLE)
   {
      lastSentLine = FileReadString(handle);
      FileClose(handle);
      Print("Last sent: ", lastSentLine);
   }

   EventSetTimer(CheckIntervalMinutes * 60);
   OnTimer(); // รันทันทีตอน init
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
}

//+------------------------------------------------------------------+
void OnTimer()
{
   Print("Checking gold news...");

   char data[];
   char result[];
   string headers = "";
   string reqHeaders = "User-Agent: MT5-GoldBot\r\n";

   int res = WebRequest("GET", GitHubURL, reqHeaders, 10000, data, result, headers);

   if(res != 200)
   {
      Print("WebRequest failed. HTTP code: ", res);
      Print("Add this URL to: Tools > Options > Expert Advisors > Allow WebRequest");
      Print("URL: https://raw.githubusercontent.com");
      return;
   }

   string content = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
   StringTrimRight(content);
   StringTrimLeft(content);

   if(StringLen(content) == 0)
   {
      Print("Empty content received.");
      return;
   }

   // แยกบรรทัด
   string lines[];
   int count = StringSplit(content, '\n', lines);
   if(count == 0) return;

   string firstLine = lines[0];
   StringTrimRight(firstLine);

   // ตรวจว่าส่งไปแล้วหรือยัง
   if(firstLine == lastSentLine)
   {
      Print("Already sent: ", firstLine);
      return;
   }

   // ส่ง notification ทีละบรรทัด
   Print("Sending ", count, " notifications...");
   for(int i = 0; i < count; i++)
   {
      string msg = lines[i];
      StringTrimRight(msg);
      if(StringLen(msg) == 0) continue;
      if(StringLen(msg) > 255) msg = StringSubstr(msg, 0, 252) + "...";

      if(SendNotification(msg))
         Print("Sent: ", msg);
      else
         Print("Failed: ", msg);

      Sleep(2000); // 2 วินาทีระหว่างแต่ละข้อความ
   }

   // บันทึก last sent
   lastSentLine = firstLine;
   int handle = FileOpen(lastSentFile, FILE_WRITE | FILE_TXT | FILE_ANSI);
   if(handle != INVALID_HANDLE)
   {
      FileWriteString(handle, lastSentLine);
      FileClose(handle);
   }

   Print("Gold news notifications sent successfully.");
}

void OnTick() {}
//+------------------------------------------------------------------+
