#!/bin/sh

# Đợi cho ngrok khởi động
echo "Đang đợi ngrok khởi động..."
sleep 10

# Lặp lại cho đến khi lấy được URL từ ngrok
MAX_TRIES=30
COUNTER=0
NGROK_URL=""

while [ $COUNTER -lt $MAX_TRIES ]; do
  echo "Đang cố gắng lấy URL từ ngrok (lần thử $COUNTER)..."
  
  # Lấy URL từ API của ngrok
  NGROK_URL=$(curl -s http://ngrok:4040/api/tunnels | grep -o '"public_url":"https://[^"]*' | sed 's/"public_url":"//g')
  
  # Nếu tìm thấy URL, thoát khỏi vòng lặp
  if [ ! -z "$NGROK_URL" ]; then
    break
  fi
  
  COUNTER=$((COUNTER+1))
  sleep 2
done

# Nếu không tìm thấy URL sau nhiều lần thử
if [ -z "$NGROK_URL" ]; then
  echo "Không thể lấy URL từ ngrok sau $MAX_TRIES lần thử. Thoát."
  exit 1
fi

echo "URL Ngrok đã được tìm thấy: $NGROK_URL"

# Cập nhật cấu hình n8n
echo "Cập nhật cấu hình webhook cho n8n..."
curl -X POST -H "Content-Type: application/json" -d "{\"key\":\"N8N_WEBHOOK_URL\",\"value\":\"$NGROK_URL\"}" http://n8n:5678/rest/variables

# Cập nhật webhook Telegram nếu có token
if [ ! -z "$TELEGRAM_BOT_TOKEN" ]; then
  echo "Cập nhật webhook Telegram..."
  WEBHOOK_URL="${NGROK_URL}/webhook"
  curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/setWebhook?url=${WEBHOOK_URL}"
  echo "\nKiểm tra thông tin webhook Telegram:"
  curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getWebhookInfo"
else
  echo "Không tìm thấy TELEGRAM_BOT_TOKEN. Bỏ qua việc cập nhật webhook Telegram."
fi

echo "\nHoàn tất cài đặt! N8N có thể truy cập tại: $NGROK_URL"