#!/bin/bash

# Указание конкретного интерфейса
INTERFACE="wlp4s0"

# Проверка прав доступа
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root. Try: sudo $0"
  exit 1
fi

# Проверка, существует ли интерфейс
if [ ! -d "/sys/class/net/$INTERFACE" ]; then
  echo "Interface $INTERFACE not found"
  exit 1
fi

# Название сети (SSID для Wi-Fi)
SSID=$(sudo iwgetid "$INTERFACE" -r 2>/dev/null)

if [ -z "$SSID" ]; then
  echo "Disconnected"
  exit 0
fi

# Определение скорости соединения
SPEED_MBPS="N/A"
if [[ "$(cat /sys/class/net/$INTERFACE/type 2>/dev/null)" -eq 1 ]]; then
  # Если интерфейс Wi-Fi
  SPEED_MBPS=$(sudo iw dev "$INTERFACE" link | awk '/tx bitrate/ {print $3}')
else
  # Если интерфейс проводной
  SPEED_MBPS=$(sudo ethtool "$INTERFACE" 2>/dev/null | awk '/Speed:/ {print $2}' || echo "N/A")
fi

# Конвертация скорости в MB/s
if [[ "$SPEED_MBPS" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
  SPEED_MBPS=$(sudo echo "$SPEED_MBPS / 8" | bc -l)
  SPEED_MBPS=$(sudo printf "%.2f" "$SPEED_MBPS")  # Округляем до двух знаков после запятой
  UNIT="MB/s"
else
  UNIT=""
fi

# Вывод информации
echo "$SSID | ${SPEED_MBPS:-N/A} $UNIT"
