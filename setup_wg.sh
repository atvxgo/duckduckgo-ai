#!/bin/bash

# Обновляем список пакетов
echo "Обновляем список пакетов..."
sudo apt update

# Устанавливаем WireGuard
echo "Устанавливаем WireGuard..."
sudo apt install -y wireguard

# Генерируем ключи для сервера
echo "Генерируем ключи для сервера..."
sudo wg genkey | sudo tee /etc/wireguard/server_private.key | wg pubkey | sudo tee /etc/wireguard/server_public.key

# Генерируем ключи для клиентов
echo "Генерируем ключи для клиентов..."
for i in {2..4}; do
  sudo wg genkey | sudo tee /etc/wireguard/client$i_private.key | wg pubkey | sudo tee /etc/wireguard/client$i_public.key
done

# Создаем конфигурационный файл для сервера
echo "Создаем конфигурационный файл для сервера..."
sudo bash -c "cat > /etc/wireguard/wg0.conf" <<EOF
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = $(cat /etc/wireguard/server_private.key)

[Peer]
PublicKey = $(cat /etc/wireguard/client2_public.key)
AllowedIPs = 10.0.0.2/32

[Peer]
PublicKey = $(cat /etc/wireguard/client3_public.key)
AllowedIPs = 10.0.0.3/32

[Peer]
PublicKey = $(cat /etc/wireguard/client4_public.key)
AllowedIPs = 10.0.0.4/32
EOF

# Создаем конфигурационные файлы для клиентов
echo "Создаем конфигурационные файлы для клиентов..."
for i in {2..4}; do
  sudo bash -c "cat > /etc/wireguard/wg0_client$i.conf" <<EOF
[Interface]
Address = 10.0.0.$i/24
ListenPort = 51820
PrivateKey = $(cat /etc/wireguard/client$i_private.key)

[Peer]
PublicKey = $(cat /etc/wireguard/server_public.key)
Endpoint = $(hostname -I | awk '{print $1}'):51820
AllowedIPs = 0.0.0.0/0
EOF
done

# Запускаем интерфейс WireGuard в фоне
echo "Запускаем интерфейс WireGuard в фоне..."
sudo wg-quick up wg0 &

# Проверяем статус интерфейса WireGuard
echo "Проверяем статус интерфейса WireGuard..."
sudo wg show

# Выводим конфигурационные файлы для клиентов
echo "Конфигурационные файлы для клиентов:"
for i in {2..4}; do
  echo "wg0_client$i.conf:"
  sudo cat /etc/wireguard/wg0_client$i.conf
done
