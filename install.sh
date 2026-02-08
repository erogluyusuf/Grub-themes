#!/bin/bash

# Root kontrolü
if [ "$EUID" -ne 0 ]; then 
  echo "Lütfen bu betiği sudo ile çalıştırın."
  exit
fi

THEME_NAME="Matrices-circle-window"
THEME_DIR="/boot/grub2/themes/$THEME_NAME"

echo "-----------------------------------------------"
echo "GRUB Özelleştirme ve Tema Kurulumu Başlıyor..."
echo "-----------------------------------------------"

# 1. Temayı Klasöre Kopyala
echo "[1/4] Tema dosyaları sisteme kopyalanıyor..."
mkdir -p /boot/grub2/themes/
cp -r . /boot/grub2/themes/$THEME_NAME 2>/dev/null

# 2. Windows  Girişini 40_custom Dosyasına Ekle
echo "[2/4] Windows  önyükleme girişi oluşturuluyor..."
cat <<EOF > /etc/grub.d/40_custom
#!/usr/bin/sh
exec tail -n +3 \$0
menuentry 'Windows' --class windows --class os {
    insmod part_gpt
    insmod fat
    search --no-floppy --fs-uuid --set=root 79C9-93A2
    chainloader /EFI/Microsoft/Boot/bootmgfw.efi
}
EOF
chmod +x /etc/grub.d/40_custom

# 3. /etc/default/grub Ayarlarını Optimize Et
echo "[3/4] /etc/default/grub yapılandırılıyor..."
# Mevcut tema ve BLSCFG satırlarını temizle/güncelle
sed -i '/GRUB_THEME=/d' /etc/default/grub
sed -i '/GRUB_ENABLE_BLSCFG=/d' /etc/default/grub
sed -i '/GRUB_DISTRIBUTOR=/d' /etc/default/grub

cat <<EOF >> /etc/default/grub
GRUB_DISTRIBUTOR="Fedora"
GRUB_ENABLE_BLSCFG=false
GRUB_THEME="$THEME_DIR/theme.txt"
EOF

# 4. GRUB'u Yenile
echo "[4/4] grub2-mkconfig ile değişiklikler işleniyor..."
grub2-mkconfig -o /boot/grub2/grub.cfg

echo "-----------------------------------------------"
echo "İşlem Tamam! Windows eklendi ve Tema aktif edildi."
echo "-----------------------------------------------"