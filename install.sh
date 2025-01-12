#!/usr/bin/env bash
#
# Скрипт установки виртуального окружения, необходимых пакетов,
# а также интерактивного создания .env файла c настройками для бота.
#
# [!] Улучшенная версия с рекомендациями.

# ---------------------------------------------------------
# 1. Общие настройки скрипта
# ---------------------------------------------------------
set -euo pipefail  # [!] Выходим при ошибках и неинициализированных переменных

# ---------------------------------------------------------
# 2. Создание и активация виртуального окружения
# ---------------------------------------------------------
echo ">>> Проверяем наличие python3..."
if ! command -v python3 &>/dev/null; then
  echo "Ошибка: python3 не найден в PATH. Установите python3 и повторите запуск."
  exit 1
fi

echo ">>> Создаём виртуальное окружение (venv) в каталоге ./venv"
python3 -m venv venv

# Проверяем, что venv действительно создался
if [[ ! -d "venv" ]]; then
  echo "Ошибка: не удалось создать виртуальное окружение venv/"
  exit 1
fi

echo ">>> Активируем venv..."
# shellcheck source=/dev/null
source venv/bin/activate

# ---------------------------------------------------------
# 3. Установка/обновление pip и необходимых пакетов
# ---------------------------------------------------------
echo ">>> Обновляем pip/setuptools/wheel..."
pip install --upgrade pip setuptools wheel

echo ">>> Устанавливаем основные библиотеки бота..."
pip install qrcode aiosqlite "aiogram==2.15" pillow python-dotenv asyncio requests "yookassa==2.3.5"

echo ">>> Даунгрейд urllib3 для совместимости..."
pip install --upgrade "urllib3<2.0"

# ---------------------------------------------------------
# 4. Сбор данных о серверах
# ---------------------------------------------------------
server_ip_list=""
server_url_list=""
login_url_list=""
add_client_url_list=""

while true; do
  echo "======================================"
  echo "Добавление нового сервера в список..."
  echo "======================================"

  read -r -p "Введите IP сервера (например, 212.xxx.xxx.xxx): " server_ip
  read -r -p "Введите порт панели (например, 22800): " panel_port

  # Формируем URL
  server_url="http://${server_ip}:${panel_port}/vay/"
  login_url="${server_url}login"
  add_client_url="${server_url}panel/api/inbounds/addClient"

  # [!] Если это первый сервер — записываем напрямую, иначе через запятую
  if [[ -z "$server_ip_list" ]]; then
    server_ip_list="$server_ip"
    server_url_list="$server_url"
    login_url_list="$login_url"
    add_client_url_list="$add_client_url"
  else
    server_ip_list="${server_ip_list},${server_ip}"
    server_url_list="${server_url_list},${server_url}"
    login_url_list="${login_url_list},${login_url}"
    add_client_url_list="${add_client_url_list},${add_client_url}"
  fi

  echo "Сформированные данные:"
  echo "  server_url: $server_url"
  echo "  login_url: $login_url"
  echo "  add_client_url: $add_client_url"

  read -r -p "Хотите ли вы добавить ещё один сервер? (y/n): " more
  case "$more" in
    [yY]) ;;
    *) break ;;
  esac
done

# ---------------------------------------------------------
# 5. Чтение остальных параметров
# ---------------------------------------------------------
echo ""
echo "======================================"
echo "Настройка остальных параметров бота..."
echo "======================================"

read -r -p "Введите BOT_TOKEN: " bot_token
read -r -p "Введите LOGIN_USERNAME: " login_username
read -r -p "Введите LOGIN_PASSWORD: " login_password

read -r -p "Введите NIK (@username): " nik
# Если пользователь забыл поставить @ — добавим
if [[ "$nik" != @* ]]; then
  nik="@$nik"
fi

read -r -p "Введите CHANNEL_ID (@channelname): " channel_id
if [[ "$channel_id" != @* ]]; then
  channel_id="@$channel_id"
fi

read -r -p "Введите ADMIN_ID (число): " admin_id

read -r -p "Введите CHANNEL_LINK (https://t.me/...): " channel_link
# Если пользователь ввёл без https://t.me/
if [[ "$channel_link" != https://t.me/* ]]; then
  channel_link="https://t.me/$channel_link"
fi

# ID инбаундов
read -r -p "Введите ID_1 (для пробного периода): " id_1
read -r -p "Введите ID_2 (для клиентов): " id_2
read -r -p "Введите ID_3 (для бонусов): " id_3

# Цены (рубли)
read -r -p "Введите цену за 1 месяц (в рублях): " price_1_month_rub
read -r -p "Введите цену за 2 месяца (в рублях): " price_2_months_rub
read -r -p "Введите цену за 6 месяцев (в рублях): " price_6_months_rub
read -r -p "Введите цену за 1 год (в рублях): " price_1_year_rub

# Конвертация в копейки
price_1_month=$((price_1_month_rub * 100))
price_2_months=$((price_2_months_rub * 100))
price_6_months=$((price_6_months_rub * 100))
price_1_year=$((price_1_year_rub * 100))

# YooKassa
read -r -p "Введите YOOKASSA_SHOP_ID: " yookassa_shop_id
read -r -p "Введите YOOKASSA_API_KEY: " yookassa_api_key

# ---------------------------------------------------------
# 6. Генерация .env файла
# ---------------------------------------------------------
echo ">>> Создаём файл .env..."

cat > .env << EOF
PAYMENTS_TOKEN=11111:TEST:11111 #не трогать

# Списки (через запятую)
SERVER_IP=$server_ip
SERVER_URL=$server_url
SERVERS_IP=$server_ip_list
SERVERS_URL=$server_url_list
LOGIN_URL=$login_url_list
ADD_CLIENT_URL=$add_client_url
ADD_CLIENT_URL_LIST=$add_client_url_list


BOT_TOKEN=$bot_token
LOGIN_USERNAME=$login_username
LOGIN_PASSWORD=$login_password

DATABASE_PATH=/etc/x-ui/x-ui.db
USERSDATABASE_PATH=users.db

ID_1=$id_1
ID_2=$id_2
ID_3=$id_3
NIK=$nik
CHANNEL_ID=$channel_id
ADMIN_ID=$admin_id
CHANNEL_LINK=$channel_link

# Цены и тарифы (в копейках)
PRICE_1_MONTH=$price_1_month
PRICE_2_MONTHS=$price_2_months
PRICE_6_MONTHS=$price_6_months
PRICE_1_YEAR=$price_1_year

# Объем трафика (в байтах)
TOTAL_GB_259200000=5368709120
TOTAL_GB_2592000000=unlimited
TOTAL_GB_5184000000=unlimited
TOTAL_GB_15552000000=unlimited
TOTAL_GB_31104000000=unlimited

# Цены и тарифы (для вывода в рублях)
PRICE_2592000000=$price_1_month_rub
PRICE_5184000000=$price_2_months_rub
PRICE_15552000000=$price_6_months_rub
PRICE_31104000000=$price_1_year_rub

# YooKassa
YOOKASSA_SHOP_ID=$yookassa_shop_id
YOOKASSA_API_KEY=$yookassa_api_key
EOF

echo ""
echo "======================================"
echo "Установка завершена! Файл .env создан."
echo "======================================"
echo "Проверьте содержимое файла .env и убедитесь, что все данные введены корректно."

# [!] На будущее: если хотите, можете дополнительно вывести сам .env (cat .env) для наглядности
echo "Содержимое .env:"
cat .env

echo "======================================"
echo "Управление ботом:"
echo "запуск - sudo systemctl start bot.service"
echo "перезапуск - sudo systemctl restart bot.service"
echo "остановка -sudo systemctl stop bot.service"
echo "======================================"

# Конец скрипта
